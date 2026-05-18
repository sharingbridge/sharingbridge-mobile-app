import 'package:flutter/material.dart';

import 'features/auth/presentation/auth_gate.dart';

void main() {
  runApp(const SharingBridgeApp());
}

class SharingBridgeApp extends StatelessWidget {
  const SharingBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: AuthGate());
  }
}
