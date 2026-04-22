import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

class PinnedShimmer extends StatefulWidget {
  const PinnedShimmer();

  @override
  State<PinnedShimmer> createState() => _PinnedShimmerState();
}

class _PinnedShimmerState extends State<PinnedShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final base =
    isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;

    final highlight =
    isDark ? AppColors.borderDark : AppColors.border;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer = Color.lerp(base, highlight, _anim.value)!;

        return SizedBox(
          height: 90,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) {
              return Container(
                width: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(14),
                ),
              );
            },
          ),
        );
      },
    );
  }
}