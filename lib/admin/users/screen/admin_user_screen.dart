import 'package:flutter/material.dart';

import '../../../core/model/app_user_model.dart';
import '../../../core/theme/colors.dart';
import '../admin_user_controller.dart';
import 'admin_user_detail_screen.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final AdminUserController _controller = AdminUserController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor =
    isDark ? AppColors.surfaceDark : AppColors.surface;

    final borderColor =
    isDark ? AppColors.borderDark : AppColors.border;

    return StreamBuilder<List<AppUser>>(
      stream: _controller.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Snapshot Error: ${snapshot.error}');
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(child: Text('No users found'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Users',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: borderColor, height: 1),
                  itemBuilder: (context, index) {
                    final user = users[index];

                    final isPremium = user.plan == 'premium';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),

                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryMuted,
                        backgroundImage: user.photoUrl.isNotEmpty
                            ? NetworkImage(user.photoUrl)
                            : null,
                        child: user.photoUrl.isEmpty
                            ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                        )
                            : null,
                      ),

                      title: Row(
                        children: [
                          Expanded(child: Text(user.name)),

                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPremium
                                  ? AppColors.primaryMuted
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isPremium
                                    ? AppColors.primary
                                    : borderColor,
                              ),
                            ),
                            child: Text(
                              isPremium ? 'Premium' : 'Free',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                color: isPremium
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(user.email),

                          const SizedBox(height: 4),

                          Text(
                            '${user.deviceType ?? 'unknown'} • v${user.appVersion ?? '-'}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      trailing: IconButton(
                        icon: const Icon(Icons.visibility_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminUserDetailScreen(user: user),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}