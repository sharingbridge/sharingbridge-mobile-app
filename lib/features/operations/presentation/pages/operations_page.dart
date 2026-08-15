import 'package:flutter/material.dart';

import '../../../../config/integration_api_paths.dart';
import '../../../../initiation_labels.dart';
import '../../../../presentation/donor_app_bar.dart';
import '../../../auth/data/auth_session_holder.dart';
import '../../../donor_seeker_interaction/data/http_order_intent_client.dart';
import '../../../donor_seeker_interaction/domain/models/donation_intent.dart';
import '../../../donor_seeker_interaction/presentation/pages/donation_intent_detail_page.dart';
import '../../../donor_seeker_interaction/presentation/widgets/reference_photo_preview.dart';
import '../../../donor_setup/data/auth_context.dart';
import '../../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../../donor_setup/data/http_donor_setup_api_client.dart';
import '../../../seeker_demand/data/http_seeker_demand_client.dart';
import '../../../seeker_demand/domain/models/seeker_demand_summary.dart';
import '../../../seeker_demand/presentation/pages/seeker_demand_detail_page.dart';

enum _InitiationKind { vendorOrder, mealNeed }

class _InitiationRow {
  const _InitiationRow({
    required this.kind,
    required this.createdAt,
    this.intent,
    this.demand,
  });

  final _InitiationKind kind;
  final DateTime? createdAt;
  final DonationIntent? intent;
  final SeekerDemandSummary? demand;
}

/// Combined vendor-order and meal-need initiations.
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
  static const String _defaultApiBaseUrl = IntegrationApiPaths.baseUrl;

  AuthContext get _session =>
      widget.authContext ?? AuthSessionHolder.resolve();

  List<_InitiationRow> _rows = <_InitiationRow>[];
  bool _loading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  List<_InitiationRow> _mergeRows(
    List<DonationIntent> intents,
    List<SeekerDemandSummary> demands,
  ) {
    final rows = <_InitiationRow>[
      ...intents.map(
        (DonationIntent intent) => _InitiationRow(
          kind: _InitiationKind.vendorOrder,
          createdAt: intent.createdAt ?? intent.updatedAt,
          intent: intent,
        ),
      ),
      ...demands.map(
        (SeekerDemandSummary demand) => _InitiationRow(
          kind: _InitiationKind.mealNeed,
          createdAt: DateTime.tryParse(demand.createdAt),
          demand: demand,
        ),
      ),
    ];
    rows.sort((a, b) {
      final aMs = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bMs = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bMs.compareTo(aMs);
    });
    return rows;
  }

  void _patchIntent(DonationIntent updated) {
    setState(() {
      _rows = _rows
          .map(
            (row) => row.kind == _InitiationKind.vendorOrder &&
                    row.intent?.orderIntentId == updated.orderIntentId
                ? _InitiationRow(
                    kind: row.kind,
                    createdAt: row.createdAt,
                    intent: updated,
                  )
                : row,
          )
          .toList(growable: false);
    });
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
      ).listDonationIntents(since: '7d');
      final demands = await HttpSeekerDemandClient(
        baseUrl: _defaultApiBaseUrl,
        authContext: _session,
        api: api,
      ).listSeekerDemands();
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = _mergeRows(intents, demands);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = error is DonorSetupBadRequestException
            ? error.message
            : 'Could not load initiations: $error';
        _rows = <_InitiationRow>[];
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openVendorOrder(DonationIntent intent) async {
    final updated = await Navigator.of(context).push<DonationIntent>(
      MaterialPageRoute<DonationIntent>(
        builder: (BuildContext context) => DonationIntentDetailPage(
          intent: intent,
          apiBaseUrl: _defaultApiBaseUrl,
          authContext: _session,
        ),
      ),
    );
    if (updated != null) {
      _patchIntent(updated);
    }
  }

  void _openMealNeed(SeekerDemandSummary demand) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            SeekerDemandDetailPage(demand: demand),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const DonorAppBar(
        title: 'Initiations',
        showSignOut: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Direct orders you pay yourself, and items opened for pledging.',
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
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_rows.isEmpty)
              const Text('No initiations yet.')
            else
              ..._rows.map(_buildRow),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(_InitiationRow row) {
    if (row.kind == _InitiationKind.vendorOrder && row.intent != null) {
      final intent = row.intent!;
      final thumb = intent.referencePhotoThumbnailUrl?.trim().isNotEmpty == true
          ? intent.referencePhotoThumbnailUrl
          : intent.referencePhotoViewUrl;
      return Card(
        child: ListTile(
          leading: intent.hasDisplayableReferencePhoto
              ? SizedBox(
                  width: 48,
                  height: 48,
                  child: ReferencePhotoPreview(
                    thumbnailUrl: thumb,
                    viewUrl: intent.referencePhotoViewUrl,
                  ),
                )
              : const Icon(Icons.delivery_dining_outlined),
          title: Text(
            intent.primaryRestaurantName ?? intent.orderIntentId,
          ),
          subtitle: Text(
            '${initiationKindLabel(InitiationFeedKind.vendorOrder)} · '
            '${intent.statusLabel} · ${intent.paymentStatusLabel}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openVendorOrder(intent),
        ),
      );
    }

    final demand = row.demand!;
    final routeLabel = initiationApiRouteLabel(demand.initiationRoute);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.restaurant_outlined),
        title: Text(demand.menuLabel ?? demand.seekerDemandId),
        subtitle: Text(
          '$routeLabel · '
          '${demand.mealUnits} unit${demand.mealUnits == 1 ? '' : 's'}'
          '${demand.localityKey != null ? ' · ${demand.localityKey}' : ''}'
          '${demand.orderCode != null ? ' · ${demand.orderCode}' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openMealNeed(demand),
      ),
    );
  }
}
