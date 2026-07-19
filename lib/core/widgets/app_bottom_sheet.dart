import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_x.dart';

/// ─────────────────────────────────────────────
/// 📄  App bottom sheets
///
/// [showAppSheet] presents a consistent, scroll-safe modal sheet with a
/// drag handle, optional title and keyboard-aware padding. Wrap your body
/// once here instead of re-building the handle + container everywhere.
/// ─────────────────────────────────────────────
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isScrollControlled = true,
  bool useRootNavigator = true,
}) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AppSheet(title: title, child: builder(ctx)),
  );
}

class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          if (title != null) ...[
            Text(title!, style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.lg),
          ],
          Flexible(child: child),
        ],
      ),
    );
  }
}
