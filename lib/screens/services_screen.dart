import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import 'payment.dart';
import 'provider_extras.dart';
import '../utils/translations.dart';

class ServiceCountry {
  final String code;
  final String name;
  final String flag;
  const ServiceCountry({required this.code, required this.name, required this.flag});
}

class ServiceCategory {
  final String key;
  final String emoji;
  final String label;
  const ServiceCategory({required this.key, required this.emoji, required this.label});
}

const kServiceCountries = [
  ServiceCountry(code: 'UG', name: 'Uganda',        flag: '\u{1F1FA}\u{1F1EC}'),
  ServiceCountry(code: 'ET', name: 'Ethiopia',       flag: '\u{1F1EA}\u{1F1F9}'),
  ServiceCountry(code: 'ER', name: 'Eritrea',        flag: '\u{1F1EA}\u{1F1F7}'),
  ServiceCountry(code: 'KE', name: 'Kenya',          flag: '\u{1F1F0}\u{1F1EA}'),
  ServiceCountry(code: 'SS', name: 'South Sudan',    flag: '\u{1F1F8}\u{1F1F8}'),
  ServiceCountry(code: 'NO', name: 'Norway',         flag: '\u{1F1F3}\u{1F1F4}'),
  ServiceCountry(code: 'SE', name: 'Sweden',         flag: '\u{1F1F8}\u{1F1EA}'),
  ServiceCountry(code: 'GB', name: 'United Kingdom', flag: '\u{1F1EC}\u{1F1E7}'),
  ServiceCountry(code: 'US', name: 'United States',  flag: '\u{1F1FA}\u{1F1F8}'),
  ServiceCountry(code: 'CA', name: 'Canada',         flag: '\u{1F1E8}\u{1F1E6}'),
];

// ═══════════════════════════════════════════════════════════
// HELPERS — Firestore fields can be String (old) or List<String> (new)
// ═══════════════════════════════════════════════════════════
/// Reads any Firestore value as a trimmed String (int, double, null → safe).
String serviceStr(dynamic v) => v == null ? '' : v.toString().trim();

/// Provider text in the selected language.
/// Firestore: publicName / description in English, plus
///   translations: { Tigrinya: {publicName, description}, Amharic: {...} }
String serviceText(Map<String, dynamic> data, String field) {
  final lang = languageNotifier.language;
  if (lang != 'English') {
    final t9n = data['translations'];
    if (t9n is Map && t9n[lang] is Map) {
      final v = serviceStr((t9n[lang] as Map)[field]);
      if (v.isNotEmpty) return v;
    }
  }
  return serviceStr(data[field]);
}

List<String> serviceStringList(dynamic v) {
  if (v == null) return [];
  if (v is String) return v.trim().isEmpty ? [] : [v.trim()];
  if (v is List) {
    return v.map((e) => e?.toString().trim() ?? '').where((s) => s.isNotEmpty).toList();
  }
  return [];
}

/// All images for a provider (`sampleImages`).
List<String> serviceImages(Map<String, dynamic> data) =>
    serviceStringList(data['sampleImages']);

/// All videos for a provider: new `sampleVideoUrls` array,
/// falls back to old single `sampleVideoUrl` string.
List<String> serviceVideos(Map<String, dynamic> data) {
  final list = serviceStringList(data['sampleVideoUrls']);
  if (list.isNotEmpty) return list;
  return serviceStringList(data['sampleVideoUrl']);
}

const kServiceCategories = [
  ServiceCategory(key: 'photographer',  emoji: '\u{1F4F8}', label: 'Photographer'),
  ServiceCategory(key: 'decoration',    emoji: '\u{1F38A}', label: 'Decoration & Events'),
  ServiceCategory(key: 'flight_visa',   emoji: '\u{2708}',  label: 'Flight & Visa'),
  ServiceCategory(key: 'transport',     emoji: '\u{1F697}', label: 'Transport'),
  ServiceCategory(key: 'clothing',      emoji: '\u{1F457}', label: 'Clothing'),
  ServiceCategory(key: 'accommodation', emoji: '\u{1F3E8}', label: 'Accommodation'),
  ServiceCategory(key: 'hawala',        emoji: '\u{1F4B0}', label: 'Hawala / Money Transfer'),
];

