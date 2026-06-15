import 'package:flutter/material.dart';

import 'features/auth/presentation/auth_gate.dart';
import 'features/push/push_registration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushRegistration.bootstrap();
  runApp(const SharingBridgeApp());
}

class SharingBridgeApp extends StatelessWidget {
  const SharingBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: AuthGate());
  }
}
