import 'package:flutter/material.dart';

import '../../../../presentation/donor_app_bar.dart';
import '../../../auth/data/auth_session_holder.dart';
import '../../../donor_setup/data/auth_context.dart';
import '../../../donor_setup/data/donor_setup_api_exceptions.dart';
import '../../../donor_setup/data/http_donor_setup_api_client.dart';
import '../../data/http_order_intent_client.dart';
import '../../domain/models/donation_intent.dart';
import '../widgets/reference_photo_preview.dart';

class DonationIntentDetailPage extends StatefulWidget {
  const DonationIntentDetailPage({
    super.key,
    required this.intent,
    this.authContext,
    this.apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    ),
  });

  final DonationIntent intent;
  final AuthContext? authContext;
  final String apiBaseUrl;

  static String formatWhen(DateTime? value) {
    if (value == null) {
      return '—';
    }
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  @override
  State<DonationIntentDetailPage> createState() =>
      _DonationIntentDetailPageState();
}

class _DonationIntentDetailPageState extends State<DonationIntentDetailPage> {
  late DonationIntent _intent = widget.intent;
  bool _savingPayment = false;
  String? _errorText;

  AuthContext get _session =>
      widget.authContext ?? AuthSessionHolder.resolve();

  Future<void> _markPaymentDone() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mark payment done?'),
          content: const Text(
            'Confirm you placed and paid for this meal in the vendor app.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Mark payment done'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _savingPayment = true;
      _errorText = null;
    });
    try {
      final updated = await HttpOrderIntentClient(
        baseUrl: widget.apiBaseUrl,
        authContext: _session,
        api: HttpDonorSetupApiClient(
          baseUrl: widget.apiBaseUrl,
          authContext: _session,
        ),
      ).markPaymentDone(_intent.orderIntentId);
      if (!mounted) {
        return;
      }
      setState(() {
        _intent = updated;
        _savingPayment = false;
      });
      if (mounted) {
        Navigator.of(context).pop(updated);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _savingPayment = false;
        _errorText = error is DonorSetupBadRequestException
            ? error.message
            : 'Could not update payment: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intent = _intent;
    return Scaffold(
      appBar: const DonorAppBar(
        title: 'Initiation detail',
        showSignOut: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _DetailRow(label: 'Reference', value: intent.orderIntentId),
          _DetailRow(label: 'Instruction pack', value: intent.packId),
          _DetailRow(label: 'Status', value: intent.statusLabel),
          _DetailRow(label: 'Payment', value: intent.paymentStatusLabel),
          _DetailRow(label: 'Delivery', value: intent.deliveryStatus.replaceAll('_', ' ')),
          if (intent.canMarkPaymentDone) ...<Widget>[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _savingPayment ? null : _markPaymentDone,
              icon: _savingPayment
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payments_outlined),
              label: Text(
                _savingPayment ? 'Saving…' : 'Mark payment done',
              ),
            ),
          ],
          if (_errorText != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (intent.hasDisplayableReferencePhoto) ...<Widget>[
            const SizedBox(height: 8),
            ReferencePhotoPreview(
              thumbnailUrl: intent.referencePhotoThumbnailUrl,
              viewUrl: intent.referencePhotoViewUrl,
              caption: 'Reference photo',
            ),
          ] else
            _DetailRow(
              label: 'Reference photo',
              value: intent.hasReferencePhoto ? 'Yes (no preview URL)' : 'No',
            ),
          if (intent.referencePhotoArtifactId?.trim().isNotEmpty == true)
            _DetailRow(
              label: 'Photo artifact',
              value: intent.referencePhotoArtifactId!,
            ),
          _DetailRow(
            label: 'Registered',
            value: DonationIntentDetailPage.formatWhen(intent.createdAt),
          ),
          _DetailRow(
            label: 'Last updated',
            value: DonationIntentDetailPage.formatWhen(intent.updatedAt),
          ),
          if (intent.verbalHandoverNotes.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text('Handover notes', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(intent.verbalHandoverNotes),
              ),
            ),
          ],
          if (intent.presetsSnapshot.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              'Saved presets at registration (${intent.presetsSnapshot.length})',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...intent.presetsSnapshot.map((Map<String, dynamic> row) {
              final restaurant =
                  row['restaurant_name']?.toString().trim() ?? 'Vendor';
              final app = row['app_name']?.toString().trim();
              final subtitle = app != null && app.isNotEmpty ? app : null;
              return Card(
                child: ListTile(
                  title: Text(restaurant),
                  subtitle: subtitle != null ? Text(subtitle) : null,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 132,
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
