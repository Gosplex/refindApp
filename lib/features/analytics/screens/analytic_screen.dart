import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/widgets/widgets.dart';
import '../../../services/in_app_purchase_service.dart';
import '../analytics_controller.dart';
import '../models/analytics_model.dart';
import '../../saved_posts/models/saved_post_model.dart';
import '../widgets/analytics_wrapper.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AnalyticsController();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.screen,
        title: Text('Analytics', style: context.text.titleLarge),
      ),
      body: StreamBuilder<AnalyticsModel>(
        stream: controller.getAnalyticsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AnalyticsShimmer();
          }
          if (!snapshot.hasData) {
            return const EmptyState(
              icon: Icons.insights_rounded,
              title: 'No analytics yet',
              message: 'Save and revisit links to unlock insights on your habits.',
            );
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(child: _HeroCard(revisitRate: data.revisitRate)),
                const SizedBox(height: AppSpacing.md),
                FadeSlideIn(
                  index: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.bookmark_border_rounded,
                          value: data.backlogCount,
                          label: 'Backlog',
                          subtitle: 'Unopened links',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_fire_department_rounded,
                          value: data.currentStreak,
                          label: 'Streak',
                          subtitle: 'Days active',
                          iconColor: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                FadeSlideIn(
                  index: 2,
                  child: StreamBuilder<bool>(
                    stream: InAppPurchaseService().proStatusStream,
                    initialData: InAppPurchaseService().isPro,
                    builder: (context, proSnap) => AnalyticsLockWrapper(
                      isPro: proSnap.data ?? false,
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                            title: 'Weekly activity',
                            padding: EdgeInsets.zero),
                        const SizedBox(height: AppSpacing.md),
                        _WeeklyChart(
                          saved: data.weeklySaved,
                          revisited: data.weeklyRevisited,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ImprovementCard(improvement: data.weeklyImprovement),
                        const SizedBox(height: AppSpacing.xxl),

                        const SectionHeader(
                            title: 'Time insights', padding: EdgeInsets.zero),
                        const SizedBox(height: AppSpacing.md),
                        _TimeCard(avgDays: data.avgTimeToRevisitDays),
                        const SizedBox(height: AppSpacing.xxl),

                        if (data.topCollection != null ||
                            data.leastUsedCollection != null) ...[
                          const SectionHeader(
                              title: 'Collections',
                              padding: EdgeInsets.zero),
                          const SizedBox(height: AppSpacing.md),
                          if (data.topCollection != null)
                            _InfoCard(
                              icon: Icons.folder_rounded,
                              label: 'Most used',
                              value: data.topCollection!,
                            ),
                          if (data.topCollection != null &&
                              data.leastUsedCollection != null)
                            const SizedBox(height: AppSpacing.sm),
                          if (data.leastUsedCollection != null)
                            _InfoCard(
                              icon: Icons.folder_outlined,
                              label: 'Least used',
                              value: data.leastUsedCollection!,
                              isSecondary: true,
                            ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],

                        if (data.topSavedSource != null ||
                            data.topRevisitedSource != null) ...[
                          const SectionHeader(
                              title: 'Sources', padding: EdgeInsets.zero),
                          const SizedBox(height: AppSpacing.md),
                          if (data.topSavedSource != null)
                            _InfoCard(
                              icon: Icons.link_rounded,
                              label: 'Top saved from',
                              value: data.topSavedSource!,
                            ),
                          if (data.topSavedSource != null &&
                              data.topRevisitedSource != null)
                            const SizedBox(height: AppSpacing.sm),
                          if (data.topRevisitedSource != null)
                            _InfoCard(
                              icon: Icons.open_in_new_rounded,
                              label: 'Most revisited',
                              value: data.topRevisitedSource!,
                            ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],

                        if (data.topLinks.isNotEmpty) ...[
                          const SectionHeader(
                              title: 'Top links', padding: EdgeInsets.zero),
                          const SizedBox(height: AppSpacing.md),
                          ...data.topLinks.asMap().entries.map((entry) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _TopLinkCard(
                                link: entry.value,
                                rank: entry.key + 1,
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Animated number that counts up from zero on first paint.
class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, required this.format, this.style});

  final double value;
  final String Function(double) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: AppMotion.slow,
      curve: AppMotion.standard,
      builder: (context, v, _) => Text(format(v), style: style),
    );
  }
}

/// ───────── Hero: revisit rate ─────────
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.revisitRate});

  final double revisitRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF5A8C69)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    size: 20, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Revisit rate',
                style: context.text.titleMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _CountUp(
            value: revisitRate,
            format: (v) => '${v.toStringAsFixed(1)}%',
            style: context.text.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'How often you actually return to saved links',
            style: context.text.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────── Quick stat ─────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.subtitle,
    this.iconColor,
  });

  final IconData icon;
  final int value;
  final String label;
  final String subtitle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = iconColor ?? c.primary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          _CountUp(
            value: value.toDouble(),
            format: (v) => v.round().toString(),
            style: context.text.headlineMedium,
          ),
          const SizedBox(height: 2),
          Text(label, style: context.text.titleSmall),
          Text(subtitle, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

/// ───────── Weekly bar chart ─────────
class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.saved, required this.revisited});

  final int saved;
  final int revisited;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final maxValue = (saved > revisited ? saved : revisited).toDouble();
    final normalizedMax = maxValue == 0 ? 10.0 : maxValue * 1.25;

    BarChartRodData rod(double y, Color color) => BarChartRodData(
          toY: y,
          width: 42,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [color.withValues(alpha: 0.75), color],
          ),
        );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ChartLegend(
                  color: c.primary, label: 'Saved', value: '$saved'),
              _ChartLegend(
                  color: c.primaryLight,
                  label: 'Revisited',
                  value: '$revisited'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: normalizedMax,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Saved', 'Revisited'];
                        if (value.toInt() >= 0 &&
                            value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(labels[value.toInt()],
                                style: context.text.labelSmall),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: normalizedMax / 4,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: c.border, strokeWidth: 0.8),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                      x: 0, barRods: [rod(saved.toDouble(), c.primary)]),
                  BarChartGroupData(
                      x: 1,
                      barRods: [rod(revisited.toDouble(), c.primaryLight)]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.xs - 2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: context.text.labelMedium),
        const SizedBox(width: AppSpacing.xs),
        Text('($value)', style: context.text.labelSmall),
      ],
    );
  }
}

