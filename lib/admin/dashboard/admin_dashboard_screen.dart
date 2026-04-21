import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:refind_app/admin/settings/screen/settings_screen.dart';

import '../../core/theme/colors.dart';
import '../notification/screen/push_screen.dart';
import '../users/screen/admin_user_screen.dart';
import 'admin_dashboard_content.dart';

/// ─────────────────────────────────────────────
/// 🌐 Admin Dashboard (Web)
/// ─────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminLogin();
    });
  }

  void _checkAdminLogin() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showAdminLoginDialog();
    }
  }

  void _showAdminLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // 🔥 important
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Admin Login',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                          );

                          Navigator.pop(context); // close dialog
                        } catch (e) {
                          debugPrint("Readon for failed ${e}");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Login failed'),
                            ),
                          );
                        }
                      },
                      child: const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _selectedIndex = 0;

  final _menus = const [
    _AdminMenuItem('Dashboard', Icons.dashboard_rounded),
    _AdminMenuItem('Users', Icons.people_alt_rounded),
    _AdminMenuItem('Push Notification', Icons.notifications_active_rounded),
    _AdminMenuItem('Settings', Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor =
    isDark ? AppColors.backgroundDark : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [

          /// 🧭 Sidebar
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark
                  : AppColors.surface,
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.border,
                ),
              ),
            ),
            child: Column(
              children: [

                /// Logo / Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primaryMuted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bookmark_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Refind Admin',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),

                /// Menu Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _menus.length,
                    itemBuilder: (context, index) {
                      final item = _menus[index];
                      final isSelected = index == _selectedIndex;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedIndex = index);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryMuted
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// Bottom section (optional later)
                const SizedBox(height: 12),
              ],
            ),
          ),

          /// 📄 Content Area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return const AdminDashboardContent();
      case 1:
        return const AdminUserScreen();
      case 2:
        return const PushScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const SizedBox();
    }
  }
}

/// ─────────────────────────────────────────────
/// 🧩 Menu Model
/// ─────────────────────────────────────────────
class _AdminMenuItem {
  final String title;
  final IconData icon;

  const _AdminMenuItem(this.title, this.icon);
}
