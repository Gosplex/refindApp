import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/model/app_user_model.dart';
import '../../../core/theme/colors.dart';
import '../users/admin_user_controller.dart';

class AdminDashboardContent extends StatelessWidget {
  const AdminDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdminUserController();

    return StreamBuilder<List<AppUser>>(
      stream: controller.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(child: Text('No data'));
        }

        /// 🔥 METRICS
        final totalUsers = users.length;
        final premiumUsers = users.where((u) => u.isPro).length;
        final freeUsers = totalUsers - premiumUsers;
        final anonymousUsers = users.where((u) => u.isAnonymous).length;

        final activeUsers = users.where((u) {
          if (u.lastSeen == null) return false;
          final now = DateTime.now();
          return now.difference(u.lastSeen!).inDays < 1;
        }).length;

        final totalPosts = users.fold(0, (sum, u) => sum + u.totalPostsCreated);
        final totalCollections = users.fold(0, (sum, u) => sum + u.totalCollectionsCreated);

        final androidUsers = users.where((u) => u.deviceType == 'android').length;
        final iosUsers = users.where((u) => u.deviceType == 'ios').length;
        final webUsers = users.where((u) => u.deviceType == 'web').length;

        final conversionRate = (premiumUsers / totalUsers * 100).toStringAsFixed(1);
        final activeRate = (activeUsers / totalUsers * 100).toStringAsFixed(1);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Overview of your application metrics',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              /// 🔥 PRIMARY METRIC CARDS (Top Row)
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      context,
                      title: 'Total Users',
                      value: totalUsers.toString(),
                      subtitle: '$activeRate% active today',
                      icon: Icons.people_outline,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _metricCard(
                      context,
                      title: 'Premium Users',
                      value: premiumUsers.toString(),
                      subtitle: '$conversionRate% conversion',
                      icon: Icons.workspace_premium_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _metricCard(
                      context,
                      title: 'Active Users',
                      value: activeUsers.toString(),
                      subtitle: 'Last 24 hours',
                      icon: Icons.trending_up,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _metricCard(
                      context,
                      title: 'Total Posts',
                      value: totalPosts.toString(),
                      subtitle: '$totalCollections collections',
                      icon: Icons.article_outlined,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// 🔥 SECONDARY METRICS (Cards Grid)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _compactCard(context, 'Anonymous', anonymousUsers.toString(),
                      Icons.person_off_outlined),
                  _compactCard(context, 'Collections', totalCollections.toString(),
                      Icons.collections_bookmark_outlined),
                  _compactCard(context, 'Android', androidUsers.toString(), Icons.android),
                  _compactCard(context, 'iOS', iosUsers.toString(), Icons.apple),
                  _compactCard(context, 'Web', webUsers.toString(), Icons.language),
                ],
              ),

              const SizedBox(height: 32),

              /// 🔥 CHARTS SECTION
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// USER DISTRIBUTION PIE CHART
                  Expanded(
                    flex: 2,
                    child: _chartCard(
                      context,
                      'User Distribution',
                      'Breakdown by subscription plan',
                      SizedBox(
                        height: 280,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            sections: [
                              PieChartSectionData(
                                value: premiumUsers.toDouble(),
                                title: '$premiumUsers',
                                color: AppColors.primary,
                                radius: 80,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                badgeWidget: _badge('Premium'),
                                badgePositionPercentageOffset: 1.5,
                              ),
                              PieChartSectionData(
                                value: freeUsers.toDouble(),
                                title: '$freeUsers',
                                color: AppColors.surfaceVariant,
                                radius: 80,
                                titleStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                badgeWidget: _badge('Free'),
                                badgePositionPercentageOffset: 1.5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  /// DEVICE DISTRIBUTION
                  Expanded(
                    flex: 2,
                    child: _chartCard(
                      context,
                      'Device Distribution',
                      'Platform usage breakdown',
                      SizedBox(
                        height: 280,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            sections: [
                              PieChartSectionData(
                                value: androidUsers.toDouble(),
                                title: '$androidUsers',
                                color: const Color(0xFF3DDC84),
                                radius: 80,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                badgeWidget: _badge('Android'),
                                badgePositionPercentageOffset: 1.5,
                              ),
                              PieChartSectionData(
                                value: iosUsers.toDouble(),
                                title: '$iosUsers',
                                color: const Color(0xFF555555),
                                radius: 80,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                badgeWidget: _badge('iOS'),
                                badgePositionPercentageOffset: 1.5,
                              ),
                              PieChartSectionData(
                                value: webUsers.toDouble(),
                                title: '$webUsers',
                                color: AppColors.primaryLight,
                                radius: 80,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                badgeWidget: _badge('Web'),
                                badgePositionPercentageOffset: 1.5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              /// 🔥 ENGAGEMENT BAR CHART
              _chartCard(
                context,
                'Content Engagement',
                'Posts and collections created by users',
                SizedBox(
                  height: 280,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (totalPosts > totalCollections ? totalPosts : totalCollections)
                          .toDouble() *
                          1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              rod.toY.toInt().toString(),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const titles = ['Posts', 'Collections'];
                              if (value.toInt() >= 0 && value.toInt() < titles.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    titles[value.toInt()],
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                          ),
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
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.border.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: totalPosts.toDouble(),
                              color: AppColors.primary,
                              width: 60,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: totalCollections.toDouble(),
                              color: AppColors.primaryLight,
                              width: 60,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  /// PRIMARY METRIC CARD WITH ICON
  Widget _metricCard(
      BuildContext context, {
        required String title,
        required String value,
        required String subtitle,
        required IconData icon,
        required Color color,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// COMPACT METRIC CARD
  Widget _compactCard(
      BuildContext context, String title, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// CHART CARD CONTAINER
  Widget _chartCard(
      BuildContext context,
      String title,
      String subtitle,
      Widget chart,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          chart,
        ],
      ),
    );
  }

  /// BADGE FOR PIE CHART LABELS
  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D2D2D),
        ),
      ),
    );
  }
}