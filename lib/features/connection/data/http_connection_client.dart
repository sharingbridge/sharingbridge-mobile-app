import '../../auth/data/auth_session_holder.dart';
import '../../donor_setup/data/auth_context.dart';
import '../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../donor_setup/data/http_donor_setup_api_client.dart';
import '../domain/models/order_connection.dart';

/// Loads order contacts from GET /v1/connections/:orderCode.
class HttpConnectionClient {
  HttpConnectionClient({
    required this.baseUrl,
    AuthContext? authContext,
    HttpDonorSetupApiClient? api,
  })  : _authOverride = authContext,
        _api = api ??
            HttpDonorSetupApiClient(
              baseUrl: baseUrl,
              authContext: authContext,
              requestTimeout: donorSeekerWriteRequestTimeout,
            );

  final String baseUrl;
  final AuthContext? _authOverride;
  final HttpDonorSetupApiClient _api;

  AuthContext get _auth => _authOverride ?? AuthSessionHolder.resolve();

  Future<OrderConnection> fetchOrderConnection(String orderCode) async {
    final trimmed = orderCode.trim();
    if (trimmed.isEmpty) {
      throw DonorSetupBadRequestException(
        statusCode: 400,
        errorCode: 'empty_order_code',
        message: 'Enter an order code.',
      );
    }

    final decoded = await _api.getDonorSeekerJson(
      path: '/v1/connections/${Uri.encodeComponent(trimmed)}',
    );

    final raw = decoded['connection'];
    if (raw is! Map<String, dynamic>) {
      throw const DonorSetupResponseException(
        'connection missing from response',
      );
    }

    final connection = OrderConnection.fromJson(raw);
    if (connection.orderCode.isEmpty) {
      throw const DonorSetupResponseException(
        'order_code missing from connection',
      );
    }
    return connection;
  }
}
