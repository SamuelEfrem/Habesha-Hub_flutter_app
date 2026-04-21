import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import 'home_screen.dart';

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
            : lang == 'English'
                ? 'Your Habesha community in your pocket'
                : 'Ditt Habesha-fellesskap i lomma';

        final joinBtn = lang == 'Tigrinya'
            ? 'እቶ'
            : lang == 'English'
                ? 'Join Now'
                : 'Bli med nå';

        return Scaffold(
          backgroundColor: kSurface,
          body: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: TibebPainter())),
            Positioned(
              top: -60,
              left: 0,
              right: 0,
              child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                      gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 0.9,
                          colors: [
                        kPrimaryContainer.withOpacity(0.4),
                        Colors.transparent
                      ]))),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(children: [
                    const Spacer(flex: 2),

                    // Logo — full circle filled with icon
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: kSecondary.withOpacity(0.7), width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: kSecondary.withOpacity(0.2),
                              blurRadius: 24,
                              spreadRadius: 4)
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset('assets/images/icon.png',
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.local_cafe_rounded,
                                size: 50,
                                color: kSecondary)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Gold divider
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                          width: 36,
                          height: 0.5,
                          color: kSecondary.withOpacity(0.4)),
                      Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                              color: kSecondary, shape: BoxShape.circle)),
                      Container(
                          width: 36,
                          height: 0.5,
                          color: kSecondary.withOpacity(0.4)),
                    ]),
                    const SizedBox(height: 24),

                    // App name
                    const Text('Habesha\nHub',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: kFontHeadline,
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            color: kSecondary,
                            height: 1.05,
                            letterSpacing: -1)),
                    const SizedBox(height: 16),

                    // Tagline — changes with language
                    Text(tagline,
                        textAlign: TextAlign.center,
                        style: tsBodyLg(color: kOnSurfaceVariant)),

                    const Spacer(flex: 3),

                    // Language selector on splash
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _langBtn('🇬🇧', 'English', 'English', lang),
                      const SizedBox(width: 10),
                      _langBtn('🇪🇷', 'ትግርኛ', 'Tigrinya', lang),
                      const SizedBox(width: 10),
                      _langBtn('🇳🇴', 'Norsk', 'Norsk', lang),
                    ]),

                    const SizedBox(height: 24),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      height: 1,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                        Colors.transparent,
                        kPrimaryContainer.withOpacity(0.6),
                        kSecondary.withOpacity(0.5),
                        Colors.transparent,
                      ])),
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
                              color: kPrimaryContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: kSecondary.withOpacity(0.5),
                                  width: 0.5)),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(joinBtn,
                                    style: tsTitleLg(color: kOnSurface)),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded,
                                    color: kOnSurface, size: 18),
                              ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.star_outline_rounded,
                          color: kSecondary.withOpacity(0.3), size: 14),
                      const SizedBox(width: 12),
                      Icon(Icons.star_outline_rounded,
                          color: kSecondary.withOpacity(0.5), size: 18),
                      const SizedBox(width: 12),
                      Icon(Icons.star_outline_rounded,
                          color: kSecondary.withOpacity(0.3), size: 14),
                    ]),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? kSecondary : kSurfaceContainer,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
              color: active ? kSecondary : kOutlineVariant.withOpacity(0.3),
              width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(flag, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(label,
              style: tsLabel(
                  color: active ? const Color(0xFF1A1200) : kOnSurfaceVariant)),
        ]),
      ),
    );
  }
}
