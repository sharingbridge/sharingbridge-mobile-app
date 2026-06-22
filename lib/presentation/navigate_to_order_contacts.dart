import 'package:flutter/material.dart';

import '../features/connection/presentation/pages/order_contacts_page.dart';

void navigateToOrderContacts(
  BuildContext context, {
  String? initialOrderCode,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => OrderContactsPage(
        initialOrderCode: initialOrderCode,
      ),
    ),
  );
}
