import 'package:flutter/material.dart';

import '../../data/capture_handover_location.dart';
import 'handover_location_confirm_card.dart';
import 'handover_location_map_picker.dart';
import 'handover_map_enabled.dart';

/// Map picker when [isHandoverMapPickerEnabled] is true; otherwise form fallback.
///
/// Android: set `GOOGLE_MAPS_API_KEY` in `android/local.properties` (Gradle sets
/// `HANDOVER_MAP_ENABLED=true` automatically). Override with
/// `--dart-define=HANDOVER_MAP_ENABLED=false` if needed.
class HandoverLocationPicker extends StatefulWidget {
  const HandoverLocationPicker({
    super.key,
    required this.location,
    required this.onLocationChanged,
    this.onRefresh,
    this.refreshing = false,
  });

  final HandoverLocation location;
  final ValueChanged<HandoverLocation> onLocationChanged;
  final VoidCallback? onRefresh;
  final bool refreshing;

  static bool get mapEnabled => isHandoverMapPickerEnabled;

  @override
  State<HandoverLocationPicker> createState() => HandoverLocationPickerState();
}

class HandoverLocationPickerState extends State<HandoverLocationPicker> {
  final GlobalKey<HandoverLocationMapPickerState> _mapKey =
      GlobalKey<HandoverLocationMapPickerState>();
  final GlobalKey<HandoverLocationConfirmCardState> _cardKey =
      GlobalKey<HandoverLocationConfirmCardState>();

  bool validate() {
    if (HandoverLocationPicker.mapEnabled) {
      return _mapKey.currentState?.validate() ?? false;
    }
    return _cardKey.currentState?.validate() ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (HandoverLocationPicker.mapEnabled) {
      return HandoverLocationMapPicker(
        key: _mapKey,
        location: widget.location,
        refreshing: widget.refreshing,
        onLocationChanged: widget.onLocationChanged,
        onRefresh: widget.onRefresh,
      );
    }
    return HandoverLocationConfirmCard(
      key: _cardKey,
      location: widget.location,
      refreshing: widget.refreshing,
      onLocationChanged: widget.onLocationChanged,
      onRefresh: widget.onRefresh,
    );
  }
}