// ═══════════════════════════════════════════════════════════
// SERVICES SCREEN — country grid
// ═══════════════════════════════════════════════════════════
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('Services'), style: tsHeadlineMd(color: kSecondary)),
                Text(tr('Select a country to find services'), style: tsBodySm()),
              ])),
              IconButton(
                tooltip: tr('Favorite services'),
                icon: const Icon(Icons.favorite_rounded, color: kRed),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const FavoriteServicesScreen())),
              ),
            ]),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 1.3,
                crossAxisSpacing: 12, mainAxisSpacing: 12,
              ),
              itemCount: kServiceCountries.length,
              itemBuilder: (_, i) {
                final c = kServiceCountries[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ServiceCategoryScreen(country: c))),
                  child: Container(
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kSecondary.withOpacity(0.15), width: 0.5),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(c.flag, style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(tr(c.name), style: tsTitleMd(), textAlign: TextAlign.center),
                      Text(c.code, style: tsBodySm(color: kTextSub)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CATEGORY SCREEN
// ═══════════════════════════════════════════════════════════
class ServiceCategoryScreen extends StatelessWidget {
  final ServiceCountry country;
  const ServiceCategoryScreen({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Row(children: [
          Text(country.flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(tr(country.name), style: tsTitleMd(color: kSecondary)),
        ]),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: kServiceCategories.length,
        itemBuilder: (_, i) {
          final cat = kServiceCategories[i];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ServiceListScreen(country: country, category: cat))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kSecondary.withOpacity(0.1), width: 0.5),
              ),
              child: Row(children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr(cat.label), style: tsTitleMd()),
                  Text(tr('Tap to view providers'), style: tsBodySm(color: kTextSub)),
                ])),
                const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 16),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PROVIDER LIST SCREEN
// ═══════════════════════════════════════════════════════════
class ServiceListScreen extends StatelessWidget {
  final ServiceCountry country;
  final ServiceCategory category;
  const ServiceListScreen({super.key, required this.country, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Text('${country.flag} ${tr(category.label)}', style: tsTitleMd(color: kSecondary)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('anonymous_services')
            .where('country', isEqualTo: country.code)
            .where('category', isEqualTo: category.key)
            .where('available', isEqualTo: true).snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(category.emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(tr('No providers yet'), style: tsTitleLg()),
              const SizedBox(height: 8),
              Text(tr('Coming soon!'), style: tsBodySm()),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final imgs = serviceImages(data);
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ServiceProviderScreen(docId: docs[i].id, data: data))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kSecondary.withOpacity(0.1)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (imgs.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(imgs.first,
                          height: 160, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 120, color: kCardHigh,
                            child: Center(child: Text(category.emoji, style: const TextStyle(fontSize: 48)))),
                        ),
                      )
                    else
                      Container(height: 120, width: double.infinity,
                        decoration: BoxDecoration(color: kCardHigh,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                        child: Center(child: Text(category.emoji, style: const TextStyle(fontSize: 48))),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(serviceText(data, 'publicName'), style: tsHeadlineSm()),
                        RatingLine(data: data),
                        if (serviceText(data, 'description').isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(serviceText(data, 'description'), style: tsBodySm(color: kTextSub), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ServiceProviderScreen(docId: docs[i].id, data: data))),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(10)),
                                child: Center(child: Text(tr('View Profile'), style: tsTitleMd(color: kTextSub).copyWith(fontSize: 12))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => BookServiceScreen(docId: docs[i].id, data: data, country: country))),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(10)),
                                child: Center(child: Text(tr('Book Now'), style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 12))),
                              ),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PROVIDER PROFILE SCREEN
