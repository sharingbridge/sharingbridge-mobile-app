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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const DonorAppBar(
        title: InitiationRouteLabels.forPledging,
        showSignOut: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            InitiationRouteLabels.forPledging,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            demand.menuLabel ?? demand.seekerDemandId,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
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
            'Opened for pledging — fulfilment is coordinated on the SharingBridge '
            'dashboard (Actions tab: pledges and eco kitchen commitments), not direct '
            'checkout in a vendor app.',
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
