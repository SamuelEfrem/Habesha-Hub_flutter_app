import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _pages = [
    {
      'emoji': '🌍',
      'title_key': 'onboard_1_title',
      'desc_key': 'onboard_1_desc',
    },
    {
      'emoji': '🍽️',
      'title_key': 'onboard_2_title',
      'desc_key': 'onboard_2_desc',
    },
    {
      'emoji': '💬',
      'title_key': 'onboard_3_title',
      'desc_key': 'onboard_3_desc',
    },
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        return Scaffold(
          backgroundColor: kSurface,
          body: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: TibebPainter())),
            SafeArea(
              child: Column(children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(t('skip'), style: tsBodySm(color: kOnSurfaceVariant)),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) {
                      final p = _pages[i];
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(p['emoji']!, style: const TextStyle(fontSize: 80)),
                            const SizedBox(height: 32),
                            Text(t(p['title_key']!),
                                style: tsHeadlineMd(color: kSecondary),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            Text(t(p['desc_key']!),
                                style: tsBodyLg(color: kOnSurfaceVariant),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i ? kSecondary : kSurfaceContainer,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  )),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: goldButton(
                    _page == _pages.length - 1 ? t('get_started') : t('next'),
                    () {
                      if (_page == _pages.length - 1) {
                        _finish();
                      } else {
                        _ctrl.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ]),
        );
      },
    );
  }
}