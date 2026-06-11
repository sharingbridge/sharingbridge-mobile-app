import 'package:flutter/material.dart';

/// Shared copy for About and the handoff gate (dignity, vendors, flow).
class AboutContent extends StatelessWidget {
  const AboutContent({super.key});

  static const List<({String title, String body})> sections =
      <({String title, String body})>[
    (
      title: 'What SharingBridge does',
      body:
          'SharingBridge helps you arrange meals for anyone who needs food — '
          'someone you meet, a parent, a senior neighbour, or yourself. '
          'Prepare courier-facing instructions, copy them, then place and pay '
          'in Swiggy or Zomato yourself.',
    ),
    (
      title: 'Consent and dignity',
      body:
          'Only continue if the person agrees to receive help and to how they '
          'may be described for the delivery partner. Ask before taking a '
          'reference photo; verbal notes are fine if they prefer not to be '
          'photographed. Prefer a visible, public spot. You decide whether to '
          'continue — the app does not certify a place as safe.',
    ),
    (
      title: 'Vendor apps (Swiggy / Zomato)',
      body:
          'Saved links open search or a restaurant — not checkout. After you '
          'copy instructions in this app: add items in the vendor app, go to '
          'checkout with delivery to the seeker address, then paste into '
          'delivery-partner instructions (not chef or cooking notes). Payment '
          'happens in the vendor app.',
    ),
    (
      title: 'Order intent',
      body:
          'Copying instructions registers an order intent for coordinators '
          'and nearby initiators on the web dashboard. It is not a placed or '
          'paid vendor order until you complete checkout there.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ({String title, String body}) section in sections) ...<Widget>[
          Text(section.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(section.body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}
