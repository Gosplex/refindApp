import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_x.dart';
import 'app_button.dart';

/// ─────────────────────────────────────────────
/// ⚠️  Confirm dialog
///
/// One themed confirm/cancel dialog, with a [destructive] mode that uses the
/// semantic error color instead of the old hardcoded `Colors.red`.
/// Returns true if the user confirmed.
/// ─────────────────────────────────────────────
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final c = ctx.c;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) ...[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: destructive ? c.errorSurface : c.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: destructive ? c.error : c.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(title, style: ctx.text.titleMedium),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(message, style: ctx.text.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: cancelLabel,
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: confirmLabel,
                      variant: destructive
                          ? AppButtonVariant.danger
                          : AppButtonVariant.primary,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
