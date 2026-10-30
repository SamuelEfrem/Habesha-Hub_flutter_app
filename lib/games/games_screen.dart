import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../utils/translations.dart';
import 'game_webview_screen.dart';
import 'purchase_service.dart';

/// Games & Life Tools. The games are web pages on Firebase Hosting
/// (public/games/…), so they can be updated without a new app release.
///  - Habesha Games: racing 3D, Dama, Genna, riddles
///  - ሓገዝ ሂወት · Life Tools: driving theory (Tigrinya), languages, Ge'ez calendar
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  static const String baseUrl = 'https://habesha-hub.no/games';

  /// Opens one of the web pages (hub, life-tools, driving …) inside the app
  static void openPage(BuildContext context, String title, String page) {
    final lang = languageNotifier.language == 'Tigrinya'
        ? 'ti'
        : languageNotifier.language == 'Amharic' ? 'am' : 'en';
    final name = FirebaseAuth.instance.currentUser?.displayName ?? '';
    final owned = PurchaseService.instance.owned;
    final url = Uri.parse('$baseUrl/$page/').replace(queryParameters: {
      'app': '1',
      'lang': lang,
      if (name.isNotEmpty) 'name': name,
      if (owned.isNotEmpty) 'pro': owned.join(','),
    });
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GameWebViewScreen(title: title, url: url),
    ));
  }

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
        iconTheme: IconThemeData(color: kSecondary),
        title: Text(tr('Games & Tools'), style: tsHeadlineSm(color: kText)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _BigCard(
            icon: Icons.sports_esports_outlined,
            title: 'Habesha Games · ጸወታታት',
            subtitle: tr('Racing 3D, Dama, Genna and riddles. Play the computer, a friend or anyone online.'),
            tags: const ['Racing 3D', 'Dama', 'Genna', 'ሕንቅልሕንቅሊተይ'],
            tint: kTintGreen, ink: kInkGreen,
            onTap: () => _open('Habesha Games', 'hub'),
          ),
          const SizedBox(height: 14),
          _BigCard(
            icon: Icons.directions_car_outlined,
            title: 'ሓገዝ ሂወት · Life Tools',
            subtitle: tr("500 driving theory questions and a practical driving test with a voice instructor (Tigrinya), languages, newcomer guides and the Ge'ez calendar."),
            tags: const ['Theory B', 'Driving test', '10+ languages', "Ge'ez calendar"],
            tint: kTintYellow, ink: kInkYellow,
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
  final IconData icon;
  final String title, subtitle;
  final List<String> tags;
  final Color tint, ink;
  final VoidCallback onTap;
  const _BigCard({required this.icon, required this.title, required this.subtitle,
      required this.tags, required this.tint, required this.ink, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: kBg, shape: BoxShape.circle),
                child: Icon(icon, color: ink, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: tsTitleLg(color: kText).copyWith(fontSize: 18, fontWeight: FontWeight.w800))),
              Icon(Icons.arrow_forward_rounded, color: kText, size: 24),
            ]),
            const SizedBox(height: 12),
            Text(subtitle, style: tsBodySm(color: kText).copyWith(fontSize: 14, height: 1.45)),
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final t in tags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(100)),
                  child: Text(t, style: TextStyle(fontFamily: kFontBody, fontSize: 12, fontWeight: FontWeight.w600, color: kText)),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