// ═══════════════════════════════════════════════════════════
class ServiceProviderScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const ServiceProviderScreen({super.key, required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final images = serviceImages(data);
    final videos = serviceVideos(data);
    final country = kServiceCountries.firstWhere((c) => c.code == data['country'], orElse: () => kServiceCountries.first);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Text(serviceText(data, 'publicName'), style: tsTitleMd(color: kSecondary)),
        actions: [
          FavoriteServiceButton(data: data),
          IconButton(
            tooltip: tr('Share'),
            icon: const Icon(Icons.share_rounded, color: kSecondary),
            onPressed: () => shareProvider(data),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (images.isNotEmpty) _ImageCarousel(images: images),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(serviceText(data, 'publicName'), style: tsHeadlineMd(color: kSecondary)),
              if (serviceStr(data['city']).isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on_rounded, color: kSecondary, size: 16),
                  const SizedBox(width: 4),
                  Text(serviceStr(data['city']), style: tsBodySm()),
                ]),
              ],
              if (serviceText(data, 'description').isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(tr('About'), style: tsLabel()),
                const SizedBox(height: 8),
                Text(serviceText(data, 'description'), style: tsBodyLg()),
              ],
              if (images.isNotEmpty || videos.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(children: [
                  Text(tr('Album'), style: tsLabel()),
                  const SizedBox(width: 8),
                  Text(
                    [
                      if (images.isNotEmpty) '${images.length} ${tr('photos')}',
                      if (videos.isNotEmpty) '${videos.length} ${tr('videos')}',
                    ].join(' · '),
                    style: tsBodySm(color: kTextSub)),
                ]),
                const SizedBox(height: 10),
                _MediaAlbum(images: images, videos: videos),
              ],
              const SizedBox(height: 24),
              ProviderReviews(providerId: docId, data: data),
              const SizedBox(height: 24),
            ]),
          ),
        ]),
      ),
      // Book button always visible at the bottom
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          // fixed height — goldButton contains a Center that would otherwise fill the whole screen
          child: SizedBox(
            height: 54,
            child: goldButton(tr('Book Now'), () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => BookServiceScreen(docId: docId, data: data, country: country))),
              icon: Icons.calendar_today_rounded),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BOOK SERVICE SCREEN
