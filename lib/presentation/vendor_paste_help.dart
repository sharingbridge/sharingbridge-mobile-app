import 'package:flutter/material.dart';

/// Expandable Swiggy / Zomato paste steps on the handoff copy step.
class VendorPasteHelp extends StatelessWidget {
  const VendorPasteHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: ExpansionTile(
        key: const Key('vendor_paste_help'),
        leading: const Icon(Icons.help_outline),
        title: const Text('Where to paste in Swiggy / Zomato'),
        children: const <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'The vendor app does not pre-fill from SharingBridge. '
                  'After you copy above:',
                ),
                SizedBox(height: 10),
                Text('1. Open vendor app → add items → checkout (delivery).'),
                Text('2. Set delivery address to the seeker location.'),
                Text(
                  '3. Find delivery-partner instructions (not chef / cooking notes).',
                ),
                Text('4. Long-press → Paste → pay in the vendor app.'),
                SizedBox(height: 8),
                Text(
                  'Swiggy: often under “Directions to reach” or delivery instructions at checkout.',
                  style: TextStyle(fontSize: 13),
                ),
                Text(
                  'Zomato: “Add instructions” on the payment / checkout screen.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
