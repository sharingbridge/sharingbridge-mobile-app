import 'package:flutter/material.dart';

import '../features/auth/presentation/sign_out_action.dart';
import 'navigate_donor_home.dart';

/// Shared app bar for donor flows: back, home, and sign-out.
class DonorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DonorAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.showHome = true,
    this.showSignOut = true,
    this.onBack,
    this.onHome,
    this.backTooltip = 'Back',
    this.homeTooltip = 'Home',
    this.actions,
  });

  final String title;
  final bool showBack;
  /// When true, shows a home control that returns to [AppHomePage]. Defaults on sub-pages ([showBack]).
  final bool showHome;
  final bool showSignOut;
  final VoidCallback? onBack;
  final VoidCallback? onHome;
  final String backTooltip;
  final String homeTooltip;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final showHomeButton = showHome && showBack;

    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(title),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: backTooltip,
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      actions: <Widget>[
        ...?actions,
        if (showHomeButton)
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: homeTooltip,
            onPressed: onHome ?? () => navigateDonorHome(context),
          ),
        if (showSignOut)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => signOutAndReturnToLogin(context),
          ),
      ],
    );
  }
}
