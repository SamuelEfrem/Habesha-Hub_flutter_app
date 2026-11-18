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
// SEND MONEY HOME — Remitly (our partner today) + help to sign up.
// Habesha Hub never handles the money itself.
//
// Can be changed WITHOUT a new app version in Firestore:
//   settings/remittance  →  { remitly: "https://…",                 // your ambassador link
//                             remitly_offer: "<offer text exactly as Remitly gives it>",
//                             remitly_disclaimer: "<Remitly's offer disclaimer, verbatim>",
//                             remitly_code: "AMB9K9",               // default AMB9K9
//                             remitly_code_enabled: false,          // hides the code
//                             remitly_help_video: "https://vz-…/playlist.m3u8" }
// Remitly Ambassador rules: every Remitly mention must be labelled
// "#Ad - paid #RemitlyAmbassador", no "free/cheapest/fastest/best" claims,
// no Remitly logo without written approval.
// Other partners (e.g. for sending from Saudi Arabia) are waiting for approval: shown as "coming soon".
// ═══════════════════════════════════════════════════════════

String _l(String en, String ti, String am) {
  final l = languageNotifier.language;
  return l == 'Tigrinya' ? ti : l == 'Amharic' ? am : en;
}

/// Countries many Habesha send money to (check each route in the Remitly app)
const _sendTo = [
  ('🇪🇹', 'Ethiopia', 'ኢትዮጵያ', 'ኢትዮጵያ'),
  ('🇪🇷', 'Eritrea', 'ኤርትራ', 'ኤርትራ'),
  ('🇺🇬', 'Uganda', 'ኡጋንዳ', 'ኡጋንዳ'),
  ('🇰🇪', 'Kenya', 'ኬንያ', 'ኬንያ'),
  ('🇪🇬', 'Egypt', 'ግብጺ', 'ግብጽ'),
];

const _defaultCode = 'AMB9K9';
const _helpWhatsApp = '4797374482';   // Habesha Hub (Norway)

class SendMoneyScreen extends StatelessWidget {
  const SendMoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kCard,
          iconTheme: IconThemeData(color: kSecondary),
          title: Text(_l('Send money home', 'ገንዘብ ናብ ዓዲ ስደዱ', 'ገንዘብ ወደ አገር ቤት ይላኩ'),
              style: tsTitleMd(color: kSecondary)),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('settings').doc('remittance').snapshots(),
          builder: (_, snap) {
            final links = (snap.data?.data() as Map<String, dynamic>?) ?? const {};
            return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: kSecondary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(_l('#Ad - paid #RemitlyAmbassador', '#ማስታወቒያ - ክፍሊት ዘለዎ #RemitlyAmbassador', '#ማስታወቂያ - የተከፈለ #RemitlyAmbassador'),
                    style: tsBodySm(color: kText).copyWith(fontWeight: FontWeight.w700)),
              ),
              Text(
                _l('Send money to your family with Remitly, a licensed company. You pay and follow the transfer in the Remitly app. Habesha Hub never handles your money.',
                   'ብRemitly፡ ፍቑድ ትካል፡ ናብ ስድራኹም ገንዘብ ስደዱ። ክፍሊትን ምክትታልን ኣብ Remitly ኣፕ እዩ። Habesha Hub ገንዘብኩም ኣይሕዝን እዩ።',
                   'ፈቃድ ባለው Remitly ለቤተሰብዎ ገንዘብ ይላኩ። ክፍያውንና ክትትሉን በRemitly መተግበሪያ ያደርጋሉ። Habesha Hub ገንዘብዎን አይይዝም።'),
                style: tsBodySm(color: kText),
              ),
              const SizedBox(height: 14),
              _SendToCard(),
              const SizedBox(height: 14),
              _RemitlyHelp(links: links),
              _ComingSoonCard(),
              const SizedBox(height: 8),
              Text(
                _l('Fees and exchange rates vary by amount, country and delivery option. They are shown in the Remitly app before you send.',
                   'ክፍሊትን ዋጋ ምንዛሪን ብመጠን፡ ሃገርን ኣገባብ ምብጻሕን ይፈላለ። ቅድሚ ምልኣኽኩም ኣብ Remitly ኣፕ ይርአ።',
                   'ክፍያና የምንዛሬ ተመን እንደ መጠኑ፣ አገሩና የመቀበያ መንገዱ ይለያያል። ከመላክዎ በፊት በRemitly መተግበሪያ ይታያል።'),
                style: tsBodySm(color: kTextSub).copyWith(fontSize: 11),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

/// Where you can send to (flags), plus a note to check the route in the app
class _SendToCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_l('Send to', 'ናበይ ትሰዱ', 'ወደየት ይላካል'), style: tsTitleMd(color: kSecondary)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in _sendTo)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(100)),
              child: Text('${c.$1} ${_l(c.$2, c.$3, c.$4)}', style: tsBodySm(color: kText).copyWith(fontWeight: FontWeight.w600)),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(100)),
            child: Text(_l('🌍 and many more', '🌍 ካልኦት ብዙሓት', '🌍 እና ሌሎች ብዙ'), style: tsBodySm(color: kText)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(_l('Cash pickup, mobile money or bank – it depends on the country. Check in the Remitly app that sending from your country to theirs is supported.',
                'ጥረ ገንዘብ፡ ሞባይል ገንዘብ ወይ ባንኪ – ከከም ሃገሩ ይፈላለ። ካብ ሃገርኩም ናብ ሃገሮም ምልኣኽ ከም ዝከኣል ኣብ Remitly ኣፕ ኣረጋግጹ።',
                'በጥሬ ገንዘብ፣ በሞባይል ገንዘብ ወይም በባንክ – እንደ አገሩ ይለያያል። ከአገርዎ ወደ አገራቸው መላክ መቻሉን በRemitly መተግበሪያ ያረጋግጡ።'),
            style: tsBodySm(color: kTextSub)),
      ]),
    );
  }
}

