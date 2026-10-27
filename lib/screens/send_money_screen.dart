import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'services_screen.dart' show openVideo;

// ═══════════════════════════════════════════════════════════
// SEND MONEY HOME — links to licensed money transfer companies.
// Habesha Hub never handles the money itself.
//
// Links can be changed WITHOUT a new app version in Firestore:
//   settings/remittance  →  { dahabshiil: "https://…", ria: "https://…", remitly: "https://…",
//                             remitly_offer: "<offer text exactly as Remitly gives it>",
//                             remitly_disclaimer: "<Remitly's offer disclaimer, verbatim>",
//                             remitly_code: "AMB9K9",
//                             remitly_code_enabled: true,      // only after Remitly OKs the code in the app
//                             remitly_help_video: "https://vz-…/playlist.m3u8" }   // your own how-to video
// (put your referral / affiliate links there when you get them)
// Remitly Ambassador rules: every Remitly mention must be labelled
// "#Ad - paid #RemitlyAmbassador", no "free/cheapest/fastest/best" claims,
// no Remitly logo without written approval.
// ═══════════════════════════════════════════════════════════

String _l(String en, String ti, String am) {
  final l = languageNotifier.language;
  return l == 'Tigrinya' ? ti : l == 'Amharic' ? am : en;
}

class _Provider {
  final String key;          // dahabshiil / ria / remitly
  final String name;
  final String emoji;
  final String defaultUrl;
  const _Provider(this.key, this.name, this.emoji, this.defaultUrl);
}

const _dahabshiil = _Provider('dahabshiil', 'Dahabshiil', '🟢', 'https://www.dahabshiil.com');
const _ria        = _Provider('ria',        'Ria',        '🟠', 'https://www.riamoneytransfer.com');
const _remitly    = _Provider('remitly',    'Remitly',    '🔵', 'https://www.remitly.com');

class _Route {
  final _Provider provider;
  final List<String> methods;   // shown as chips
  const _Route(this.provider, this.methods);
}

class _Country {
  final String code, flag, en, ti, am;
  final List<_Route> routes;
  const _Country(this.code, this.flag, this.en, this.ti, this.am, this.routes);
}

const _countries = [
  _Country('ET', '🇪🇹', 'Ethiopia', 'ኢትዮጵያ', 'ኢትዮጵያ', [
    _Route(_dahabshiil, ['cash']),
  ]),
  _Country('UG', '🇺🇬', 'Uganda', 'ኡጋንዳ', 'ኡጋንዳ', [
    _Route(_ria,        ['cash', 'mobile']),
    _Route(_dahabshiil, ['cash']),
  ]),
  _Country('ER', '🇪🇷', 'Eritrea', 'ኤርትራ', 'ኤርትራ', [
    _Route(_remitly, []),
  ]),
];

String _methodLabel(String m) {
  switch (m) {
    case 'cash':   return _l('💵 Cash pickup', '💵 ጥረ ገንዘብ ምውሳድ', '💵 በጥሬ ገንዘብ መቀበል');
    case 'mobile': return _l('📱 Mobile money', '📱 ሞባይል ገንዘብ', '📱 ሞባይል ገንዘብ');
    case 'bank':   return _l('🏦 Bank', '🏦 ባንኪ', '🏦 ባንክ');
  }
  return m;
}

