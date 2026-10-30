import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import 'home_screen.dart';
import '../utils/translations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _fade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _enter();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _enter() {
    Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const HomeScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (context, _) {
        final lang = languageNotifier.language;

        // Language-aware texts
        // Correct translations
        final tagline = lang == 'Tigrinya'
            ? 'ናይ ሓበሻ ማሕበረሰብኩም ኣብ ኢድኩም'
            : lang == 'Amharic'
                ? 'የሃበሻ ማህበረሰብዎ በእጅዎ'
                : tr('Your Habesha community in your pocket');

        final joinBtn = lang == 'Tigrinya'
            ? 'እቶ'
            : lang == 'Amharic'
                ? 'አሁን ይቀላቀሉ'
                : tr('Join Now');

        return Scaffold(
          backgroundColor: kBg,
          body: Stack(children: [
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(children: [
                    const Spacer(flex: 2),

                    // Logo
                    habeshaLogo(size: 104),
                    const SizedBox(height: 22),
                    SizedBox(width: 96, child: ClipRRect(borderRadius: BorderRadius.circular(3), child: habeshaStripe(height: 5))),
                    const SizedBox(height: 22),

                    // App name
                    Text('Habesha\nHub',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: kFontHeadline,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: kText,
                            height: 1.05,
                            letterSpacing: -1)),
                    const SizedBox(height: 16),

                    // Tagline — changes with language
                    Text(tagline,
                        textAlign: TextAlign.center,
                        style: tsBodyLg(color: kTextSub).copyWith(fontSize: 15)),

                    const Spacer(flex: 3),

                    // Language selector on splash
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _langBtn('🇬🇧', 'English', 'English', lang),
                        _langBtn('🇪🇷', 'ትግርኛ', 'Tigrinya', lang),
                        _langBtn('🇪🇹', 'አማርኛ', 'Amharic', lang),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // CTA button — language-aware
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: GestureDetector(
                        onTap: _enter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                              color: kSecondary,
                              borderRadius: BorderRadius.circular(100)),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(joinBtn,
                                    style: tsTitleLg(color: kOnAccent)),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded,
                                    color: kOnAccent, size: 18),
                              ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _langBtn(String flag, String label, String code, String current) {
    final active = current == code;
    return GestureDetector(
      onTap: () => languageNotifier.setLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: active ? kSecondary : kCard,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label,
            style: tsTitleMd(color: active ? kOnAccent : kText)),
      ),
    );
  }
}
