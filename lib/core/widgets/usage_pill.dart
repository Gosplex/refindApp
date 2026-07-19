import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_x.dart';
import 'motion.dart';

/// ─────────────────────────────────────────────
/// ⚡  UsagePill
///
/// Compact "used / limit" indicator that turns amber near the limit and red
/// at it. Shared by Home (saves) and Collections. Tap for details / upsell.
/// ─────────────────────────────────────────────
class UsagePill extends StatelessWidget {
  const UsagePill({
    super.key,
    required this.total,
    required this.limit,
    required this.onTap,
    this.icon = Icons.bolt_rounded,
  });

  final int total;
  final int limit;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isNearLimit = total >= (limit * 0.8).floor();
    final isAtLimit = total >= limit;

    final bg = isAtLimit
        ? c.errorSurface
        : isNearLimit
            ? c.warningSurface
            : c.primarySurface;
    final fg = isAtLimit
        ? c.error
        : isNearLimit
            ? c.warning
            : c.primary;

    return PressableScale(
      onTap: onTap,
      pressedScale: 0.9,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 3),
            Text(
              '$total',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
                height: 1,
              ),
            ),
            Text(
              '/${limit >= 999999 ? '∞' : limit}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: fg.withValues(alpha: 0.6),
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
