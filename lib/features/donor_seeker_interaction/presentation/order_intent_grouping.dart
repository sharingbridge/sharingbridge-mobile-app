import '../domain/models/donation_intent.dart';

enum DonationHistoryGroupMode {
  day,
}

class DonationIntentGroup {
  const DonationIntentGroup({
    required this.label,
    required this.intents,
  });

  final String label;
  final List<DonationIntent> intents;
}

String dayGroupLabel(DateTime? value) {
  if (value == null) {
    return 'Unknown date';
  }
  final local = value.toLocal();
  final y = local.year;
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

List<DonationIntentGroup> groupDonationIntents(
  List<DonationIntent> intents, {
  DonationHistoryGroupMode mode = DonationHistoryGroupMode.day,
}) {
  if (intents.isEmpty) {
    return <DonationIntentGroup>[];
  }
  if (mode != DonationHistoryGroupMode.day) {
    return <DonationIntentGroup>[
      DonationIntentGroup(label: 'All', intents: intents),
    ];
  }

  final sorted = List<DonationIntent>.from(intents)
    ..sort((DonationIntent a, DonationIntent b) {
      final at = a.sortTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.sortTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });

  final Map<String, List<DonationIntent>> buckets = <String, List<DonationIntent>>{};
  for (final DonationIntent intent in sorted) {
    final label = dayGroupLabel(intent.sortTime);
    buckets.putIfAbsent(label, () => <DonationIntent>[]).add(intent);
  }

  return buckets.entries
      .map(
        (MapEntry<String, List<DonationIntent>> entry) =>
            DonationIntentGroup(label: entry.key, intents: entry.value),
      )
      .toList();
}
