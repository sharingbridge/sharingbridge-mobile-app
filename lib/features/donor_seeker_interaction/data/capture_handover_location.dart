import 'package:geolocator/geolocator.dart';

import 'handover_location_result.dart';

/// GPS at handover registration time (neighbourhood feed + PostGIS).
class HandoverLocation {
  const HandoverLocation({
    required this.lat,
    required this.lng,
    this.label = '',
    this.formattedAddress = '',
    this.localityKey = '',
  });

  final double lat;
  final double lng;
  final String label;
  final String formattedAddress;
  final String localityKey;

  HandoverLocation copyWith({
    double? lat,
    double? lng,
    String? label,
    String? formattedAddress,
    String? localityKey,
  }) {
    return HandoverLocation(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      label: label ?? this.label,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      localityKey: localityKey ?? this.localityKey,
    );
  }
}

/// Returns coordinates when permission and services allow; otherwise null.
Future<HandoverLocation?> captureHandoverLocation() async {
  final result = await captureHandoverLocationResult();
  return result.location;
}

/// Detailed capture result for permission and GPS error messaging.
Future<HandoverLocationResult> captureHandoverLocationResult() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return const HandoverLocationResult(
      failure: HandoverLocationFailure.servicesDisabled,
    );
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    return const HandoverLocationResult(
      failure: HandoverLocationFailure.permissionDeniedForever,
    );
  }
  if (permission == LocationPermission.denied) {
    return const HandoverLocationResult(
      failure: HandoverLocationFailure.permissionDenied,
    );
  }

  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return HandoverLocationResult(
      location: HandoverLocation(
        lat: position.latitude,
        lng: position.longitude,
      ),
    );
  } catch (_) {
    return const HandoverLocationResult(
      failure: HandoverLocationFailure.positionUnavailable,
    );
  }
}
