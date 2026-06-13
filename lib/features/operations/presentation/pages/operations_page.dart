import 'package:flutter/material.dart';

import '../../../../presentation/donor_app_bar.dart';
import '../../../auth/data/auth_session_holder.dart';
import '../../../donor_seeker_interaction/data/http_order_intent_client.dart';
import '../../../donor_seeker_interaction/domain/models/donation_intent.dart';
import '../../../donor_seeker_interaction/presentation/pages/donation_intent_detail_page.dart';
import '../../../donor_seeker_interaction/presentation/order_intent_grouping.dart';
import '../../../donor_setup/data/auth_context.dart';
import '../../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../../donor_setup/data/http_donor_setup_api_client.dart';
import '../../../seeker_demand/data/http_seeker_demand_client.dart';
import '../../../seeker_demand/domain/models/seeker_demand_summary.dart';

/// Combined order initiations + recorded meal needs (seeker demands).
class OperationsPage extends StatefulWidget {
  const OperationsPage({
    super.key,
    this.authContext,
  });

  final AuthContext? authContext;

  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  static const String _defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  AuthContext get _session =>
      widget.authContext ?? AuthSessionHolder.resolve();

  List<DonationIntent> _intents = <DonationIntent>[];
  List<SeekerDemandSummary> _demands = <SeekerDemandSummary>[];
  bool _loading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final api = HttpDonorSetupApiClient(
        baseUrl: _defaultApiBaseUrl,
        authContext: _session,
      );
      final intents = await HttpOrderIntentClient(
        baseUrl: _defaultApiBaseUrl,
        authContext: _session,
        api: api,
      ).listDonationIntents();
      final demands = await HttpSeekerDemandClient(
        baseUrl: _defaultApiBaseUrl,
        authContext: _session,
        api: api,
      ).listSeekerDemands();
      if (!mounted) {
        return;
      }
      setState(() {
        _intents = intents;
        _demands = demands;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = error is DonorSetupBadRequestException
            ? error.message
            : 'Could not load operations: $error';
        _intents = <DonationIntent>[];
        _demands = <SeekerDemandSummary>[];
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = groupDonationIntents(_intents);

    return Scaffold(
      appBar: const DonorAppBar(
        title: 'Meal operations',
        showSignOut: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Order initiations and recorded meal needs in one place. '
              'Coordinators use the web dashboard for pledges and vendor bids.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_errorText != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Order initiations',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_intents.isEmpty)
              const Text('No order initiations yet.')
            else
              ...groups.expand((group) sync* {
                yield Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    group.label,
                    style: theme.textTheme.labelLarge,
                  ),
                );
                for (final intent in group.intents) {
                  yield Card(
                    child: ListTile(
                      title: Text(intent.orderIntentId),
                      subtitle: Text(
                        '${intent.statusLabel} · ${intent.paymentStatusLabel}',
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                DonationIntentDetailPage(
                              intent: intent,
                              apiBaseUrl: _defaultApiBaseUrl,
                              authContext: _session,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              }),
            const SizedBox(height: 20),
            Text(
              'Recorded meal needs',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (!_loading && _demands.isEmpty)
              const Text('No meal needs recorded yet.')
            else if (!_loading)
              ..._demands.map(
                (row) => Card(
                  child: ListTile(
                    title: Text(row.menuLabel ?? row.seekerDemandId),
                    subtitle: Text(
                      '${row.mealUnits} unit${row.mealUnits == 1 ? '' : 's'}'
                      '${row.localityKey != null ? ' · ${row.localityKey}' : ''}'
                      ' · ${row.status}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
