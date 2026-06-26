import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../auth/data/auth_session_holder.dart';
import '../../../donor_setup/data/auth_context.dart';
import '../../../donor_setup/data/donor_seeker_api_errors.dart';
import '../../data/capture_handover_location.dart';
import '../../data/http_geocode_client.dart';

/// Cab-style map picker: pan map, fixed center pin, server reverse geocode.
class HandoverLocationMapPicker extends StatefulWidget {
  const HandoverLocationMapPicker({
    super.key,
    required this.location,
    required this.onLocationChanged,
    this.onRefresh,
    this.refreshing = false,
    this.apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    ),
    this.authContext,
  });

  final HandoverLocation location;
  final ValueChanged<HandoverLocation> onLocationChanged;
  final VoidCallback? onRefresh;
  final bool refreshing;
  final String apiBaseUrl;
  final AuthContext? authContext;

  @override
  State<HandoverLocationMapPicker> createState() =>
      HandoverLocationMapPickerState();
}

class HandoverLocationMapPickerState extends State<HandoverLocationMapPicker> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _pickupNoteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng _mapTarget = const LatLng(12.9716, 80.2206);
  bool _mapReady = false;
  bool _resolvingAddress = false;
  String? _resolveError;
  Timer? _geocodeDebounce;
  bool _suppressCameraCallback = false;

  AuthContext get _session =>
      widget.authContext ?? AuthSessionHolder.resolve();

  @override
  void initState() {
    super.initState();
    _mapTarget = LatLng(widget.location.lat, widget.location.lng);
    _pickupNoteController.text = widget.location.label;
    _addressController.text = widget.location.formattedAddress;
    if (widget.location.formattedAddress.isEmpty) {
      unawaited(_resolveAddressFor(_mapTarget));
    }
  }

  @override
  void didUpdateWidget(covariant HandoverLocationMapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.lat != widget.location.lat ||
        oldWidget.location.lng != widget.location.lng) {
      _mapTarget = LatLng(widget.location.lat, widget.location.lng);
      unawaited(_moveCameraTo(_mapTarget));
      unawaited(_resolveAddressFor(_mapTarget));
    }
    if (oldWidget.location.formattedAddress != widget.location.formattedAddress) {
      _addressController.text = widget.location.formattedAddress;
    }
    if (oldWidget.location.label != widget.location.label &&
        widget.location.label != _pickupNoteController.text) {
      _pickupNoteController.text = widget.location.label;
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _pickupNoteController.dispose();
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  static String? _validatePickupNote(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter a pickup note (landmark or gate).';
    }
    if (trimmed.length < 3) {
      return 'Use at least 3 characters for the pickup note.';
    }
    if (trimmed.length > 200) {
      return 'Keep the pickup note under 200 characters.';
    }
    return null;
  }

  bool validate() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return false;
    }
    if (widget.location.formattedAddress.trim().isEmpty) {
      setState(() {
        _resolveError =
            'Move the map or tap Use current location until an address loads.';
      });
      return false;
    }
    _emitCurrent();
    return true;
  }

  Future<void> _centerOnDeviceLocation() async {
    if (widget.onRefresh != null) {
      widget.onRefresh!();
      return;
    }
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _resolveError = 'Turn on location services and try again.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _resolveError = 'Location permission is required.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final target = LatLng(position.latitude, position.longitude);
      setState(() => _mapTarget = target);
      await _moveCameraTo(target);
      await _resolveAddressFor(target);
    } catch (_) {
      setState(() => _resolveError = 'Could not read GPS right now.');
    }
  }

  Future<void> _moveCameraTo(LatLng target) async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    _suppressCameraCallback = true;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(target, 17),
    );
    _suppressCameraCallback = false;
  }

  void _onCameraIdle() {
    if (_suppressCameraCallback || !_mapReady) {
      return;
    }
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_resolveAddressFor(_mapTarget));
    });
  }

  Future<void> _resolveAddressFor(LatLng target) async {
    setState(() {
      _resolvingAddress = true;
      _resolveError = null;
    });
    try {
      final result = await HttpGeocodeClient(
        baseUrl: widget.apiBaseUrl,
        authContext: _session,
      ).reverseGeocode(
        locationLat: target.latitude,
        locationLng: target.longitude,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _resolvingAddress = false;
        _mapTarget = LatLng(result.lat, result.lng);
        _addressController.text = result.formattedAddress;
      });
      widget.onLocationChanged(
        HandoverLocation(
          lat: result.lat,
          lng: result.lng,
          label: _pickupNoteController.text.trim(),
          formattedAddress: result.formattedAddress,
          localityKey: result.localityKey,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resolvingAddress = false;
        _resolveError = formatDonorSeekerError(e);
        _addressController.text = '';
      });
      widget.onLocationChanged(
        HandoverLocation(
          lat: target.latitude,
          lng: target.longitude,
          label: _pickupNoteController.text.trim(),
        ),
      );
    }
  }

  void _emitCurrent() {
    widget.onLocationChanged(
      widget.location.copyWith(label: _pickupNoteController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = widget.refreshing || _resolvingAddress;
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
                'Pick handover location',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Move the map so the pin sits on the handover point.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      GoogleMap(
                        key: const Key('handover_location_map'),
                        initialCameraPosition: CameraPosition(
                          target: _mapTarget,
                          zoom: 17,
                        ),
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                          setState(() => _mapReady = true);
                        },
                        onCameraMove: (CameraPosition position) {
                          _mapTarget = position.target;
                        },
                        onCameraIdle: _onCameraIdle,
                      ),
                      const IgnorePointer(
                        child: Icon(
                          Icons.location_pin,
                          size: 42,
                          color: Colors.red,
                        ),
                      ),
                      if (busy)
                        const ColoredBox(
                          color: Color(0x33FFFFFF),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('handover_location_use_gps'),
                onPressed: busy ? null : _centerOnDeviceLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Use current location'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('handover_location_formatted_address'),
                controller: _addressController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText:
                      busy ? 'Looking up address…' : 'Move map to load address',
                  border: const OutlineInputBorder(),
                ),
              ),
              if (widget.location.localityKey.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Postal area: ${widget.location.localityKey}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('handover_location_label'),
                controller: _pickupNoteController,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Pickup note (landmark / gate)',
                  hintText: 'e.g. North gate, Block B',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: _validatePickupNote,
                onChanged: (_) => _emitCurrent(),
              ),
              if (_resolveError != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _resolveError!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
