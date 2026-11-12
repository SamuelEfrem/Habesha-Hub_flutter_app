import 'package:cached_network_image/cached_network_image.dart';
import '../utils/contact.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';
import 'auth_screen.dart';

// "Websites for businesses" — an offer from Habesha Tech Help (Samuel).
// Packages, prices, portfolio and FAQ live in app_config/websites (public read, admin write).
// Requests go to websiteRequests: the person sees and deletes their own, only the admin sees all.
// Internal notes are kept apart in websiteRequestNotes (admin only).
// No payments in the app: offers and invoices happen outside (Fiken/Conta, bank, Vipps).

final _db = FirebaseFirestore.instance;
final _content = _db.collection('app_config').doc('websites');
final _requests = _db.collection('websiteRequests');
final _notes = _db.collection('websiteRequestNotes');

/// The "Habesha Tech Help" business profile, where the offer is shown
const kTechHelpBusinessId = 'HBstLTkSi47nOVkM6Vx2';
const _adminUid = 'W3z67R3wiXUVvcPFDS0oxgfaDlj1';
const _privacyUrl = 'https://habesha-hub.no/privacy.html';

bool get _isAdmin {
  final u = FirebaseAuth.instance.currentUser;
  return u != null && (u.uid == _adminUid || u.email == 'samuelefriem@gmail.com');
}

String _s(dynamic v) => v == null ? '' : '$v';

const kWebsiteStatuses = ['new', 'contacted', 'offer_sent', 'in_progress', 'live', 'cancelled'];
String websiteStatusLabel(String s) => switch (s) {
  'new' => tr('New'),
  'contacted' => tr('Contacted'),
  'offer_sent' => tr('Offer sent'),
  'in_progress' => tr('In progress'),
  'live' => tr('Live'),
  'cancelled' => tr('Cancelled'),
  _ => s,
};
(Color, Color) _statusColors(String s) => switch (s) {
  'new' => (kTintBlue, kInkBlue),
  'live' => (kTintGreen, kInkGreen),
  'cancelled' => (kCard, kTextSub),
  _ => (kTintYellow, kInkYellow),
};

const kWebsiteLanguages = ['English', 'Norwegian', 'Tigrinya', 'Amharic', 'Other'];

// ── Content (with defaults until the admin saves something) ──

class WebPackage {
  final String key, name, desc, setup, monthly;
  final bool from;
  const WebPackage({required this.key, required this.name, required this.desc, this.setup = '', this.monthly = '', this.from = false});
  factory WebPackage.fromMap(Map m) => WebPackage(key: _s(m['key']), name: _s(m['name']), desc: _s(m['desc']),
      setup: _s(m['setup']), monthly: _s(m['monthly']), from: m['from'] == true);
  Map<String, dynamic> toMap() => {'key': key, 'name': name, 'desc': desc, 'setup': setup, 'monthly': monthly, 'from': from};
}

const _defaultPackages = [
  WebPackage(key: 'basic', name: 'Basic', desc: '1–3 pages, mobile friendly, contact + map, linked to your Habesha Hub profile'),
  WebPackage(key: 'standard', name: 'Standard', desc: '5–8 pages, gallery, menu or price list, basic SEO, contact form'),
  WebPackage(key: 'pro', name: 'Pro', desc: 'Booking or online ordering, several languages (also Tigrinya and Amharic)', from: true),
];
const _defaultIncluded = ['Hosting', 'Security updates', 'Small changes', 'Support'];
const _defaultFaq = [
  {'q': 'How long does it take?', 'a': 'A Basic website is usually ready in 1–2 weeks after we have your texts and photos.'},
  {'q': 'Who owns the domain?', 'a': 'You do. You buy and pay for the domain yourself, so it is always yours.'},
  {'q': 'How do I pay?', 'a': 'You get an offer and an invoice from Habesha Tech Help. Nothing is paid in the app.'},
];

class WebsiteContent {
  final List<WebPackage> packages;
  final List<String> included;
  final List<Map<String, String>> portfolio, faq;
  const WebsiteContent(this.packages, this.included, this.portfolio, this.faq);

  factory WebsiteContent.from(Map<String, dynamic>? d) {
    List<Map<String, String>> maps(dynamic v) => v is List
        ? [for (final e in v) if (e is Map) {for (final k in e.keys) '$k': _s(e[k])}]
        : <Map<String, String>>[];
    final pk = d?['packages'];
    return WebsiteContent(
      pk is List && pk.isNotEmpty ? [for (final p in pk) if (p is Map) WebPackage.fromMap(p)] : _defaultPackages,
      d?['included'] is List ? [for (final e in d!['included']) _s(e)] : _defaultIncluded,
      maps(d?['portfolio']),
      d?['faq'] is List ? maps(d!['faq']) : [for (final f in _defaultFaq) Map<String, String>.from(f)],
    );
  }
}

