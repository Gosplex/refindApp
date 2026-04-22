import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
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
    final isPro = InAppPurchaseService().isPro;

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: StreamBuilder<AnalyticsModel>(
        stream: controller.getAnalyticsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AnalyticsShimmer();
          }

          if (!snapshot.hasData) {
            return const _EmptyState();
          }

          final data = snapshot.data!;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ───────── HERO CARD (Revisit Rate) ─────────
                _HeroCard(revisitRate: data.revisitRate),

                const SizedBox(height: 20),

                /// ───────── QUICK STATS ─────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.bookmark_border_rounded,
                        title: "Backlog",
                        value: data.backlogCount.toString(),
                        subtitle: "Unopened links",
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.local_fire_department_rounded,
                        title: "Streak",
                        value: "${data.currentStreak}",
                        subtitle: "Days active",
                        isDark: isDark,
                        iconColor: AppColors.warning,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                AnalyticsLockWrapper(
                  isPro: isPro,
                  child: Column(
                    children: [
                      /// ───────── WEEKLY ACTIVITY ─────────
                      const _SectionHeader(title: "Weekly Activity"),
                      const SizedBox(height: 12),

                      _WeeklyChart(
                        saved: data.weeklySaved,
                        revisited: data.weeklyRevisited,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 12),

                      _ImprovementCard(
                        improvement: data.weeklyImprovement,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 24),

                      /// ───────── REMINDERS ─────────
                      // const _SectionHeader(title: "Reminders"),
                      // const SizedBox(height: 12),
                      //
                      // _ReminderEffectivenessCard(
                      //   total: data.totalReminders,
                      //   worked: data.revisitedAfterReminder,
                      //   effectiveness: data.reminderEffectiveness,
                      //   isDark: isDark,
                      // ),
                      const SizedBox(height: 24),

                      /// ───────── TIME INSIGHTS ─────────
                      const _SectionHeader(title: "Time Insights"),
                      const SizedBox(height: 12),

                      _TimeCard(
                        avgDays: data.avgTimeToRevisitDays,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 24),

                      /// ───────── COLLECTIONS ─────────
                      if (data.topCollection != null ||
                          data.leastUsedCollection != null) ...[
                        const _SectionHeader(title: "Collections"),
                        const SizedBox(height: 12),

                        if (data.topCollection != null)
                          _InfoCard(
                            icon: Icons.folder_rounded,
                            label: "Most used",
                            value: data.topCollection!,
                            isDark: isDark,
                          ),

                        if (data.topCollection != null &&
                            data.leastUsedCollection != null)
                          const SizedBox(height: 10),

                        if (data.leastUsedCollection != null)
                          _InfoCard(
                            icon: Icons.folder_outlined,
                            label: "Least used",
                            value: data.leastUsedCollection!,
                            isDark: isDark,
                            isSecondary: true,
                          ),

                        const SizedBox(height: 24),
                      ],

                      /// ───────── SOURCES ─────────
                      if (data.topSavedSource != null ||
                          data.topRevisitedSource != null) ...[
                        const _SectionHeader(title: "Sources"),
                        const SizedBox(height: 12),

                        if (data.topSavedSource != null)
                          _InfoCard(
                            icon: Icons.link_rounded,
                            label: "Top saved from",
                            value: data.topSavedSource!,
                            isDark: isDark,
                          ),

                        if (data.topSavedSource != null &&
                            data.topRevisitedSource != null)
                          const SizedBox(height: 10),

                        if (data.topRevisitedSource != null)
                          _InfoCard(
                            icon: Icons.open_in_new_rounded,
                            label: "Most revisited",
                            value: data.topRevisitedSource!,
                            isDark: isDark,
                          ),

                        const SizedBox(height: 24),
                      ],

                      /// ───────── TOP LINKS ─────────
                      if (data.topLinks.isNotEmpty) ...[
                        const _SectionHeader(title: "Top Links"),
                        const SizedBox(height: 12),

                        ...data.topLinks.asMap().entries.map((entry) {
                          final index = entry.key;
                          final link = entry.value;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TopLinkCard(
                              link: link,
                              rank: index + 1,
                              isDark: isDark,
                            ),
                          );
                        }),
                      ],
                    ],
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

/// ─────────────────────────────────────────────
/// HERO CARD
/// ─────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final double revisitRate;

  const _HeroCard({required this.revisitRate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Revisit Rate",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "${revisitRate.toStringAsFixed(1)}%",
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "How often you actually return to saved links",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// STAT CARD
/// ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final bool isDark;
  final Color? iconColor;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.isDark,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: iconColor ?? AppColors.primary),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// WEEKLY CHART
/// ─────────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final int saved;
  final int revisited;
  final bool isDark;

  const _WeeklyChart({
    required this.saved,
    required this.revisited,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    final maxValue = (saved > revisited ? saved : revisited).toDouble();
    final normalizedMax = maxValue == 0 ? 10.0 : maxValue * 1.2;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ChartLegend(
                color: AppColors.primary,
                label: "Saved",
                value: saved.toString(),
              ),
              _ChartLegend(
                color: AppColors.primaryLight,
                label: "Revisited",
                value: revisited.toString(),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                        final labels = ['Saved', 'Revisited'];
                        if (value.toInt() >= 0 &&
                            value.toInt() < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[value.toInt()],
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: normalizedMax / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: border, strokeWidth: 0.8);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: saved.toDouble(),
                        color: AppColors.primary,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: revisited.toDouble(),
                        color: AppColors.primaryLight,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
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
  final Color color;
  final String label;
  final String value;

  const _ChartLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(width: 4),
        Text("($value)", style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// ─────────────────────────────────────────────
/// IMPROVEMENT CARD
/// ─────────────────────────────────────────────
class _ImprovementCard extends StatelessWidget {
  final double improvement;
  final bool isDark;

  const _ImprovementCard({required this.improvement, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    final isPositive = improvement >= 0;
    final color = isPositive ? AppColors.success : AppColors.error;
    final icon = isPositive
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "vs last week",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  "${isPositive ? '+' : ''}${improvement.toStringAsFixed(1)}%",
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// REMINDER EFFECTIVENESS CARD
/// ─────────────────────────────────────────────
class _ReminderEffectivenessCard extends StatelessWidget {
  final int total;
  final int worked;
  final double effectiveness;
  final bool isDark;

  const _ReminderEffectivenessCard({
    required this.total,
    required this.worked,
    required this.effectiveness,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ReminderStat(
                icon: Icons.notifications_outlined,
                label: "Sent",
                value: total.toString(),
              ),
              Container(width: 1, height: 40, color: border),
              _ReminderStat(
                icon: Icons.check_circle_outline,
                label: "Worked",
                value: worked.toString(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                sections: [
                  PieChartSectionData(
                    value: worked.toDouble(),
                    color: AppColors.success,
                    radius: 25,
                    title: '',
                  ),
                  PieChartSectionData(
                    value: (total - worked).toDouble(),
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant,
                    radius: 25,
                    title: '',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "${effectiveness.toStringAsFixed(0)}% effective",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

class _ReminderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReminderStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// ─────────────────────────────────────────────
/// TIME CARD
/// ─────────────────────────────────────────────
class _TimeCard extends StatelessWidget {
  final double avgDays;
  final bool isDark;

  const _TimeCard({required this.avgDays, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    String speed;
    Color speedColor;

    if (avgDays < 1) {
      speed = "Lightning fast";
      speedColor = AppColors.success;
    } else if (avgDays < 3) {
      speed = "Quick";
      speedColor = AppColors.primary;
    } else if (avgDays < 7) {
      speed = "Moderate";
      speedColor = AppColors.warning;
    } else {
      speed = "Slow";
      speedColor = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Avg time to revisit",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  "${avgDays.toStringAsFixed(1)} days",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: speedColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        speed,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: speedColor),
                      ),
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

/// ─────────────────────────────────────────────
/// INFO CARD
/// ─────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool isSecondary;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSecondary ? AppColors.textTertiary : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall,
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

/// ─────────────────────────────────────────────
/// TOP LINK CARD
/// ─────────────────────────────────────────────
class _TopLinkCard extends StatelessWidget {
  final SavedPost link;
  final int rank;
  final bool isDark;

  const _TopLinkCard({
    required this.link,
    required this.rank,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else {
      rankColor = const Color(0xFFCD7F32); // Bronze
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "$rank",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: rankColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  link.domain ?? link.url,
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${link.visitCount} visit${link.visitCount != 1 ? 's' : ''}",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
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

/// ─────────────────────────────────────────────
/// SECTION HEADER
/// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

/// ─────────────────────────────────────────────
/// EMPTY STATE
/// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 52,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No analytics yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Save and revisit links to see insights',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class AnalyticsShimmer extends StatefulWidget {
  const AnalyticsShimmer({super.key});

  @override
  State<AnalyticsShimmer> createState() => _AnalyticsShimmerState();
}

class _AnalyticsShimmerState extends State<AnalyticsShimmer>
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

  Widget _box({required Color color, double height = 80, double radius = 14}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final base = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariant;

    final highlight = isDark ? AppColors.borderDark : AppColors.border;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer = Color.lerp(base, highlight, _anim.value)!;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HERO
              _box(color: shimmer, height: 140, radius: 18),

              const SizedBox(height: 20),

              /// BACKLOG + STREAK
              Row(
                children: [
                  Expanded(child: _box(color: shimmer, height: 110)),
                  const SizedBox(width: 10),
                  Expanded(child: _box(color: shimmer, height: 110)),
                ],
              ),

              const SizedBox(height: 24),

              /// WEEKLY CHART
              _box(color: shimmer, height: 220),

              const SizedBox(height: 12),

              /// IMPROVEMENT
              _box(color: shimmer, height: 70),

              const SizedBox(height: 24),

              /// TIME CARD
              _box(color: shimmer, height: 110),

              const SizedBox(height: 24),

              /// COLLECTIONS
              _box(color: shimmer, height: 70),
              const SizedBox(height: 10),
              _box(color: shimmer, height: 70),

              const SizedBox(height: 24),

              /// SOURCES
              _box(color: shimmer, height: 70),
              const SizedBox(height: 10),
              _box(color: shimmer, height: 70),

              const SizedBox(height: 24),

              /// TOP LINKS
              _box(color: shimmer, height: 80),
              const SizedBox(height: 10),
              _box(color: shimmer, height: 80),
              const SizedBox(height: 10),
              _box(color: shimmer, height: 80),
            ],
          ),
        );
      },
    );
  }
}
