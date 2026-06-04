import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/web_dashboard_url.dart';
import '../features/donor_seeker_interaction/presentation/pages/donation_history_page.dart';
import '../features/donor_seeker_interaction/presentation/pages/donor_seeker_interaction_page.dart';
import '../features/donor_setup/presentation/pages/donor_setup_page.dart';
import 'donor_app_bar.dart';

/// Entry hub: vendor presets (before field) vs help a seeker (BRD steps 2+).
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  Future<void> _openWebDashboard(BuildContext context) async {
    final url = WebDashboardUrl.value.trim();
    if (!WebDashboardUrl.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Rebuild the app with --dart-define=WEB_DASHBOARD_URL=<your web app URL>.',
          ),
          duration: Duration(seconds: 5),
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
    final webUrl = WebDashboardUrl.value.trim();
    final webSubtitle = WebDashboardUrl.isConfigured
        ? 'Open $webUrl — nearby intents, distance (m), and photos.'
        : 'Requires WEB_DASHBOARD_URL when you build the app (see mobile-client.md).';

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
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              key: const Key('nav_web_dashboard'),
              leading: const Icon(Icons.open_in_browser),
              title: const Text('Neighbourhood dashboard (web)'),
              subtitle: Text(webSubtitle),
              trailing: const Icon(Icons.chevron_right),
              enabled: WebDashboardUrl.isConfigured,
              onTap: () => _openWebDashboard(context),
            ),
          ),
        ],
      ),
    );
  }
}
