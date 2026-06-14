import 'package:flutter/material.dart';

import '../../../../presentation/donor_app_bar.dart';

import '../../../auth/data/auth_session_holder.dart';
import '../../../donor_setup/data/auth_context.dart';
import '../../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../../donor_setup/data/http_donor_setup_api_client.dart';
import '../../data/http_order_intent_client.dart';
import '../../domain/models/donation_intent.dart';
import '../order_intent_grouping.dart';
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

  /// Current sign-in (re-reads holder; do not cache in initState).
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
      appBar: const DonorAppBar(title: 'Initiations'),
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
            'No initiations yet. Start one from Help a seeker or Start initiation.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final groups = groupDonationIntents(_intents);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: _buildGroupedRows(context, groups),
    );
  }

  List<Widget> _buildGroupedRows(
    BuildContext context,
    List<DonationIntentGroup> groups,
  ) {
    final children = <Widget>[];
    var rowIndex = 0;
    for (final DonationIntentGroup group in groups) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  group.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                '${group.intents.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
      for (final DonationIntent intent in group.intents) {
        if (rowIndex > 0) {
          children.add(const Divider(height: 1, indent: 16));
        }
        children.add(
          _IntentRow(
            key: Key('donation_history_row_$rowIndex'),
            intent: intent,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) =>
                      DonationIntentDetailPage(intent: intent),
                ),
              );
            },
          ),
        );
        rowIndex += 1;
      }
    }
    return children;
  }
}

class _IntentRow extends StatelessWidget {
  const _IntentRow({
    super.key,
    required this.intent,
    required this.onTap,
  });

  final DonationIntent intent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final restaurant = intent.primaryRestaurantName;
    final subtitleParts = <String>[
      intent.statusLabel,
      if (restaurant != null) restaurant,
      DonationIntentDetailPage.formatWhen(intent.sortTime),
    ];
    return ListTile(
      leading: intent.hasDisplayableReferencePhoto
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                intent.referencePhotoThumbnailUrl ??
                    intent.referencePhotoViewUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported_outlined),
              ),
            )
          : intent.hasReferencePhoto
              ? const Icon(Icons.photo_outlined)
              : null,
      title: Text(intent.orderIntentId),
      subtitle: Text(subtitleParts.join(' · ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
