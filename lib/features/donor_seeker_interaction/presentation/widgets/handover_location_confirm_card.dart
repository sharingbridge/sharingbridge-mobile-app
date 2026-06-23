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
      _HandoverLocationConfirmCardState();
}

class _HandoverLocationConfirmCardState extends State<HandoverLocationConfirmCard> {
  late final TextEditingController _labelController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  String? _coordError;

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
      _coordError = null;
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

  void _emitLocation() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null ||
        lng == null ||
        lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      setState(() {
        _coordError = 'Enter valid latitude (-90 to 90) and longitude (-180 to 180).';
      });
      return;
    }
    setState(() => _coordError = null);
    widget.onLocationChanged(
      widget.location.copyWith(
        lat: lat,
        lng: lng,
        label: _labelController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Confirm handover location',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Adjust the delivery area label or coordinates if GPS is slightly off.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('handover_location_label'),
              controller: _labelController,
              enabled: !widget.refreshing,
              decoration: const InputDecoration(
                labelText: 'Delivery area / address label',
                hintText: 'e.g. North gate, Block B',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _emitLocation(),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
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
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                    ],
                    onChanged: (_) => _emitLocation(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
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
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                    ],
                    onChanged: (_) => _emitLocation(),
                  ),
                ),
              ],
            ),
            if (_coordError != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _coordError!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
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
                label: Text(widget.refreshing ? 'Refreshing GPS…' : 'Refresh GPS'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