// ═══════════════════════════════════════════════════════════
class BookServiceScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final ServiceCountry country;
  const BookServiceScreen({super.key, required this.docId, required this.data, required this.country});

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  final _db = FirebaseFirestore.instance;
  final _notesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;
  bool _done = false;
  String _payFrom = guessPayCountry();      // country the customer pays from
  Map<String, PaymentInfo>? _methods;
  String? _bookingId;

  @override
  void initState() {
    super.initState();
    loadPaymentMethods().then((m) { if (mounted) setState(() => _methods = m); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Text(tr('Book Service'), style: tsTitleMd(color: kSecondary)),
      ),
      body: _done ? _success() : _form(),
    );
  }

  // ── WhatsApp contact ──────────────────────────────────────
  static const _waNumber = '4797374482'; // Habesha Hub (Norway, +47) — wa.me needs country code

  Future<void> _openWhatsApp(String message) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$_waNumber?text=$encoded');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _success() {
    final lang = languageNotifier.language;
    final name = serviceStr(widget.data['publicName']);
    final dateStr = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

    // WhatsApp-melding basert på språk
    final waMsg = lang == 'Tigrinya'
        ? 'ሰላም! ቡኪንግ ሰዲደ ኣለኹ:\n$name\nዕለት: $dateStr\nተወሳኺ ሓበሬታ ንሃቡኒ።'
        : lang == 'Amharic'
        ? 'ሰላም! ቡኪንግ ላኩ:\n$name\nቀን: $dateStr\nበተጨማሪ መረጃ ያሳውቁኝ።'
        : lang == 'Norsk'
        ? 'Hei! Jeg har sendt en bookingforespørsel:\n$name\nDato: $dateStr\nKontakt meg med mer informasjon.'
        : 'Hi! I sent a booking request:\n$name\nDate: $dateStr\nPlease contact me with more info.';

    final titles = {
      'Tigrinya': 'ቡኪንግ ተሰዲዱ!',
      'Amharic':  'ቡኪንግ ተልኳል!',
      'Norsk':    'Booking sendt!',
      'English':  'Booking Sent!',
    };
    final subs = {
      'Tigrinya': 'ቡኪንግኩም ተቐቢልና ኣለና። ብ WhatsApp ክትዘራረቡ ጠውቑ።',
      'Amharic':  'ቡኪንግዎ ደርሷል። በ WhatsApp ለማነጋገር ጠቅ ያድርጉ።',
      'Norsk':    'Forespørselen din er mottatt. Trykk for å kontakte oss på WhatsApp.',
      'English':  'Your request is received. Tap below to contact us on WhatsApp.',
    };
    final waBtnLabel = {
      'Tigrinya': 'ብ WhatsApp ተዛረቡ',
      'Amharic':  'በ WhatsApp ያነጋግሩ',
      'Norsk':    'Kontakt på WhatsApp',
      'English':  'Chat on WhatsApp',
    };

    return Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 80, height: 80,
          decoration: BoxDecoration(shape: BoxShape.circle, color: kGreen.withOpacity(0.15)),
          child: const Icon(Icons.check_circle_rounded, color: kGreen, size: 48)),
        const SizedBox(height: 24),
        Text(titles[lang] ?? titles['English']!, style: tsHeadlineSm(), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12)),
          child: Text(subs[lang] ?? subs['English']!, style: tsBodySm(), textAlign: TextAlign.center)),
        const SizedBox(height: 24),
        // WhatsApp-knapp
        GestureDetector(
          onTap: () => _openWhatsApp(waMsg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.chat_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(waBtnLabel[lang] ?? waBtnLabel['English']!,
                style: tsTitleMd(color: Colors.white)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        if (_bookingId != null)
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ReceiptScreen(bookingId: _bookingId!))),
            icon: const Icon(Icons.receipt_long_rounded, color: kSecondary),
            label: Text(tr('See my booking'), style: tsTitleMd(color: kSecondary)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kSecondary.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
        const SizedBox(height: 12),
        goldButton(lang == 'Norsk' ? 'Tilbake' : lang == 'Tigrinya' ? 'ተመለስ' : lang == 'Amharic' ? 'ተመለስ' : 'Go Back',
          () => Navigator.pop(context)),
      ]),
    ));
  }

  Widget _form() {
    final user = FirebaseAuth.instance.currentUser;
    final lang = languageNotifier.language;

    final dateLabel = {'Tigrinya':'ዕለት ምረጹ','Amharic':'ቀን ይምረጡ','Norsk':'VELG DATO','English':'SELECT DATE'};
    final reqLabel  = {'Tigrinya':'ተወሳኺ ሕቶታት','Amharic':'ተጨማሪ ጥያቄዎች','Norsk':'SPESIELLE ØNSKER','English':'SPECIAL REQUESTS'};
    final hintLabel = {'Tigrinya':'ዝኾነ ተወሳኺ ሓበሬታ...','Amharic':'ማንኛውም ተጨማሪ መረጃ...','Norsk':'Spesielle ønsker eller detaljer...','English':'Any special requests or details...'};
    final btnLabel  = {'Tigrinya':'ቡኪንግ ሰዱ','Amharic':'ቡኪንግ ላኩ','Norsk':'Send bookingforespørsel','English':'Send Booking Request'};
    final infoLabel = {'Tigrinya':'Habesha Hub ድሕሪ ቡኪንግ ብ WhatsApp ክረኽበኩም እዩ።','Amharic':'Habesha Hub ቡኪንጉን ተቀብሎ በ WhatsApp ያነጋግርዎታል።','Norsk':'Habesha Hub tar kontakt med deg på WhatsApp etter bestilling.','English':'Habesha Hub will contact you on WhatsApp after booking.'};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kSecondary.withOpacity(0.2))),
          child: Row(children: [
            const Text('\u{1F4CB}', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(serviceText(widget.data, 'publicName'), style: tsTitleMd(color: kSecondary)),
              Text('${widget.country.flag} ${tr(widget.country.name)}', style: tsBodySm()),
            ])),
          ]),
        ),
        const SizedBox(height: 20),
        Text(dateLabel[lang] ?? dateLabel['English']!, style: tsLabel()),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context, initialDate: _selectedDate,
              firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (ctx, child) => Theme(
                data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: kSecondary, surface: kSurfaceContainer)),
                child: child!),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kSecondary.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded, color: kSecondary, size: 20),
              const SizedBox(width: 12),
              Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: tsTitleMd()),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Text(reqLabel[lang] ?? reqLabel['English']!, style: tsLabel()),
        const SizedBox(height: 8),
        TextField(controller: _notesCtrl, maxLines: 4, style: tsBodyLg(color: kText),
          decoration: InputDecoration(hintText: hintLabel[lang] ?? hintLabel['English']!)),
        const SizedBox(height: 20),
        // ── where will you pay from ─────────────────────
        Text(tr('WHERE WILL YOU PAY FROM?'), style: tsLabel()),
        const SizedBox(height: 8),
        PayFromPicker(value: _payFrom, onChanged: (v) => setState(() => _payFrom = v)),
        const SizedBox(height: 8),
        Builder(builder: (_) {
          final m = _methods?[_payFrom];
          final method = m?.method ?? payCountry(_payFrom).method;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.payments_outlined, color: kSecondary, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              '${tr('After confirmation you pay with')} $method'
              '${(m?.hasNumber ?? false) ? ' — ${m!.number}' : ''}. '
              '${tr('You get a receipt in the app.')}',
              style: tsBodySm())),
          ]);
        }),
        const SizedBox(height: 24),
        // WhatsApp info-boks
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF25D366).withOpacity(0.08), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3))),
          child: Row(children: [
            const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(infoLabel[lang] ?? infoLabel['English']!, style: tsBodySm())),
          ]),
        ),
        const SizedBox(height: 24),
        primaryButton(_saving ? '' : (btnLabel[lang] ?? btnLabel['English']!), _saving ? null : () async {
          if (user == null) return;
          setState(() => _saving = true);
          final ref = _db.collection('service_bookings').doc();
          await ref.set({
            'bookingCode': bookingCode(ref.id),
            'payCountry':  _payFrom,
            'lang':        languageNotifier.language,
            'serviceId':   widget.docId,
            'serviceName': serviceStr(widget.data['publicName']),
            'category':    serviceStr(widget.data['category']),
            'country':     widget.country.code,
            'userId':      user.uid,
            'userEmail':   user.email ?? '',
            'date':        _selectedDate.toIso8601String(),
            'notes':       _notesCtrl.text.trim(),
            'status':      'created',
            'createdAt':   FieldValue.serverTimestamp(),
          });
          // Cloud Function sender FCM-varsel til Samuel automatisk
          setState(() { _saving = false; _done = true; _bookingId = ref.id; });
        }, loading: _saving),
      ]),
    );
  }

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }
}

