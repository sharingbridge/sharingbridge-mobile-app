import 'package:flutter/material.dart';

import 'about_content.dart';
import 'donor_app_bar.dart';

/// Read-only about SharingBridge and the handoff flow.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DonorAppBar(title: 'About'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: const <Widget>[
          AboutContent(),
        ],
      ),
    );
  }
}