Stream<WebsiteContent> websiteContent() => _content.snapshots().map((s) => WebsiteContent.from(s.data()));

String _price(WebPackage p) {
  if (p.setup.isEmpty && p.monthly.isEmpty) return tr('Price on request');
  final setup = p.setup.isEmpty ? '' : '${p.from ? '${tr('from')} ' : ''}${p.setup}';
  final monthly = p.monthly.isEmpty ? '' : '${p.monthly} ${tr('/month')}';
  return [setup, monthly].where((e) => e.isNotEmpty).join(' + ');
}

Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
// questions about websites go by e-mail (the WhatsApp number is only for bookings)
Future<void> _wa(String text) => emailSupport(subject: 'Website – Habesha Tech Help', body: text);

// ── Entry cards ──

/// On the Habesha Tech Help profile
class WebsitesOfferCard extends StatelessWidget {
  const WebsitesOfferCard({super.key});
  @override
  Widget build(BuildContext context) => _EntryCard(
    emoji: '🌐',
    title: tr('Websites for businesses'),
    text: tr('Get a modern website for your business – connected to your Habesha Hub profile.'),
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WebsitesScreen())),
  );
}

/// On a business the user owns, when it has no website of its own
class NoWebsiteCard extends StatelessWidget {
  final Business business;
  const NoWebsiteCard({super.key, required this.business});

  static bool shouldShow(Business b) {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous || b.id == kTechHelpBusinessId || u.uid != b.ownerId) return false;
    final w = (b.website ?? '').trim().toLowerCase();
    return w.isEmpty || w.contains('wa.me') || w.contains('facebook.com') || w.contains('instagram.com') || w.contains('tiktok.com');
  }

  @override
  Widget build(BuildContext context) => _EntryCard(
    emoji: '💻',
    title: tr('No website yet? Get one'),
    text: tr('A simple website for your business, connected to your Habesha Hub profile.'),
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WebsiteRequestForm(business: business))),
  );
}

class _EntryCard extends StatelessWidget {
  final String emoji, title, text;
  final VoidCallback onTap;
  const _EntryCard({required this.emoji, required this.title, required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: kTintBlue,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: tsTitleMd(color: kText)),
            const SizedBox(height: 2),
            Text(text, style: tsBodySm(color: kTextSub)),
          ])),
          Icon(Icons.arrow_forward_rounded, color: kInkBlue),
        ]),
      ),
    ),
  );
}

// ── The offer ──

class WebsitesScreen extends StatelessWidget {
  const WebsitesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = FirebaseAuth.instance.currentUser?.isAnonymous == false;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: Text(tr('Websites for businesses'), style: tsTitleMd(color: kText)), actions: [
        if (signedIn) TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyWebsiteRequestsScreen())),
          child: Text(tr('My requests'))),
      ]),
      body: StreamBuilder<WebsiteContent>(
        stream: websiteContent(),
        builder: (_, snap) {
          if (snap.hasError) return Center(child: Text(tr('Could not load. Try again later.'), style: tsBodySm(color: kTextSub)));
          if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kHabGreen, strokeWidth: 2));
          final c = snap.data!;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 100), children: [
            Text(tr('Get a modern website for your business – connected to your Habesha Hub profile.'), style: tsBodyLg(color: kText)),
            const SizedBox(height: 16),
            for (final p in c.packages) _PackageCard(p),
            const SizedBox(height: 8),
            _section(tr("What's included")),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final i in c.included) Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Icon(Icons.check_circle_rounded, color: kHabGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tr(i), style: tsBodyLg(color: kText))),
                  ]),
                ),
                const SizedBox(height: 4),
                Text(tr('Domain is paid by and owned by the customer.'), style: tsBodySm(color: kTextSub)),
              ]),
            ),
            if (c.portfolio.isNotEmpty) ...[
              _section(tr('Examples')),
              SizedBox(height: 190, child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final p in c.portfolio) _PortfolioCard(p),
              ])),
            ],
            if (c.faq.isNotEmpty) ...[
              _section(tr('Questions and answers')),
              for (final f in c.faq) Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(tr(f['q'] ?? ''), style: tsTitleMd(color: kText).copyWith(fontSize: 15)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    children: [Align(alignment: Alignment.centerLeft, child: Text(tr(f['a'] ?? ''), style: tsBodyLg(color: kTextSub)))],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _wa('Hi Habesha Tech Help, I want a website for my business'),
              icon: const Icon(Icons.email_outlined, size: 18), label: Text('${tr('Contact us by email')} · support@habesha-hub.no')),
          ]);
        },
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
    child: Text(t, style: tsHeadlineSm(color: kText)),
  );
}

