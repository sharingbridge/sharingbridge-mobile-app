import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/data/donor_seeker_api_errors.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/data/donor_setup_api_exceptions.dart';

void main() {
  test('maps auth failures to re-login copy with support refs', () {
    expect(
      formatDonorSeekerError(
        const DonorSetupBadRequestException(
          statusCode: 401,
          errorCode: 'missing_auth_context',
          message:
              'Your sign-in has expired or is invalid. Please sign out and sign in again.',
          detail: 'Missing or invalid Bearer token.',
        ),
      ),
      'Your sign-in has expired or is invalid. Please sign out and sign in again. '
      '(Support: HTTP 401 · missing_auth_context · Missing or invalid Bearer token.)',
    );
  });

  test('keeps legacy bearer wording in the support ref', () {
    final text = formatDonorSeekerError(
      const DonorSetupBadRequestException(
        statusCode: 401,
        errorCode: 'missing_auth_context',
        message: 'A valid Bearer token is required.',
      ),
    );
    expect(text, contains('sign in again'));
    expect(text, contains('Support:'));
    expect(text, contains('A valid Bearer token is required.'));
  });

  test('keeps non-auth client errors', () {
    expect(
      formatDonorSeekerError(
        const DonorSetupBadRequestException(
          statusCode: 400,
          errorCode: 'invalid_request',
          message: 'Choose a standard menu item.',
        ),
      ),
      'Choose a standard menu item.',
    );
  });
}
