import 'package:flutter/material.dart';

import '../features/donor_seeker_interaction/presentation/pages/donor_seeker_interaction_page.dart';
import 'about_content.dart';
import 'donor_app_bar.dart';

/// Required read-through before entering Help a seeker.
class HandoffAboutGatePage extends StatefulWidget {
  const HandoffAboutGatePage({super.key});

  @override
  State<HandoffAboutGatePage> createState() => _HandoffAboutGatePageState();
}

class _HandoffAboutGatePageState extends State<HandoffAboutGatePage> {
  final ScrollController _scrollController = ScrollController();
  bool _scrolledToEnd = false;
  bool _acknowledged = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final atEnd = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 32;
    if (atEnd != _scrolledToEnd) {
      setState(() => _scrolledToEnd = atEnd);
    }
  }

  void _continueToHandoff() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const DonorSeekerInteractionPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _scrolledToEnd && _acknowledged;
    return Scaffold(
      appBar: const DonorAppBar(title: 'Before you help'),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              children: <Widget>[
                Text(
                  'Please read before helping a seeker',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const AboutContent(),
                if (!_scrolledToEnd)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Scroll to the end to continue.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          Material(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  CheckboxListTile(
                    key: const Key('handoff_gate_acknowledge'),
                    contentPadding: EdgeInsets.zero,
                    value: _acknowledged,
                    onChanged: _scrolledToEnd
                        ? (bool? value) {
                            setState(() => _acknowledged = value ?? false);
                          }
                        : null,
                    title: const Text(
                      'I understand consent, vendor paste steps, and my role.',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  FilledButton(
                    key: const Key('handoff_gate_continue'),
                    onPressed: canContinue ? _continueToHandoff : null,
                    child: const Text('Continue to Help a seeker'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
