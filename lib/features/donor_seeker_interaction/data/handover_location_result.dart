import 'capture_handover_location.dart';

enum HandoverLocationFailure {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  positionUnavailable,
}

class HandoverLocationResult {
  const HandoverLocationResult({
    this.location,
    this.failure,
  });

  final HandoverLocation? location;
  final HandoverLocationFailure? failure;

  bool get isSuccess => location != null;

  String get message {
    switch (failure) {
      case HandoverLocationFailure.servicesDisabled:
        return 'Turn on location services on this device, then try again.';
      case HandoverLocationFailure.permissionDenied:
        return 'Location permission is required. Allow access when prompted.';
      case HandoverLocationFailure.permissionDeniedForever:
        return 'Location permission is blocked. Enable it in system settings for SharingBridge.';
      case HandoverLocationFailure.positionUnavailable:
        return 'Could not read GPS right now. Move to an open area and try again.';
      case null:
        return '';
    }
  }
}
