import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:refind_app/features/subscription/subscription_screen.dart';
import 'package:refind_app/services/app_version_service.dart';
import '../../core/theme/colors.dart';
import '../../main.dart';
import '../../services/in_app_purchase_service.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_service.dart';
import '../saved_posts/saved_posts_controller.dart';
import 'settings_controller.dart';
import 'models/user_settings_model.dart';

final SavedPostsController _postsController = SavedPostsController();

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController controller = SettingsController();

  final auth = AuthService();

  // ── auth / subscription state ──────────────────────────────────────────────
  StreamSubscription? _sub;
  bool isSubscribed = false;
  bool _isSigningIn = false;

  // ── settings state ─────────────────────────────────────────────────────────
  bool isLoading = true;
  bool notificationsEnabled = true;
  String defaultReminder = '2 hours';
  String stopAfter = '3 days';
  String theme = 'System';

  late TimeOfDay quietStart;
  late TimeOfDay quietEnd;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    _sub = InAppPurchaseService().proStatusStream.listen((isPro) {
      if (!mounted) return;

      setState(() {
        isSubscribed = isPro;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    await controller.loadSettings();
    final s = controller.settings!;
    setState(() {
      notificationsEnabled = s.notificationsEnabled;
      defaultReminder = s.defaultReminder;
      stopAfter = s.stopAfter;
      theme = s.theme;
      quietStart = TimeOfDay(
        hour: s.quietStartHour,
        minute: s.quietStartMinute,
      );
      quietEnd = TimeOfDay(hour: s.quietEndHour, minute: s.quietEndMinute);
      isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await controller.updateSettings(
      UserSettings(
        notificationsEnabled: notificationsEnabled,
        defaultReminder: defaultReminder,
        stopAfter: stopAfter,
        theme: theme,
        quietStartHour: quietStart.hour,
        quietStartMinute: quietStart.minute,
        quietEndHour: quietEnd.hour,
        quietEndMinute: quietEnd.minute,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved ✅"), showCloseIcon: true),
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? quietStart : quietEnd,
    );
    if (picked != null) {
      setState(() => isStart ? quietStart = picked : quietEnd = picked);
      await _saveSettings();
    }
  }

  // ── Google sign-in stub ────────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    HapticFeedback.lightImpact();

    setState(() => _isSigningIn = true);

    try {
      final result = await auth.signInWithGoogle();

      final user = result?.user;

      if (user != null) {
        AuthController().onGoogleSignInComplete();
      }

      if (!mounted) return;

      setState(() => _isSigningIn = false);

      if (result == null) return;

      await auth.ensureDisplayName();

      final name = auth.currentUser?.displayName ?? "User";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Welcome $name"), showCloseIcon: true),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSigningIn = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign-in failed"), showCloseIcon: true),
      );
    }
  }

  // ── clear dialog ───────────────────────────────────────────────────────────
  void _showClearDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Clear All Data',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        content: Text(
          'All saved posts will be permanently deleted. This cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Clearing posts...")),
                );

                await _postsController.deleteAllPosts();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All posts deleted"),
                    showCloseIcon: true,
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Failed to delete posts"),
                    showCloseIcon: true,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              // ── Account card ─────────────────────────────────────────────────
              _AccountCard(
                isDark: isDark,
                isSubscribed: isSubscribed,
                onSignIn: _signInWithGoogle,
                isAnonymous: auth.isAnonymous(),
                name: auth.displayName,
                email: auth.email,
              ),

              const SizedBox(height: 24),

              // ── Notifications ─────────────────────────────────────────────────
              _SectionLabel(label: 'Notifications'),
              _SettingsCard(
                isDark: isDark,
                children: [
                  _SwitchRow(
                    title: 'Enable Notifications',
                    value: notificationsEnabled,
                    isDark: isDark,
                    onChanged: (val) async {
                      HapticFeedback.selectionClick();
                      setState(() => notificationsEnabled = val);
                      await _saveSettings();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Reminders ────────────────────────────────────────────────────
              _SectionLabel(label: 'Reminder Settings'),
              Stack(
                children: [
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _DropdownRow(
                        title: 'Default Reminder',
                        value: defaultReminder,
                        isDark: isDark,
                        items: ['2 hours', '6 hours', '1 day'],
                        onChanged: (_) {},
                      ),
                      _Divider(isDark: isDark),
                      _DropdownRow(
                        title: 'Stop Reminding After',
                        value: stopAfter,
                        isDark: isDark,
                        items: ['1 day', '3 days', '7 days', 'Never'],
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                  if (!isSubscribed) _ProOverlay(isDark: isDark),
                ],
              ),

              const SizedBox(height: 20),

              // ── Quiet Hours ───────────────────────────────────────────────────
              _SectionLabel(label: 'Quiet Hours'),
              Stack(
                children: [
                  _SettingsCard(
                    isDark: isDark,
                    children: [
                      _TimeRow(
                        title: 'Start Time',
                        time: quietStart,
                        isDark: isDark,
                        onTap: () {},
                      ),
                      _Divider(isDark: isDark),
                      _TimeRow(
                        title: 'End Time',
                        time: quietEnd,
                        isDark: isDark,
                        onTap: () {},
                      ),
                    ],
                  ),
                  if (!isSubscribed) _ProOverlay(isDark: isDark),
                ],
              ),
              const SizedBox(height: 20),

              // ── Appearance ────────────────────────────────────────────────────
              _SectionLabel(label: 'Appearance'),
              _SettingsCard(
                isDark: isDark,
                children: [
                  _DropdownRow(
                    title: 'Theme',
                    value: theme,
                    isDark: isDark,
                    items: ['System', 'Light', 'Dark'],
                    onChanged: (val) async {
                      setState(() => theme = val!);
                      themeController.setTheme(val!);
                      await _saveSettings();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Danger Zone ───────────────────────────────────────────────────
              _SectionLabel(label: 'Danger Zone'),
              _SettingsCard(
                isDark: isDark,
                children: [
                  _DangerRow(
                    title: 'Clear All Saved Posts',
                    onTap: _showClearDialog,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── About ─────────────────────────────────────────────────────────
              _SectionLabel(label: 'About'),
              _SettingsCard(
                isDark: isDark,
                children: [_AboutRow(isDark: isDark)],
              ),
            ],
          ),
        ),
        if (_isSigningIn)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🧩  Account Card
// ─────────────────────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.isDark,
    required this.isSubscribed,
    required this.onSignIn,
    required this.isAnonymous,
    this.name,
    this.email,
  });

  final bool isDark;
  final bool isSubscribed;
  final VoidCallback onSignIn;
  final bool isAnonymous;
  final String? name;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;
    final badgeBg = isSubscribed
        ? AppColors.primaryMuted
        : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant);
    final badgeFg = isSubscribed ? AppColors.primary : AppColors.textTertiary;
    final mutedBg = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariant;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — title + plan badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Account', style: Theme.of(context).textTheme.titleSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSubscribed ? 'PREMIUM' : 'FREE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: badgeFg,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Identity row — changes based on auth state
          isAnonymous
              ? _SignInButton(
                  isDark: isDark,
                  border: border,
                  mutedBg: mutedBg,
                  onTap: onSignIn,
                )
              : _SignedInRow(
                  isDark: isDark,
                  border: border,
                  mutedBg: mutedBg,
                  name: name,
                  email: email,
                  onTap: onSignIn,
                ),

          // Upgrade button — only for free users
          if (!isSubscribed) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight, width: 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade to Premium',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Unlimited bookmarks & smart reminders',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Anonymous state — show Google sign-in button
class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.isDark,
    required this.border,
    required this.mutedBg,
    required this.onTap,
  });

  final bool isDark;
  final Color border;
  final Color mutedBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: mutedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Row(
          children: [
            _GoogleMark(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign in with Google',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sync bookmarks across all your devices',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Signed-in state — avatar + name + email + switch account option
class _SignedInRow extends StatelessWidget {
  const _SignedInRow({
    required this.isDark,
    required this.border,
    required this.mutedBg,
    required this.onTap,
    this.name,
    this.email,
  });

  final bool isDark;
  final Color border;
  final Color mutedBg;
  final VoidCallback onTap;
  final String? name;
  final String? email;

  String get _initials {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return '?';
    final parts = n.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: mutedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        children: [
          // Avatar circle with initials
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  height: 1,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Your account',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Minimal Google "G" mark drawn with plain Flutter widgets — no asset needed.
class _GoogleMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4285F4),
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🧩  Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(letterSpacing: 0.4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🧩  Shared card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.isDark, required this.children});

  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final border = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(children: children),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🧩  Row atoms
// ─────────────────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0,
      thickness: 0.8,
      color: isDark ? AppColors.borderDark : AppColors.border,
      indent: 16,
      endIndent: 16,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  const _DropdownRow({
    required this.title,
    required this.value,
    required this.isDark,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final String value;
  final bool isDark;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surface,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
            icon: Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.title,
    required this.time,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final TimeOfDay time;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyLarge),
            Text(
              time.format(context),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.error),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.error.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // App icon placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bookmark_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Refind', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                'Revisit what matters · v${AppVersionService().fullVersion}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProOverlay extends StatelessWidget {
  const _ProOverlay({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppColors.surfaceDark : AppColors.surface)
                .withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Premium feature',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}