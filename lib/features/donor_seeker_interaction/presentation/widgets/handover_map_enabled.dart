/// Whether the cab-style handover map UI is compiled in.
///
/// Set automatically from [GOOGLE_MAPS_API_KEY] in `android/local.properties`
/// at Gradle build time, or override with
/// `--dart-define=HANDOVER_MAP_ENABLED=true|false`.
bool handoverMapEnabledFromDefine(String raw) {
  final normalized = raw.trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

/// Compile-time flag — native map tiles still require `GOOGLE_MAPS_API_KEY` in
/// `android/local.properties` (Android manifest).
bool get isHandoverMapPickerEnabled {
  const raw = String.fromEnvironment(
    'HANDOVER_MAP_ENABLED',
    defaultValue: 'false',
  );
  return handoverMapEnabledFromDefine(raw);
}
