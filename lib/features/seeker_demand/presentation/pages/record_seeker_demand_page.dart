import 'package:flutter/material.dart';

import '../../../auth/data/auth_session_holder.dart';
import '../../../donor_seeker_interaction/data/capture_handover_location.dart';
import '../../../donor_setup/data/auth_context.dart';
import '../../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../../../presentation/donor_app_bar.dart';
import '../../data/http_seeker_demand_client.dart';
import '../../data/http_standard_offers_client.dart';

/// Record seeker-expressed meal demand for neighbourhood aggregation.
class RecordSeekerDemandPage extends StatefulWidget {
  const RecordSeekerDemandPage({
    super.key,
    this.authContext,
    this.captureLocation,
  });

  final AuthContext? authContext;
  final Future<HandoverLocation?> Function()? captureLocation;

  @override
  State<RecordSeekerDemandPage> createState() => _RecordSeekerDemandPageState();
}

class _RecordSeekerDemandPageState extends State<RecordSeekerDemandPage> {
  static const String _defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  final TextEditingController _notesController = TextEditingController();
  int _mealUnits = 1;
  bool _submitting = false;
  bool _loadingOffers = false;
  String? _errorText;
  String? _lastDemandId;
  String? _areaLocalityKey;
  List<StandardOfferOption> _offers = <StandardOfferOption>[];
  String? _selectedOfferId;
  HandoverLocation? _capturedLocation;

  AuthContext get _session =>
      widget.authContext ?? AuthSessionHolder.resolve();

  Future<HandoverLocation?> _captureLocation() {
    final fn = widget.captureLocation ?? captureHandoverLocation;
    return fn();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadOffersForArea() async {
    setState(() {
      _loadingOffers = true;
      _errorText = null;
    });

    final location = await _captureLocation();
    if (!mounted) {
      return;
    }
    if (location == null) {
      setState(() {
        _loadingOffers = false;
        _errorText =
            'Location is required to load standard menu items for this area.';
      });
      return;
    }

    try {
      final offers = await HttpStandardOffersClient(
        baseUrl: _defaultApiBaseUrl,
        authContext: _session,
      ).listForLocation(
        locationLat: location.lat,
        locationLng: location.lng,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingOffers = false;
        _capturedLocation = location;
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
        _errorText = _formatSubmitError(e);
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedOfferId == null || _selectedOfferId!.isEmpty) {
      setState(() => _errorText = 'Choose a standard menu item.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final location = _capturedLocation ?? await _captureLocation();
    try {
      final result = await HttpSeekerDemandClient(
        baseUrl: _defaultApiBaseUrl,
        authContext: _session,
      ).recordSeekerDemand(
        standardOfferId: _selectedOfferId!,
        mealUnits: _mealUnits,
        verbalNotes: _notesController.text,
        locationLat: location?.lat,
        locationLng: location?.lng,
        locationLabel: location?.label,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _lastDemandId = result.seekerDemandId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Meal need recorded (${result.seekerDemandId}). '
            'Others can pledge toward it from the supply board.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorText = _formatSubmitError(e);
      });
    }
  }

  String _formatSubmitError(Object error) {
    if (error is DonorSetupTimeoutException) {
      return 'The server took too long to respond (it may be waking up on Render). '
          'Wait a few seconds and try again.';
    }
    if (error is DonorSetupNetworkException) {
      return 'Network error while recording demand. Check your connection and try again.';
    }
    if (error is DonorSetupBadRequestException) {
      return error.message;
    }
    return 'Could not record demand: $error';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DonorAppBar(title: 'Record meal need'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: <Widget>[
          Text(
            'Record what a seeker is asking for',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a standard menu item for this postal area (IN:TN:PIN) — not free text. '
            'Light dinner and full lunch are separate lines with their own prices.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('record_seeker_demand_load_offers'),
            onPressed: _submitting || _loadingOffers
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
                  : 'Detect area & load menu items',
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
          if (_offers.isEmpty)
            Text(
              'Load menu items for the seeker\'s location before recording demand.',
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
              onChanged: _submitting
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
                onPressed: _submitting || _mealUnits <= 1
                    ? null
                    : () => setState(() => _mealUnits -= 1),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_mealUnits', style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                key: const Key('record_seeker_demand_units_inc'),
                onPressed: _submitting || _mealUnits >= 50
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
            enabled: !_submitting,
            decoration: const InputDecoration(
              labelText: 'Extra notes (optional)',
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
              'Last reference: $_lastDemandId',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
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
            label: Text(_submitting ? 'Recording…' : 'Record meal need'),
          ),
        ],
      ),
    );
  }
}
