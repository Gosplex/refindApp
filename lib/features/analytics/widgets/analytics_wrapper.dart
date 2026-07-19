import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/widgets/widgets.dart';
import '../../subscription/subscription_screen.dart';

class AnalyticsLockWrapper extends StatelessWidget {
  final bool isPro;
  final Widget child;

  const AnalyticsLockWrapper({
    super.key,
    required this.isPro,
    required this.child,
  });

  void _openPaywall(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isPro) return child;

    final c = context.c;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.15),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openPaywall(context),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: c.primarySurface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(Icons.insights_rounded,
                              size: 24, color: AppColors.primary),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          "See what's actually working",
                          style: context.text.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        Text(
                          "You're saving links… but are you using them?\nUnlock deeper insight into your habits.",
                          style: context.text.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: 'Unlock insights',
                          icon: Icons.auto_awesome_rounded,
                          expand: false,
                          onPressed: () => _openPaywall(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