class _PackageCard extends StatelessWidget {
  final WebPackage p;
  const _PackageCard(this.p);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(tr(p.name), style: tsHeadlineSm(color: kText))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: kTintGreen, borderRadius: BorderRadius.circular(100)),
          child: Text(_price(p), style: tsBodySm(color: kInkGreen).copyWith(fontWeight: FontWeight.w800)),
        ),
      ]),
      const SizedBox(height: 6),
      Text(tr(p.desc), style: tsBodyLg(color: kTextSub)),
      Align(alignment: Alignment.centerRight, child: TextButton(
        onPressed: () => openWebsiteRequest(context, package: p.key), child: Text(tr('Choose')))),
    ]),
  );
}

class _PortfolioCard extends StatelessWidget {
  final Map<String, String> p;
  const _PortfolioCard(this.p);
  @override
  Widget build(BuildContext context) {
    final link = p['link'] ?? '', img = p['image'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: link.startsWith('https://') ? () => _open(link) : null,
          child: SizedBox(width: 220, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(height: 130, width: 220, child: img.startsWith('https://')
                ? CachedNetworkImage(imageUrl: img, fit: BoxFit.cover, memCacheWidth: 500,
                    errorWidget: (_, __, ___) => Container(color: kTintBlue))
                : Container(color: kTintBlue, child: const Center(child: Text('🌐', style: TextStyle(fontSize: 36))))),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                Expanded(child: Text(p['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: tsTitleMd(color: kText))),
                if (link.isNotEmpty) Icon(Icons.open_in_new_rounded, size: 16, color: kTextSub),
              ]),
            ),
          ])),
        ),
      ),
    );
  }
}

// ── Request form ──

/// Opens the form; asks the person to log in first
Future<void> openWebsiteRequest(BuildContext context, {String package = '', Business? business}) async {
  final u = FirebaseAuth.instance.currentUser;
  if (u == null || u.isAnonymous) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Log in to send a request'))));
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    return;
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => WebsiteRequestForm(package: package, business: business)));
}

class WebsiteRequestForm extends StatefulWidget {
  final String package;
  final Business? business;
  const WebsiteRequestForm({super.key, this.package = '', this.business});
  @override
  State<WebsiteRequestForm> createState() => _WebsiteRequestFormState();
}