// ═══════════════════════════════════════════════════════════
// IMAGE CAROUSEL — swipe through all `sampleImages`
// ═══════════════════════════════════════════════════════════
class _ImageCarousel extends StatefulWidget {
  final List<String> images;
  const _ImageCarousel({required this.images});
  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  final _ctrl = PageController();
  int _index = 0;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.images;
    return Column(children: [
      SizedBox(
        height: 260,
        child: Stack(children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: imgs.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => Image.network(
              imgs[i],
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(color: kCardHigh,
                      child: const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5))),
              errorBuilder: (_, __, ___) => Container(color: kCardHigh,
                child: Center(child: Icon(Icons.image_not_supported_rounded, color: kTextSub, size: 40))),
            ),
          ),
          if (imgs.length > 1)
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(100)),
                child: Text('${_index + 1} / ${imgs.length}',
                    style: tsBodySm(color: Colors.white).copyWith(fontSize: 11)),
              ),
            ),
        ]),
      ),
      if (imgs.length > 1) _Dots(count: imgs.length, index: _index),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
// MEDIA ALBUM — photos + videos together in one grid (Instagram style)
// Tap a tile → fullscreen viewer, swipe through everything.
// ═══════════════════════════════════════════════════════════
class _MediaItem {
  final String url;
  final bool isVideo;
  const _MediaItem(this.url, this.isVideo);

  /// Bunny Stream gives a thumbnail next to playlist.m3u8
  String? get thumb => isVideo && url.endsWith('/playlist.m3u8')
      ? url.replaceFirst(RegExp(r'playlist\.m3u8$'), 'thumbnail.jpg')
      : (isVideo ? null : url);
}

class _MediaAlbum extends StatelessWidget {
  final List<String> images;
  final List<String> videos;
  const _MediaAlbum({required this.images, required this.videos});

  @override
  Widget build(BuildContext context) {
    // videos first, then photos
    final items = [
      ...videos.map((u) => _MediaItem(u, true)),
      ...images.map((u) => _MediaItem(u, false)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
      itemBuilder: (_, i) {
        final it = items[i];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => _MediaViewerScreen(items: items, start: i))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(fit: StackFit.expand, children: [
              if (it.thumb != null)
                Image.network(it.thumb!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: kCardHigh,
                    child: Icon(it.isVideo ? Icons.videocam_rounded : Icons.broken_image_rounded,
                        color: kTextSub)))
              else
                Container(color: kCardHigh,
                    child: Icon(Icons.videocam_rounded, color: kTextSub)),
              if (it.isVideo)
                const Center(child: Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white, size: 34,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black54)])),
            ]),
          ),
        );
      },
    );
  }
}

