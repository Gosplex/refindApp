import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/widgets/widgets.dart';
import '../../saved_posts/models/saved_post_model.dart';

/// A saved-link row. Used on Home and inside Collection details.
/// Public API is unchanged: [post], [onDelete], [onDismiss], [onTap].
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onDelete,
    required this.onDismiss,
    required this.onTap,
  });

  final SavedPost post;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final tags = post.tags ?? const [];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Thumbnail(image: post.image, size: 66, radius: AppRadius.md),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.public_rounded,
                          size: 12, color: c.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.domain ?? post.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _TagRow(tags: tags),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _Actions(
              isDismissed: post.isDismissed,
              onDelete: onDelete,
              onDismiss: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final visible = tags.take(3).toList();
    final overflow = tags.length - visible.length;

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        ...visible.map((t) => TagPill(label: t)),
        if (overflow > 0) TagPill(label: '+$overflow', faded: true),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isDismissed,
    required this.onDelete,
    required this.onDismiss,
  });

  final bool isDismissed;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconAction(
          icon: isDismissed
              ? Icons.notifications_off_rounded
              : Icons.notifications_active_rounded,
          color: isDismissed ? c.textTertiary : c.primary,
          background: isDismissed ? c.surfaceVariant : c.primarySurface,
          onTap: onDismiss,
        ),
        const SizedBox(height: AppSpacing.sm),
        _IconAction(
          icon: Icons.delete_outline_rounded,
          color: c.textTertiary,
          background: c.surfaceVariant,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      pressedScale: 0.88,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}