class _WebsiteRequestFormState extends State<WebsiteRequestForm> {
  final _biz = TextEditingController(), _name = TextEditingController(), _phone = TextEditingController(),
      _email = TextEditingController(), _city = TextEditingController(), _country = TextEditingController(),
      _domain = TextEditingController(), _desc = TextEditingController(), _time = TextEditingController();
  late String _package = widget.package;
  String _bizId = '', _error = '';
  bool _hasDomain = false, _consent = false, _saving = false;
  final Set<String> _langs = {'English'};
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _myBiz = [];

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser;
    _name.text = u?.displayName ?? '';
    _email.text = u?.email ?? '';
    _phone.text = u?.phoneNumber ?? '';
    if (widget.business != null) _fill(widget.business!.id, widget.business!.toMap());
    if (u != null) {
      _db.collection('businesses').where('ownerId', isEqualTo: u.uid).get().then((q) {
        if (mounted) setState(() => _myBiz = q.docs.where((d) => d.id != kTechHelpBusinessId).toList());
      }).catchError((_) {});
    }
  }

  void _fill(String id, Map<String, dynamic> b) {
    _bizId = id;
    _biz.text = _s(b['name']);
    if (_s(b['phone']).isNotEmpty) _phone.text = _s(b['phone']);
    if (_s(b['country']).isNotEmpty) _country.text = _s(b['country']);
    // the city after the postcode ("Storgata 50, 0182 Oslo" → "Oslo"); no guess without a postcode
    final m = RegExp(r'\b\d{4,5}\s+([^\d,]{2,})$').firstMatch(_s(b['address']).trim());
    if (_s(b['city']).isNotEmpty) {
      _city.text = _s(b['city']);
    } else if (m != null) {
      _city.text = m.group(1)!.trim();
    }
    final w = _s(b['website']);
    if (w.isNotEmpty && !w.contains('wa.me')) { _hasDomain = true; _domain.text = w; }
  }

  @override
  void dispose() {
    for (final c in [_biz, _name, _phone, _email, _city, _country, _domain, _desc, _time]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    var phone = _phone.text.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (phone.startsWith('00')) phone = '+${phone.substring(2)}';   // 0047… → +47…
    if (_biz.text.trim().isEmpty || _name.text.trim().isEmpty || _city.text.trim().isEmpty) {
      setState(() => _error = tr('Please write business name, your name and city'));
      return;
    }
    if (!RegExp(r'^\+\d{7,15}$').hasMatch(phone)) {
      setState(() => _error = tr('Write the phone or WhatsApp number with country code, e.g. +47'));
      return;
    }
    if (_package.isEmpty) { setState(() => _error = tr('Please choose a package')); return; }
    if (!_consent) { setState(() => _error = tr('Please tick the box so we may contact you')); return; }
    setState(() { _saving = true; _error = ''; });
    try {
      await _requests.add({
        'uid': FirebaseAuth.instance.currentUser!.uid,
        'businessId': _bizId,
        'businessName': _biz.text.trim(),
        'contactName': _name.text.trim(),
        'phone': phone,
        'email': _email.text.trim(),
        'city': _city.text.trim(),
        'country': _country.text.trim(),
        'package': _package,
        'hasDomain': _hasDomain,
        'domain': _hasDomain ? _domain.text.trim() : '',
        'languages': _langs.toList(),
        'description': _desc.text.trim(),
        'contactTime': _time.text.trim(),
        'consent': true,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => _SentScreen(businessName: _biz.text.trim())));
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = tr('Could not send. Try again later.'); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: Text(tr('Get a website'), style: tsTitleMd(color: kText))),
      body: StreamBuilder<WebsiteContent>(
        stream: websiteContent(),
        builder: (_, snap) {
          final packages = snap.data?.packages ?? _defaultPackages;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
            if (_myBiz.isNotEmpty) ...[
              _label(tr('Your business on Habesha Hub')),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final d in _myBiz) ChoiceChip(
                  label: Text(_s(d.data()['name'])), selected: _bizId == d.id, selectedColor: kHabGreen, showCheckmark: false,
                  labelStyle: TextStyle(color: _bizId == d.id ? Colors.white : kText),
                  onSelected: (_) => setState(() => _fill(d.id, d.data()))),
              ]),
            ],
            _field(_biz, tr('Business name')),
            _field(_name, tr('Your name')),
            _field(_phone, tr('Phone / WhatsApp (with country code)'), type: TextInputType.phone),
            _field(_email, tr('Email (optional)'), type: TextInputType.emailAddress),
            Row(children: [
              Expanded(child: _field(_city, tr('City'))),
              const SizedBox(width: 10),
              Expanded(child: _field(_country, tr('Country'))),
            ]),
            _label(tr('Package')),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final p in packages) ChoiceChip(
                label: Text('${tr(p.name)} · ${_price(p)}'), selected: _package == p.key, selectedColor: kHabGreen, showCheckmark: false,
                labelStyle: TextStyle(color: _package == p.key ? Colors.white : kText),
                onSelected: (_) => setState(() => _package = p.key)),
              ChoiceChip(
                label: Text(tr('Not sure')), selected: _package == 'unsure', selectedColor: kHabGreen, showCheckmark: false,
                labelStyle: TextStyle(color: _package == 'unsure' ? Colors.white : kText),
                onSelected: (_) => setState(() => _package = 'unsure')),
            ]),
            _label(tr('Do you already have a domain?')),
            Row(children: [
              ChoiceChip(label: Text(tr('Yes')), selected: _hasDomain, selectedColor: kHabGreen, showCheckmark: false,
                  labelStyle: TextStyle(color: _hasDomain ? Colors.white : kText), onSelected: (_) => setState(() => _hasDomain = true)),
              const SizedBox(width: 8),
              ChoiceChip(label: Text(tr('No')), selected: !_hasDomain, selectedColor: kHabGreen, showCheckmark: false,
                  labelStyle: TextStyle(color: !_hasDomain ? Colors.white : kText), onSelected: (_) => setState(() => _hasDomain = false)),
            ]),
            if (_hasDomain) _field(_domain, tr('Domain name, e.g. mybusiness.no')),
            _label(tr('Languages on the website')),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final l in kWebsiteLanguages) FilterChip(
                label: Text(tr(l)), selected: _langs.contains(l), selectedColor: kTintGreen, checkmarkColor: kInkGreen,
                onSelected: (on) => setState(() => on ? _langs.add(l) : _langs.remove(l))),
            ]),
            _field(_desc, tr('What do you need? (short)'), lines: 4, max: 1000),
            _field(_time, tr('Best time to contact you (optional)')),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: kHabGreen,
              value: _consent,
              onChanged: (v) => setState(() => _consent = v == true),
              title: Text(tr('I agree that Habesha Hub may contact me about this request.'), style: tsBodySm(color: kText)),
              subtitle: GestureDetector(
                onTap: () => _open(_privacyUrl),
                child: Text(tr('Privacy policy'), style: tsBodySm(color: kInkBlue).copyWith(decoration: TextDecoration.underline))),
            ),
            if (_error.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_error, style: tsBodySm(color: kRed)),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kHabGreen, minimumSize: const Size.fromHeight(50)),
              onPressed: _saving ? null : _send,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(tr('Send request')),
            ),
            const SizedBox(height: 8),
            Text(tr('No payment in the app. You get an offer from Habesha Tech Help first.'), textAlign: TextAlign.center,
                style: tsBodySm(color: kTextSub)),
          ]);
        },
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
    child: Text(t, style: tsTitleMd(color: kText)),
  );

  Widget _field(TextEditingController c, String label, {TextInputType? type, int lines = 1, int? max}) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(
      controller: c, keyboardType: type, maxLines: lines, maxLength: max ?? 120,
      decoration: InputDecoration(labelText: label, counterText: '', filled: true, fillColor: kCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
    ),
  );
}

