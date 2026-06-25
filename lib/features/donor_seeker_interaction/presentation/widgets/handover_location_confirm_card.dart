import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/capture_handover_location.dart';

/// Editable handover coordinates and area label for user confirmation.
class HandoverLocationConfirmCard extends StatefulWidget {
  const HandoverLocationConfirmCard({
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

  @override
  State<HandoverLocationConfirmCard> createState() =>
      HandoverLocationConfirmCardState();
}

class HandoverLocationConfirmCardState extends State<HandoverLocationConfirmCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.location.label);
    _latController = TextEditingController(
      text: _formatCoord(widget.location.lat),
    );
    _lngController = TextEditingController(
      text: _formatCoord(widget.location.lng),
    );
  }

  @override
  void didUpdateWidget(covariant HandoverLocationConfirmCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.lat != widget.location.lat ||
        oldWidget.location.lng != widget.location.lng ||
        oldWidget.location.label != widget.location.label) {
      _labelController.text = widget.location.label;
      _latController.text = _formatCoord(widget.location.lat);
      _lngController.text = _formatCoord(widget.location.lng);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  String _formatCoord(double value) => value.toStringAsFixed(6);

  static String? validateLabel(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter a delivery area or address label.';
    }
    if (trimmed.length < 3) {
      return 'Use at least 3 characters for the area label.';
    }
    if (trimmed.length > 200) {
      return 'Keep the area label under 200 characters.';
    }
    return null;
  }

  static String? validateLatitude(String? value) {
    final lat = double.tryParse(value?.trim() ?? '');
    if (lat == null || lat < -90 || lat > 90) {
      return 'Enter a valid latitude (-90 to 90).';
    }
    return null;
  }

  static String? validateLongitude(String? value) {
    final lng = double.tryParse(value?.trim() ?? '');
    if (lng == null || lng < -180 || lng > 180) {
      return 'Enter a valid longitude (-180 to 180).';
    }
    return null;
  }

  void _emitLocation() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) {
      return;
    }
    widget.onLocationChanged(
      widget.location.copyWith(
        lat: lat,
        lng: lng,
        label: _labelController.text.trim(),
      ),
    );
  }

  /// Validates fields and syncs the latest values to [onLocationChanged].
  bool validate() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (valid) {
      _emitLocation();
    }
    return valid;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Confirm handover location',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Add a delivery area label and adjust coordinates if GPS is slightly off.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('handover_location_label'),
                controller: _labelController,
                enabled: !widget.refreshing,
                decoration: const InputDecoration(
                  labelText: 'Delivery area / address label',
                  hintText: 'e.g. North gate, Block B',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: validateLabel,
                onChanged: (_) => _emitLocation(),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      key: const Key('handover_location_lat'),
                      controller: _latController,
                      enabled: !widget.refreshing,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d*'),
                        ),
                      ],
                      validator: validateLatitude,
                      onChanged: (_) => _emitLocation(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('handover_location_lng'),
                      controller: _lngController,
                      enabled: !widget.refreshing,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d*'),
                        ),
                      ],
                      validator: validateLongitude,
                      onChanged: (_) => _emitLocation(),
                    ),
                  ),
                ],
              ),
              if (widget.onRefresh != null) ...<Widget>[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('handover_location_refresh'),
                  onPressed: widget.refreshing ? null : widget.onRefresh,
                  icon: widget.refreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    widget.refreshing ? 'Refreshing GPS…' : 'Refresh GPS',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
