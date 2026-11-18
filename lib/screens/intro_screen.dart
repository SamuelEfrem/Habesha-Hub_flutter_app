import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/language_notifier.dart';
import '../utils/translations.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart' show kOnboardingKey;

/// Short animated intro (about 6 seconds), shown once (and again after big updates:
/// change the key). Five quick scenes, then the logo and "Start". Tap = next, "Skip" = home.
const kIntroKey = 'intro_v3_done';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  // one run of the scene animation, and a slow loop for the rings / music bars
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  int _i = 0;
  Timer? _t;

  // emoji, title, line, colour (strong colours: the intro looks the same in light and dark mode)
  static const _scenes = [
    ('🤝', 'Habesha Hub Services', 'Book trusted Habesha services', Color(0xFF1F7A55)),
    ('🛍️', 'Market', 'Buy, sell & swap', Color(0xFF2F62A8)),
    ('💸', 'Send money', 'Send money home', Color(0xFFB8452E)),
    ('🎵', 'Events', 'Habesha events near you', Color(0xFF7B3FB0)),
    ('🏎️', 'Learn & play', 'Racing, Dama, Domino and more', Color(0xFFA9770A)),
  ];
  static const _brand = Color(0xFF14523A);
  static const _langs = [('English', 'EN'), ('Tigrinya', 'ትግርኛ'), ('Amharic', 'አማርኛ')];

  bool get _last => _i >= _scenes.length;

  @override
  void initState() {
    super.initState();
    _play();
  }

  void _play() {
    _a.forward(from: 0);
    _t?.cancel();
    if (!_last) _t = Timer(const Duration(milliseconds: 1250), _next);
  }

  void _next() {
    if (!mounted) return;
    if (_last) { _finish(); return; }
    setState(() => _i++);
    _play();
  }

  Future<void> _finish() async {
    _t?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kIntroKey, true);
    await prefs.setBool(kOnboardingKey, true);
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => const HomeScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  void dispose() {
    _t?.cancel();
    _a.dispose();
    _loop.dispose();
    super.dispose();
  }

  Animation<double> _part(double from, double to, [Curve c = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _a, curve: Interval(from, to, curve: c));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final colour = _last ? _brand : _scenes[_i].$4;
        return Scaffold(
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _next,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [colour, Color.lerp(colour, Colors.black, 0.45)!],
              )),
              child: SafeArea(child: Column(children: [
                // story-style progress + Skip
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                  child: Row(children: [
                    for (var k = 0; k <= _scenes.length; k++) Expanded(child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: k <= _i ? 0.95 : 0.3),
                        borderRadius: BorderRadius.circular(2)),
                    )),
                    TextButton(onPressed: _finish,
                        child: Text(tr('Skip'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                  ]),
                ),
                Expanded(child: Center(child: _last ? _logoScene() : _scene(_scenes[_i]))),
                // language, so the intro can be read in Tigrinya or Amharic
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (final l in _langs) Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => languageNotifier.setLanguage(l.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: languageNotifier.language == l.$1 ? 0.95 : 0.15),
                            borderRadius: BorderRadius.circular(100)),
                          child: Text(l.$2, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                              color: languageNotifier.language == l.$1 ? colour : Colors.white)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ])),
            ),
          ),
        );
      },
    );
  }

  Widget _scene((String, String, String, Color) s) {
    final car = s.$1 == '🏎️';
    final music = s.$1 == '🎵';
    final pop = _part(0, 0.6, Curves.elasticOut);
    final title = _part(0.2, 0.65);
    final line = _part(0.4, 0.9);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 260, height: 220,
        child: AnimatedBuilder(
          animation: Listenable.merge([_a, _loop]),
          builder: (_, __) => Stack(alignment: Alignment.center, children: [
            // soft rings that grow and fade
            for (var r = 0; r < 2; r++) Builder(builder: (_) {
              final p = (_loop.value + r * 0.5) % 1.0;
              return Container(
                width: 120 + 110 * p, height: 120 + 110 * p,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35 * (1 - p)), width: 2)),
              );
            }),
            // music: little bars jumping to the beat
            if (music) Positioned(bottom: 6, child: Row(children: [
              for (var b = 0; b < 7; b++) Container(
                width: 6, margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 10 + 26 * (0.5 + 0.5 * math.sin(_loop.value * 2 * math.pi * 2 + b)).abs(),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(3)),
              ),
            ])),
            // the big icon: pops in (the car drives in from the left)
            Transform.translate(
              offset: Offset(car ? -220 * (1 - _part(0, 0.55, Curves.easeOutBack).value) : 0, 0),
              child: Transform.scale(
                scale: car ? 1 : pop.value.clamp(0.0, 1.4),
                child: Container(
                  width: 124, height: 124,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10))]),
                  child: Text(s.$1, style: const TextStyle(fontSize: 62)),
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 22),
      FadeTransition(opacity: title, child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(title),
        child: Text(tr(s.$2), textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.15)),
      )),
      const SizedBox(height: 10),
      FadeTransition(opacity: line, child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(tr(s.$3), textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 17, height: 1.35)),
      )),
    ]);
  }

  Widget _logoScene() {
    final pop = _part(0, 0.7, Curves.elasticOut);
    final rest = _part(0.35, 1);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: _a,
        builder: (_, child) => Transform.scale(scale: pop.value.clamp(0.0, 1.3), child: child),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Image.asset('assets/images/icon.png', width: 120, height: 120),
        ),
      ),
      const SizedBox(height: 22),
      FadeTransition(opacity: rest, child: Column(children: [
        const Text('Habesha Hub', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(tr('Your Habesha world in one app'), textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 17)),
        const SizedBox(height: 28),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _brand,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
          onPressed: _finish,
          child: Text(tr('Start'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
      ])),
    ]);
  }
}
