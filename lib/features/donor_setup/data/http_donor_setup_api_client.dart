import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../../auth/data/auth_session_holder.dart';
import 'auth_context.dart';
import 'donor_setup_api_client.dart';
import 'donor_setup_api_exceptions.dart';

/// Server may retry orchestration on Render 429 with backoff (up to ~2 min).
const Duration suggestVendorsRequestTimeout = Duration(seconds: 90);

/// Retry policy applied to a single API call.
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialBackoff = const Duration(milliseconds: 200),
    this.backoffMultiplier = 2.0,
    this.retryOnServerError = true,
  });

  /// Conservative policy used by mutating POSTs: only retry on network-level
  /// failures (the request likely never reached the server). Never retry on
  /// 5xx because the server may have partially processed the write.
  static const RetryPolicy mutating = RetryPolicy(
    maxAttempts: 2,
    retryOnServerError: false,
  );

  final int maxAttempts;
  final Duration initialBackoff;
  final double backoffMultiplier;
  final bool retryOnServerError;

  Duration backoffFor(int attempt) {
    final factor = math.pow(backoffMultiplier, attempt - 1);
    return Duration(
      milliseconds: (initialBackoff.inMilliseconds * factor).round(),
    );
  }
}

class HttpDonorSetupApiClient implements DonorSetupApiClient {
  HttpDonorSetupApiClient({
    required this.baseUrl,
    /// Fixed credentials for tests only. When null (production), [_auth] reads
    /// [AuthSessionHolder] on every request so a JWT set after page load is used.
    AuthContext? authContext,
    HttpClient? httpClient,
    this.requestTimeout = const Duration(seconds: 8),
    this.retryPolicy = const RetryPolicy(),
    this.savePresetsRetryPolicy = RetryPolicy.mutating,
  })  : _authOverride = authContext,
        _httpClient = httpClient ?? HttpClient() {
    _httpClient.connectionTimeout = requestTimeout;
  }

  final String baseUrl;
  final AuthContext? _authOverride;

  /// Credentials for the outgoing call: re-reads [AuthSessionHolder] when there is
  /// no [_authOverride]. Reuses the same JWT from sign-in; does not mint a new token.
  AuthContext get _auth => _authOverride ?? AuthSessionHolder.resolve();
  final HttpClient _httpClient;
  final Duration requestTimeout;
  final RetryPolicy retryPolicy;
  final RetryPolicy savePresetsRetryPolicy;

