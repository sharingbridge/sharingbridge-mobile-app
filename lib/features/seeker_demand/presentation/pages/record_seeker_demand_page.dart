import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/integration_api_paths.dart';
import '../../../auth/data/auth_session_holder.dart';
import '../../../donor_seeker_interaction/data/capture_handover_location.dart';
import '../../../donor_seeker_interaction/data/handover_location_result.dart';
import '../../../donor_seeker_interaction/data/http_reference_photo_client.dart';
import '../../../donor_seeker_interaction/domain/models/reference_photo_upload.dart';
import '../../../donor_seeker_interaction/presentation/widgets/reference_photo_preview.dart';
import '../../../donor_seeker_interaction/presentation/widgets/handover_location_picker.dart';
import '../../../donor_setup/data/auth_context.dart';
import '../../../donor_setup/data/donor_seeker_api_errors.dart';
import '../../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../../../connection_consent.dart';
import '../../../../initiation_labels.dart';
import '../../../../presentation/donor_app_bar.dart';
import '../../data/http_seeker_demand_client.dart';
import '../../data/http_standard_offers_client.dart';
import '../../../../seeker_demand_initiation_route.dart';

/// Record seeker-expressed meal demand for neighbourhood aggregation.
class RecordSeekerDemandPage extends StatefulWidget {
  const RecordSeekerDemandPage({
    super.key,
    this.authContext,
    this.captureLocationResult,
    this.initiationRoute = SeekerDemandInitiationRoute.ecoKitchenPledge,
    this.emailSharingConsentAcknowledged = false,
  });

  final AuthContext? authContext;
  final Future<HandoverLocationResult> Function()? captureLocationResult;
  final String initiationRoute;
  final bool emailSharingConsentAcknowledged;

  @override
  State<RecordSeekerDemandPage> createState() => _RecordSeekerDemandPageState();
}

class _RecordSeekerDemandPageState extends State<RecordSeekerDemandPage> {
  static const String _defaultApiBaseUrl = IntegrationApiPaths.baseUrl;
  static const String _defaultPhotoServiceBaseUrl = String.fromEnvironment(
    'PHOTO_SERVICE_BASE_URL',
    defaultValue: 'http://localhost:8092',
  );

  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<HandoverLocationPickerState> _locationPickerKey =
      GlobalKey<HandoverLocationPickerState>();
  int _mealUnits = 1;
  bool _submitting = false;
  bool _loadingOffers = false;
  bool _recorded = false;
  bool _emailShareConsent = false;
  bool _refreshingLocation = false;
  String? _errorText;
  String? _lastDemandId;
  String? _lastOrderCode;
  String? _areaLocalityKey;
  List<StandardOfferOption> _offers = <StandardOfferOption>[];
  String? _selectedOfferId;
  HandoverLocation? _capturedLocation;
  double? _menuLoadedLat;
  double? _menuLoadedLng;
  bool _requiresMenuReload = false;
  XFile? _referencePhoto;
  String? _referencePhotoViewUrl;
  String? _referencePhotoThumbnailUrl;

  AuthContext get _session =>
      widget.authContext ?? AuthSessionHolder.resolve();

  bool get _isSelfPay =>
      widget.initiationRoute == SeekerDemandInitiationRoute.ecoKitchenSelfPay;

  String get _routeTitle => initiationApiRouteLabel(widget.initiationRoute);

  String get _introCopy => _isSelfPay
      ? 'Pick a standard menu item for this postal area. Eco kitchens in the pool '
          'can commit; you pay them off-platform after connection is ready.'
      : 'Pick a standard menu item for this postal area. Add an optional reference '
          'photo and notes so pledgers understand the handover context.';

  String get _consentTitle => _isSelfPay
      ? ConnectionConsentCopy.initiatorEcoKitchenSelfPayTitle
      : ConnectionConsentCopy.initiatorOpenForPledgingTitle;

  String get _consentBody => _isSelfPay
      ? ConnectionConsentCopy.initiatorEcoKitchenSelfPayBody
      : ConnectionConsentCopy.initiatorOpenForPledgingBody;

  String get _submitLabel =>
      _isSelfPay ? 'Open for eco kitchens' : 'Open for pledging';

  String get _successSnackCopy => _isSelfPay
      ? 'Opened for eco kitchens'
      : 'Opened for pledging';

