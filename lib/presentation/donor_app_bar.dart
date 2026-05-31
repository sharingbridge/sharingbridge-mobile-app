import 'package:flutter/material.dart';

import '../features/auth/presentation/sign_out_action.dart';

/// Shared app bar for donor flows: explicit back (when [showBack]) and sign-out.
class DonorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DonorAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.showSignOut = true,
    this.onBack,
    this.backTooltip = 'Back',
    this.actions,
  });

  final String title;
  final bool showBack;
  final bool showSignOut;
  final VoidCallback? onBack;
  final String backTooltip;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
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