class _SentScreen extends StatelessWidget {
  final String businessName;
  const _SentScreen({required this.businessName});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(backgroundColor: kBg),
    body: Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_rounded, color: kHabGreen, size: 72),
        const SizedBox(height: 14),
        Text(tr('Request sent'), style: tsHeadlineSm(color: kText)),
        const SizedBox(height: 8),
        Text(tr('Thank you! Habesha Tech Help will contact you soon.'), textAlign: TextAlign.center, style: tsBodyLg(color: kTextSub)),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: kHabGreen),
          onPressed: () => _wa('Hi Habesha Tech Help, I sent a website request for: $businessName'),
          icon: const Icon(Icons.email_outlined), label: Text(tr('Contact us by email'))),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyWebsiteRequestsScreen())),
          child: Text(tr('My requests'))),
      ]),
    )),
  );
}

// ── The person's own requests ──

class MyWebsiteRequestsScreen extends StatelessWidget {
  const MyWebsiteRequestsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: Text(tr('My website requests'), style: tsTitleMd(color: kText))),
      body: u == null || u.isAnonymous
          ? Center(child: Text(tr('Log in to send a request'), style: tsBodySm(color: kTextSub)))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _requests.where('uid', isEqualTo: u.uid).snapshots(),
              builder: (_, snap) {
                if (snap.hasError) return Center(child: Text(tr('Could not load. Try again later.'), style: tsBodySm(color: kTextSub)));
                if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kHabGreen, strokeWidth: 2));
                final docs = _newestFirst(snap.data!.docs);
                if (docs.isEmpty) return Center(child: Text(tr('You have no requests yet'), style: tsBodySm(color: kTextSub)));
                return ListView(padding: const EdgeInsets.all(16), children: [
                  for (final d in docs) Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(_s(d.data()['businessName']), style: tsTitleMd(color: kText))),
                        _StatusPill(_s(d.data()['status'])),
                      ]),
                      const SizedBox(height: 4),
                      Text('${tr('Package')}: ${_packageLabel(_s(d.data()['package']))}', style: tsBodySm(color: kTextSub)),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton.icon(
                          onPressed: () => _wa('Hi Habesha Tech Help, about my website request: ${_s(d.data()['businessName'])}'),
                          icon: const Icon(Icons.email_outlined, size: 18), label: Text(tr('Email'))),
                        TextButton.icon(
                          onPressed: () async {
                            final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
                              backgroundColor: kCard,
                              title: Text(tr('Delete this request?'), style: tsTitleMd(color: kText)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('Cancel'))),
                                TextButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('Delete'), style: TextStyle(color: kRed))),
                              ],
                            ));
                            if (ok == true) await d.reference.delete();
                          },
                          icon: Icon(Icons.delete_outline_rounded, size: 18, color: kRed),
                          label: Text(tr('Delete'), style: TextStyle(color: kRed))),
                      ]),
                    ]),
                  ),
                ]);
              },
            ),
    );
  }
}

