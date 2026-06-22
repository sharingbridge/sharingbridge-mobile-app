/// Initiator-facing integration-service routes (legacy `/v1/donor-*` still accepted).
abstract final class IntegrationApiPaths {
  static const String suggestVendors = '/v1/initiator-setup/suggest-vendors';
  static const String preferences = '/v1/initiator-setup/preferences';
  static const String preferencesDeleteItem =
      '/v1/initiator-setup/preferences/delete-item';
  static const String instructionPack = '/v1/instruction-pack';
  static const String orderIntents = '/v1/order-intents';

  static String connection(String orderCode) =>
      '/v1/connections/${Uri.encodeComponent(orderCode.trim())}';
}
