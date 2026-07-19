import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_x.dart';
import 'motion.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }
enum AppButtonSize { normal, large }

/// ─────────────────────────────────────────────
/// 🔘  AppButton
///
/// One button for the whole app. Variants for primary / secondary / ghost /
/// danger, a built-in loading spinner, optional leading icon, full-width
/// mode and a press-scale animation. Replaces the empty primary_button.dart.
/// ─────────────────────────────────────────────
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.normal,
    this.expand = true,
    this.loading = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = AppButtonSize.normal,
    this.expand = true,
    this.loading = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = AppButtonSize.normal,
    this.expand = true,
    this.loading = false,
  }) : variant = AppButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final enabled = onPressed != null && !loading;
    final height = size == AppButtonSize.large ? 54.0 : 48.0;

    late final Color bg;
    late final Color fg;
    late final Border? border;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = c.primary;
        fg = c.onPrimary;
        border = null;
      case AppButtonVariant.danger:
        bg = c.error;
        fg = Colors.white;
        border = null;
      case AppButtonVariant.secondary:
        bg = c.surface;
        fg = c.textPrimary;
        border = Border.all(color: c.border, width: 1);
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = c.primary;
        border = null;
    }

    final content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(fg),
            ),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 19, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge?.copyWith(
                    color: fg,
                    fontSize: size == AppButtonSize.large ? 16 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );

    return PressableScale(
      onTap: enabled ? () {
        HapticFeedback.lightImpact();
        onPressed!();
      } : null,
      pressedScale: 0.96,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.5,
        duration: AppMotion.fast,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: expand ? AppSpacing.xl : AppSpacing.xxl,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: border,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}
