import 'package:flutter/material.dart';

import '../features/donor_seeker_interaction/presentation/pages/donation_history_page.dart';
import '../features/donor_seeker_interaction/presentation/pages/donor_seeker_interaction_page.dart';
import '../features/donor_setup/presentation/pages/donor_setup_page.dart';
import 'donor_app_bar.dart';

/// Entry hub: vendor presets (before field) vs help a seeker (BRD steps 2+).
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DonorAppBar(
        title: 'SharingBridge',
        showBack: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: <Widget>[
          Text(
            'Choose how you are using the app right now.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              key: const Key('nav_donor_setup'),
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Vendor presets'),
              subtitle: const Text(
                'Search vendors, save order links and menu presets before you go out.',
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const DonorSetupPage(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              key: const Key('nav_field_flow'),
              leading: const Icon(Icons.volunteer_activism_outlined),
              title: const Text('Help a seeker'),
              subtitle: const Text(
                'Someone is asking for help now — quick guidance, consent, and handover details.',
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const DonorSeekerInteractionPage(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              key: const Key('nav_donation_history'),
              leading: const Icon(Icons.history),
              title: const Text('Order initiation history'),
              subtitle: const Text(
                'Order initiations you registered when copying delivery instructions.',
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) =>
                        const DonationHistoryPage(),
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
