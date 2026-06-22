import 'package:flutter/material.dart';

import '../features/auth/presentation/sign_out_action.dart';
import 'navigate_donor_home.dart';

/// Shared app bar for initiator signed-in flows: back, home, and sign-out.
class InitiatorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const InitiatorAppBar({
    super.key,
    required this.title,
    this.isHub = false,
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
  /// Hub screen ([AppHomePage]) — no back or home controls.
  final bool isHub;
  final bool showBack;
  /// When true and not [isHub], shows home → [AppHomePage] via [navigateDonorHome].
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
    final showHomeButton = showHome && !isHub;

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
          TextButton.icon(
            key: const Key('donor_app_bar_home'),
            icon: const Icon(Icons.home, size: 22),
            label: const Text('Home'),
            onPressed: onHome ?? () => navigateDonorHome(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
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

/// Legacy name — prefer [InitiatorAppBar].
typedef DonorAppBar = InitiatorAppBar;
