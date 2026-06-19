import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'utils/language_notifier.dart';
import 'theme/app_theme.dart';
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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
  await languageNotifier.load();

  runApp(const HabeshahubApp());
}

class HabeshahubApp extends StatelessWidget {
  const HabeshahubApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder lytter på languageNotifier.
    // Når brukeren bytter språk, vil hele appen tegnes på nytt med det nye språket.
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'Habesha Hub',
          debugShowCheckedModeBanner: false,

          // Bruker temaet fra lib/theme/app_theme.dart
          theme: habeshaTheme(),

          // Starter appen på Splash Screen
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
        if (!snap.hasData) return const SizedBox();
        final done = snap.data!.getBool('onboarding_done') ?? false;
        return done ? const SplashScreen() : const OnboardingScreen();
      },
    );
  }
}
