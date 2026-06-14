import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/data/auth_session_holder.dart';
import '../../../donor_seeker_interaction/data/capture_handover_location.dart';
import '../../../donor_seeker_interaction/data/handover_location_result.dart';
import '../../../donor_seeker_interaction/data/http_reference_photo_client.dart';
import '../../../donor_seeker_interaction/domain/models/reference_photo_upload.dart';
import '../../../donor_seeker_interaction/presentation/widgets/reference_photo_preview.dart';
import '../../../donor_setup/data/auth_context.dart';
import '../../../donor_setup/data/donor_seeker_api_errors.dart';
import '../../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../../../initiation_labels.dart';
import '../../../../presentation/donor_app_bar.dart';
import '../../data/http_seeker_demand_client.dart';
import '../../data/http_standard_offers_client.dart';

/// Record seeker-expressed meal demand for neighbourhood aggregation.
class RecordSeekerDemandPage extends StatefulWidget {
  const RecordSeekerDemandPage({
    super.key,
    this.authContext,
    this.captureLocationResult,
  });

  final AuthContext? authContext;
  final Future<HandoverLocationResult> Function()? captureLocationResult;

  @override
  State<RecordSeekerDemandPage> createState() => _RecordSeekerDemandPageState();
}

class _RecordSeekerDemandPageState extends State<RecordSeekerDemandPage> {
  static const String _defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  static const String _defaultPhotoServiceBaseUrl = String.fromEnvironment(
    'PHOTO_SERVICE_BASE_URL',
    defaultValue: 'http://localhost:8092',
  );

  final TextEditingController _notesController = TextEditingController();
  int _mealUnits = 1;
  bool _submitting = false;
  bool _loadingOffers = false;
  bool _recorded = false;
  String? _errorText;
  String? _lastDemandId;
  String? _areaLocalityKey;
  List<StandardOfferOption> _offers = <StandardOfferOption>[];
  String? _selectedOfferId;
  HandoverLocation? _capturedLocation;
  XFile? _referencePhoto;
  String? _referencePhotoViewUrl;
  String? _referencePhotoThumbnailUrl;

  AuthContext get _session =>
      widget.authContext ?? AuthSessionHolder.resolve();

