import 'donor_setup_api_exceptions.dart';

const String _reloginMessage =
    'Your sign-in has expired or is invalid. Please sign out and sign in again.';

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
    return 'The server took too long to respond. '
        'If this is the first request after idle, wait a moment and try again '
        '(the API may be waking up).';
  }
  if (error is DonorSetupNetworkException) {
    return 'Network error. Check your connection and try again.';
  }
  if (error is DonorSetupBadRequestException) {
    if (_isAuthFailure(error.statusCode, error.errorCode, error.message)) {
      return _authReloginWithSupport(
        statusCode: error.statusCode,
        errorCode: error.errorCode,
        detail: error.detail ?? error.message,
      );
    }
    return error.message;
  }
  if (error is DonorSetupServerException) {
    if (_isAuthFailure(error.statusCode, null, error.message)) {
      return _authReloginWithSupport(
        statusCode: error.statusCode,
        detail: error.message,
      );
    }
    return error.message;
  }
  if (error is DonorSetupApiException) {
    if (_looksLikeAuthMessage(error.message)) {
      return _authReloginWithSupport(detail: error.message);
    }
    return error.message;
  }
  final raw = error.toString();
  if (_looksLikeAuthMessage(raw)) {
    return _authReloginWithSupport(detail: raw);
  }
  return 'Something went wrong: $error';
}

String _authReloginWithSupport({
  int? statusCode,
  String? errorCode,
  String? detail,
}) {
  final parts = <String>[];
  if (statusCode != null) {
    parts.add('HTTP $statusCode');
  }
  final code = errorCode?.trim() ?? '';
  if (code.isNotEmpty) {
    parts.add(code);
  }
  final technical = detail?.trim() ?? '';
  if (technical.isNotEmpty &&
      technical.toLowerCase() != _reloginMessage.toLowerCase() &&
      !technical.toLowerCase().startsWith('your sign-in has expired')) {
    parts.add(technical);
  }
  if (parts.isEmpty) {
    return _reloginMessage;
  }
  return '$_reloginMessage (Support: ${parts.join(' · ')})';
}

bool _isAuthFailure(int? statusCode, String? errorCode, String? message) {
  if (statusCode == 401) {
    return true;
  }
  final code = errorCode?.trim().toLowerCase() ?? '';
  if (code == 'missing_auth_context' ||
      code == 'unauthorized' ||
      code == 'token_expired' ||
      code == 'invalid_token') {
    return true;
  }
  return _looksLikeAuthMessage(message);
}

bool _looksLikeAuthMessage(String? message) {
  final text = message?.toLowerCase() ?? '';
  if (text.isEmpty) {
    return false;
  }
  return text.contains('bearer token') ||
      text.contains('token is invalid') ||
      text.contains('token is expired') ||
      text.contains('token expired') ||
      text.contains('invalid token') ||
      text.contains('unauthorized') ||
      text.contains('sign-in has expired') ||
      text.contains('sign in again');
}
