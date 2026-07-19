import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_x.dart';

/// ─────────────────────────────────────────────
/// 🏷️  AppChip
///
/// Compact, selectable pill used for tags, collection selectors and filters.
/// Animates smoothly between selected / unselected states.
/// ─────────────────────────────────────────────
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.tonal = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  /// When true (and not selected), uses a soft brand tint background —
  /// good for read-only tags.
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final bg = selected
        ? c.primarySurface
        : tonal
            ? c.primarySurface.withValues(alpha: 0.55)
            : c.surfaceVariant;

    final fg = selected
        ? c.primary
        : tonal
            ? c.primary
            : c.textSecondary;

    final borderColor = selected ? c.primary : Colors.transparent;

    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: AppSpacing.xs + 2),
            ],
            Text(
              label,
              style: context.text.labelMedium?.copyWith(
                color: fg,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiny read-only tag pill for dense contexts like cards.
class TagPill extends StatelessWidget {
  const TagPill({super.key, required this.label, this.faded = false});

  final String label;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: faded ? c.surfaceVariant : c.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.1,
          color: faded ? c.textTertiary : c.primary,
        ),
      ),
    );
  }
}
