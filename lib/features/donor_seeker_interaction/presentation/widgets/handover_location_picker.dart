import 'package:flutter/material.dart';

import '../../data/capture_handover_location.dart';
import 'handover_location_confirm_card.dart';
import 'handover_location_map_picker.dart';

/// Map picker when [GOOGLE_MAPS_API_KEY] is set; otherwise coordinate form fallback.
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

  static bool get mapEnabled {
    const key = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: '',
    );
    return key.trim().isNotEmpty;
  }

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
