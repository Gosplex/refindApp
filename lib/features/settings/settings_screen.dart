import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:refind_app/features/subscription/subscription_screen.dart';
import 'package:refind_app/services/app_version_service.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/widgets.dart';
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

  StreamSubscription? _sub;
  bool isSubscribed = false;
  bool _isSigningIn = false;

  bool isLoading = true;
  bool notificationsEnabled = true;
  bool weekRecapEnabled = false;
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
      setState(() => isSubscribed = isPro);
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
    if (!mounted) return;
    setState(() {
      notificationsEnabled = s.notificationsEnabled;
      weekRecapEnabled = s.weekRecapEnabled;
      defaultReminder = s.defaultReminder;
      stopAfter = s.stopAfter;
      theme = s.theme;
      quietStart = TimeOfDay(hour: s.quietStartHour, minute: s.quietStartMinute);
      quietEnd = TimeOfDay(hour: s.quietEndHour, minute: s.quietEndMinute);
      isLoading = false;
    });
  }

  Future<void> _saveSettings({bool toast = true}) async {
    await controller.updateSettings(
      UserSettings(
        notificationsEnabled: notificationsEnabled,
        weekRecapEnabled: weekRecapEnabled,
        defaultReminder: defaultReminder,
        stopAfter: stopAfter,
        theme: theme,
        quietStartHour: quietStart.hour,
        quietStartMinute: quietStart.minute,
        quietEndHour: quietEnd.hour,
        quietEndMinute: quietEnd.minute,
      ),
    );
    if (toast) _toast('Saved');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), showCloseIcon: true),
    );
  }

  void _openPaywall() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
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
      _toast('Welcome $name');
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSigningIn = false);
      _toast('Sign-in failed');
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirm = await showConfirmDialog(
      context,
      icon: Icons.person_remove_rounded,
      title: 'Delete account?',
      message:
          'This permanently deletes your account, collections and all saved links. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirm) return;

    try {
      _toast('Deleting account…');
      await AuthController().deleteAccount();
      _toast('Account deleted');
    } catch (e) {
      _toast('Failed to delete account');
    }
  }

  Future<void> _showClearDialog() async {
    final confirm = await showConfirmDialog(
      context,
      icon: Icons.delete_sweep_rounded,
      title: 'Clear all saved posts?',
      message:
          'All saved posts will be permanently deleted. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirm) return;

    try {
      _toast('Clearing posts…');
      await _postsController.deleteAllPosts();
      _toast('All posts deleted');
    } catch (e) {
      _toast('Failed to delete posts');
    }
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

    final c = context.c;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            titleSpacing: AppSpacing.screen,
            title: Text('Settings', style: context.text.titleLarge),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, AppSpacing.md, AppSpacing.screen, 110),
            children: [
              FadeSlideIn(
                child: _AccountCard(
                  isSubscribed: isSubscribed,
                  isAnonymous: auth.isAnonymous(),
                  name: auth.displayName,
                  email: auth.email,
                  onSignIn: _signInWithGoogle,
                  onUpgrade: _openPaywall,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Notifications
              FadeSlideIn(
                index: 1,
                child: _Section(
                  label: 'Notifications',
                  child: _SettingsGroup(
                    children: [
                      _SwitchTile(
                        title: 'Enable notifications',
                        value: notificationsEnabled,
                        onChanged: (val) async {
                          HapticFeedback.selectionClick();
                          setState(() => notificationsEnabled = val);
                          await _saveSettings();
                        },
                      ),
                      _SwitchTile(
                        title: 'Weekly recap',
                        subtitle: 'A summary of your week',
                        value: weekRecapEnabled,
                        locked: !isSubscribed,
                        onLockedTap: _openPaywall,
                        onChanged: (val) async {
                          HapticFeedback.selectionClick();
                          setState(() => weekRecapEnabled = val);
                          await _saveSettings();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Reminders (pro)
              FadeSlideIn(
                index: 2,
                child: _Section(
                  label: 'Reminder settings',
                  child: _LockableGroup(
                    locked: !isSubscribed,
                    onLockedTap: _openPaywall,
                    children: [
                      _DropdownTile(
                        title: 'Default reminder',
                        value: defaultReminder,
                        items: const ['2 hours', '6 hours', '1 day'],
                        onChanged: (val) async {
                          if (val == null) return;
                          setState(() => defaultReminder = val);
                          await _saveSettings();
                        },
                      ),
                      _DropdownTile(
                        title: 'Stop reminding after',
                        value: stopAfter,
                        items: const ['1 day', '3 days', '7 days', 'Never'],
                        onChanged: (val) async {
                          if (val == null) return;
                          setState(() => stopAfter = val);
                          await _saveSettings();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Quiet hours (pro)
              FadeSlideIn(
                index: 3,
                child: _Section(
                  label: 'Quiet hours',
                  child: _LockableGroup(
                    locked: !isSubscribed,
                    onLockedTap: _openPaywall,
                    children: [
                      _TimeTile(
                        title: 'Start time',
                        time: quietStart,
                        onTap: () => _pickTime(true),
                      ),
                      _TimeTile(
                        title: 'End time',
                        time: quietEnd,
                        onTap: () => _pickTime(false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Appearance
              FadeSlideIn(
                index: 4,
                child: _Section(
                  label: 'Appearance',
                  child: _SettingsGroup(
                    children: [
                      _DropdownTile(
                        title: 'Theme',
                        value: theme,
                        items: const ['System', 'Light', 'Dark'],
                        onChanged: (val) async {
                          if (val == null) return;
                          setState(() => theme = val);
                          themeController.setTheme(val);
                          await _saveSettings();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Danger zone
              FadeSlideIn(
                index: 5,
                child: _Section(
                  label: 'Danger zone',
                  child: _SettingsGroup(
                    children: [
                      _DangerTile(
                        title: 'Clear all saved posts',
                        icon: Icons.delete_sweep_rounded,
                        onTap: _showClearDialog,
                      ),
                      if (!auth.isAnonymous())
                        _DangerTile(
                          title: 'Delete account',
                          icon: Icons.person_remove_rounded,
                          onTap: _showDeleteAccountDialog,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // About
              FadeSlideIn(index: 6, child: const _AboutTile()),
            ],
          ),
        ),
        if (_isSigningIn)
          Container(
            color: c.overlay,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Account card
// ─────────────────────────────────────────────
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.isSubscribed,
    required this.isAnonymous,
    required this.onSignIn,
    required this.onUpgrade,
    this.name,
    this.email,
  });

  final bool isSubscribed;
  final bool isAnonymous;
  final VoidCallback onSignIn;
  final VoidCallback onUpgrade;
  final String? name;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Account', style: context.text.titleSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 4),
                decoration: BoxDecoration(
                  color: isSubscribed ? c.primarySurface : c.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  isSubscribed ? 'PREMIUM' : 'FREE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSubscribed ? c.primary : c.textTertiary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          isAnonymous
              ? _SignInButton(onTap: onSignIn)
              : _SignedInRow(name: name, email: email),
          if (!isSubscribed) ...[
            const SizedBox(height: AppSpacing.md),
            _UpgradeBanner(onTap: onUpgrade),
          ],
        ],
      ),
    );
  }
}

class _UpgradeBanner extends StatelessWidget {
  const _UpgradeBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md + 1),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF5A8C69)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upgrade to Premium',
                      style: context.text.titleSmall
                          ?.copyWith(color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Unlimited bookmarks & smart reminders',
                      style: context.text.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.border, width: 0.8),
        ),
        child: Row(
          children: [
            _GoogleMark(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sign in with Google',
                      style: context.text.titleSmall),
                  const SizedBox(height: 2),
                  Text('Sync bookmarks across all your devices',
                      style: context.text.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedInRow extends StatelessWidget {
  const _SignedInRow({this.name, this.email});

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
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border, width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name ?? 'Your account',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall),
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall),
                ],
              ],
            ),
          ),
          Icon(Icons.verified_rounded, size: 18, color: c.primary),
        ],
      ),
    );
  }
}

/// Minimal Google "G" mark — no asset needed.
class _GoogleMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
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
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4285F4),
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section scaffolding
// ─────────────────────────────────────────────
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(
            label.toUpperCase(),
            style: context.text.labelSmall?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: context.c.textTertiary,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// A card grouping rows, auto-inserting hairline dividers between them.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Divider(
            height: 1,
            thickness: 0.8,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
            color: c.border));
      }
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: rows),
    );
  }
}

/// A settings group that dims + locks behind a premium overlay when [locked].
class _LockableGroup extends StatelessWidget {
  const _LockableGroup({
    required this.children,
    required this.locked,
    required this.onLockedTap,
  });

  final List<Widget> children;
  final bool locked;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    final group = _SettingsGroup(children: children);
    if (!locked) return group;

    final c = context.c;
    return Stack(
      children: [
        group,
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onLockedTap,
            child: Container(
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              alignment: Alignment.center,
              child: const _PremiumChip(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumChip extends StatelessWidget {
  const _PremiumChip();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 7),
      decoration: BoxDecoration(
        color: c.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 13, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs + 2),
          Text('Premium feature',
              style: context.text.labelMedium
                  ?.copyWith(color: c.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Row atoms
// ─────────────────────────────────────────────
class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.locked = false,
    this.onLockedTap,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool locked;
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.bodyLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: context.text.labelSmall),
                ],
              ],
            ),
          ),
          if (locked)
            GestureDetector(
              onTap: onLockedTap,
              child: const _MiniLock(),
            )
          else
            Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MiniLock extends StatelessWidget {
  const _MiniLock();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 6),
      decoration: BoxDecoration(
        color: c.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text('Premium',
              style: context.text.labelSmall?.copyWith(color: c.primary)),
        ],
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  const _DropdownTile({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: context.text.bodyLarge),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(AppRadius.md),
            dropdownColor: c.surface,
            style: context.text.bodyMedium?.copyWith(color: c.primary),
            icon: Icon(Icons.expand_more_rounded,
                size: 18, color: c.textTertiary),
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e,
                          style: TextStyle(color: c.textPrimary, fontSize: 14)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.title,
    required this.time,
    required this.onTap,
  });

  final String title;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: context.text.bodyLarge),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 5),
              decoration: BoxDecoration(
                color: c.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                time.format(context),
                style: context.text.labelMedium
                    ?.copyWith(color: c.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
        child: Row(
          children: [
            Icon(icon, size: 19, color: c.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(title,
                  style: context.text.bodyLarge?.copyWith(color: c.error)),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: c.error.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF5A8C69)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.bookmark_rounded,
                size: 22, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Refind', style: context.text.titleSmall),
              const SizedBox(height: 2),
              Text(
                'Revisit what matters · v${AppVersionService().fullVersion}',
                style: context.text.labelSmall,
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.favorite_rounded, size: 16, color: c.primary),
        ],
      ),
    );
  }
}
