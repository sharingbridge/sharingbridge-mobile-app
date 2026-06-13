import 'donor_setup_api_exceptions.dart';

/// User-facing copy for integration / donor-seeker API failures.
String formatDonorSeekerError(
  Object error, {
  bool instructionPack = false,
}) {
  if (error is DonorSetupTimeoutException) {
    if (instructionPack) {
      return 'Generating instructions is taking longer than usual. '
          'This can happen when photo analysis or AI handover text runs — '
          'not because the app is waking up. Wait a moment and tap Retry.';
    }
    return 'The server took too long to respond. Check your connection and try again.';
  }
  if (error is DonorSetupNetworkException) {
    return 'Network error. Check your connection and try again.';
  }
  if (error is DonorSetupBadRequestException) {
    return error.message;
  }
  if (error is DonorSetupApiException) {
    return error.toString();
  }
  return 'Something went wrong: $error';
}