List<QueryDocumentSnapshot<Map<String, dynamic>>> _newestFirst(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) =>
    docs.toList()..sort((a, b) {
      final x = a.data()['createdAt'], y = b.data()['createdAt'];
      return x is Timestamp && y is Timestamp ? y.compareTo(x) : 0;
    });

String _packageLabel(String key) => switch (key) {
  'basic' => tr('Basic'),
  'standard' => tr('Standard'),
  'pro' => tr('Pro'),
  'unsure' => tr('Not sure'),
  _ => key,
};

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);
  @override
  Widget build(BuildContext context) {
    final (bg, ink) = _statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(websiteStatusLabel(status), style: tsBodySm(color: ink).copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

// ── Admin ──

class WebsiteRequestsAdminTab extends StatefulWidget {
  const WebsiteRequestsAdminTab({super.key});
  @override
  State<WebsiteRequestsAdminTab> createState() => _WebsiteRequestsAdminTabState();
}

class _WebsiteRequestsAdminTabState extends State<WebsiteRequestsAdminTab> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _requests.orderBy('createdAt', descending: true).limit(300).snapshots(),
      builder: (_, snap) {
        if (snap.hasError) return Center(child: Text(tr('Could not load. Try again later.'), style: tsBodySm(color: kTextSub)));
        if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kHabGreen, strokeWidth: 2));
        final all = snap.data!.docs;
        final docs = _filter.isEmpty ? all : all.where((d) => _s(d.data()['status']) == _filter).toList();
        int n(String s) => all.where((d) => _s(d.data()['status']) == s).length;
        return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WebsiteContentEditor())),
            icon: const Icon(Icons.edit_note_rounded), label: Text(tr('Edit packages, prices, examples and FAQ'))),
          const SizedBox(height: 10),
          SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, children: [
            _chip('${tr('All')} (${all.length})', _filter.isEmpty, () => setState(() => _filter = '')),
            for (final s in kWebsiteStatuses) _chip('${websiteStatusLabel(s)} (${n(s)})', _filter == s, () => setState(() => _filter = s)),
          ])),
          const SizedBox(height: 10),
          if (docs.isEmpty) Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(child: Text(tr('No requests'), style: tsBodySm(color: kTextSub)))),
          for (final d in docs) Padding(padding: const EdgeInsets.only(bottom: 10), child: Material(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WebsiteRequestDetail(id: d.id))),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_s(d.data()['businessName']), style: tsTitleMd(color: kText)),
                    Text([_s(d.data()['contactName']), _s(d.data()['city']), _packageLabel(_s(d.data()['package']))]
                        .where((e) => e.isNotEmpty).join(' · '), style: tsBodySm(color: kTextSub)),
                  ])),
                  _StatusPill(_s(d.data()['status'])),
                ]),
              ),
            ),
          )),
        ]);
      },
    );
  }

  Widget _chip(String label, bool on, VoidCallback tap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(label: Text(label), selected: on, onSelected: (_) => tap(), selectedColor: kHabGreen, showCheckmark: false,
        labelStyle: TextStyle(color: on ? Colors.white : kText, fontWeight: FontWeight.w600)),
  );
}

class WebsiteRequestDetail extends StatefulWidget {
  final String id;
  const WebsiteRequestDetail({super.key, required this.id});
  @override
  State<WebsiteRequestDetail> createState() => _WebsiteRequestDetailState();
}

class _WebsiteRequestDetailState extends State<WebsiteRequestDetail> {
  final _note = TextEditingController();
  bool _noteLoaded = false;

