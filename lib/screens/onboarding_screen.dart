import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../utils/theme_notifier.dart';
import '../utils/translations.dart';
import 'home_screen.dart';
import 'user_guide_screen.dart';

/// Shown once (and once more after big updates, see [kOnboardingKey]):
/// what the app can do, with the language chosen on the first page.
const kOnboardingKey = 'onboarding_v2_done';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  List<(IconData, Color, Color, String, String)> get _pages => [
        (Icons.waving_hand_outlined, kTintGreen, kInkGreen, 'Welcome to Habesha Hub',
            'Your Habesha community in one app. Choose your language:'),
        (Icons.place_outlined, kTintRed, kInkRed, 'Find Habesha places and services',
            'Restaurants, shops, barbers and churches near you, and trusted services like photographers and transport that you can book.'),
        (Icons.shopping_bag_outlined, kTintBlue, kInkBlue, 'Buy, sell, swap and rent',
            'The Market for second-hand things and zuria, and Home shops for injera, spices, coffee and crafts made by our community.'),
        (Icons.chat_bubble_outline_rounded, kTintYellow, kInkYellow, 'Ask Habesha AI',
            'Write, speak or send a photo – in Tigrinya, Amharic or English. It can even post your listing for you.'),
        (Icons.sports_esports_outlined, kTintGreen, kInkGreen, 'Play and learn',
            'Dama, Genna, racing and riddles, driving theory in Tigrinya, and trusted partners to send money home.'),
      ];

  static const _langs = [('English', 'English'), ('Tigrinya', 'ትግርኛ'), ('Amharic', 'አማርኛ')];

  Future<void> _finish({bool guide = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await prefs.setBool(kOnboardingKey, true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    if (guide) Navigator.push(context, MaterialPageRoute(builder: (_) => const UserGuideScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (_, __) {
        final pages = _pages;
        final last = _page == pages.length - 1;
        return Scaffold(
          backgroundColor: kBg,
          body: SafeArea(
            child: Column(children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(languageNotifier.t('skip'), style: tsTitleMd(color: kTextSub)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: pages.length,
                  itemBuilder: (_, i) {
                    final p = pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        if (i == 0) ...[habeshaLogo(size: 96), const SizedBox(height: 28)]
                        else ...[
                          Container(
                            width: 120, height: 120,
                            decoration: BoxDecoration(color: p.$2, shape: BoxShape.circle),
                            child: Icon(p.$1, size: 54, color: p.$3),
                          ),
                          const SizedBox(height: 32),
                        ],
                        Text(tr(p.$4), textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: kFontHeadline, fontSize: 28, height: 1.2,
                                fontWeight: FontWeight.w800, color: kText)),
                        const SizedBox(height: 14),
                        Text(tr(p.$5), textAlign: TextAlign.center, style: tsBodyLg(color: kTextSub).copyWith(fontSize: 16)),
                        if (i == 0) ...[
                          const SizedBox(height: 24),
                          Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                            for (final l in _langs)
                              ChoiceChip(
                                label: Text(l.$2),
                                selected: languageNotifier.language == l.$1,
                                onSelected: (_) => languageNotifier.setLanguage(l.$1),
                                showCheckmark: false,
                                selectedColor: kSecondary,
                                labelStyle: tsTitleMd(color: languageNotifier.language == l.$1 ? kOnAccent : kText)
                                    .copyWith(fontSize: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                          ]),
                        ],
                      ]),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: _page == i ? kSecondary : kCardHigh, borderRadius: BorderRadius.circular(100)),
                    )),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: goldButton(last ? languageNotifier.t('get_started') : languageNotifier.t('next'), () {
                  if (last) {
                    _finish();
                  } else {
                    _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }
                }),
              ),
              SizedBox(
                height: 48,
                child: last
                    ? TextButton(
                        onPressed: () => _finish(guide: true),
                        child: Text(tr('See how to use the app'), style: tsTitleMd(color: kSecondary)))
                    : null,
              ),
              const SizedBox(height: 16),
            ]),
          ),
        );
      },
    );
  }
}
