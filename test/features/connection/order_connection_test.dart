import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/connection/domain/models/order_connection.dart';

void main() {
  group('OrderConnection.fromJson', () {
    test('parses ready connection for initiator', () {
      final connection = OrderConnection.fromJson(<String, dynamic>{
        'order_code': 'SB-7K2M-9F3',
        'status': 'ready',
        'initiation_route': 'eco_kitchen_self_pay',
        'viewer_role': 'initiator',
        'safety_copy': 'Confirm before paying.',
        'menu_label': 'Lemon rice',
        'meal_units': 2,
        'price_inr': 120,
        'locality_key': 'IN:TN:600001',
        'seeker_demand_id': 'sd-1',
        'demand': <String, dynamic>{
          'seeker_demand_id': 'sd-1',
          'status': 'open',
          'need_description': 'Lemon rice',
          'verbal_notes': 'No onion',
          'location_label': 'Adyar',
          'standard_offer_id': 'offer-1',
          'recorded_at': '2026-06-10T10:00:00Z',
        },
        'kitchen': <String, dynamic>{
          'display_name': 'Green Kitchen',
          'login_email': 'kitchen@example.com',
        },
        'counterparty_email': 'kitchen@example.com',
      });

      expect(connection.orderCode, 'SB-7K2M-9F3');
      expect(connection.contactsReady, isTrue);
      expect(connection.kitchenLoginEmail, 'kitchen@example.com');
      expect(connection.demand?.locationLabel, 'Adyar');
      expect(connection.pledgers, isEmpty);
    });

    test('parses pending kitchen without contacts', () {
      final connection = OrderConnection.fromJson(<String, dynamic>{
        'order_code': 'SB-ABCD-123',
        'status': 'pending_kitchen',
        'initiation_route': 'eco_kitchen_pledge',
        'viewer_role': 'initiator',
        'menu_label': 'Meals',
        'locality_key': 'IN:TN',
      });

      expect(connection.contactsReady, isFalse);
      expect(connection.kitchenLoginEmail, isNull);
    });

    test('parses pledgers for coordinator view', () {
      final connection = OrderConnection.fromJson(<String, dynamic>{
        'order_code': 'SB-ABCD-123',
        'status': 'ready',
        'initiation_route': 'eco_kitchen_pledge',
        'viewer_role': 'coordinator',
        'menu_label': 'Meals',
        'locality_key': 'IN:TN',
        'initiator': <String, dynamic>{'login_email': 'initiator@example.com'},
        'pledgers': <Map<String, dynamic>>[
          <String, dynamic>{
            'pledged_by_user_id': 'u-2',
            'meal_units': 3,
            'login_email': 'pledger@example.com',
          },
        ],
      });

      expect(connection.initiatorEmail, 'initiator@example.com');
      expect(connection.pledgers, hasLength(1));
      expect(connection.pledgers.first.mealUnits, 3);
    });
  });
}
