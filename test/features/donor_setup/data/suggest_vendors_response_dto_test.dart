import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/data/dto/suggest_vendors_response_dto.dart';

void main() {
  test('maps valid suggestions and trims to five', () {
    final json = <String, dynamic>{
      'suggestions': List.generate(
        6,
        (int i) => <String, dynamic>{
          'restaurant_name': 'R$i',
          'menu_items': <String>['Meals'],
          'order_url': 'https://example.com/$i',
          'app_name': 'VendorApp',
          'confidence': 0.8,
        },
      ),
    };

    final dto = SuggestVendorsResponseDto.fromJson(json);
    expect(dto.suggestions.length, 5);
    expect(dto.source, isNull);
  });

  test('maps source field when present', () {
    final json = <String, dynamic>{
      'source': 'deterministic',
      'suggestions': <Map<String, dynamic>>[
        <String, dynamic>{
          'restaurant_name': 'R0',
          'menu_items': <String>['Meals'],
          'order_url': 'https://example.com/0',
          'app_name': 'VendorApp',
          'confidence': 0.8,
        },
      ],
    };
    final dto = SuggestVendorsResponseDto.fromJson(json);
    expect(dto.source, 'deterministic');
  });

  test('throws for malformed payload', () {
    expect(
      () => SuggestVendorsResponseDto.fromJson(<String, dynamic>{
        'suggestions': 'not-a-list',
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
