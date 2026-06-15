import 'package:flutter/material.dart';

import '../../../../initiation_labels.dart';
import '../../../../presentation/donor_app_bar.dart';
import '../../domain/models/seeker_demand_summary.dart';

class SeekerDemandDetailPage extends StatelessWidget {
  const SeekerDemandDetailPage({
    super.key,
    required this.demand,
  });

  final SeekerDemandSummary demand;

  static String formatWhen(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw.isEmpty ? '—' : raw;
    }
    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  bool get _isSelfPay => demand.initiationRoute == 'eco_kitchen_self_pay';

  String get _routeLabel => initiationApiRouteLabel(demand.initiationRoute);

  String get _bodyCopy => _isSelfPay
      ? 'Eco kitchen pool — coordinators commit on the SharingBridge dashboard '
          '(Actions tab). After a kitchen commits, open Connection with order code '
          '${demand.orderCode ?? 'SB-…'} to pay off-platform.'
      : 'Open for pledging — pledgers and eco kitchens coordinate on the '
          'SharingBridge dashboard (Actions tab: pledges and kitchen commitments), '
          'not direct checkout in a vendor app.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: DonorAppBar(
        title: _routeLabel,
        showSignOut: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            _routeLabel,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            demand.menuLabel ?? demand.seekerDemandId,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (demand.orderCode != null && demand.orderCode!.isNotEmpty)
            _DetailRow(label: 'Order code', value: demand.orderCode!),
          _DetailRow(label: 'Reference', value: demand.seekerDemandId),
          _DetailRow(
            label: 'Units',
            value: '${demand.mealUnits}',
          ),
          if (demand.localityKey != null)
            _DetailRow(label: 'Area', value: demand.localityKey!),
          _DetailRow(label: 'Status', value: demand.status),
          _DetailRow(
            label: 'Recorded',
            value: formatWhen(demand.createdAt),
          ),
          const SizedBox(height: 12),
          Text(
            _bodyCopy,
            style: theme.textTheme.bodyMedium,
          ),
          if (demand.verbalNotes?.trim().isNotEmpty == true) ...<Widget>[
            const SizedBox(height: 16),
            Text('Notes', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(demand.verbalNotes!.trim()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
