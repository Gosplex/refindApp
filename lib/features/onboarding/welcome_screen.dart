import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme_x.dart';
import '../../core/widgets/widgets.dart';
import '../../main.dart';
import '../../navigation/bottom_nav.dart';
import '../auth/auth_controller.dart';
import '../settings/settings_controller.dart';

enum _Action { google, guest }

/// Shown after splash when there is no signed-in session (fresh install,
/// reinstall, or signed out). Offers to sign in — so returning users land back
/// on their real account instead of silently creating a throwaway anon — or
/// continue without an account.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _auth = AuthController();
  _Action? _busy;
  String _status = '';

  void _setStatus(String s) {
    if (mounted) setState(() => _status = s);
  }

  Future<void> _google() async {
    setState(() {
      _busy = _Action.google;
      _status = 'Opening Google…';
    });
    final user = await _auth.signInWithGoogleForOnboarding(onStatus: _setStatus);
    if (!mounted) return;
    if (user == null) {
      setState(() => _busy = null); // cancelled / failed
      return;
    }
    await _goHome();
  }

  Future<void> _guest() async {
    setState(() {
      _busy = _Action.guest;
      _status = 'Getting things ready…';
    });
    final ok = await _auth.continueAsGuest(onStatus: _setStatus);
    if (!mounted) return;
    if (!ok) {
      setState(() => _busy = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
      return;
    }
    await _goHome();
  }

  Future<void> _goHome() async {
    _setStatus('Almost done…');
    final settings = SettingsController();
    await settings.loadSettings();
    themeController.setTheme(settings.settings?.theme ?? 'System');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: AppMotion.medium,
        pageBuilder: (_, __, ___) => const BottomNav(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final busy = _busy != null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Brand
              FadeSlideIn(
                child: Column(
                  children: [
                    const _BrandBadge(),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Refind',
                        style: context.text.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Save links, and actually come back to them.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Value props
              FadeSlideIn(
                index: 1,
                child: Column(
                  children: const [
                    _Feature(
                      icon: Icons.ios_share_rounded,
                      title: 'Save from anywhere',
                      subtitle: 'Share any link straight into Refind',
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _Feature(
                      icon: Icons.notifications_active_rounded,
                      title: 'Gentle reminders',
                      subtitle: 'Nudges to revisit what matters',
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _Feature(
                      icon: Icons.insights_rounded,
                      title: 'See your habits',
                      subtitle: 'Know what you actually revisit',
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // CTAs
              FadeSlideIn(
                index: 2,
                child: Column(
                  children: [
                    AppButton(
                      label: 'Continue with Google',
                      icon: Icons.login_rounded,
                      size: AppButtonSize.large,
                      loading: _busy == _Action.google,
                      onPressed: busy ? null : _google,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton.secondary(
                      label: 'Continue without an account',
                      size: AppButtonSize.large,
                      loading: _busy == _Action.guest,
                      onPressed: busy ? null : _guest,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Live status while busy; helper caption otherwise.
                    SizedBox(
                      height: 18,
                      child: AnimatedSwitcher(
                        duration: AppMotion.fast,
                        child: busy
                            ? Row(
                                key: ValueKey(_status),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sync_rounded,
                                      size: 13, color: c.primary),
                                  const SizedBox(width: AppSpacing.xs + 2),
                                  Flexible(
                                    child: Text(
                                      _status,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.labelMedium
                                          ?.copyWith(color: c.primary),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Sign in to sync and restore your links across devices.',
                                key: const ValueKey('caption'),
                                textAlign: TextAlign.center,
                                style: context.text.labelSmall
                                    ?.copyWith(color: c.textTertiary),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF5A8C69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(Icons.bookmark_rounded, size: 38, color: Colors.white),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: c.primarySurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 22, color: c.primary),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleSmall),
              const SizedBox(height: 2),
              Text(subtitle, style: context.text.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
