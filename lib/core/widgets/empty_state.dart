import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_x.dart';
import 'app_button.dart';

/// ─────────────────────────────────────────────
/// 🌱  EmptyState
///
/// Friendly, reusable "nothing here yet" panel with a gently floating icon
/// and an optional call-to-action. Used on Home, Collections, Analytics…
/// ─────────────────────────────────────────────
class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_controller.value);
                return Transform.translate(
                  offset: Offset(0, -6 * t),
                  child: child,
                );
              },
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: c.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 38, color: c.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
            if (widget.message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.message!,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium,
              ),
            ],
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: widget.actionLabel!,
                icon: Icons.add_rounded,
                expand: false,
                onPressed: widget.onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
