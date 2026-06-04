import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/donor_seeker_interaction/presentation/pages/donation_history_page.dart';
import '../features/donor_seeker_interaction/presentation/pages/donor_seeker_interaction_page.dart';
import '../features/donor_setup/presentation/pages/donor_setup_page.dart';
import 'donor_app_bar.dart';

/// Entry hub: vendor presets (before field) vs help a seeker (BRD steps 2+).
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  static const String _webDashboardUrl = String.fromEnvironment(
    'WEB_DASHBOARD_URL',
    defaultValue: '',
  );

  Future<void> _openWebDashboard(BuildContext context) async {
    final url = _webDashboardUrl.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Web dashboard URL is not configured (WEB_DASHBOARD_URL).',
          ),
        ),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WEB_DASHBOARD_URL is not a valid URL.')),
      );
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the web dashboard.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DonorAppBar(
        title: 'SharingBridge',
        isHub: true,
        showBack: false,
        showHome: false,
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
          if (_webDashboardUrl.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                key: const Key('nav_web_dashboard'),
                leading: const Icon(Icons.open_in_browser),
                title: const Text('Neighbourhood dashboard (web)'),
                subtitle: const Text(
                  'See nearby order intents, distance, and photos in the browser.',
                ),
                onTap: () => _openWebDashboard(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
