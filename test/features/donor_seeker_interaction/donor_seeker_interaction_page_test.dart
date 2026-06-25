import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharingbridge_mobile_app/features/donor_seeker_interaction/application/delivery_instruction_stub.dart';
import 'package:sharingbridge_mobile_app/features/donor_seeker_interaction/data/capture_handover_location.dart';
import 'package:sharingbridge_mobile_app/features/donor_seeker_interaction/domain/models/instruction_pack_result.dart';
import 'package:sharingbridge_mobile_app/features/donor_seeker_interaction/presentation/pages/donor_seeker_interaction_page.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/application/load_presets_usecase.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/data/auth_context.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/donor_preset.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/suggest_vendors_result.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/models/vendor_suggestion.dart';
import 'package:sharingbridge_mobile_app/features/donor_setup/domain/repositories/donor_setup_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sharingbridge_mobile_app/features/auth/data/auth_session_holder.dart';
import 'package:sharingbridge_mobile_app/presentation/app_home_page.dart';
import 'package:sharingbridge_mobile_app/presentation/handoff_gate_ack_store.dart';

class _FakeRepo implements DonorSetupRepository {
  _FakeRepo(this.presets);

  final List<DonorPreset> presets;

  @override
  Future<void> clearPresets({required String userId}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<DonorPreset>> loadPresets({required String userId}) async {
    return List<DonorPreset>.from(presets);
  }

  @override
  Future<void> removePreset({
    required String userId,
    required DonorPreset preset,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> savePresets({
    required String userId,
    required List<DonorPreset> presets,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<SuggestVendorsResult> suggestVendors({
    required String queryText,
    required double? lat,
    required double? lng,
    String? manualArea,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AuthSessionHolder.clear();
  });

  testWidgets('home hub skips read-through gate when already acknowledged', (
    WidgetTester tester,
  ) async {
    AuthSessionHolder.setSession(userId: 'alice', token: 'jwt-alice');
    await HandoffGateAckStore().markAcknowledgedForUser('alice');

    await tester.pumpWidget(
      const MaterialApp(home: AppHomePage()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav_start_initiation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start_initiation_vendor_order')));
    await tester.pumpAndSettle();

    expect(find.text('Before you help'), findsNothing);
    expect(find.text('Help a seeker'), findsWidgets);
  });

  testWidgets('home hub lists donor setup and opens field flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppHomePage()),
    );

    expect(find.textContaining('Vendor presets'), findsWidgets);
    expect(find.textContaining('Start initiation'), findsWidgets);
    expect(find.byKey(const Key('nav_web_dashboard')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav_start_initiation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start_initiation_vendor_order')));
    await tester.pumpAndSettle();

    expect(find.text('Before you help'), findsOneWidget);
    expect(find.textContaining('Consent and dignity'), findsOneWidget);
  });

  testWidgets('field page loads instructions and enables vendors after copy', (
    WidgetTester tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
      MethodCall call,
    ) async {
      if (call.method == 'Clipboard.setData') {
        return;
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final presets = <DonorPreset>[
      DonorPreset(
        restaurantName: 'Cafe X',
        orderUrl: 'https://example.com/order',
        menuItems: const <String>['Coffee'],
        appName: 'Swiggy',
        source: 'test',
        confidence: 0.8,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: DonorSeekerInteractionPage(
          authContext: const AuthContext(userId: 'u1', authToken: 'tok'),
          loadPresetsUseCase: LoadPresetsUseCase(_FakeRepo(presets)),
          captureHandoverLocation: () async => const HandoverLocation(
            lat: 12.94,
            lng: 80.24,
          ),
          deliveryInstructionsRequest: ({
            required List<DonorPreset> presets,
            required bool hasReferencePhoto,
            String? referencePhotoArtifactId,
            String? referencePhotoViewUrl,
            String? referencePhotoThumbnailUrl,
            String? verbalHandoverNotes,
            double? lat,
            double? lng,
            String? locationLabel,
          }) async {
            return InstructionPackResult(
              deliveryInstructions: buildDeliveryInstructionsStub(
                presets,
                referencePhotoIncluded: hasReferencePhoto,
                verbalHandoverNotes: verbalHandoverNotes,
                lat: lat,
                lng: lng,
                locationLabel: locationLabel,
              ),
              packId: 'test-pack',
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('field_help_capture_location')), findsOneWidget);
    await tester.tap(find.byKey(const Key('field_help_capture_location')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('handover_location_lat')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('handover_location_label')),
      'North gate',
    );
    await tester.pump();

    expect(find.byKey(const Key('field_help_generate_ai')), findsOneWidget);
    await tester.tap(find.byKey(const Key('field_help_generate_ai')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('field_help_instruction_body')), findsOneWidget);
    expect(find.textContaining('consent'), findsWidgets);

    final openFinder = find.byKey(const Key('field_help_open_vendor_0'));
    expect(openFinder, findsOneWidget);
    expect(
      tester.widget<FilledButton>(openFinder).onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('field_help_copy_instructions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      tester.widget<FilledButton>(openFinder).onPressed,
      isNotNull,
    );
    expect(
      find.text('Copy instructions to clipboard and register order intent'),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
  });
}
