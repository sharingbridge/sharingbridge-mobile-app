import 'package:flutter/material.dart';

import '../../../../presentation/navigate_to_help_a_seeker.dart';
import '../../../seeker_demand/presentation/pages/record_seeker_demand_page.dart';

/// Choose how payment will happen, then continue into the shared initiation flow.
class StartInitiationPage extends StatelessWidget {
  const StartInitiationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Start initiation')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'How will this meal be paid for?',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Both paths start the same way — location, optional reference photo, '
            'and handover notes — then diverge on payment.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              key: const Key('start_initiation_vendor_order'),
              leading: const Icon(Icons.delivery_dining_outlined),
              title: const Text('I will pay in the vendor app'),
              subtitle: const Text(
                'AI delivery instructions, copy to Swiggy/Zomato, and register a vendor order.',
              ),
              onTap: () => navigateToHelpASeeker(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              key: const Key('start_initiation_meal_need'),
              leading: const Icon(Icons.volunteer_activism_outlined),
              title: const Text('Others pledge toward this need'),
              subtitle: const Text(
                'Record a standard menu item for this area. Payment happens through pledges and vendor bids.',
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const RecordSeekerDemandPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
