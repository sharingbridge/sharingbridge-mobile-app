import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/connection/data/http_connection_client.dart';
import 'package:sharingbridge_mobile_app/features/connection/domain/models/order_connection.dart';
import 'package:sharingbridge_mobile_app/features/connection/presentation/pages/order_contacts_page.dart';

class _FakeConnectionClient extends HttpConnectionClient {
  _FakeConnectionClient({required this.connection})
      : super(baseUrl: 'http://test');

  final OrderConnection connection;

  @override
  Future<OrderConnection> fetchOrderConnection(String orderCode) async {
    return connection;
  }
}

void main() {
  testWidgets('OrderContactsPage shows lookup field and result', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrderContactsPage(
          initialOrderCode: 'SB-7K2M-9F3',
          client: _FakeConnectionClient(
            connection: OrderConnection.fromJson(<String, dynamic>{
              'order_code': 'SB-7K2M-9F3',
              'status': 'ready',
              'initiation_route': 'eco_kitchen_self_pay',
              'viewer_role': 'initiator',
              'menu_label': 'Lemon rice',
              'locality_key': 'IN:TN',
              'counterparty_email': 'kitchen@example.com',
              'kitchen': <String, dynamic>{
                'display_name': 'Green Kitchen',
                'login_email': 'kitchen@example.com',
              },
            }),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('order_contacts_code_field')), findsOneWidget);
    expect(find.text('SB-7K2M-9F3'), findsWidgets);
    expect(find.text('Contacts ready'), findsOneWidget);
    expect(find.text('kitchen@example.com'), findsOneWidget);
  });
}
