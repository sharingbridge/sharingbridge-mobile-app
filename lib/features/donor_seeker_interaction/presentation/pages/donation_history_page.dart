import 'package:flutter/material.dart';

import '../../../auth/data/auth_session_holder.dart';
import '../../../donor_setup/data/auth_context.dart';
import '../../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../../donor_setup/data/http_donor_setup_api_client.dart';
import '../../data/http_order_intent_client.dart';
import '../../domain/models/donation_intent.dart';
import 'donation_intent_detail_page.dart';

class DonationHistoryPage extends StatefulWidget {
  const DonationHistoryPage({
    super.key,
    this.authContext,
    this.listDonationIntents,
  });

  final AuthContext? authContext;

  /// Injected for tests; defaults to [HttpOrderIntentClient.listDonationIntents].
  final Future<List<DonationIntent>> Function()? listDonationIntents;

  @override
  State<DonationHistoryPage> createState() => _DonationHistoryPageState();
}

class _DonationHistoryPageState extends State<DonationHistoryPage> {
  static const String _defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  AuthContext get _session =>
      widget.authContext ?? AuthSessionHolder.resolve();
  late final Future<List<DonationIntent>> Function() _listDonationIntents;
  List<DonationIntent> _intents = <DonationIntent>[];
  bool _loading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _listDonationIntents = widget.listDonationIntents ??
        () {
          return HttpOrderIntentClient(
            baseUrl: _defaultApiBaseUrl,
            authContext: widget.authContext,
            api: HttpDonorSetupApiClient(
              baseUrl: _defaultApiBaseUrl,
              authContext: widget.authContext,
            ),
          ).listDonationIntents();
        };
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final intents = await _listDonationIntents();
      if (!mounted) {
        return;
      }
      setState(() {
        _intents = intents;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = _friendlyError(error);
        _intents = <DonationIntent>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is DonorSetupTimeoutException) {
      return 'The server took too long to respond. Pull to retry.';
    }
    if (error is DonorSetupNetworkException) {
      return 'Network unavailable. Pull to retry.';
    }
    if (error is DonorSetupServerException) {
      return 'Server error (HTTP ${error.statusCode}). Pull to retry.';
    }
    if (error is DonorSetupBadRequestException) {
      return error.message;
    }
    if (error is DonorSetupResponseException) {
      return 'Unexpected server response.';
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order initiation history')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _intents.isEmpty && _errorText == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorText != null && _intents.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(_errorText!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              key: const Key('donation_history_retry'),
              onPressed: _refresh,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (_intents.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(
            'No order initiations yet. Register one from Help a seeker when you copy delivery instructions.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _intents.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final intent = _intents[index];
        final restaurant = intent.primaryRestaurantName;
        final subtitleParts = <String>[
          intent.statusLabel,
          if (restaurant != null) restaurant,
          DonationIntentDetailPage.formatWhen(intent.sortTime),
        ];
        return ListTile(
          key: Key('donation_history_row_$index'),
          title: Text(intent.orderIntentId),
          subtitle: Text(subtitleParts.join(' · ')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) =>
                    DonationIntentDetailPage(intent: intent),
              ),
            );
          },
        );
      },
    );
  }
}
