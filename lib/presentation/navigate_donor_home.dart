import 'package:flutter/material.dart';

import 'donor_navigator_shell.dart';

/// Pops the signed-in stack back to [AppHomePage] ([DonorNavigatorShell.homeRouteName]).
void navigateDonorHome(BuildContext context) {
  Navigator.of(context).popUntil(
    (Route<dynamic> route) =>
        route.settings.name == DonorNavigatorShell.homeRouteName ||
        route.isFirst,
  );
}
