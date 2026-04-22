import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../subscription/subscription_screen.dart';

class AnalyticsLockWrapper extends StatelessWidget {
  final bool isPro;
  final Widget child;

  const AnalyticsLockWrapper({
    super.key,
    required this.isPro,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isPro) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        child,

        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                /// 🔥 REAL BLUR LAYER
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 14,
                    sigmaY: 14,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.15),
                  ),
                ),

                /// 🔒 CONTENT
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// ICON
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.insights_rounded,
                            size: 22,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// HEADLINE
                        Text(
                          "See what's actually working",
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 6),

                        /// DESCRIPTION
                        Text(
                          "You're saving links… but are you actually using them?\nUnlock deeper insights into your habits.",
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 18),

                        /// CTA BUTTON
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const SubscriptionScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Unlock Insights",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
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