/// ───────── Improvement vs last week ─────────
class _ImprovementCard extends StatelessWidget {
  const _ImprovementCard({required this.improvement});

  final double improvement;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isPositive = improvement >= 0;
    final color = isPositive ? c.success : c.error;

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              isPositive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('vs last week', style: context.text.labelSmall),
                const SizedBox(height: 2),
                Text(
                  '${isPositive ? '+' : ''}${improvement.toStringAsFixed(1)}%',
                  style: context.text.titleMedium?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────── Avg time to revisit ─────────
class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.avgDays});

  final double avgDays;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final String speed;
    final Color speedColor;
    if (avgDays < 1) {
      speed = 'Lightning fast';
      speedColor = c.success;
    } else if (avgDays < 3) {
      speed = 'Quick';
      speedColor = c.primary;
    } else if (avgDays < 7) {
      speed = 'Moderate';
      speedColor = c.warning;
    } else {
      speed = 'Slow';
      speedColor = c.error;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: c.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.schedule_rounded,
                size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Avg time to revisit',
                    style: context.text.labelMedium),
                const SizedBox(height: AppSpacing.xs + 2),
                Text('${avgDays.toStringAsFixed(1)} days',
                    style: context.text.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: speedColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(speed,
                      style: context.text.labelSmall
                          ?.copyWith(color: speedColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────── Generic info row ─────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isSecondary = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppCard(
      child: Row(
        children: [
          Icon(icon, size: 20, color: isSecondary ? c.textTertiary : c.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.labelSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────── Top link (ranked) ─────────
class _TopLinkCard extends StatelessWidget {
  const _TopLinkCard({required this.link, required this.rank});

  final SavedPost link;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final Color rankColor = switch (rank) {
      1 => const Color(0xFFE0B341),
      2 => const Color(0xFFB4B4B4),
      _ => const Color(0xFFC17F45),
    };

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text('$rank',
                  style: context.text.titleSmall?.copyWith(
                    color: rankColor,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(link.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall),
                const SizedBox(height: 4),
                Text(link.domain ?? link.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.visibility_rounded, size: 14, color: c.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${link.visitCount} visit${link.visitCount != 1 ? 's' : ''}',
                      style: context.text.labelSmall
                          ?.copyWith(color: c.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ───────── Loading skeleton ─────────
class AnalyticsShimmer extends StatelessWidget {
  const AnalyticsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    Widget box(double height, {double radius = AppRadius.lg}) =>
        SkeletonBox(height: height, radius: radius);

    return Shimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box(140, radius: AppRadius.xl),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: box(110)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: box(110)),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            box(230),
            const SizedBox(height: AppSpacing.md),
            box(72),
            const SizedBox(height: AppSpacing.xxl),
            box(96),
            const SizedBox(height: AppSpacing.xxl),
            box(72),
            const SizedBox(height: AppSpacing.sm),
            box(72),
          ],
        ),
      ),
    );
  }
}
