import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../admin/dashboard/admin_dashboard_screen.dart';
import '../../main.dart';
import '../../navigation/bottom_nav.dart';
import '../../core/theme/colors.dart';
import '../../services/app_version_service.dart';
import '../appUpdate/app_update_screen.dart';
import '../auth/auth_controller.dart';
import '../onboarding/welcome_screen.dart';
import '../settings/settings_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Orchestrated one-shot entrance.
  late final AnimationController _entrance;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _wordFade;
  late final Animation<double> _wordSpacing;
  late final Animation<double> _taglineFade;
  late final Animation<double> _bottomFade;

  // Looping ambient motion (background, rings, particles, progress).
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _logoFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _wordFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.32, 0.66, curve: Curves.easeOut),
    );
    _wordSpacing = Tween<double>(begin: 12.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.32, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.52, 0.82, curve: Curves.easeOut),
    );
    _bottomFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.68, 1.0, curve: Curves.easeOut),
    );

    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();

    _entrance.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startApp();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Boot / navigation logic (unchanged behavior)
  // ─────────────────────────────────────────────
  void _goToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BottomNav()),
    );
  }

  Future<void> _openStore() async {
    const url =
        "https://play.google.com/store/apps/details?id=com.app.refind";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _startApp() async {
    /// Navigate earlier if web
    if (kIsWeb) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      });
      return;
    }

    final authController = AuthController();
    final settingsController = SettingsController();

    try {
      // Do NOT create an anonymous account eagerly. If there's no persisted
      // session, show the welcome gate so returning users can sign back into
      // their real account instead of spawning a throwaway anon.
      final hasSession = await authController.bootstrapExistingSession();
      if (!mounted) return;

      if (!hasSession) {
        _goToWelcome();
        return;
      }

      await Future.wait([
        settingsController.loadSettings(),
        AppVersionService().init(),
      ]);

      if (!mounted) return;

      themeController.setTheme(settingsController.settings?.theme ?? 'System');
      if (openedFromShareIntent == true) return;

      final versionService = AppVersionService();
      final config = versionService.remoteConfig;

      if (config != null && versionService.isUpdateAvailable) {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => AppUpdateScreen(
              model: config,
              onLater: () {
                Navigator.pop(context);
                _goToHome();
              },
              onUpdate: _openStore,
            ),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => BottomNav(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } catch (e) {
      debugPrint("Splash init error: $e");
      if (!mounted) return;
      // If a session exists, fail open into the app; otherwise show the gate.
      if (FirebaseAuth.instance.currentUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BottomNav()),
        );
      } else {
        _goToWelcome();
      }
    }
  }

  void _goToWelcome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const WelcomeScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // Living gradient backdrop
          _AnimatedBackground(animation: _ambient),

          // Drifting ambient bookmarks
          Positioned.fill(child: _Particles(animation: _ambient)),

          // Centered brand lockup
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 168,
                  height: 168,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _PulseRings(animation: _ambient),
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: const _LogoMark(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                FadeTransition(
                  opacity: _wordFade,
                  child: AnimatedBuilder(
                    animation: _wordSpacing,
                    builder: (context, _) {
                      return Text(
                        'Refind',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: _wordSpacing.value,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    'Revisit what matters',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom loader
          Positioned(
            bottom: bottomInset + 44,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _bottomFade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ProgressBar(animation: _ambient),
                  const SizedBox(height: 16),
                  Text(
                    'Getting things ready…',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 0.4,
                    ),
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

/// Slowly breathing multi-stop sage gradient with a soft top glow.
class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({required this.animation});

  final Animation<double> animation;

  static const _dark = Color(0xFF4E7D5D);
  static const _mid = AppColors.primary;
  static const _light = Color(0xFF83B491);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = (math.sin(animation.value * 2 * math.pi) + 1) / 2;
        final begin = Alignment.lerp(
            Alignment.topLeft, Alignment.topRight, t)!;
        final end = Alignment.lerp(
            Alignment.bottomRight, Alignment.bottomLeft, t)!;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: const [_dark, _mid, _light],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.35),
                radius: 1.1,
                colors: [
                  Colors.white.withValues(alpha: 0.12 + 0.04 * t),
                  Colors.transparent,
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

/// The frosted squircle app mark.
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Icon(Icons.bookmark_rounded, size: 46, color: Colors.white),
    );
  }
}

/// Concentric rings that expand and fade out from behind the logo.
class _PulseRings extends StatelessWidget {
  const _PulseRings({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(3, (i) {
            final t = (animation.value + i / 3) % 1.0;
            final scale = 0.7 + t * 1.15;
            final opacity = (1 - t) * 0.28;
            return Opacity(
              opacity: opacity,
              child: Container(
                width: 108 * scale,
                height: 108 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.4,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Gentle upward drift of translucent bookmark glyphs.
class _Particles extends StatelessWidget {
  const _Particles({required this.animation});

  final Animation<double> animation;

  // x fraction, size, opacity, phase, speed
  static const _specs = [
    [0.12, 18.0, 0.10, 0.0, 1.0],
    [0.82, 26.0, 0.08, 0.3, 0.8],
    [0.28, 14.0, 0.10, 0.6, 1.2],
    [0.68, 20.0, 0.07, 0.15, 0.9],
    [0.5, 16.0, 0.09, 0.75, 1.1],
    [0.9, 13.0, 0.08, 0.5, 1.0],
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return Stack(
              children: _specs.map((s) {
                final t = (animation.value * s[4] + s[3]) % 1.0;
                final y = h * (1.05 - t * 1.2);
                final x = w * s[0];
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: (s[2] * (1 - (t - 0.5).abs() * 1.4))
                        .clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: (t - 0.5) * 0.6,
                      child: Icon(
                        Icons.bookmark_rounded,
                        size: s[1],
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

/// Slim indeterminate progress bar with a sweeping highlight.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.animation});

  final Animation<double> animation;

  static const _width = 140.0;
  static const _seg = 48.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value;
            final dx = -_seg + (_width + _seg) * t;
            return Stack(
              children: [
                Positioned(
                  left: dx,
                  child: Container(
                    width: _seg,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
