import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/data/donor_seeker_api_errors.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/data/donor_setup_api_exceptions.dart';

void main() {
  test('maps invalid/expired token errors to re-login copy', () {
    expect(
      formatDonorSeekerError(
        const DonorSetupBadRequestException(
          statusCode: 401,
          errorCode: 'missing_auth_context',
          message: 'A valid Bearer token is required.',
        ),
      ),
      'Your sign-in has expired or is invalid. Please sign out and sign in again.',
    );
    expect(
      formatDonorSeekerError(
        const DonorSetupBadRequestException(
          statusCode: 401,
          errorCode: null,
          message: 'Token is expired.',
        ),
      ),
      contains('sign in again'),
    );
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