class SendMoneyScreen extends StatelessWidget {
  const SendMoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) => DefaultTabController(
        length: _countries.length,
        child: Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            backgroundColor: kCard,
            iconTheme: const IconThemeData(color: kSecondary),
            title: Text(_l('Send money home', 'ገንዘብ ናብ ዓዲ ስደዱ', 'ገንዘብ ወደ አገር ቤት ይላኩ'),
                style: tsTitleMd(color: kSecondary)),
            bottom: TabBar(
              indicatorColor: kSecondary,
              labelColor: kSecondary,
              unselectedLabelColor: kTextSub,
              tabs: [
                for (final c in _countries)
                  Tab(text: '${c.flag} ${_l(c.en, c.ti, c.am)}'),
              ],
            ),
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('settings').doc('remittance').snapshots(),
            builder: (_, snap) {
              final links = (snap.data?.data() as Map<String, dynamic>?) ?? const {};
              return TabBarView(children: [
                for (final c in _countries) _CountryTab(country: c, links: links),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class _CountryTab extends StatelessWidget {
  final _Country country;
  final Map<String, dynamic> links;
  const _CountryTab({required this.country, required this.links});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: kSecondary.withOpacity(0.12), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kSecondary.withOpacity(0.5))),
        child: Text(
          _l('AD – Habesha Hub may be paid when you use these links.',
             'ማስታወቒያ – Habesha Hub ነዞም መላግቦታት ክትጥቀሙ ከለኹም ክኽፈል ይኽእል።',
             'ማስታወቂያ – Habesha Hub እነዚህን አገናኞች ሲጠቀሙ ክፍያ ሊያገኝ ይችላል።'),
          style: tsBodySm(color: kText).copyWith(fontWeight: FontWeight.w700)),
      ),
      Text(
        _l('Send money to ${country.en} with a licensed company. You pay and track the transfer in their app — Habesha Hub never handles your money.',
           'ብፍቑድ ትካል ናብ ${country.ti} ገንዘብ ስደዱ። ክፍሊትን ምክትታልን ኣብ ናቶም ኣፕ እዩ — Habesha Hub ገንዘብኩም ኣይሕዝን እዩ።',
           'ፈቃድ ባለው ድርጅት ወደ ${country.am} ገንዘብ ይላኩ። ክፍያውንና ክትትሉን በእነሱ መተግበሪያ ያደርጋሉ — Habesha Hub ገንዘብዎን አይይዝም።'),
        style: tsBodySm(),
      ),
      const SizedBox(height: 16),
      for (final r in country.routes) _ProviderCard(route: r, links: links),
      if (country.routes.any((r) => r.provider.key == 'remitly')) _RemitlyHelp(links: links),
      const SizedBox(height: 8),
      Text(
        _l('Fees and exchange rates vary by amount, route and delivery option – they are shown in the app before you send.',
           'ክፍሊትን ዋጋ ምንዛሪን ብመጠን፡ መንገድን ኣገባብ ምብጻሕን ይፈላለ – ቅድሚ ምልኣኽኩም ኣብ ኣፕ ይርአ።',
           'ክፍያና የምንዛሬ ተመን እንደ መጠኑ፣ መስመሩና የመቀበያ መንገዱ ይለያያል – ከመላክዎ በፊት በመተግበሪያው ይታያል።'),
        style: tsBodySm(color: kTextSub).copyWith(fontSize: 11),
      ),
    ]);
  }
}

class _ProviderCard extends StatelessWidget {
  final _Route route;
  final Map<String, dynamic> links;
  const _ProviderCard({required this.route, required this.links});

