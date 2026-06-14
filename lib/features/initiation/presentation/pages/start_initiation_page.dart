import 'package:flutter/material.dart';

import '../../../../initiation_labels.dart';
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
            'How should this meal be fulfilled?',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Every route starts the same way — location, optional reference photo, '
            'and handover notes — then diverges on payment and fulfilment.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              key: const Key('start_initiation_vendor_order'),
              leading: const Icon(Icons.delivery_dining_outlined),
              title: const Text(InitiationRouteLabels.directOrder),
              subtitle: const Text(
                'You pay in the vendor app yourself — AI delivery instructions, '
                'copy to Swiggy/Zomato, then register the order.',
              ),
              onTap: () => navigateToHelpASeeker(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              key: const Key('start_initiation_meal_need'),
              leading: const Icon(Icons.volunteer_activism_outlined),
              title: const Text(InitiationRouteLabels.forPledging),
              subtitle: const Text(
                'Record a standard menu item for this area. Others fund it via '
                'pledges on the SharingBridge dashboard.',
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
          const SizedBox(height: 12),
          Card(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.6,
            ),
            child: ListTile(
              enabled: false,
              leading: Icon(
                Icons.groups_outlined,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              title: Text(
                InitiationRouteLabels.communityKitchens,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              subtitle: Text(
                'Open kitchens commit to a standard menu — nutritious, hygienic, '
                'economical meals at scale. Coming soon.',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
