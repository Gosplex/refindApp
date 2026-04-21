import 'package:flutter/material.dart';
import '../../../core/model/app_user_model.dart';
import '../../../core/theme/colors.dart';

class AdminUserDetailScreen extends StatelessWidget {
  final AppUser user;

  const AdminUserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor =
    isDark ? AppColors.surfaceDark : AppColors.surface;

    final borderColor =
    isDark ? AppColors.borderDark : AppColors.border;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('User Details'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primaryMuted,
                      backgroundImage: user.photoUrl.isNotEmpty
                          ? NetworkImage(user.photoUrl)
                          : null,
                      child: user.photoUrl.isEmpty
                          ? Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(fontSize: 20),
                      )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style:
                          Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(user.email),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// GRID
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [

                    _infoCard(
                      context,
                      'Account',
                      [
                        _infoRow('UID', user.uid),
                        _infoRow(
                            'Anonymous', user.isAnonymous.toString()),
                        _infoRow('Created At',
                            user.createdAt?.toString() ?? '-'),
                        _infoRow('Last Seen',
                            user.lastSeen?.toString() ?? '-'),
                      ],
                    ),

                    _infoCard(
                      context,
                      'Usage',
                      [
                        _infoRow('Posts',
                            user.totalPostsCreated.toString()),
                        _infoRow('Collections',
                            user.totalCollectionsCreated.toString()),
                      ],
                    ),

                    _infoCard(
                      context,
                      'Subscription',
                      [
                        _infoRow('Plan', user.plan),
                        _infoRow(
                            'Is Pro', user.isPro.toString()),
                        _infoRow('Entitlements',
                            user.entitlements.join(', ')),
                      ],
                    ),

                    _infoCard(
                      context,
                      'Device',
                      [
                        _infoRow(
                            'Device', user.deviceType ?? '-'),
                        _infoRow(
                            'Platform', user.platform ?? '-'),
                        _infoRow(
                            'Version', user.appVersion ?? '-'),
                      ],
                    ),

                    _infoCard(
                      context,
                      'RevenueCat',
                      [
                        _infoRow('RC User ID',
                            user.rcAppUserId ?? '-'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(
      BuildContext context,
      String title,
      List<Widget> children,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor =
    isDark ? AppColors.surfaceDark : AppColors.surface;

    final borderColor =
    isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      width: 420,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}