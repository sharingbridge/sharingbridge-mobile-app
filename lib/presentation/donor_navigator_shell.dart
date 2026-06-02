import 'package:flutter/material.dart';

import 'app_home_page.dart';

/// Signed-in navigation stack; [AppHomePage] is the root route so Home can pop back reliably.
class DonorNavigatorShell extends StatelessWidget {
  const DonorNavigatorShell({super.key});

  static const String homeRouteName = '/donor-home';

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: homeRouteName,
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute<void>(
          settings: const RouteSettings(name: homeRouteName),
          builder: (BuildContext context) => const AppHomePage(),
        );
      },
    );
  }
}
