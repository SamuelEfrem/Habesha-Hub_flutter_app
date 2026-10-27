import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'utils/language_notifier.dart';
import 'theme/app_theme.dart';
import 'utils/theme_notifier.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('nb', null);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF20201F),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // Crash reports (not while developing on the PC)
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    print('Firebase init error: $e');
  }
  try {
    await NotificationService.initialize();
  } catch (e) {
    print('Notification init error: $e');
  }
  await languageNotifier.load();
  await themeNotifier.load();

  // Push about new providers / videos in the chosen language
  NotificationService.syncNewsTopic(languageNotifier.language);
  languageNotifier.addListener(
      () => NotificationService.syncNewsTopic(languageNotifier.language));

  runApp(const HabeshahubApp());
}

class HabeshahubApp extends StatefulWidget {
  const HabeshahubApp({super.key});

  @override
  State<HabeshahubApp> createState() => _HabeshahubAppState();
}

class _HabeshahubAppState extends State<HabeshahubApp> {
  @override
  void initState() {
    super.initState();
    _applySystemBars();
    themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  // Colours like kBg / kText are read while building, so every screen that
  // is already open (also pages pushed on top) must build again. Marking all
  // elements dirty keeps their state (scroll position, typed text …).
  void _onThemeChanged() {
    _applySystemBars();
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }
    (context as Element).visitChildren(rebuild);
  }

  void _applySystemBars() {
    final dark = themeNotifier.isDark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: dark ? const Color(0xFF20201F) : const Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder lytter på languageNotifier.
    // Når brukeren bytter språk, vil hele appen tegnes på nytt med det nye språket.
    return AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) {
        return MaterialApp(
          title: 'Habesha Hub',
          debugShowCheckedModeBanner: false,
          theme: habeshaLightTheme(),
          darkTheme: habeshaTheme(),
          themeMode: themeNotifier.mode,
          // Analytics: which screens people open
          navigatorObservers: [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
          // Status bar icons: dark on the light theme, light on the dark theme
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: themeNotifier.isDark
                ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
                : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
            child: child!,
          ),
          home: const AppEntry(),
        );
      },
    );
  }
}

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (_, snap) {
        if (!snap.hasData) return Scaffold(backgroundColor: kBg);
        final done = snap.data!.getBool('onboarding_done') ?? false;
        return done ? const SplashScreen() : const OnboardingScreen();
      },
    );
  }
}
