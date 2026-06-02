import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

/// Thumbnail for a local pick or Cloudinary URL, with optional full-size link.
class ReferencePhotoPreview extends StatelessWidget {
  const ReferencePhotoPreview({
    super.key,
    this.localFile,
    this.thumbnailUrl,
    this.viewUrl,
    this.caption,
    this.onRemove,
  });

  final XFile? localFile;
  final String? thumbnailUrl;
  final String? viewUrl;
  final String? caption;
  final VoidCallback? onRemove;

  String? get _displayUrl {
    final thumb = thumbnailUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) {
      return thumb;
    }
    final view = viewUrl?.trim();
    if (view != null && view.isNotEmpty) {
      return view;
    }
    return null;
  }

  Future<void> _openFullImage() async {
    final target = viewUrl?.trim().isNotEmpty == true
        ? viewUrl!.trim()
        : _displayUrl;
    if (target == null) {
      return;
    }
    final uri = Uri.tryParse(target);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasLocal = localFile != null;
    final networkUrl = _displayUrl;

    if (!hasLocal && networkUrl == null) {
      return const SizedBox.shrink();
    }

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (caption != null && caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  caption!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: _buildImage(context),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                if (viewUrl != null && viewUrl!.trim().isNotEmpty)
                  TextButton.icon(
                    onPressed: _openFullImage,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('View full image'),
                  ),
                const Spacer(),
                if (onRemove != null)
                  TextButton(
                    onPressed: onRemove,
                    child: const Text('Remove'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final file = localFile;
    if (file != null) {
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorPlaceholder(context),
      );
    }

    final url = _displayUrl!;
    return Image.network(
      url,
      fit: BoxFit.cover,
      frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSyncLoaded) {
        if (frame == null) {
          return _loadingPlaceholder(context);
        }
        return child;
      },
      errorBuilder: (_, __, ___) => _errorPlaceholder(context),
    );
  }

  Widget _loadingPlaceholder(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.photo_outlined, size: 40),
      ),
    );
  }

  Widget _errorPlaceholder(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 40),
      ),
    );
  }
}
