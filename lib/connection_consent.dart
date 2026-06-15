import 'package:flutter/material.dart';

/// Copy for upfront consent before eco-kitchen routes that share login emails.
abstract final class ConnectionConsentCopy {
  static const initiatorOpenForPledgingTitle =
      'Email sharing when a kitchen commits';

  static const initiatorOpenForPledgingBody =
      'When an eco kitchen commits to fulfil this need, pledgers and that kitchen '
      'will see each other\'s SharingBridge login emails in the app so they can '
      'coordinate payment and delivery off-platform. '
      'If you pledge too, your email is included.';

  static const initiatorOpenForPledgingCheckbox =
      'I understand login emails may be shared for payment coordination';

  static const initiatorEcoKitchenSelfPayTitle =
      'Email sharing with the eco kitchen';

  static const initiatorEcoKitchenSelfPayBody =
      'When an eco kitchen commits, your SharingBridge login email will be shared '
      'with that kitchen (and theirs with you) for payment and delivery '
      'off-platform. SharingBridge does not process payments.';

  static const pledgingRouteHint =
      'Pledgers will be asked to consent before pledging on the dashboard.';
}

/// Dialog before entering the for-pledging capture flow.
Future<bool> confirmInitiatorEmailSharingConsent(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  var agreed = false;
  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(body),
                  const SizedBox(height: 12),
                  Text(
                    ConnectionConsentCopy.pledgingRouteHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: agreed,
                    onChanged: (bool? value) {
                      setState(() => agreed = value ?? false);
                    },
                    title: const Text(
                      ConnectionConsentCopy.initiatorOpenForPledgingCheckbox,
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: agreed ? () => Navigator.of(context).pop(true) : null,
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    },
  );
  return result == true;
}
