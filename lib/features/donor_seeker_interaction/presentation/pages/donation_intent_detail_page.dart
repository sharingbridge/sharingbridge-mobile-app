import 'package:flutter/material.dart';

import '../../domain/models/donation_intent.dart';

class DonationIntentDetailPage extends StatelessWidget {
  const DonationIntentDetailPage({super.key, required this.intent});

  final DonationIntent intent;

  static String formatWhen(DateTime? value) {
    if (value == null) {
      return '—';
    }
    final local = value.toLocal();
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
      appBar: AppBar(title: const Text('Donation intent')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _DetailRow(label: 'Reference', value: intent.orderIntentId),
          _DetailRow(label: 'Instruction pack', value: intent.packId),
          _DetailRow(label: 'Status', value: intent.statusLabel),
          _DetailRow(
            label: 'Reference photo',
            value: intent.hasReferencePhoto ? 'Yes' : 'No',
          ),
          _DetailRow(label: 'Registered', value: formatWhen(intent.createdAt)),
          _DetailRow(label: 'Last updated', value: formatWhen(intent.updatedAt)),
          if (intent.verbalHandoverNotes.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text('Handover notes', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(intent.verbalHandoverNotes),
              ),
            ),
          ],
          if (intent.presetsSnapshot.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              'Saved presets at registration (${intent.presetsSnapshot.length})',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...intent.presetsSnapshot.map((Map<String, dynamic> row) {
              final restaurant =
                  row['restaurant_name']?.toString().trim() ?? 'Vendor';
              final app = row['app_name']?.toString().trim();
              final subtitle = app != null && app.isNotEmpty ? app : null;
              return Card(
                child: ListTile(
                  title: Text(restaurant),
                  subtitle: subtitle != null ? Text(subtitle) : null,
                ),
              );
            }),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          SelectableText(value),
        ],
      ),
    );
  }
}
