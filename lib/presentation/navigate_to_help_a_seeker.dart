import 'package:flutter/material.dart';

import '../features/auth/data/auth_session_holder.dart';
import '../features/donor_seeker_interaction/presentation/pages/donor_seeker_interaction_page.dart';
import 'handoff_about_gate_page.dart';
import 'handoff_gate_ack_store.dart';

/// Opens Help a seeker, skipping the read-through gate when already acknowledged
/// for the signed-in user this login (until sign-out).
Future<void> navigateToHelpASeeker(BuildContext context) async {
  final userId = AuthSessionHolder.resolve().userId.trim();
  if (userId.isNotEmpty &&
      await HandoffGateAckStore().hasAcknowledgedForUser(userId)) {
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const DonorSeekerInteractionPage(),
      ),
    );
    return;
  }
  if (!context.mounted) {
    return;
  }
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => const HandoffAboutGatePage(),
    ),
  );
}