  bool get _menuReady =>
      _offers.isNotEmpty && !_requiresMenuReload && !_loadingOffers;

  bool get _showMenuLoadButton =>
      _capturedLocation == null || _requiresMenuReload;

  static bool _coordsDiffer(
    double aLat,
    double aLng,
    double bLat,
    double bLng,
  ) {
    const epsilon = 0.000001;
    return (aLat - bLat).abs() > epsilon || (aLng - bLng).abs() > epsilon;
  }

  void _invalidateMenuForCoordinateChange() {
    _offers = <StandardOfferOption>[];
    _selectedOfferId = null;
    _areaLocalityKey = null;
    _requiresMenuReload = true;
  }

  void _markMenuLoadedFor(HandoverLocation location) {
    _menuLoadedLat = location.lat;
    _menuLoadedLng = location.lng;
    _requiresMenuReload = false;
  }

  void _onHandoverLocationChanged(HandoverLocation updated) {
    final divergedFromMenu = _menuLoadedLat != null &&
        _menuLoadedLng != null &&
        _coordsDiffer(
          _menuLoadedLat!,
          _menuLoadedLng!,
          updated.lat,
          updated.lng,
        );
    setState(() {
      _capturedLocation = updated;
      if (divergedFromMenu && !_requiresMenuReload) {
        _invalidateMenuForCoordinateChange();
      }
    });
  }

  Future<HandoverLocationResult> _captureLocationResult() {
    final fn = widget.captureLocationResult ?? captureHandoverLocationResult;
    return fn();
  }

