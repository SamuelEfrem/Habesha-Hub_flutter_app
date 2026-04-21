import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'utils/language_notifier.dart';
import 'theme/app_theme.dart';

void main() async {
  // Sørger for at Flutter-motoren er klar før vi kjører async-kode
  WidgetsFlutterBinding.ensureInitialized();

  // Setter stilen på statuslinjen og navigasjonslinjen på telefonen
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF20201F),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialiserer Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Laster inn lagret språkvalg (Norsk, Engelsk eller Tigrinya)
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
          home: const SplashScreen(),
        );
      },
    );
  }
}