class _MediaViewerScreen extends StatefulWidget {
  final List<_MediaItem> items;
  final int start;
  const _MediaViewerScreen({required this.items, required this.start});
  @override
  State<_MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<_MediaViewerScreen> {
  late final PageController _ctrl = PageController(initialPage: widget.start);
  late int _index = widget.start;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_index + 1} / ${items.length}',
            style: tsTitleMd(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: items.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final it = items[i];
          if (it.isVideo) {
            // only build the player for the visible page (saves data)
            if (i != _index) return const SizedBox.shrink();
            return Center(child: _InlineVideoPlayer(key: ValueKey(it.url), url: it.url));
          }
          return InteractiveViewer(
            child: Center(child: Image.network(it.url, fit: BoxFit.contain,
              loadingBuilder: (_, child, p) => p == null ? child
                  : const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5)),
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded,
                  color: Colors.white38, size: 60))),
          );
        },
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: i == index ? 18 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: i == index ? kSecondary : kTextSub.withOpacity(0.4),
          borderRadius: BorderRadius.circular(100),
        ),
      )),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
// INLINE VIDEO PLAYER (HLS via video_player + chewie)
// Plays Bunny.net .m3u8 in-app — URL never exposed to user.
// Starts PAUSED — user taps play to start.
// ═══════════════════════════════════════════════════════════
class _InlineVideoPlayer extends StatefulWidget {
  final String url;
  final double? height;
  const _InlineVideoPlayer({super.key, required this.url, this.height});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> with WidgetsBindingObserver {
  // pause when the app goes to the background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _vpc?.pause();
  }

  // pause when another screen is opened on top of this one
  @override
  void deactivate() {
    _vpc?.pause();
    super.deactivate();
  }

  VideoPlayerController? _vpc;
  ChewieController?      _chc;
  bool _ready  = false;
  bool _error  = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      final uri = Uri.parse(widget.url);
      _vpc = VideoPlayerController.networkUrl(
        uri,
        formatHint: VideoFormat.hls,
        httpHeaders: const {'User-Agent': 'HabeshaHub/1.0'},
      );
      await _vpc!.initialize();
      await _vpc!.pause();
      _vpc!.addListener(_onTick);
      _chc = ChewieController(
        videoPlayerController: _vpc!,
        autoPlay:   false,          // ← ingen autoplay
        looping:    true,
        // ─── Security: hide all controls so URL stays hidden ───
        showControls:              false,
        allowFullScreen:           false,
        showOptions:               false,
        allowPlaybackSpeedChanging: false,
        allowMuting:               false,
      );
      if (mounted) setState(() => _ready = true);
    } catch (e, st) {
      debugPrint('🔴 InlineVideo error: $e');
      debugPrint('$st');
      if (mounted) setState(() => _error = true);
    }
  }

  bool _wasPlaying = false;
  void _onTick() {
    final playing = _vpc?.value.isPlaying ?? false;
    if (playing != _wasPlaying && mounted) {
      _wasPlaying = playing;
      setState(() {});
    }
  }

  void _toggle() {
    if (_vpc == null) return;
    _vpc!.value.isPlaying ? _vpc!.pause() : _vpc!.play();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vpc?.removeListener(_onTick);
    _chc?.dispose();
    _vpc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height ?? 200;
    if (_error) {
      return Container(
        height: h,
        decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.videocam_off_rounded, color: kSecondary, size: 40),
          const SizedBox(height: 8),
          Text(tr('Video not available'), style: tsBodySm()),
        ])),
      );
    }
    if (!_ready) {
      return Container(
        height: h,
        decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(12)),
        child: const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5)),
      );
    }
    final playing = _vpc!.value.isPlaying;
    Widget video = AspectRatio(
      aspectRatio: _vpc!.value.aspectRatio,
      child: Chewie(controller: _chc!),
    );
    if (widget.height != null) {
      video = Container(color: Colors.black, height: h, child: Center(child: video));
    }
    return GestureDetector(
      onTap: _toggle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(alignment: Alignment.center, children: [
          video,
          if (!playing)
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
            ),
        ]),
      ),
    );
  }
}