  @override
  Future<Map<String, dynamic>> suggestVendors({
    required String queryText,
    required double? lat,
    required double? lng,
    String? manualArea,
  }) {
    final trimmedArea = manualArea?.trim();
    final hasGps = lat != null && lng != null;
    final hasArea = trimmedArea != null && trimmedArea.isNotEmpty;
    final payload = <String, dynamic>{
      'query_text': queryText,
      'location_precision': hasGps
          ? 'gps'
          : (hasArea ? 'manual_area' : 'unspecified'),
      'client_platform': 'flutter-mobile',
      if (hasGps) ...<String, dynamic>{'lat': lat, 'lng': lng},
      if (hasArea) 'manual_area': trimmedArea,
    };

    return _runWithRetry(
      policy: retryPolicy,
      operation: () => _sendJson(
        method: 'POST',
        uri: Uri.parse('$baseUrl/v1/donor-setup/suggest-vendors'),
        body: payload,
        timeout: suggestVendorsRequestTimeout,
      ),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getPresets({required String userId}) {
    return _runWithRetry(
      policy: retryPolicy,
      operation: () async {
        final decoded = await _sendJson(
          method: 'GET',
          uri: _auth.donorSetupPreferencesUri(
            baseUrl,
            explicitUserId: userId,
          ),
        );
        final presetsRaw = decoded['presets'];
        if (presetsRaw is! List) {
          throw const DonorSetupResponseException(
            'presets must be a list',
          );
        }
        return presetsRaw.cast<Map<String, dynamic>>();
      },
    );
  }

  @override
  Future<void> savePresets({
    required String userId,
    required List<Map<String, dynamic>> payload,
  }) {
    return _runWithRetry<void>(
      policy: savePresetsRetryPolicy,
      operation: () async {
        await _sendJson(
          method: 'POST',
          uri: Uri.parse('$baseUrl/v1/donor-setup/preferences'),
          body: _auth.withOptionalUserId(
            <String, dynamic>{'presets': payload},
            explicitUserId: userId,
          ),
        );
      },
    );
  }

  @override
  Future<void> clearPresets({required String userId}) {
    return _runWithRetry<void>(
      policy: savePresetsRetryPolicy,
      operation: () async {
        await _sendJson(
          method: 'DELETE',
          uri: _auth.donorSetupPreferencesUri(
            baseUrl,
            explicitUserId: userId,
          ),
        );
      },
    );
  }

  /// Donor–seeker instruction pack (integration-service → ai-orchestration).
  /// Uses [requestTimeout] (90s when created via [HttpInstructionPackClient]).
  Future<Map<String, dynamic>> requestInstructionPack({
    required Map<String, dynamic> body,
  }) {
    return _runWithRetry(
      policy: const RetryPolicy(maxAttempts: 1),
      operation: () => _sendJson(
        method: 'POST',
        uri: Uri.parse('$baseUrl/v1/donor-seeker/instruction-pack'),
        body: body,
      ),
    );
  }

  /// Donor–seeker routes (instruction-pack, order-intents, …).
  Future<Map<String, dynamic>> postDonorSeekerJson({
    required String path,
    required Map<String, dynamic> body,
  }) {
    return _runWithRetry(
      policy: savePresetsRetryPolicy,
      operation: () => _sendJson(
        method: 'POST',
        uri: Uri.parse('$baseUrl$path'),
        body: body,
      ),
    );
  }

  Future<Map<String, dynamic>> patchDonorSeekerJson({
    required String path,
    required Map<String, dynamic> body,
  }) {
    return _runWithRetry(
      policy: savePresetsRetryPolicy,
      operation: () => _sendJson(
        method: 'PATCH',
        uri: Uri.parse('$baseUrl$path'),
        body: body,
      ),
    );
  }

  Future<Map<String, dynamic>> getDonorSeekerJson({
    required String path,
    Map<String, String>? queryParameters,
  }) {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
    return _runWithRetry(
      policy: retryPolicy,
      operation: () => _sendJson(method: 'GET', uri: uri),
    );
  }

  @override
  Future<void> removePreset({
    required String userId,
    required String restaurantName,
    required String orderUrl,
  }) {
    return _runWithRetry<void>(
      policy: savePresetsRetryPolicy,
      operation: () async {
        await _sendJson(
          method: 'POST',
          uri: Uri.parse(
            '$baseUrl/v1/donor-setup/preferences/delete-item',
          ),
          body: _auth.withOptionalUserId(
            <String, dynamic>{
              'restaurant_name': restaurantName,
              'order_url': orderUrl,
            },
            explicitUserId: userId,
          ),
        );
      },
    );
  }

  /// Executes a single HTTP call and maps low-level errors to typed
  /// [DonorSetupApiException]s. Does NOT retry; that's [_runWithRetry]'s job.
  Future<Map<String, dynamic>> _sendJson({
    required String method,
    required Uri uri,
    Object? body,
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? requestTimeout;
    HttpClientResponse response;
    try {
      final HttpClientRequest request;
      switch (method) {
        case 'GET':
          request = await _httpClient.getUrl(uri);
          break;
        case 'POST':
          request = await _httpClient.postUrl(uri);
          break;
        case 'DELETE':
          request = await _httpClient.deleteUrl(uri);
          break;
        case 'PATCH':
          request = await _httpClient.patchUrl(uri);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
      _auth.toHeaders().forEach((name, value) {
        request.headers.set(name, value);
      });
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      response = await request.close().timeout(effectiveTimeout);
    } on TimeoutException catch (error) {
      throw DonorSetupTimeoutException(
        'Request to $uri timed out after ${effectiveTimeout.inMilliseconds}ms: $error',
      );
    } on SocketException catch (error) {
      throw DonorSetupNetworkException(
        'Network unavailable for $uri: ${error.message}',
      );
    } on HttpException catch (error) {
      throw DonorSetupNetworkException(
        'HTTP transport error for $uri: ${error.message}',
      );
    }

    final responseBody = await utf8
        .decodeStream(response)
        .timeout(effectiveTimeout, onTimeout: () => '');

    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      if (responseBody.isEmpty) {
        return <String, dynamic>{};
      }
      final dynamic decoded;
      try {
        decoded = jsonDecode(responseBody);
      } on FormatException catch (error) {
        throw DonorSetupResponseException(
          'Response was not valid JSON: ${error.message}',
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw const DonorSetupResponseException(
          'Response must be a JSON object',
        );
      }
      return decoded;
    }

    final parsed = _safeParseError(responseBody);
    if (status >= 400 && status < 500) {
      throw DonorSetupBadRequestException(
        statusCode: status,
        errorCode: parsed.code,
        message: parsed.message ?? 'HTTP $status',
      );
    }
    throw DonorSetupServerException(
      statusCode: status,
      message: parsed.message ?? 'HTTP $status',
    );
  }

  Future<T> _runWithRetry<T>({
    required RetryPolicy policy,
    required Future<T> Function() operation,
  }) async {
    var attempt = 0;
    while (true) {
      attempt += 1;
      try {
        return await operation();
      } on DonorSetupApiException catch (error) {
        final canRetry = _isRetryable(error, policy) && attempt < policy.maxAttempts;
        if (!canRetry) {
          rethrow;
        }
        await Future<void>.delayed(policy.backoffFor(attempt));
      }
    }
  }

  bool _isRetryable(DonorSetupApiException error, RetryPolicy policy) {
    if (error is DonorSetupNetworkException ||
        error is DonorSetupTimeoutException) {
      return true;
    }
    if (error is DonorSetupServerException) {
      return policy.retryOnServerError;
    }
    return false;
  }

  _ParsedError _safeParseError(String body) {
    if (body.isEmpty) {
      return const _ParsedError();
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return _ParsedError(
          code: decoded['code']?.toString(),
          message: decoded['message']?.toString(),
        );
      }
    } on FormatException {
      // Fall through to raw body fallback below.
    }
    return _ParsedError(message: body);
  }
}

class _ParsedError {
  const _ParsedError({this.code, this.message});

  final String? code;
  final String? message;
}