  Future<HandoverLocationResult> _captureLocationResult() {
    final fn = widget.captureLocationResult ?? captureHandoverLocationResult;
    return fn();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickReferencePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _referencePhoto = picked;
      _referencePhotoViewUrl = null;
      _referencePhotoThumbnailUrl = null;
    });
  }

  Future<ReferencePhotoUpload?> _uploadReferencePhotoIfNeeded() async {
    if (_referencePhoto == null) {
      return null;
    }
    if (_referencePhotoViewUrl != null || _referencePhotoThumbnailUrl != null) {
      return ReferencePhotoUpload(
        artifactId: '',
        viewUrl: _referencePhotoViewUrl ?? '',
        thumbnailUrl: _referencePhotoThumbnailUrl ?? '',
      );
    }
    return HttpReferencePhotoClient(
      baseUrl: _defaultPhotoServiceBaseUrl,
      authContext: _session,
    ).uploadSeekerReference(_referencePhoto!);
  }

  Future<void> _loadOffersForArea() async {
    setState(() {
      _loadingOffers = true;
      _errorText = null;
    });

    final capture = await _captureLocationResult();
    if (!mounted) {
      return;
    }
    if (!capture.isSuccess) {
      setState(() {
        _loadingOffers = false;
        _errorText = capture.message.isNotEmpty
            ? capture.message
            : 'Location is required to load standard menu items for this area.';
      });
      return;
    }

    try {
      final offers = await HttpStandardOffersClient(
        baseUrl: _defaultApiBaseUrl,
        authContext: _session,
      ).listForLocation(
        locationLat: capture.location!.lat,
        locationLng: capture.location!.lng,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingOffers = false;
        _capturedLocation = capture.location;
        _offers = offers;
        _selectedOfferId =
            offers.isNotEmpty ? offers.first.standardOfferId : null;
        _areaLocalityKey = offers.isNotEmpty
            ? offers.first.localityKey
            : null;
        if (offers.isEmpty) {
          _errorText =
              'No standard menu items are configured for this postal area.';
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingOffers = false;
        _errorText = formatDonorSeekerError(e);
      });
    }
  }

  Future<void> _submit() async {
    if (_recorded) {
      return;
    }
    if (_selectedOfferId == null || _selectedOfferId!.isEmpty) {
      setState(() => _errorText = 'Choose a standard menu item.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    HandoverLocation? location = _capturedLocation;
    if (location == null) {
      final capture = await _captureLocationResult();
      if (!capture.isSuccess) {
        if (!mounted) {
          return;
        }
        setState(() {
          _submitting = false;
          _errorText = capture.message;
        });
        return;
      }
      location = capture.location;
      _capturedLocation = location;
    }

    final resolvedLocation = location!;
    try {
      ReferencePhotoUpload? uploaded;
      if (_referencePhoto != null) {
        uploaded = await _uploadReferencePhotoIfNeeded();
        if (!mounted) {
          return;
        }
        setState(() {
          _referencePhotoViewUrl = uploaded?.viewUrl;
          _referencePhotoThumbnailUrl = uploaded?.thumbnailUrl;
        });
      }

      final notes = _composeNotes(uploaded);
      final result = await HttpSeekerDemandClient(
        baseUrl: _defaultApiBaseUrl,
        authContext: _session,
      ).recordSeekerDemand(
        standardOfferId: _selectedOfferId!,
        mealUnits: _mealUnits,
        verbalNotes: notes,
        locationLat: resolvedLocation.lat,
        locationLng: resolvedLocation.lng,
        locationLabel: resolvedLocation.label,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _recorded = true;
        _lastDemandId = result.seekerDemandId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opened for pledging (${result.seekerDemandId}). '
            'View it under Initiations.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorText = formatDonorSeekerError(e);
      });
    }
  }

  String _composeNotes(ReferencePhotoUpload? uploaded) {
    final parts = <String>[];
    final typed = _notesController.text.trim();
    if (typed.isNotEmpty) {
      parts.add(typed);
    }
    if (uploaded != null) {
      final view = uploaded.viewUrl.trim();
      final thumb = uploaded.thumbnailUrl.trim();
      if (view.isNotEmpty) {
        parts.add('Reference photo: $view');
      } else if (thumb.isNotEmpty) {
        parts.add('Reference photo: $thumb');
      }
    }
    return parts.join('\n');
  }

  void _recordAnother() {
    setState(() {
      _recorded = false;
      _lastDemandId = null;
      _mealUnits = 1;
      _notesController.clear();
      _referencePhoto = null;
      _referencePhotoViewUrl = null;
      _referencePhotoThumbnailUrl = null;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DonorAppBar(title: InitiationRouteLabels.forPledging),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: <Widget>[
          Text(
            'Record what a seeker is asking for',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a standard menu item for this postal area. Add an optional reference '
            'photo and notes so others understand the handover context.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('record_seeker_demand_load_offers'),
            onPressed: _submitting || _loadingOffers || _recorded
                ? null
                : () => _loadOffersForArea(),
            icon: _loadingOffers
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(
              _loadingOffers
                  ? 'Loading menu…'
                  : _capturedLocation == null
                      ? 'Allow location & load menu'
                      : 'Reload menu for area',
            ),
          ),
          if (_areaLocalityKey != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Postal area: $_areaLocalityKey',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _submitting || _recorded ? null : _pickReferencePhoto,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(
              _referencePhoto == null
                  ? 'Add reference photo (optional)'
                  : 'Retake reference photo',
            ),
          ),
          if (_referencePhoto != null) ...<Widget>[
            const SizedBox(height: 8),
            ReferencePhotoPreview(
              localFile: _referencePhoto,
              thumbnailUrl: _referencePhotoThumbnailUrl,
              viewUrl: _referencePhotoViewUrl,
              caption: 'Reference photo',
              onRemove: _submitting || _recorded
                  ? null
                  : () => setState(() {
                        _referencePhoto = null;
                        _referencePhotoViewUrl = null;
                        _referencePhotoThumbnailUrl = null;
                      }),
            ),
          ],
          const SizedBox(height: 16),
          if (_offers.isEmpty)
            Text(
              'Load menu items for the seeker\'s location before recording.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            DropdownButtonFormField<String>(
              key: const Key('record_seeker_demand_offer'),
              value: _selectedOfferId,
              decoration: const InputDecoration(
                labelText: 'Standard menu item',
                border: OutlineInputBorder(),
              ),
              items: _offers
                  .map(
                    (offer) => DropdownMenuItem<String>(
                      value: offer.standardOfferId,
                      child: Text(
                        offer.priceInr != null
                            ? '${offer.menuLabel} (₹${offer.priceInr})'
                            : offer.menuLabel,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _submitting || _recorded
                  ? null
                  : (value) => setState(() => _selectedOfferId = value),
            ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Text('Meal units'),
              const SizedBox(width: 12),
              IconButton(
                key: const Key('record_seeker_demand_units_dec'),
                onPressed: _submitting || _recorded || _mealUnits <= 1
                    ? null
                    : () => setState(() => _mealUnits -= 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_mealUnits', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                key: const Key('record_seeker_demand_units_inc'),
                onPressed: _submitting || _recorded || _mealUnits >= 50
                    ? null
                    : () => setState(() => _mealUnits += 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('record_seeker_demand_notes'),
            controller: _notesController,
            enabled: !_submitting && !_recorded,
            decoration: const InputDecoration(
              labelText: 'Handover notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          if (_errorText != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_lastDemandId != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Recorded: $_lastDemandId',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          if (_recorded)
            OutlinedButton.icon(
              onPressed: _recordAnother,
              icon: const Icon(Icons.add),
              label: const Text('Record another for pledging'),
            )
          else
            FilledButton.icon(
              key: const Key('record_seeker_demand_submit'),
              onPressed: _submitting || _offers.isEmpty ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_submitting ? 'Recording…' : 'Open for pledging'),
            ),
        ],
      ),
    );
  }
}
