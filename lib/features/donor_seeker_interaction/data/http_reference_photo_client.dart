import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../auth/data/auth_session_holder.dart';
import '../../donor_setup/data/auth_context.dart';
import '../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../domain/models/reference_photo_upload.dart';

/// Uploads seeker reference photos to sharingbridge-photo-service.
class HttpReferencePhotoClient {
  HttpReferencePhotoClient({
    required this.baseUrl,
    AuthContext? authContext,
    HttpClient? httpClient,
    this.requestTimeout = const Duration(seconds: 30),
  })  : _authOverride = authContext,
        _httpClient = httpClient ?? HttpClient() {
    _httpClient.connectionTimeout = requestTimeout;
  }

  final String baseUrl;
  final AuthContext? _authOverride;
  final HttpClient _httpClient;
  final Duration requestTimeout;

  AuthContext get _auth => _authOverride ?? AuthSessionHolder.resolve();

  Future<ReferencePhotoUpload> uploadSeekerReference(XFile file) async {
    final token = _auth.bearerToken.trim();
    if (token.isEmpty) {
      throw const DonorSetupBadRequestException(
        statusCode: 401,
        errorCode: 'missing_auth',
        message: 'Sign in is required to upload a photo.',
      );
    }

    final uri = Uri.parse(
      '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/v1/photos/upload',
    );
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const DonorSetupResponseException('Photo file is empty.');
    }

    final mime = (file.mimeType ?? 'image/jpeg').split(';').first.trim().toLowerCase();
    final boundary = '----sb-${DateTime.now().microsecondsSinceEpoch}';
    final filename = file.name.trim().isNotEmpty ? file.name : 'reference.jpg';

    final body = <int>[];
    void writeString(String value) {
      body.addAll(utf8.encode(value));
    }

    writeString('--$boundary\r\n');
    writeString('Content-Disposition: form-data; name="photo_type"\r\n\r\n');
    writeString('seeker_reference\r\n');
    writeString('--$boundary\r\n');
    writeString(
      'Content-Disposition: form-data; name="file"; filename="$filename"\r\n',
    );
    writeString('Content-Type: $mime\r\n\r\n');
    body.addAll(bytes);
    writeString('\r\n--$boundary--\r\n');

    final request = await _httpClient.postUrl(uri);
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/form-data; boundary=$boundary',
    );
    request.contentLength = body.length;
    request.add(body);

    final response = await request.close().timeout(requestTimeout);
    final responseBody = await response.transform(utf8.decoder).join();

    Map<String, dynamic> decoded = <String, dynamic>{};
    if (responseBody.isNotEmpty) {
      try {
        final parsed = jsonDecode(responseBody);
        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        } else if (parsed is Map) {
          decoded = Map<String, dynamic>.from(parsed);
        }
      } on FormatException {
        throw DonorSetupResponseException(
          'Photo upload response was not valid JSON (HTTP ${response.statusCode}).',
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded['message']?.toString() ??
          'Photo upload failed (HTTP ${response.statusCode}).';
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw DonorSetupBadRequestException(
          statusCode: response.statusCode,
          errorCode: decoded['code']?.toString(),
          message: message,
        );
      }
      throw DonorSetupResponseException(message);
    }

    return ReferencePhotoUpload.fromJson(decoded);
  }
}
