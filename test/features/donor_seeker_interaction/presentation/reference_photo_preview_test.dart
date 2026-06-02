import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_seeker_interaction/presentation/widgets/reference_photo_preview.dart';

void main() {
  testWidgets('shows network preview and view full image action', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReferencePhotoPreview(
            thumbnailUrl: 'https://res.cloudinary.com/demo/thumb.jpg',
            viewUrl: 'https://res.cloudinary.com/demo/view.jpg',
            caption: 'Reference photo',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Reference photo'), findsOneWidget);
    expect(find.text('View full image'), findsOneWidget);
  });
}