  @override
  void initState() {
    super.initState();
    _notes.doc(widget.id).get().then((s) {
      if (!mounted) return;
      setState(() { _note.text = _s(s.data()?['text']); _noteLoaded = true; });
    }).catchError((_) { if (mounted) setState(() => _noteLoaded = true); });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: Text(tr('Website request'), style: tsTitleMd(color: kText))),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _requests.doc(widget.id).snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kHabGreen, strokeWidth: 2));
          final r = snap.data!.data();
          if (r == null) return Center(child: Text(tr('The request was deleted'), style: tsBodySm(color: kTextSub)));
          final phone = _s(r['phone']), email = _s(r['email']);
          final t = r['createdAt'] is Timestamp ? (r['createdAt'] as Timestamp).toDate() : null;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(_s(r['businessName']), style: tsHeadlineSm(color: kText)),
            if (t != null) Text('${t.day}.${t.month}.${t.year}', style: tsBodySm(color: kTextSub)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (phone.isNotEmpty) FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kHabGreen),
                onPressed: () => _open('https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}?text=${Uri.encodeComponent('Hi ${_s(r['contactName'])}, this is Samuel from Habesha Tech Help about your website request (${_s(r['businessName'])}).')}'),
                icon: const Icon(Icons.chat_rounded, size: 18), label: Text(tr('WhatsApp'))),
              if (phone.isNotEmpty) OutlinedButton.icon(
                onPressed: () => _open('tel:$phone'), icon: const Icon(Icons.call_rounded, size: 18), label: Text(tr('Call'))),
              if (email.isNotEmpty) OutlinedButton.icon(
                onPressed: () => _open('mailto:$email?subject=${Uri.encodeComponent('Website for ${_s(r['businessName'])}')}'),
                icon: const Icon(Icons.mail_outline_rounded, size: 18), label: Text(tr('Email'))),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final (k, v) in [
                  (tr('Your name'), _s(r['contactName'])),
                  (tr('Phone / WhatsApp (with country code)'), phone),
                  (tr('Email (optional)'), email),
                  (tr('City'), [_s(r['city']), _s(r['country'])].where((e) => e.isNotEmpty).join(', ')),
                  (tr('Package'), _packageLabel(_s(r['package']))),
                  (tr('Domain'), r['hasDomain'] == true ? _s(r['domain']) : tr('No')),
                  (tr('Languages on the website'), (r['languages'] is List ? (r['languages'] as List).map((e) => tr('$e')).join(', ') : '')),
                  (tr('Best time to contact you (optional)'), _s(r['contactTime'])),
                  (tr('What do you need? (short)'), _s(r['description'])),
                ]) if (v.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(k, style: tsBodySm(color: kTextSub)),
                    SelectableText(v, style: tsBodyLg(color: kText)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Text(tr('Status'), style: tsTitleMd(color: kText)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in kWebsiteStatuses) ChoiceChip(
                label: Text(websiteStatusLabel(s)), selected: _s(r['status']) == s, selectedColor: kHabGreen, showCheckmark: false,
                labelStyle: TextStyle(color: _s(r['status']) == s ? Colors.white : kText),
                onSelected: (_) => _requests.doc(widget.id).update({'status': s, 'statusAt': FieldValue.serverTimestamp()})),
            ]),
            const SizedBox(height: 16),
            Text(tr('Internal notes (only you see them)'), style: tsTitleMd(color: kText)),
            const SizedBox(height: 8),
            TextField(
              controller: _note, enabled: _noteLoaded, maxLines: 5, maxLength: 3000,
              decoration: InputDecoration(filled: true, fillColor: kCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
            ),
            Align(alignment: Alignment.centerRight, child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kHabGreen),
              onPressed: () async {
                await _notes.doc(widget.id).set({'text': _note.text.trim(), 'updatedAt': FieldValue.serverTimestamp()});
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Saved'))));
              },
              child: Text(tr('Save')))),
          ]);
        },
      ),
    );
  }
}

/// Admin: packages, prices, what's included, examples and FAQ
class WebsiteContentEditor extends StatefulWidget {
  const WebsiteContentEditor({super.key});
  @override
  State<WebsiteContentEditor> createState() => _WebsiteContentEditorState();
}

class _WebsiteContentEditorState extends State<WebsiteContentEditor> {
  List<Map<String, TextEditingController>> _pk = [], _pf = [], _fq = [];
  List<bool> _from = [];
  final _incl = TextEditingController();
  bool _loaded = false, _saving = false;

  Map<String, TextEditingController> _ctrls(Map<String, String> m, List<String> keys) =>
      {for (final k in keys) k: TextEditingController(text: m[k] ?? '')};