  @override
  void initState() {
    super.initState();
    if (widget.emailSharingConsentAcknowledged) {
      _emailShareConsent = true;
    }
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

  Future<void> _refreshHandoverLocation() async {
    setState(() {
      _refreshingLocation = true;
      _errorText = null;
    });
    final preservedLabel = _capturedLocation?.label.trim() ?? '';
    final capture = await _captureLocationResult();
    if (!mounted) {
      return;
    }
    if (!capture.isSuccess) {
      setState(() {
        _refreshingLocation = false;
        _errorText = capture.message.isNotEmpty
            ? capture.message
            : 'Could not refresh GPS.';
      });
      return;
    }
    setState(() {
      _refreshingLocation = false;
      _capturedLocation = capture.location!.copyWith(label: preservedLabel);
    });
    await _loadOffersForArea();
  }

  /// Loads standard menu for [location_lat]/[location_lng]. Postal area is never
  /// derived from the label — only from coordinates (server reverse-geocode).
  Future<void> _loadOffersForArea({bool captureFreshGps = false}) async {
    setState(() {
      _loadingOffers = true;
      _errorText = null;
    });

    final preservedLabel = _capturedLocation?.label.trim() ?? '';
    HandoverLocation? location;

    if (captureFreshGps || _capturedLocation == null) {
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
      location = capture.location!.copyWith(label: preservedLabel);
    } else {
      location = _capturedLocation;
    }

    try {
      final offers = await HttpStandardOffersClient(
        baseUrl: _defaultApiBaseUrl,
        authContext: _session,
      ).listForLocation(
        locationLat: location!.lat,
        locationLng: location.lng,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingOffers = false;
        _capturedLocation = location!.copyWith(
          label: preservedLabel.isNotEmpty ? preservedLabel : location.label,
        );
        _offers = offers;
        _selectedOfferId =
            offers.isNotEmpty ? offers.first.standardOfferId : null;
        _areaLocalityKey = offers.isNotEmpty
            ? offers.first.localityKey
            : null;
        if (offers.isNotEmpty) {
          _markMenuLoadedFor(_capturedLocation!);
        } else {
          _menuLoadedLat = null;
          _menuLoadedLng = null;
          _requiresMenuReload = false;
        }
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
    if (_requiresMenuReload) {
      setState(
        () => _errorText = 'Reload the menu for the updated coordinates.',
      );
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
    if (_locationPickerKey.currentState?.validate() != true) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorText =
            'Confirm handover location — add a delivery area or address label.';
      });
      return;
    }
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
        initiationRoute: widget.initiationRoute,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _recorded = true;
        _lastDemandId = result.seekerDemandId;
        _lastOrderCode = result.orderCode;
      });
      final orderBit = result.orderCode != null && result.orderCode!.isNotEmpty
          ? ' · ${result.orderCode}'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$_successSnackCopy (${result.seekerDemandId}$orderBit). '
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
      _lastOrderCode = null;
      _mealUnits = 1;
      _notesController.clear();
      _referencePhoto = null;
      _referencePhotoViewUrl = null;
      _referencePhotoThumbnailUrl = null;
      _errorText = null;
      _emailShareConsent = widget.emailSharingConsentAcknowledged;
      _offers = <StandardOfferOption>[];
      _selectedOfferId = null;
      _areaLocalityKey = null;
      _capturedLocation = null;
      _menuLoadedLat = null;
      _menuLoadedLng = null;
      _requiresMenuReload = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuReady = _menuReady;
    return Scaffold(
      appBar: DonorAppBar(title: _routeTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: <Widget>[
          Text(
            _isSelfPay
                ? 'Record your eco kitchen initiation'
                : 'Record what a seeker is asking for',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _introCopy,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (_showMenuLoadButton)
            OutlinedButton.icon(
              key: const Key('record_seeker_demand_load_offers'),
              onPressed: _submitting || _loadingOffers || _recorded
                  ? null
                  : () => _loadOffersForArea(
                        captureFreshGps: _capturedLocation == null,
                      ),
              icon: _loadingOffers
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restaurant_menu_outlined),
              label: Text(
                _loadingOffers
                    ? 'Loading menu…'
                    : _capturedLocation == null
                        ? 'Allow location & load menu'
                        : 'Reload menu for updated coordinates',
              ),
            ),
          if (_requiresMenuReload) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Coordinates changed — reload the menu before choosing a menu item.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          if (_capturedLocation != null) ...<Widget>[
            const SizedBox(height: 12),
            HandoverLocationPicker(
              key: _locationPickerKey,
              location: _capturedLocation!,
              refreshing: _refreshingLocation || _loadingOffers,
              onLocationChanged: _onHandoverLocationChanged,
              onRefresh: _submitting || _recorded
                  ? null
                  : () => _refreshHandoverLocation(),
            ),
          ],
          if (_areaLocalityKey != null && !_requiresMenuReload) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Postal area: $_areaLocalityKey',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _submitting || _recorded || !menuReady
                ? null
                : _pickReferencePhoto,
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
              onRemove: _submitting || _recorded || !menuReady
                  ? null
                  : () => setState(() {
                        _referencePhoto = null;
                        _referencePhotoViewUrl = null;
                        _referencePhotoThumbnailUrl = null;
                      }),
            ),
          ],
          const SizedBox(height: 16),
          if (!menuReady && !_requiresMenuReload)
            Text(
              'Load menu items for the seeker\'s location before recording.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else if (menuReady)
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
              onChanged: _submitting || _recorded || !menuReady
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
                onPressed: _submitting || _recorded || !menuReady || _mealUnits <= 1
                    ? null
                    : () => setState(() => _mealUnits -= 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_mealUnits', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                key: const Key('record_seeker_demand_units_inc'),
                onPressed: _submitting || _recorded || !menuReady || _mealUnits >= 50
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
            enabled: !_submitting && !_recorded && menuReady,
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
          if (!_recorded && !widget.emailSharingConsentAcknowledged) ...<Widget>[
            const SizedBox(height: 16),
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _consentTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _consentBody,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (!_isSelfPay) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        ConnectionConsentCopy.pledgingRouteHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _emailShareConsent,
                      onChanged: _submitting
                          ? null
                          : (bool? value) {
                              setState(
                                () => _emailShareConsent = value ?? false,
                              );
                            },
                      title: const Text(
                        ConnectionConsentCopy.initiatorOpenForPledgingCheckbox,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_lastOrderCode != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Order code: $_lastOrderCode',
              style: Theme.of(context).textTheme.bodySmall,
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
              label: Text('Record another · ${_isSelfPay ? 'I pay' : 'pledging'}'),
            )
          else
            FilledButton.icon(
              key: const Key('record_seeker_demand_submit'),
              onPressed: _submitting || !menuReady || !_emailShareConsent
                  ? null
                  : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_submitting ? 'Recording…' : _submitLabel),
            ),
        ],
      ),
    );
  }
}
