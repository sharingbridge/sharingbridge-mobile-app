import 'package:flutter/material.dart';

import '../../../../connection_consent.dart';
import '../../../../initiation_labels.dart';
import '../../../../presentation/navigate_to_help_a_seeker.dart';
import '../../../seeker_demand/presentation/pages/record_seeker_demand_page.dart';
import '../../../../seeker_demand_initiation_route.dart';

/// Choose how payment will happen, then continue into the shared initiation flow.
class StartInitiationPage extends StatelessWidget {
  const StartInitiationPage({super.key});

  Future<void> _openForPledging(BuildContext context) async {
    final ok = await confirmInitiatorEmailSharingConsent(
      context,
      title: ConnectionConsentCopy.initiatorOpenForPledgingTitle,
      body: ConnectionConsentCopy.initiatorOpenForPledgingBody,
    );
    if (!ok || !context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const RecordSeekerDemandPage(
          initiationRoute: SeekerDemandInitiationRoute.ecoKitchenPledge,
        ),
      ),
    );
  }

  Future<void> _openEcoKitchenSelfPay(BuildContext context) async {
    final ok = await confirmInitiatorEmailSharingConsent(
      context,
      title: ConnectionConsentCopy.initiatorEcoKitchenSelfPayTitle,
      body: ConnectionConsentCopy.initiatorEcoKitchenSelfPayBody,
    );
    if (!ok || !context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const RecordSeekerDemandPage(
          initiationRoute: SeekerDemandInitiationRoute.ecoKitchenSelfPay,
        ),
      ),
    );
  }

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
              title: const Text(InitiationRouteLabels.ecoKitchenPledge),
              subtitle: const Text(
                'Record a standard menu item for this area. Pledgers fund units on '
                'the SharingBridge dashboard; an eco kitchen commits to fulfil.',
              ),
              onTap: () => _openForPledging(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              key: const Key('start_initiation_eco_kitchen_self_pay'),
              leading: const Icon(Icons.groups_outlined),
              title: const Text(InitiationRouteLabels.ecoKitchenSelfPay),
              subtitle: const Text(
                'Eco kitchens commit to a standard menu — nutritious, hygienic, '
                'eco-friendly packaging at economical scale. You pay off-platform '
                'after connection is ready.',
              ),
              onTap: () => _openEcoKitchenSelfPay(context),
            ),
          ),
        ],
      ),
    );
  }
}