  @override
  void initState() {
    super.initState();
    _content.get().then((s) {
      final c = WebsiteContent.from(s.data());
      setState(() {
        _pk = [for (final p in c.packages) _ctrls({'key': p.key, 'name': p.name, 'desc': p.desc, 'setup': p.setup, 'monthly': p.monthly},
            ['key', 'name', 'desc', 'setup', 'monthly'])];
        _from = [for (final p in c.packages) p.from];
        _incl.text = c.included.join('\n');
        _pf = [for (final p in c.portfolio) _ctrls(p, ['title', 'image', 'link'])];
        _fq = [for (final f in c.faq) _ctrls(f, ['q', 'a'])];
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    for (final l in [_pk, _pf, _fq]) {
      for (final m in l) {
        for (final c in m.values) {
          c.dispose();
        }
      }
    }
    _incl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    String v(Map<String, TextEditingController> m, String k) => m[k]!.text.trim();
    final links = [for (final p in _pf) ...[v(p, 'image'), v(p, 'link')]].where((e) => e.isNotEmpty);
    if (links.any((e) => !e.startsWith('https://'))) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Links must start with https://'))));
      return;
    }
    await _content.set({
      'packages': [
        for (var i = 0; i < _pk.length; i++) if (v(_pk[i], 'name').isNotEmpty)
          WebPackage(key: v(_pk[i], 'key').isEmpty ? 'p$i' : v(_pk[i], 'key'), name: v(_pk[i], 'name'), desc: v(_pk[i], 'desc'),
              setup: v(_pk[i], 'setup'), monthly: v(_pk[i], 'monthly'), from: _from[i]).toMap(),
      ],
      'included': _incl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'portfolio': [for (final p in _pf) if (v(p, 'title').isNotEmpty) {'title': v(p, 'title'), 'image': v(p, 'image'), 'link': v(p, 'link')}],
      'faq': [for (final f in _fq) if (v(f, 'q').isNotEmpty) {'q': v(f, 'q'), 'a': v(f, 'a')}],
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Saved'))));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) return const Scaffold();
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: Text(tr('Websites: content'), style: tsTitleMd(color: kText)), actions: [
        TextButton(onPressed: _saving || !_loaded ? null : _save, child: Text(tr('Save'))),
      ]),
      body: !_loaded
          ? Center(child: CircularProgressIndicator(color: kHabGreen, strokeWidth: 2))
          : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 60), children: [
              _head(tr('Packages'), () => setState(() {
                _pk.add(_ctrls({}, ['key', 'name', 'desc', 'setup', 'monthly']));
                _from.add(false);
              })),
              for (var i = 0; i < _pk.length; i++) _box([
                _f(_pk[i]['name']!, tr('Name')),
                _f(_pk[i]['desc']!, tr('Description'), lines: 2),
                Row(children: [
                  Expanded(child: _f(_pk[i]['setup']!, tr('Setup price, e.g. 4 900 kr'))),
                  const SizedBox(width: 8),
                  Expanded(child: _f(_pk[i]['monthly']!, tr('Monthly, e.g. 199 kr'))),
                ]),
                SwitchListTile(contentPadding: EdgeInsets.zero, value: _from[i], activeThumbColor: kHabGreen,
                    title: Text(tr('Show "from" before the price'), style: tsBodySm(color: kText)),
                    onChanged: (x) => setState(() => _from[i] = x)),
              ], () => setState(() { _pk.removeAt(i); _from.removeAt(i); })),
              _head(tr("What's included"), null),
              _f(_incl, tr('One per line'), lines: 5),
              _head(tr('Examples'), () => setState(() => _pf.add(_ctrls({}, ['title', 'image', 'link'])))),
              for (var i = 0; i < _pf.length; i++) _box([
                _f(_pf[i]['title']!, tr('Title')),
                _f(_pf[i]['image']!, tr('Image link (https://)')),
                _f(_pf[i]['link']!, tr('Website link (https://)')),
              ], () => setState(() => _pf.removeAt(i))),
              _head(tr('Questions and answers'), () => setState(() => _fq.add(_ctrls({}, ['q', 'a'])))),
              for (var i = 0; i < _fq.length; i++) _box([
                _f(_fq[i]['q']!, tr('Question')),
                _f(_fq[i]['a']!, tr('Answer'), lines: 3),
              ], () => setState(() => _fq.removeAt(i))),
            ]),
    );
  }

  Widget _head(String t, VoidCallback? add) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 18, 2, 6),
    child: Row(children: [
      Expanded(child: Text(t, style: tsHeadlineSm(color: kText))),
      if (add != null) IconButton(onPressed: add, icon: Icon(Icons.add_circle_outline_rounded, color: kHabGreen)),
    ]),
  );

  Widget _box(List<Widget> children, VoidCallback remove) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      ...children,
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: remove,
          icon: Icon(Icons.delete_outline_rounded, color: kRed, size: 18), label: Text(tr('Remove'), style: TextStyle(color: kRed)))),
    ]),
  );

  Widget _f(TextEditingController c, String label, {int lines = 1}) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: TextField(controller: c, maxLines: lines,
        decoration: InputDecoration(labelText: label, isDense: true, filled: true, fillColor: kBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
  );
}
