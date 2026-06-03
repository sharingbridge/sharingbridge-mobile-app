import 'package:geolocator/geolocator.dart';

/// GPS at handover registration time (neighbourhood feed + PostGIS).
class HandoverLocation {
  const HandoverLocation({
    required this.lat,
    required this.lng,
    this.label = '',
  });

  final double lat;
  final double lng;
  final String label;
}

/// Returns coordinates when permission and services allow; otherwise null.
Future<HandoverLocation?> captureHandoverLocation() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return null;
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return HandoverLocation(
      lat: position.latitude,
      lng: position.longitude,
    );
  } catch (_) {
    return null;
  }
}
