import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../saved_posts/models/saved_post_model.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onDelete,
    required this.onDismiss,
    required this.onTap,
  });

  final SavedPost    post;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final borderColor  = isDark ? AppColors.borderDark  : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final mutedColor   = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color:        surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: borderColor, width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _Thumbnail(image: post.image, mutedColor: mutedColor),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      post.domain ?? post.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    const SizedBox(height: 10),

                    if (post.tags != null && post.tags!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _TagRow(tags: post.tags!, isDark: isDark),
                    ],

                  ],
                ),
              ),

              const SizedBox(width: 4),

              _Actions(
                isDismissed: post.isDismissed,
                onDelete:    onDelete,
                onDismiss:   onDismiss,
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags, required this.isDark});

  final List<String> tags;
  final bool         isDark;

  @override
  Widget build(BuildContext context) {
    final visible = tags.take(3).toList();
    final overflow = tags.length - visible.length;

    return Wrap(
      spacing:   5,
      runSpacing: 4,
      children: [
        ...visible.map((tag) => _Tag(label: tag, isDark: isDark)),
        if (overflow > 0)
          _Tag(label: '+$overflow', isDark: isDark, faded: true),
      ],
    );
  }
}


class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.isDark,
    this.faded = false,
  });

  final String label;
  final bool   isDark;
  final bool   faded;

  @override
  Widget build(BuildContext context) {
    final bg = faded
        ? (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant)
        : AppColors.primaryMuted;
    final fg = faded
        ? AppColors.textTertiary
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w400,
          color:      fg,
          height:     1,
        ),
      ),
    );
  }
}


class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.image, required this.mutedColor});

  final String? image;
  final Color   mutedColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: image != null
          ? Image.network(
        image!,
        width:  62,
        height: 62,
        fit:    BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(mutedColor),
      )
          : _placeholder(mutedColor),
    );
  }

  Widget _placeholder(Color color) {
    return Container(
      width:  62,
      height: 62,
      color:  color,
      child: Icon(
        Icons.link_rounded,
        size:  22,
        color: AppColors.textTertiary,
      ),
    );
  }
}



class _Actions extends StatelessWidget {
  const _Actions({
    required this.isDismissed,
    required this.onDelete,
    required this.onDismiss,
  });

  final bool         isDismissed;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon:    Icons.delete_outline_rounded,
          color:   AppColors.textTertiary,
          onTap:   onDelete,
        ),
        const SizedBox(height: 2),
        _ActionButton(
          icon:  isDismissed
              ? Icons.notifications_off_outlined
              : Icons.notifications_outlined,
          color: isDismissed
              ? AppColors.error
              : AppColors.primary,
          onTap: onDismiss,
        ),
      ],
    );
  }
}


class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:     onTap,
      behavior:  HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}