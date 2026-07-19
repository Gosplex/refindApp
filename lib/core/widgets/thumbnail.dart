import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_x.dart';

/// ─────────────────────────────────────────────
/// 🖼️  Thumbnail
///
/// Network image with a graceful fallback icon and a soft fade-in once the
/// image decodes. Used by post cards, previews and detail headers.
/// ─────────────────────────────────────────────
class Thumbnail extends StatelessWidget {
  const Thumbnail({
    super.key,
    required this.image,
    this.size = 64,
    this.radius = AppRadius.md,
    this.fallbackIcon = Icons.link_rounded,
  });

  final String? image;
  final double size;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: (image == null || image!.isEmpty)
            ? _fallback(context)
            : Image.network(
                image!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(context),
                frameBuilder: (context, child, frame, wasSync) {
                  if (wasSync || frame != null) {
                    return AnimatedOpacity(
                      opacity: 1,
                      duration: AppMotion.medium,
                      child: child,
                    );
                  }
                  return _fallback(context, loading: true);
                },
              ),
      ),
    );
  }

  Widget _fallback(BuildContext context, {bool loading = false}) {
    final c = context.c;
    return Container(
      color: c.surfaceVariant,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        size: size * 0.34,
        color: c.textTertiary,
      ),
    );
  }
}