  @override
  Widget build(BuildContext context) {
    final p = route.provider;
    final custom = (links[p.key] ?? '').toString().trim();
    final url = custom.startsWith('https://') ? custom : p.defaultUrl;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSecondary.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (p.key == 'remitly') ...[
          Text(_l('#Ad - paid #RemitlyAmbassador', '#ማስታወቒያ - ክፍሊት ዘለዎ #RemitlyAmbassador', '#ማስታወቂያ - የተከፈለ #RemitlyAmbassador'),
              style: tsBodySm(color: kSecondary).copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
        ],
        Row(children: [
          Text(p.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Text(p.name, style: tsHeadlineSm())),
        ]),
        const SizedBox(height: 10),
        if (p.key == 'remitly') ...[
          if ((links['remitly_offer'] ?? '').toString().trim().isNotEmpty) ...[
            Text(links['remitly_offer'].toString().trim(), style: tsBodySm(color: kText)),
            const SizedBox(height: 4),
          ],
          if ((links['remitly_disclaimer'] ?? '').toString().trim().isNotEmpty) ...[
            Text(links['remitly_disclaimer'].toString().trim(), style: tsBodySm(color: kTextSub).copyWith(fontSize: 10)),
            const SizedBox(height: 6),
          ],
          Text(_l('Check in the Remitly app that sending from your country is supported.',
                  'ካብ ሃገርኩም ምልኣኽ ከም ዝከኣል ኣብ Remitly ኣፕ ኣረጋግጹ።',
                  'ከአገርዎ መላክ መቻሉን በ Remitly መተግበሪያ ያረጋግጡ።'),
              style: tsBodySm(color: kTextSub)),
          const SizedBox(height: 8),
        ],
        if (route.methods.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in route.methods)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(100)),
                child: Text(_methodLabel(m), style: tsBodySm(color: kText)),
              ),
          ])
        else
          Text(_l('See delivery options in the app', 'ኣማራጺታት ምብጻሕ ኣብ ኣፕ ርኣዩ', 'የመቀበያ አማራጮችን በመተግበሪያው ይመልከቱ'),
              style: tsBodySm(color: kTextSub)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.send_rounded, color: Color(0xFF1A1200), size: 18),
            label: Text(_l('Send with ${p.name}', 'ብ ${p.name} ስደዱ', 'በ ${p.name} ይላኩ'),
                style: tsTitleMd(color: const Color(0xFF1A1200))),
            style: ElevatedButton.styleFrom(
              backgroundColor: kSecondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// REMITLY HELP — step-by-step guide, offer code, how-to video,
// "Open Remitly" and personal help on WhatsApp.
// ═══════════════════════════════════════════════════════════
const _helpWhatsApp = '4797374482';   // Habesha Hub (Norway)

class _RemitlyHelp extends StatelessWidget {
  final Map<String, dynamic> links;
  const _RemitlyHelp({required this.links});

  String _str(String k) => (links[k] ?? '').toString().trim();

  Future<void> _openRemitly() async {
    final custom = _str('remitly');
    if (custom.startsWith('https://')) {
      await launchUrl(Uri.parse(custom), mode: LaunchMode.externalApplication);
      return;
    }
    // Android: Play Store page shows "Open" if the app is installed, "Install" if not.
    final uri = defaultTargetPlatform == TargetPlatform.android
        ? Uri.parse('https://play.google.com/store/apps/details?id=com.remitly.androidapp')
        : Uri.parse('https://www.remitly.com');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _whatsAppHelp() async {
    final msg = _l(
      'Hi Habesha Hub! I need help to register and send money with Remitly.',
      'ሰላም Habesha Hub! ብ Remitly ንምምዝጋብን ገንዘብ ንምልኣኽን ሓገዝ የድልየኒ።',
      'ሰላም Habesha Hub! በ Remitly ለመመዝገብና ገንዘብ ለመላክ እርዳታ እፈልጋለሁ።');
    await launchUrl(Uri.parse('https://wa.me/$_helpWhatsApp?text=${Uri.encodeComponent(msg)}'),
        mode: LaunchMode.externalApplication);
  }

  Widget _step(String n, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 26, height: 26, alignment: Alignment.center,
        decoration: const BoxDecoration(color: kSecondary, shape: BoxShape.circle),
        child: Text(n, style: const TextStyle(color: Color(0xFF1A1200), fontWeight: FontWeight.w800))),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: tsBodySm(color: kText))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final code = _str('remitly_code');
    final showCode = links['remitly_code_enabled'] == true && code.isNotEmpty;
    final offer = _str('remitly_offer');
    final disclaimer = _str('remitly_disclaimer');
    final video = _str('remitly_help_video');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kSecondary.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_l('How to send with Remitly', 'ከመይ ብ Remitly ትልእኹ', 'በ Remitly እንዴት እንደሚላክ'),
            style: tsTitleMd(color: kSecondary)),
        const SizedBox(height: 12),

        // ── New customers: code + offer (only when enabled) ──
        if (showCode) ...[
          Text(_l('#Ad - paid #RemitlyAmbassador', '#ማስታወቒያ - ክፍሊት ዘለዎ #RemitlyAmbassador', '#ማስታወቂያ - የተከፈለ #RemitlyAmbassador'),
              style: tsBodySm(color: kSecondary).copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(_l('New to Remitly? Use this code when you sign up:',
                  'ሓድሽ ተጠቃሚ Remitly ዲኹም? ክትምዝገቡ ከለኹም እዚ ኮድ ተጠቐሙ፦',
                  'አዲስ የ Remitly ተጠቃሚ ነዎት? ሲመዘገቡ ይህን ኮድ ይጠቀሙ፦'),
              style: tsBodySm(color: kText)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_l('Code copied', 'ኮድ ተቐዲሑ', 'ኮዱ ተቀድቷል'))));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kSecondary)),
              child: Row(children: [
                Expanded(child: Text(code, style: tsHeadlineSm(color: kSecondary).copyWith(letterSpacing: 3))),
                const Icon(Icons.copy_rounded, color: kSecondary, size: 20),
                const SizedBox(width: 6),
                Text(_l('Copy', 'ቕዳሕ', 'ቅዳ'), style: tsBodySm(color: kSecondary)),
              ]),
            ),
          ),
          if (offer.isNotEmpty) ...[const SizedBox(height: 8), Text(offer, style: tsBodySm(color: kText))],
          if (disclaimer.isNotEmpty) ...[const SizedBox(height: 4),
            Text(disclaimer, style: tsBodySm(color: kTextSub).copyWith(fontSize: 10))],
          const SizedBox(height: 6),
          Text(_l('The code is only for new Remitly customers.', 'እዚ ኮድ ንሓደስቲ ተጠቀምቲ Remitly ጥራይ እዩ።', 'ኮዱ ለአዲስ የ Remitly ደንበኞች ብቻ ነው።'),
              style: tsBodySm(color: kTextSub)),
          const SizedBox(height: 14),
        ],

        // ── Steps ──
        Text(_l('New customer', 'ሓድሽ ተጠቃሚ', 'አዲስ ደንበኛ'), style: tsLabel()),
        const SizedBox(height: 8),
        _step('1', _l('Tap "Open Remitly" and install the app.', '"Remitly ክፈት" ጠውቑ እሞ ኣፕ ኣውርዱ።', '"Remitly ክፈት" ይንኩና መተግበሪያውን ይጫኑ።')),
        _step('2', _l(showCode ? 'Sign up with your email and enter the code above.' : 'Sign up with your email.',
                      showCode ? 'ብኢመይልኩም ተመዝገቡ እሞ ላዕሊ ዘሎ ኮድ ኣእትዉ።' : 'ብኢመይልኩም ተመዝገቡ።',
                      showCode ? 'በኢሜይልዎ ይመዝገቡና ከላይ ያለውን ኮድ ያስገቡ።' : 'በኢሜይልዎ ይመዝገቡ።')),
        _step('3', _l('Verify your identity with your ID when Remitly asks.', 'Remitly ምስ ዝሓተኩም መንነትኩም ብመንነት ወረቐት ኣረጋግጹ።', 'Remitly ሲጠይቅ ማንነትዎን በመታወቂያዎ ያረጋግጡ።')),
        _step('4', _l('Add the receiver, choose cash pickup, mobile money or bank, and send.', 'ተቐባላይ ወስኹ፡ ጥረ ገንዘብ፡ ሞባይል ገንዘብ ወይ ባንኪ ምረጹ እሞ ስደዱ።', 'ተቀባዩን ያክሉ፣ በጥሬ ገንዘብ፣ ሞባይል ገንዘብ ወይም ባንክ ይምረጡና ይላኩ።')),
        const SizedBox(height: 4),
        Text(_l('Already a Remitly customer? Just open the app and send.',
                'ቅድሚ ሕጂ Remitly ትጥቀሙ ዲኹም? ኣፕ ክፈቱ እሞ ስደዱ።',
                'ቀድሞ የ Remitly ደንበኛ ነዎት? መተግበሪያውን ይክፈቱና ይላኩ።'),
            style: tsBodySm(color: kTextSub)),
        const SizedBox(height: 14),

        // ── Buttons ──
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _openRemitly,
          icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF1A1200), size: 18),
          label: Text(_l('Open Remitly', 'Remitly ክፈት', 'Remitly ክፈት'), style: tsTitleMd(color: const Color(0xFF1A1200))),
          style: ElevatedButton.styleFrom(backgroundColor: kSecondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
        if (video.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _HelpVideoScreen(url: video))),
            icon: const Icon(Icons.play_circle_rounded, color: kSecondary),
            label: Text(_l('Watch how it works', 'ከመይ ከም ዝሰርሕ ርኣዩ', 'እንዴት እንደሚሰራ ይመልከቱ'), style: tsTitleMd(color: kSecondary)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: kSecondary.withOpacity(0.6)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
        ],
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _whatsAppHelp,
          icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
          label: Text(_l('Need help? Chat on WhatsApp', 'ሓገዝ የድልየኩም? ብ WhatsApp ተዛረቡ', 'እርዳታ ይፈልጋሉ? በ WhatsApp ያውሩ'),
              style: tsTitleMd(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
        const SizedBox(height: 8),
        Text(_l('We guide you step by step. Never share your password or card details with anyone – also not with us.',
                'ስጉምቲ ብስጉምቲ ንመርሓኩም። ፓስዎርድኩም ወይ ካርድኩም ንማንም ኣይተካፍሉ – ንዓና እውን።',
                'ደረጃ በደረጃ እንመራዎታለን። የይለፍ ቃልዎን ወይም የካርድ መረጃዎን ለማንም አያጋሩ – ለእኛም ጭምር።'),
            style: tsBodySm(color: kTextSub).copyWith(fontSize: 11)),
      ]),
    );
  }
}

/// Plays the how-to video (Bunny Stream link) inside the app.
class _HelpVideoScreen extends StatefulWidget {
  final String url;
  const _HelpVideoScreen({required this.url});
  @override
  State<_HelpVideoScreen> createState() => _HelpVideoScreenState();
}

class _HelpVideoScreenState extends State<_HelpVideoScreen> {
  VideoPlayerController? _vpc;
  ChewieController? _chc;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    openVideo(widget.url).then((c) {
      if (!mounted) { c.dispose(); return; }
      setState(() {
        _vpc = c;
        _chc = ChewieController(videoPlayerController: c, autoPlay: true,
            aspectRatio: c.value.aspectRatio, allowFullScreen: true);
      });
    }).catchError((_) { if (mounted) setState(() => _error = true); });
  }

  @override
  void dispose() { _chc?.dispose(); _vpc?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
    body: Center(child: _error
        ? Text(_l('Could not load the video', 'ቪድዮ ክጽዓን ኣይከኣለን', 'ቪዲዮውን መጫን አልተቻለም'), style: const TextStyle(color: Colors.white))
        : _chc == null
            ? const CircularProgressIndicator(color: kSecondary)
            : Chewie(controller: _chc!)),
  );
}