/// Other partners are waiting for approval: no service yet
class _ComingSoonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('⏳', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_l('More partners coming soon', 'ተወሳኺ መሻርኽቲ ቀረባ', 'ተጨማሪ አጋሮች በቅርቡ'), style: tsTitleMd(color: kText)),
          const SizedBox(height: 4),
          Text(_l('We are waiting for approval from other partners, for example to send from Saudi Arabia and other countries where Remitly does not work. No service yet, but we will be glad to help you soon.',
                  'ካብ ካልኦት መሻርኽቲ ፍቓድ ንጽበ ኣለና፡ ንኣብነት ካብ ሳዑዲ ዓረብን Remitly ዘይሰርሓሉ ካልኦት ሃገራትን ንምልኣኽ። ገና ኣገልግሎት የለን፡ ግን ቀረባ ክንሕግዘኩም ደስ ክብለና እዩ።',
                  'ከሌሎች አጋሮች ፈቃድ እየጠበቅን ነው፣ ለምሳሌ ከሳውዲ አረቢያና Remitly ከማይሰራባቸው ሌሎች አገሮች ለመላክ። ገና አገልግሎት የለም፣ ግን በቅርቡ ልንረዳዎ ደስተኞች ነን።'),
              style: tsBodySm(color: kTextSub)),
        ])),
      ]),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// REMITLY — code, what you get / what we get, do it yourself
