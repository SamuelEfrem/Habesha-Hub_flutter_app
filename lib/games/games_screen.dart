import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../utils/translations.dart';
import 'game_webview_screen.dart';
import 'purchase_service.dart';

/// Games & Life Tools. The games are web pages on Firebase Hosting
/// (public/games/…), so they can be updated without a new app release.
///  - Habesha Games: racing 3D, Dama, Gebeta, Genna, riddles
///  - ሓገዝ ሂወት · Life Tools: driving theory (Tigrinya), languages, Ge'ez calendar
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  static const String baseUrl = 'https://habesha-hub.no/games';

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  @override
  void initState() {
    super.initState();
    PurchaseService.instance.init();
  }

  String get _lang => languageNotifier.language == 'Tigrinya'
      ? 'ti'
      : languageNotifier.language == 'Amharic' ? 'am' : 'en';

  Uri _url(String page) {
    final name = FirebaseAuth.instance.currentUser?.displayName ?? '';
    final owned = PurchaseService.instance.owned;
    return Uri.parse('${GamesScreen.baseUrl}/$page/').replace(queryParameters: {
      'app': '1',
      'lang': _lang,
      if (name.isNotEmpty) 'name': name,
      if (owned.isNotEmpty) 'pro': owned.join(','),
    });
  }

  void _open(String title, String page) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameWebViewScreen(title: title, url: _url(page)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Text(tr('Games & Tools'), style: tsHeadlineSm(color: kText)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _BigCard(
            emoji: '🎮',
            title: 'Habesha Games · ጸወታታት',
            subtitle: tr('Racing 3D, Dama, Gebeta, Genna and riddles. Play the computer, a friend or anyone online.'),
            tags: const ['🏎️ Racing 3D', '⚫ Dama', '🪨 Gebeta', '🏑 Genna', '❓'],
            colors: const [Color(0xFF8B0000), Color(0xFF3A0A0A)],
            onTap: () => _open('Habesha Games', 'hub'),
          ),
          const SizedBox(height: 14),
          _BigCard(
            emoji: '💡',
            title: 'ሓገዝ ሂወት · Life Tools',
            subtitle: tr('300 driving theory questions with road signs (Tigrinya), learn languages and the Ge\'ez calendar.'),
            tags: const ['🚗 Theory B', '🗣️ 10+', '📅 Ge\'ez'],
            colors: const [Color(0xFF6B5A12), Color(0xFF2A2408)],
            onTap: () => _open('Life Tools', 'life-tools'),
          ),
          const SizedBox(height: 22),
          Center(
            child: TextButton.icon(
              onPressed: () => PurchaseService.instance.restore(),
              icon: Icon(Icons.restore_rounded, color: kTextSub, size: 18),
              label: Text(tr('Restore purchases'), style: tsBodySm(color: kTextSub)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final List<String> tags;
  final List<Color> colors;
  final VoidCallback onTap;
  const _BigCard({required this.emoji, required this.title, required this.subtitle,
      required this.tags, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: kSecondary.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.25), borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: tsTitleLg(color: Colors.white).copyWith(fontSize: 18))),
              const Icon(Icons.play_circle_fill_rounded, color: kSecondary, size: 34),
            ]),
            const SizedBox(height: 12),
            Text(subtitle, style: tsBodySm(color: Colors.white70).copyWith(fontSize: 13.5)),
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final t in tags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(100)),
                  child: Text(t, style: const TextStyle(fontFamily: kFontBody, fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
