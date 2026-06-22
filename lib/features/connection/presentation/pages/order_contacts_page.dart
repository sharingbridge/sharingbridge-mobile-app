import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../connection_copy.dart';
import '../../../../initiation_labels.dart';
import '../../../../presentation/donor_app_bar.dart';
import '../../../donor_setup/data/donor_seeker_api_errors.dart';
import '../../data/http_connection_client.dart';
import '../../domain/models/order_connection.dart';

class OrderContactsPage extends StatefulWidget {
  const OrderContactsPage({
    super.key,
    this.initialOrderCode,
    this.client,
    this.apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    ),
  });

  final String? initialOrderCode;
  final HttpConnectionClient? client;
  final String apiBaseUrl;

  @override
  State<OrderContactsPage> createState() => _OrderContactsPageState();
}

class _OrderContactsPageState extends State<OrderContactsPage> {
  late final TextEditingController _codeController;
  late final HttpConnectionClient _client;

  bool _loading = false;
  String? _errorText;
  OrderConnection? _connection;

  @override
  void initState() {
    super.initState();
    _client = widget.client ??
        HttpConnectionClient(baseUrl: widget.apiBaseUrl);
    final initial = widget.initialOrderCode?.trim() ?? '';
    _codeController = TextEditingController(text: initial);
    if (initial.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _load(initial);
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load([String? code]) async {
    final trimmed = (code ?? _codeController.text).trim();
    if (trimmed.isEmpty) {
      setState(() {
        _errorText = 'Enter an order code (for example SB-7K2M-9F3).';
        _connection = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final connection = await _client.fetchOrderConnection(trimmed);
      if (!mounted) {
        return;
      }
      setState(() {
        _connection = connection;
        _codeController.text = connection.orderCode;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _connection = null;
        _errorText = formatDonorSeekerError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: DonorAppBar(
        title: 'Order contacts',
        showSignOut: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'After an eco kitchen commits, look up your order code to see login '
            'emails for off-platform payment and delivery.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('order_contacts_code_field'),
            controller: _codeController,
            enabled: !_loading,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Order code',
              hintText: 'SB-7K2M-9F3',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _load(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('order_contacts_lookup'),
            onPressed: _loading ? null : () => _load(),
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(_loading ? 'Loading…' : 'View contacts'),
          ),
          if (_errorText != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              _errorText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (_connection != null) ...<Widget>[
            const SizedBox(height: 24),
            _ConnectionDetail(connection: _connection!),
          ],
          const SizedBox(height: 24),
          Text(
            ConnectionCopy.safety,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionDetail extends StatelessWidget {
  const _ConnectionDetail({required this.connection});

  final OrderConnection connection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final demand = connection.demand;
    final headline = connection.menuLabel.trim().isNotEmpty
        ? connection.menuLabel
        : demand?.needDescription ?? connection.orderCode;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  connection.orderCode,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              _StatusChip(
                label: connection.contactsReady
                    ? 'Contacts ready'
                    : 'Waiting for kitchen',
                ready: connection.contactsReady,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            initiationApiRouteLabel(connection.initiationRoute),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(headline, style: theme.textTheme.titleLarge),
          if (connection.mealUnits != null || connection.priceInr != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                <String>[
                  if (connection.mealUnits != null)
                    '${connection.mealUnits} meal unit'
                    '${connection.mealUnits == 1 ? '' : 's'}',
                  if (connection.priceInr != null)
                    '₹${connection.priceInr}',
                ].join(' · '),
              ),
            ),
          if (demand?.locationLabel.trim().isNotEmpty == true)
            _MetaRow(label: 'Area', value: demand!.locationLabel),
          if (demand?.recordedAt.trim().isNotEmpty == true)
            _MetaRow(
              label: 'Recorded',
              value: _formatWhen(demand!.recordedAt),
            ),
          if (demand?.verbalNotes.trim().isNotEmpty == true)
            _MetaRow(label: 'Notes', value: demand!.verbalNotes),
          const SizedBox(height: 16),
          if (connection.contactsReady) ...<Widget>[
            Text('Contact emails', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (connection.kitchen?.displayName.trim().isNotEmpty == true)
              _MetaRow(
                label: 'Eco kitchen',
                value: connection.kitchen!.displayName,
              ),
            if (connection.kitchenLoginEmail?.trim().isNotEmpty == true)
              _EmailRow(
                label: 'Kitchen login email',
                email: connection.kitchenLoginEmail!,
              ),
            if (connection.initiatorEmail?.trim().isNotEmpty == true)
              _EmailRow(
                label: 'Initiator login email',
                email: connection.initiatorEmail!,
              ),
            if (connection.pledgers.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text('Pledgers', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final pledger in connection.pledgers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${pledger.loginEmail ?? '—'} · ${pledger.mealUnits} unit'
                    '${pledger.mealUnits == 1 ? '' : 's'}',
                  ),
                ),
            ],
          ] else
            const Text(
              'No eco kitchen has committed to this order yet. Contact emails '
              'appear here once a kitchen commitment is recorded.',
            ),
          ],
        ),
      ),
    );
  }

  static String _formatWhen(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw.isEmpty ? '—' : raw;
    }
    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.ready});

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ready ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _EmailRow extends StatelessWidget {
  const _EmailRow({required this.label, required this.email});

  final String label;
  final String email;

  Future<void> _openMail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: email);
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _openMail(context),
              child: Text(
                email,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