// or with our help on a WhatsApp video call (screen share).
// ═══════════════════════════════════════════════════════════
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
      'Hi Habesha Hub! I need help to register with Remitly. Can we do a WhatsApp video call?',
      'ሰላም Habesha Hub! ኣብ Remitly ንምምዝጋብ ሓገዝ የድልየኒ። ብWhatsApp ቪድዮ ክንዛረብ ንኽእል ዶ?',
      'ሰላም Habesha Hub! በRemitly ለመመዝገብ እርዳታ እፈልጋለሁ። በWhatsApp ቪዲዮ ጥሪ ማውራት እንችላለን?');
    await launchUrl(Uri.parse('https://wa.me/$_helpWhatsApp?text=${Uri.encodeComponent(msg)}'),
        mode: LaunchMode.externalApplication);
  }

  Widget _step(String n, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 26, height: 26, alignment: Alignment.center,
        decoration: BoxDecoration(color: kSecondary, shape: BoxShape.circle),
        child: Text(n, style: TextStyle(color: kOnAccent, fontWeight: FontWeight.w800))),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: tsBodySm(color: kText))),
    ]),
  );

  Widget _info(String emoji, String title, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: tsBodySm(color: kText).copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(text, style: tsBodySm(color: kTextSub)),
      ])),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final code = _str('remitly_code').isEmpty ? _defaultCode : _str('remitly_code');
    final showCode = links['remitly_code_enabled'] != false;
    final offer = _str('remitly_offer');
    final disclaimer = _str('remitly_disclaimer');
    final video = _str('remitly_help_video');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🔵', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Text('Remitly', style: tsHeadlineSm())),
        ]),
        const SizedBox(height: 12),

        // ── New customers: our code ──
        if (showCode) ...[
          Text(_l('New to Remitly? Use our code:', 'ሓድሽ ኣብ Remitly ዲኹም? ኮድና ተጠቐሙ፦', 'ለRemitly አዲስ ነዎት? ኮዳችንን ይጠቀሙ፦'),
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
                Icon(Icons.copy_rounded, color: kSecondary, size: 20),
                const SizedBox(width: 6),
                Text(_l('Copy', 'ቕዳሕ', 'ቅዳ'), style: tsBodySm(color: kSecondary)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── What you get / what we get ──
        _info('🎁', _l('What you get', 'እንታይ ትረኽቡ', 'ምን ያገኛሉ'),
            offer.isNotEmpty ? offer : _l('New customers may get a welcome offer on their first transfer. See the offer in the Remitly app.',
                'ሓደስቲ ዓማዊል ኣብ ቀዳማይ ምልኣኾም ናይ እንቋዕ ብደሓን መጻእኩም ቅናሽ ክረኽቡ ይኽእሉ። ኣብ Remitly ኣፕ ርኣዩ።',
                'አዲስ ደንበኞች በመጀመሪያ ዝውውራቸው የእንኳን ደህና መጡ ቅናሽ ሊያገኙ ይችላሉ። በRemitly መተግበሪያ ይመልከቱ።')),
        if (disclaimer.isNotEmpty) Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 10),
          child: Text(disclaimer, style: tsBodySm(color: kTextSub).copyWith(fontSize: 10)),
        ),
        _info('🤝', _l('What we get', 'እንታይ ንረክብ', 'ምን እናገኛለን'),
            _l('Habesha Hub gets a small reward from Remitly when a new customer uses our code. It does not cost you anything extra.',
               'ሓድሽ ዓሚል ኮድና ምስ ዝጥቀም፡ Habesha Hub ካብ Remitly ንእሽቶ ሽልማት ይረክብ። ንዓኹም ተወሳኺ ክፍሊት የብሉን።',
               'አዲስ ደንበኛ ኮዳችንን ሲጠቀም Habesha Hub ከRemitly ትንሽ ሽልማት ያገኛል። ለእርስዎ ተጨማሪ ወጪ የለውም።')),
        const SizedBox(height: 4),

        // ── Way 1: do it yourself ──
        Text(_l('Do it yourself', 'ባዕልኹም ግበርዎ', 'ራስዎ ያድርጉት'), style: tsTitleMd(color: kSecondary)),
        const SizedBox(height: 8),
        _step('1', _l('Tap "Open Remitly" and install the app.', '"Remitly ክፈት" ጠውቑ እሞ ኣፕ ኣውርዱ።', '"Remitly ክፈት" ይንኩና መተግበሪያውን ይጫኑ።')),
        _step('2', _l('Sign up with your own phone number and email.', 'ብናይ ገዛእ ርእስኹም ቁጽሪ ስልክን ኢመይልን ተመዝገቡ።', 'በራስዎ ስልክ ቁጥርና ኢሜይል ይመዝገቡ።')),
        if (showCode)
          _step('3', _l('Enter the code $code (at sign-up or on your first transfer).', 'ኮድ $code ኣእትዉ (ክትምዝገቡ ከለኹም ወይ ኣብ ቀዳማይ ምልኣኽኩም)።', 'ኮድ $code ያስገቡ (ሲመዘገቡ ወይም በመጀመሪያ ዝውውርዎ)።')),
        _step(showCode ? '4' : '3', _l('Verify your identity with your ID when Remitly asks.', 'Remitly ምስ ዝሓተኩም መንነትኩም ብመንነት ወረቐት ኣረጋግጹ።', 'Remitly ሲጠይቅ ማንነትዎን በመታወቂያዎ ያረጋግጡ።')),
        _step(showCode ? '5' : '4', _l('Add the receiver, choose cash pickup, mobile money or bank, and send.', 'ተቐባላይ ወስኹ፡ ጥረ ገንዘብ፡ ሞባይል ገንዘብ ወይ ባንኪ ምረጹ እሞ ስደዱ።', 'ተቀባዩን ያክሉ፣ በጥሬ ገንዘብ፣ ሞባይል ገንዘብ ወይም ባንክ ይምረጡና ይላኩ።')),
        Text(_l('Already a Remitly customer? Just open the app and send.',
                'ቅድሚ ሕጂ Remitly ትጥቀሙ ዲኹም? ኣፕ ክፈቱ እሞ ስደዱ።',
                'ቀድሞ የRemitly ደንበኛ ነዎት? መተግበሪያውን ይክፈቱና ይላኩ።'),
            style: tsBodySm(color: kTextSub)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _openRemitly,
          icon: Icon(Icons.open_in_new_rounded, color: kOnAccent, size: 18),
          label: Text(_l('Open Remitly', 'Remitly ክፈት', 'Remitly ክፈት'), style: tsTitleMd(color: kOnAccent)),
          style: ElevatedButton.styleFrom(backgroundColor: kSecondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
        if (video.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _HelpVideoScreen(url: video))),
            icon: Icon(Icons.play_circle_rounded, color: kSecondary),
            label: Text(_l('Watch how it works', 'ከመይ ከም ዝሰርሕ ርኣዩ', 'እንዴት እንደሚሰራ ይመልከቱ'), style: tsTitleMd(color: kSecondary)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: kSecondary.withOpacity(0.6)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
        ],
        const SizedBox(height: 18),

        // ── Way 2: we help you on a WhatsApp video call ──
        Text(_l('Or we help you', 'ወይ ንሕና ንሕግዘኩም', 'ወይም እኛ እንረዳዎታለን'), style: tsTitleMd(color: kSecondary)),
        const SizedBox(height: 6),
        Text(_l('Call us on WhatsApp video and share your screen. We guide you step by step while you sign up on your own phone.',
                'ብWhatsApp ቪድዮ ደውሉልና እሞ ስክሪንኩም ኣካፍሉ። ኣብ ናትኩም ስልኪ ክትምዝገቡ ከለኹም ስጉምቲ ብስጉምቲ ንመርሓኩም።',
                'በWhatsApp ቪዲዮ ይደውሉልንና ስክሪንዎን ያጋሩ። በራስዎ ስልክ ሲመዘገቡ ደረጃ በደረጃ እንመራዎታለን።'),
            style: tsBodySm(color: kText)),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _whatsAppHelp,
          icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
          label: Text(_l('Get help on WhatsApp', 'ብWhatsApp ሓገዝ ርኸቡ', 'በWhatsApp እርዳታ ያግኙ'),
              style: tsTitleMd(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
        const SizedBox(height: 8),
        Text(_l('🔒 Stop sharing your screen when you type your card, password or SMS code. Never share them with anyone – also not with us.',
                '🔒 ካርድኩም፡ ፓስዎርድኩም ወይ SMS ኮድ ክትጽሕፉ ከለኹም ምክፋል ስክሪን ኣቋርጹ። ንማንም ኣይተካፍልዎም – ንዓና እውን።',
                '🔒 ካርድዎን፣ የይለፍ ቃልዎን ወይም የSMS ኮድ ሲጽፉ ስክሪን ማጋራትን ያቁሙ። ለማንም አያጋሩ – ለእኛም ጭምር።'),
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
            ? CircularProgressIndicator(color: kSecondary)
            : Chewie(controller: _chc!)),
  );
}
