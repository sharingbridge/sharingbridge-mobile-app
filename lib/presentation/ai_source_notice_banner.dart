import 'package:flutter/material.dart';

import '../features/donor_setup/domain/models/ai_content_source.dart';

/// Amber banner when API content is mock/deterministic/fallback (not live AI).
class AiSourceNoticeBanner extends StatelessWidget {
  const AiSourceNoticeBanner({
    super.key,
    required this.source,
  });

  final AiContentSource source;

  @override
  Widget build(BuildContext context) {
    final message = source.userNotice;
    if (message == null) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colors.tertiaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                Icons.info_outline,
                size: 20,
                color: colors.onTertiaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onTertiaryContainer,
                        height: 1.35,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
