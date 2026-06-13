import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';



import '../config/web_dashboard_url.dart';

import '../features/auth/data/auth_session_store.dart';

import '../features/auth/presentation/sign_out_action.dart';

import '../features/initiation/presentation/pages/start_initiation_page.dart';

import '../features/operations/presentation/pages/operations_page.dart';

import '../features/donor_setup/presentation/pages/donor_setup_page.dart';

import 'about_page.dart';

import 'donor_app_bar.dart';



/// Entry hub: vendor presets (before field) vs help a seeker (BRD steps 2+).

class AppHomePage extends StatefulWidget {

  const AppHomePage({super.key});



  @override

  State<AppHomePage> createState() => _AppHomePageState();

}



class _AppHomePageState extends State<AppHomePage> {

  StoredAuthSession? _session;



  @override

  void initState() {

    super.initState();

    _loadSession();

  }



  Future<void> _loadSession() async {

    final stored = await AuthSessionStore().load();

    if (!mounted) {

      return;

    }

    setState(() => _session = stored);

  }



  String get _accountLabel {

    final email = _session?.email?.trim();

    if (email != null && email.isNotEmpty) {

      return email;

    }

    final name = _session?.name?.trim();

    if (name != null && name.isNotEmpty) {

      return name;

    }

    final userId = _session?.userId.trim() ?? '';

    if (userId.isNotEmpty) {

      return userId;

    }

    return 'Signed in';

  }



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

      appBar: DonorAppBar(

        title: 'SharingBridge',

        isHub: true,

        showBack: false,

        showHome: false,

        showSignOut: false,

        actions: <Widget>[

          TextButton.icon(

            key: const Key('nav_about'),

            icon: const Icon(Icons.info_outline, size: 22),

            label: const Text('About'),

            onPressed: () {

              Navigator.of(context).push(

                MaterialPageRoute<void>(

                  builder: (BuildContext context) => const AboutPage(),

                ),

              );

            },

          ),

        ],

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

              key: const Key('nav_start_initiation'),

              leading: const Icon(Icons.play_circle_outline),

              title: const Text('Start initiation'),

              subtitle: const Text(

                'Pay in a vendor app yourself, or record a meal need for the pledge flow.',

              ),

              onTap: () {

                Navigator.of(context).push(

                  MaterialPageRoute<void>(

                    builder: (BuildContext context) =>

                        const StartInitiationPage(),

                  ),

                );

              },

            ),

          ),

          const SizedBox(height: 8),

          Card(

            child: ListTile(

              key: const Key('nav_meal_operations'),

              leading: const Icon(Icons.history),

              title: const Text('Initiations'),

              subtitle: const Text(

                'Vendor orders and meal needs you started.',

              ),

              onTap: () {

                Navigator.of(context).push(

                  MaterialPageRoute<void>(

                    builder: (BuildContext context) =>

                        const OperationsPage(),

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

          const SizedBox(height: 24),

          Card(

            child: Padding(

              padding: const EdgeInsets.all(16),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: <Widget>[

                  Row(

                    children: <Widget>[

                      Icon(

                        Icons.account_circle_outlined,

                        color: Theme.of(context).colorScheme.primary,

                      ),

                      const SizedBox(width: 12),

                      Expanded(

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: <Widget>[

                            Text(

                              'Signed in',

                              style: Theme.of(context).textTheme.labelMedium,

                            ),

                            Text(

                              _accountLabel,

                              style: Theme.of(context).textTheme.titleSmall,

                            ),

                          ],

                        ),

                      ),

                    ],

                  ),

                  const SizedBox(height: 8),

                  Text(

                    'The app remembers your sign-in until you sign out or the '

                    'session expires (about 1 hour). Use Switch account to sign '

                    'in with a different Google user.',

                    style: Theme.of(context).textTheme.bodySmall,

                  ),

                  const SizedBox(height: 16),

                  OutlinedButton.icon(

                    key: const Key('home_switch_account'),

                    onPressed: () =>

                        switchGoogleAccountAndReturnToLogin(context),

                    icon: const Icon(Icons.swap_horiz),

                    label: const Text('Switch Google account'),

                  ),

                  const SizedBox(height: 8),

                  TextButton.icon(

                    key: const Key('home_sign_out'),

                    onPressed: () => signOutAndReturnToLogin(context),

                    icon: const Icon(Icons.logout),

                    label: const Text('Sign out'),

                  ),

                ],

              ),

            ),

          ),

        ],

      ),

    );

  }

}


