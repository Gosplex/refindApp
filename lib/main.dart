import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/home/save_link_from_intent_screen.dart';
import 'features/limitGuard/usage_provider.dart';
import 'features/reminders/onesignal_service.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool openedFromShareIntent = false;

final themeController = ThemeController();

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await OneSignalService.init();
  }

  String? sharedText;

  if (!kIsWeb) {
    final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();

    if (initialMedia.isNotEmpty) {
      sharedText = initialMedia.first.path;
      openedFromShareIntent = true;
    }
  }

  // final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
  //
  // String? sharedText;
  // if (initialMedia.isNotEmpty) {
  //   sharedText = initialMedia.first.path;
  //   openedFromShareIntent = true;
  // }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UsageProvider()..init()),
      ],
      child: RefindApp(initialSharedText: sharedText),
    ),
  );
}

class RefindApp extends StatefulWidget {
  final String? initialSharedText;
  const RefindApp({super.key, this.initialSharedText});

  @override
  State<RefindApp> createState() => _RefindAppState();
}

class _RefindAppState extends State<RefindApp> {
  StreamSubscription? _intentSub;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((
        files,
      ) {
        if (files.isNotEmpty) {
          final value = files.first.path;
          _handleSharedText(value);
        }
      });

      ReceiveSharingIntent.instance.getInitialMedia().then((files) {
        if (files.isNotEmpty) {
          final value = files.first.path;
          _handleSharedText(value);
        }
      });
    }
  }

  void _handleSharedText(String value) {
    print("Shared: $value");
    openedFromShareIntent = true;
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => SaveLinkFromIntentScreen(sharedText: value),
      ),
    );
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  /// AuthController init error

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (_, __) {
        return MaterialApp(
          navigatorObservers: [FirebaseAnalyticsObserver(analytics: analytics)],
          navigatorKey: navigatorKey,
          title: 'Refind',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: widget.initialSharedText != null
              ? SaveLinkFromIntentScreen(sharedText: widget.initialSharedText!)
              : SplashScreen(),
        );
      },
    );
  }
}
