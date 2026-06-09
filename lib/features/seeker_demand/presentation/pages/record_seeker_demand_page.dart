import 'package:flutter/material.dart';

import '../../../auth/data/auth_session_holder.dart';
import '../../../donor_seeker_interaction/data/capture_handover_location.dart';
import '../../../donor_setup/data/auth_context.dart';
import '../../../../presentation/donor_app_bar.dart';
import '../../data/http_seeker_demand_client.dart';

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

  final TextEditingController _needController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  int _mealUnits = 1;
  bool _submitting = false;
  String? _errorText;
  String? _lastDemandId;

  AuthContext get _session =>
      widget.authContext ?? AuthSessionHolder.resolve();

  Future<HandoverLocation?> _captureLocation() {
    final fn = widget.captureLocation ?? captureHandoverLocation;
    return fn();
  }

  @override
  void dispose() {
    _needController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final need = _needController.text.trim();
    if (need.isEmpty) {
      setState(() => _errorText = 'Describe what the seeker needs.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final location = await _captureLocation();
    try {
      final result = await HttpSeekerDemandClient(
        baseUrl: _defaultApiBaseUrl,
        authContext: _session,
      ).recordSeekerDemand(
        needDescription: need,
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
            'Demand recorded (${result.seekerDemandId}). '
            'Coordinators see it on the web Demand tab.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorText = 'Could not record demand: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DonorAppBar(title: 'Record seeker demand'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: <Widget>[
          Text(
            'Record what a seeker is asking for',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This feeds the neighbourhood demand board. It is not a vendor order '
            'until someone pledges and pays in a vendor app.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('record_seeker_demand_need'),
            controller: _needController,
            enabled: !_submitting,
            decoration: const InputDecoration(
              labelText: 'What do they need?',
              hintText: 'e.g. 2 vegetarian meals, lunch for family of 3',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
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
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_submitting ? 'Recording…' : 'Record demand'),
          ),
        ],
      ),
    );
  }
}
