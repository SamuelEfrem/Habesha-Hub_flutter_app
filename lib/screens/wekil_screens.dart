import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/contact.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../utils/theme_notifier.dart';
import '../utils/translations.dart';
import 'services_screen.dart';
import 'services_catalog.dart';
import '../utils/countries.dart';

// ═══════════════════════════════════════════════════════════
// HABESHA HUB SERVICE — one trusted person (ወኪል, "wekil") per country
// takes the request and finds the right service provider for the user.
//   wekils/{email}            { country, name }      admin only (the wekil may read his own)
//   serviceRequests/{id}      { userId, country, category, city, when, text, name, phone,
//                               status: new|working|done|cancelled, note, createdAt, updatedAt }
//   app_config/wekilCountries { list: [...] }        countries that have a wekil
// No payments in the app. Requests are private: the user, the wekil of that country and the admin.
// ═══════════════════════════════════════════════════════════

final _db = FirebaseFirestore.instance;
const _adminEmail = 'samuelefriem@gmail.com';

const kWekilCountries = [
  'Norway', 'Sweden', 'Denmark', 'UK', 'Germany', 'Netherlands', 'France', 'Belgium', 'Switzerland', 'Italy',
  'USA', 'Canada', 'Ethiopia', 'Eritrea', 'Uganda', 'Kenya', 'South Sudan', 'Rwanda', 'Egypt', 'Angola',
];
const _flags = {
  'Norway': '🇳🇴', 'Sweden': '🇸🇪', 'Denmark': '🇩🇰', 'UK': '🇬🇧', 'Germany': '🇩🇪', 'Netherlands': '🇳🇱',
  'France': '🇫🇷', 'Belgium': '🇧🇪', 'Switzerland': '🇨🇭', 'Italy': '🇮🇹', 'USA': '🇺🇸', 'Canada': '🇨🇦',
  'Ethiopia': '🇪🇹', 'Eritrea': '🇪🇷', 'Uganda': '🇺🇬', 'Kenya': '🇰🇪', 'South Sudan': '🇸🇸', 'Rwanda': '🇷🇼',
  'Egypt': '🇪🇬', 'Angola': '🇦🇴',
};
String flagOf(String c) => _flags[c] ?? '🌍';

/// Always "Habesha Hub Services" (in the chosen language); the country is shown next to it.
String hubName(String c) => tr('Habesha Hub Services');

const _iso = {
  'NO': 'Norway', 'SE': 'Sweden', 'DK': 'Denmark', 'GB': 'UK', 'DE': 'Germany', 'NL': 'Netherlands', 'FR': 'France',
  'BE': 'Belgium', 'CH': 'Switzerland', 'IT': 'Italy', 'US': 'USA', 'CA': 'Canada', 'ET': 'Ethiopia', 'ER': 'Eritrea',
  'UG': 'Uganda', 'KE': 'Kenya', 'SS': 'South Sudan', 'RW': 'Rwanda', 'EG': 'Egypt', 'AO': 'Angola',
};
String? _myCountry;
String codeOfCountry(String name) {
  for (final e in _iso.entries) { if (e.value == name) return e.key; }
  return '';
}

/// The wekils' WhatsApp numbers by ISO code ("NO" → "+47 …"), public in app_config/wekilCountries.
Map<String, String>? _phones;
Future<Map<String, String>> wekilPhones() async {
  if (_phones != null) return _phones!;
  try {
    final d = await _db.collection('app_config').doc('wekilCountries').get();
    final m = d.data()?['phones'];
    _phones = m is Map ? m.map((k, v) => MapEntry(k.toString(), v.toString())) : {};
  } catch (_) {
    return {};
  }
  return _phones!;
}

String hubNameForCode(String code) => tr('Habesha Hub Services');

/// ISO code of the country this account is wekil for ('' = not a wekil).
Future<String> myWekilCode() async => codeOfCountry(await myWekilCountry());

/// The user's country from the position (only if location is already allowed; we never ask here).
Future<String> detectCountry() async {
  if (_myCountry != null) return _myCountry!;
  try {
    final p = await Geolocator.checkPermission();
    if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        final pm = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (pm.isNotEmpty) return _myCountry = _iso[(pm.first.isoCountryCode ?? '').toUpperCase()] ?? '';
      }
    }
  } catch (_) {}
  return '';
}

/// The country for the home screen shortcut "Habesha Hub Norge" ('' = no wekil there: "Habesha Hub Services").
Future<String> hubShortcutCountry() async {
  final c = await detectCountry();
  try {
    final d = await _db.collection('app_config').doc('wekilCountries').get();
    final list = List<String>.from(d.data()?['list'] ?? const []);
    if (list.contains(c)) return c;
  } catch (_) {}
  return '';
}

const _cats = [
  ('food', '🍲', 'Food & catering'),
  ('moving', '🚚', 'Moving & transport'),
  ('papers', '📄', 'Translation & papers'),
  ('beauty', '💇', 'Hair & beauty'),
  ('wedding', '💍', 'Weddings & events'),
  ('cleaning', '🧹', 'Cleaning'),
  ('repair', '🔧', 'Repairs & handyman'),
  ('photo', '📸', 'Photo & video'),
  ('other', '✨', 'Other'),
];
String _catLabel(String k) { for (final c in _cats) { if (c.$1 == k) return '${c.$2} ${tr(c.$3)}'; } return k; }

String _statusLabel(String s) => switch (s) {
      'working' => tr('A wekil is working on it'),
      'done' => tr('Done'),
      'cancelled' => tr('Cancelled'),
      _ => tr('Received'),
    };
Color _statusColor(String s) => switch (s) {
      'working' => kInkYellow,
      'done' => kHabGreen,
      'cancelled' => kTextSub,
      _ => kInkBlue,
    };

bool get _isAdmin => FirebaseAuth.instance.currentUser?.email == _adminEmail;

/// The country this account is wekil for ('' = not a wekil).
Future<String> myWekilCountry() async {
  final u = FirebaseAuth.instance.currentUser;
  final email = (u?.email ?? '').toLowerCase();
  if (u == null || u.isAnonymous || email.isEmpty || !u.emailVerified) return '';
  try {
    final d = await _db.collection('wekils').doc(email).get();
    return (d.data()?['country'] ?? '').toString();
  } catch (_) {
    return '';
  }
}

Widget _pageScaffold(BuildContext context, String title, Widget body, {Widget? fab}) => AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: kSecondary),
          title: Text(title, style: tsTitleMd(color: kText).copyWith(fontSize: 18)),
        ),
        floatingActionButton: fab,
        body: body,
      ),
    );

// ═══════════════════════════════════════════════════════════
// 1. USER — "What do you need?"
// ═══════════════════════════════════════════════════════════
class ServiceHubScreen extends StatefulWidget {
  const ServiceHubScreen({super.key});
  @override
  State<ServiceHubScreen> createState() => _ServiceHubScreenState();
}

/// Habesha Hub <country>: choose the country, see the categories with the photos and videos
/// the wekil posted; booking goes to the wekil. "Didn't find it?" sends a request to the wekil.
class _ServiceHubScreenState extends State<ServiceHubScreen> {
  String _code = '';           // ISO code, e.g. "NO"
  String _city = '';           // region / city ('' = all regions)
  bool _loading = true;

  String get _title => tr('Habesha Hub Services');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loc = await ServiceLocation.load();
    _code = loc.$1;
    _city = loc.$2;
    if (mounted) setState(() => _loading = false);
  }


  /// "Did not find what you need?": an e-mail to Habesha Hub, no login needed
  Future<void> _ask() => emailSupport(
        subject: '${tr('Habesha Hub Services')} – ${tr(countryName(_code))}${_city.isEmpty ? '' : ' · $_city'}',
        body: '${tr('Hi! I am looking for')}: ');


  /// Country and region: the sheet lists the regions (cities) that have providers.
  Future<void> _pickCountry() async {
    final r = await pickServiceLocation(context, _code, _city, const []);
    if (r == null || !mounted) return;
    await ServiceLocation.save(r.$1, r.$2);
    setState(() { _code = r.$1; _city = r.$2; });
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    final groups = kServiceGroups;
    return _pageScaffold(context, _loading ? 'Habesha Hub' : _title, _loading
        ? Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5))
        : ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 40), children: [
            // the country: always shown, easy to change
            Material(
              color: kTintGreen,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _pickCountry,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    Text(countryFlag(_code), style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${tr(countryName(_code))} · ${_city.isEmpty ? tr('All regions') : _city}', style: tsTitleLg(color: kInkGreen)),
                      Text(tr('Choose country and region'), style: tsBodySm(color: kInkGreen)),
                    ])),
                    Icon(Icons.expand_more_rounded, color: kInkGreen),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // every category; inside: the photos and videos the wekil posted
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.35,
              children: [
                for (final g in groups)
                  Material(
                    color: kCard,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceGroupScreen(group: g, country: _code, city: _city))),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(g.emoji, style: const TextStyle(fontSize: 30)),
                          Text(tr(g.label), maxLines: 2, overflow: TextOverflow.ellipsis, style: tsTitleMd(color: kText)),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            // didn't find it? the wekil finds it
            Material(
              color: kCard,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _ask,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Text('🤝', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr('Did not find what you need?'), style: tsTitleMd(color: kText)),
                      Text('${tr('Tell')} $_title ${tr('and we find it for you')}', style: tsBodySm(color: kTextSub)),
                    ])),
                    Icon(Icons.chevron_right_rounded, color: kTextSub),
                  ]),
                ),
              ),
            ),
            if (me != null && !me.isAnonymous) ...[
              const SizedBox(height: 24),
              _MyRequests(uid: me.uid),
            ],
          ]));
  }
}

class _MyRequests extends StatelessWidget {
  final String uid;
  const _MyRequests({required this.uid});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('serviceRequests').where('userId', isEqualTo: uid).snapshots(),
      builder: (context, snap) {
        final docs = (snap.data?.docs ?? const []).toList()
          ..sort((a, b) => _ms(b.data()['createdAt']).compareTo(_ms(a.data()['createdAt'])));
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('My requests'), style: tsTitleMd(color: kText)),
          const SizedBox(height: 8),
          for (final d in docs.take(10)) _RequestTile(doc: d, forWekil: false),
        ]);
      },
    );
  }
}

int _ms(dynamic t) => t is Timestamp ? t.millisecondsSinceEpoch : 0;

class _RequestTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool forWekil;
  const _RequestTile({required this.doc, required this.forWekil});
  @override
  Widget build(BuildContext context) {
    final r = doc.data();
    final st = (r['status'] ?? 'new').toString();
    final ts = r['createdAt'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: forWekil ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => WekilRequestScreen(id: doc.id))) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(_catLabel((r['category'] ?? '').toString()), style: tsTitleMd(color: kText))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: _statusColor(st).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(100)),
                  child: Text(_statusLabel(st), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _statusColor(st))),
                ),
              ]),
              const SizedBox(height: 4),
              Text([
                if (forWekil) (r['name'] ?? '').toString(),
                (r['city'] ?? '').toString(),
                if (ts is Timestamp) DateFormat('dd.MM HH:mm').format(ts.toDate()),
              ].where((x) => x.isNotEmpty).join('  ·  '), style: tsBodySm(color: kTextSub)),
              if ((r['text'] ?? '').toString().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 4),
                    child: Text(r['text'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: tsBodySm(color: kText))),
              if (!forWekil && (r['note'] ?? '').toString().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 6),
                    child: Text('💬 ${r['note']}', style: tsBodySm(color: kInkGreen))),
              if (!forWekil && st == 'new')
                Align(alignment: Alignment.centerRight, child: TextButton(
                  onPressed: () => doc.reference.update({'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()}),
                  child: Text(tr('Cancel request'), style: tsBodySm(color: kRed)),
                )),
            ]),
          ),
        ),
      ),
    );
  }
}

class ServiceRequestForm extends StatefulWidget {
  final String country, category;
  const ServiceRequestForm({super.key, required this.country, required this.category});
  @override
  State<ServiceRequestForm> createState() => _ServiceRequestFormState();
}

class _ServiceRequestFormState extends State<ServiceRequestForm> {
  late final _name = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName ?? '');
  final _phone = TextEditingController(), _city = TextEditingController(), _when = TextEditingController(), _text = TextEditingController();
  String _error = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // fill in from the member details when we have them
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      _db.collection('members').doc(u.uid).get().then((d) {
        final m = d.data();
        if (m == null || !mounted) return;
        setState(() {
          if (_name.text.isEmpty) _name.text = (m['name'] ?? '').toString();
          if (_phone.text.isEmpty) _phone.text = (m['phone'] ?? '').toString();
          if (_city.text.isEmpty) _city.text = (m['city'] ?? '').toString();
        });
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _city, _when, _text]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _send() async {
    final digits = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (_name.text.trim().length < 2 || digits.length < 8 || _city.text.trim().isEmpty || _text.text.trim().length < 5) {
      setState(() => _error = tr('Please fill in name, WhatsApp (with country code), city and what you need.'));
      return;
    }
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    setState(() { _saving = true; _error = ''; });
    try {
      await _db.collection('serviceRequests').add({
        'userId': u.uid, 'country': widget.country, 'category': widget.category,
        'name': _name.text.trim(), 'phone': _phone.text.trim(), 'city': _city.text.trim(),
        'when': _when.text.trim(), 'text': _text.text.trim(),
        'status': 'new', 'note': '',
        'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      await showDialog(context: context, builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('✅ ${tr('Request sent')}', style: tsTitleLg(color: kText)),
        content: Text(tr('Our wekil will contact you on WhatsApp soon. You can follow the status under "My requests".'), style: tsBodyLg(color: kText)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK', style: tsTitleMd(color: kSecondary)))],
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = tr('Something went wrong. Please try again.'); });
    }
  }

  Widget _f(TextEditingController c, String label, {TextInputType? type, int lines = 1, String? hint}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(controller: c, keyboardType: type, maxLines: lines, minLines: 1, style: tsBodyLg(color: kText),
            decoration: InputDecoration(labelText: label, hintText: hint)),
      );

  @override
  Widget build(BuildContext context) {
    return _pageScaffold(context, _catLabel(widget.category), ListView(padding: const EdgeInsets.all(20), children: [
      Text('${flagOf(widget.country)} ${hubName(widget.country)}', style: tsBodySm(color: kTextSub)),
      const SizedBox(height: 14),
      _f(_text, tr('What do you need?'), lines: 4, hint: tr('E.g. food for 50 people on Saturday')),
      _f(_city, tr('City')),
      _f(_when, tr('When? (optional)')),
      _f(_name, tr('Your name')),
      _f(_phone, tr('WhatsApp number'), type: TextInputType.phone, hint: '+47…'),
      Text(tr('Only Habesha Hub and our wekil see this. It is never shown to others.'), style: tsBodySm(color: kTextSub)),
      if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error, style: tsBodySm(color: kRed))),
      const SizedBox(height: 18),
      goldButton(_saving ? '' : tr('Send request'), _saving ? null : _send, loading: _saving, icon: Icons.send_rounded),
    ]));
  }
}

// ═══════════════════════════════════════════════════════════
// 2. WEKIL (and admin) — the requests of one country
// ═══════════════════════════════════════════════════════════
class WekilInboxScreen extends StatefulWidget {
  /// '' = admin: every country
  final String country;
  const WekilInboxScreen({super.key, required this.country});
  @override
  State<WekilInboxScreen> createState() => _WekilInboxScreenState();
}

class _WekilInboxScreenState extends State<WekilInboxScreen> {
  String _filter = 'open';

  @override
  Widget build(BuildContext context) {
    final col = _db.collection('serviceRequests');
    final q = widget.country.isEmpty ? col : col.where('country', isEqualTo: widget.country);
    return _pageScaffold(context,
        widget.country.isEmpty ? '${tr('Service requests')} · ${tr('All countries')}' : '${flagOf(widget.country)} ${tr('Service requests')}',
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: q.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text(tr('Could not load requests'), style: tsBodySm(color: kTextSub)));
            if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
            final all = snap.data!.docs.toList()..sort((a, b) => _ms(b.data()['createdAt']).compareTo(_ms(a.data()['createdAt'])));
            bool open(String s) => s == 'new' || s == 'working';
            final list = all.where((d) => _filter == 'open' ? open((d.data()['status'] ?? 'new').toString()) : !open((d.data()['status'] ?? 'new').toString())).toList();
            final nOpen = all.where((d) => open((d.data()['status'] ?? 'new').toString())).length;
            return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
              Row(children: [
                ChoiceChip(label: Text('${tr('Open')} ($nOpen)'), selected: _filter == 'open', showCheckmark: false, selectedColor: kSecondary,
                    labelStyle: TextStyle(color: _filter == 'open' ? kOnAccent : kText, fontWeight: FontWeight.w600),
                    onSelected: (_) => setState(() => _filter = 'open')),
                const SizedBox(width: 8),
                ChoiceChip(label: Text(tr('Finished')), selected: _filter == 'closed', showCheckmark: false, selectedColor: kSecondary,
                    labelStyle: TextStyle(color: _filter == 'closed' ? kOnAccent : kText, fontWeight: FontWeight.w600),
                    onSelected: (_) => setState(() => _filter = 'closed')),
                const Spacer(),
                if (widget.country.isNotEmpty) IconButton(
                  tooltip: tr('Service providers'),
                  icon: Icon(Icons.storefront_rounded, color: kSecondary),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WekilProvidersScreen(country: widget.country))),
                ),
                if (_isAdmin) IconButton(
                  tooltip: tr('Wekils'),
                  icon: Icon(Icons.manage_accounts_rounded, color: kSecondary),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WekilAdminScreen())),
                ),
              ]),
              const SizedBox(height: 10),
              if (list.isEmpty) Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(child: Text(tr('No requests here'), style: tsBodyLg(color: kTextSub))),
              ),
              for (final d in list) Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (widget.country.isEmpty) Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text('${flagOf((d.data()['country'] ?? '').toString())} ${tr((d.data()['country'] ?? '').toString())}', style: tsBodySm(color: kTextSub)),
                ),
                _RequestTile(doc: d, forWekil: true),
              ]),
            ]);
          },
        ));
  }
}

class WekilRequestScreen extends StatefulWidget {
  final String id;
  const WekilRequestScreen({super.key, required this.id});
  @override
  State<WekilRequestScreen> createState() => _WekilRequestScreenState();
}

class _WekilRequestScreenState extends State<WekilRequestScreen> {
  final _note = TextEditingController();
  bool _noteLoaded = false;

  @override
  void dispose() { _note.dispose(); super.dispose(); }

  DocumentReference<Map<String, dynamic>> get _ref => _db.collection('serviceRequests').doc(widget.id);

  Future<void> _set(String status) async {
    await _ref.update({'status': status, 'note': _note.text.trim(), 'updatedAt': FieldValue.serverTimestamp()});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ ${_statusLabel(status)}'), backgroundColor: kGreen));
  }

  @override
  Widget build(BuildContext context) {
    return _pageScaffold(context, tr('Service request'), StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _ref.snapshots(),
      builder: (context, snap) {
        final r = snap.data?.data();
        if (r == null) return Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
        if (!_noteLoaded) { _note.text = (r['note'] ?? '').toString(); _noteLoaded = true; }
        final st = (r['status'] ?? 'new').toString();
        final digits = (r['phone'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
        Widget row(IconData i, String t) => t.isEmpty ? const SizedBox.shrink() : Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(i, size: 18, color: kSecondary), const SizedBox(width: 10),
                Expanded(child: Text(t, style: tsBodyLg(color: kText))),
              ]),
            );
        return ListView(padding: const EdgeInsets.all(20), children: [
          Text(_catLabel((r['category'] ?? '').toString()), style: tsHeadlineSm(color: kText)),
          const SizedBox(height: 4),
          Text(_statusLabel(st), style: tsTitleMd(color: _statusColor(st))),
          const SizedBox(height: 16),
          row(Icons.notes_rounded, (r['text'] ?? '').toString()),
          row(Icons.place_outlined, '${flagOf((r['country'] ?? '').toString())} ${r['city'] ?? ''}'),
          row(Icons.schedule_rounded, (r['when'] ?? '').toString()),
          row(Icons.person_outline_rounded, (r['name'] ?? '').toString()),
          row(Icons.phone_outlined, (r['phone'] ?? '').toString()),
          const SizedBox(height: 8),
          if (digits.length >= 8) FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            icon: const Icon(Icons.chat_rounded),
            label: Text(tr('Contact on WhatsApp'), style: const TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () => launchUrl(Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent('${hubName((r['country'] ?? '').toString())}: ${r['name'] ?? ''}')}'),
                mode: LaunchMode.externalApplication),
          ),
          const SizedBox(height: 18),
          TextField(controller: _note, maxLines: 3, minLines: 1, style: tsBodyLg(color: kText),
              decoration: InputDecoration(labelText: tr('Message to the customer (optional)'))),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (st != 'working') OutlinedButton(onPressed: () => _set('working'), child: Text(tr('I am working on it'))),
            if (st != 'done') FilledButton(style: FilledButton.styleFrom(backgroundColor: kHabGreen), onPressed: () => _set('done'), child: Text(tr('Done'))),
            if (st != 'cancelled') TextButton(onPressed: () => _set('cancelled'), child: Text(tr('Cancel request'), style: TextStyle(color: kRed))),
          ]),
        ]);
      },
    ));
  }
}

/// Opens the right inbox: admin → all countries, wekil → his country.
Future<void> openWekilInbox(BuildContext context) async {
  final c = _isAdmin ? '' : await myWekilCountry();
  if (!context.mounted || (!_isAdmin && c.isEmpty)) return;
  Navigator.push(context, MaterialPageRoute(builder: (_) => WekilInboxScreen(country: c)));
}

/// Profile row for wekils (hidden for everyone else).
class WekilRow extends StatelessWidget {
  const WekilRow({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _isAdmin ? Future.value('') : myWekilCountry(),
      builder: (context, snap) {
        final c = snap.data ?? '';
        if (!_isAdmin && c.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: kTintGreen,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => openWekilInbox(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Text(c.isEmpty ? '🌍' : flagOf(c), style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${tr('Wekil')} · ${tr('Service requests')}', style: tsTitleMd(color: kInkGreen))),
                  Icon(Icons.chevron_right_rounded, color: kInkGreen),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 3. ADMIN — who is wekil where
// ═══════════════════════════════════════════════════════════
class WekilAdminScreen extends StatelessWidget {
  const WekilAdminScreen({super.key});

  static Future<void> _syncCountries() async {
    final all = await _db.collection('wekils').get();
    final list = {for (final d in all.docs) (d.data()['country'] ?? '').toString()}..remove('');
    final phones = {for (final d in all.docs) if ((d.data()['phone'] ?? '').toString().isNotEmpty) codeOfCountry((d.data()['country'] ?? '').toString()): d.data()['phone'].toString()};
    await _db.collection('app_config').doc('wekilCountries').set({'list': list.toList()..sort(), 'phones': phones});
    _phones = null;
  }

  /// Change the wekil's name or the WhatsApp number customers book on.
  Future<void> _edit(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> d) async {
    final name = TextEditingController(text: (d.data()['name'] ?? '').toString());
    final phone = TextEditingController(text: (d.data()['phone'] ?? '').toString());
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: kCard,
      title: Text('${flagOf((d.data()['country'] ?? '').toString())} ${d.id}', style: tsTitleMd(color: kText)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, style: tsBodyLg(color: kText), decoration: InputDecoration(labelText: tr('Name'))),
        const SizedBox(height: 10),
        TextField(controller: phone, keyboardType: TextInputType.phone, style: tsBodyLg(color: kText),
            decoration: InputDecoration(labelText: tr('WhatsApp number'), hintText: '+46 …', helperText: tr('Customers see this number'))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'), style: tsBodySm(color: kTextSub))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: kSecondary, foregroundColor: kOnAccent),
            onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Save'))),
      ],
    ));
    if (ok != true) return;
    await d.reference.update({'name': name.text.trim(), 'phone': phone.text.trim(), 'code': codeOfCountry((d.data()['country'] ?? '').toString())});
    await _syncCountries();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ ${tr('Saved')}'), backgroundColor: kGreen));
    }
  }

  Future<void> _add(BuildContext context) async {
    final email = TextEditingController(), name = TextEditingController(), phone = TextEditingController();
    String country = 'Norway';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      backgroundColor: kCard,
      title: Text(tr('Add wekil'), style: tsTitleLg(color: kText)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: email, keyboardType: TextInputType.emailAddress, style: tsBodyLg(color: kText),
            decoration: InputDecoration(labelText: tr('Email'), hintText: 'samiefr+norge@gmail.com')),
        const SizedBox(height: 10),
        TextField(controller: name, style: tsBodyLg(color: kText), decoration: InputDecoration(labelText: tr('Name'))),
        const SizedBox(height: 10),
        TextField(controller: phone, keyboardType: TextInputType.phone, style: tsBodyLg(color: kText),
            decoration: InputDecoration(labelText: tr('WhatsApp number'), hintText: '+47 …', helperText: tr('Customers see this number'))),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: country, dropdownColor: kCard, style: tsBodyLg(color: kText),
          items: [for (final c in kWekilCountries) DropdownMenuItem(value: c, child: Text('${flagOf(c)} ${tr(c)}'))],
          onChanged: (v) => setS(() => country = v ?? country),
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'), style: tsBodySm(color: kTextSub))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: kSecondary, foregroundColor: kOnAccent),
            onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Save'))),
      ],
    )));
    final e = email.text.trim().toLowerCase();
    if (ok != true || !e.contains('@')) return;
    await _db.collection('wekils').doc(e).set({'country': country, 'code': codeOfCountry(country), 'name': name.text.trim(),
        'phone': phone.text.trim(), 'createdAt': FieldValue.serverTimestamp()});
    await _syncCountries();
  }

  @override
  Widget build(BuildContext context) {
    return _pageScaffold(context, tr('Wekils'), StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('wekils').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
        final docs = snap.data!.docs;
        return ListView(padding: const EdgeInsets.all(16), children: [
          Text(tr('Each wekil logs in with his own email and password and sees only the requests of his country. Tip: samiefr+norge@gmail.com, samiefr+sverige@gmail.com … all arrive in samiefr@gmail.com.'),
              style: tsBodySm(color: kTextSub)),
          const SizedBox(height: 14),
          if (docs.isEmpty) Text(tr('No wekils yet'), style: tsBodyLg(color: kTextSub)),
          for (final d in docs)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Text(flagOf((d.data()['country'] ?? '').toString()), style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${d.data()['name'] ?? ''}'.isEmpty ? tr((d.data()['country'] ?? '').toString()) : '${d.data()['name']} · ${tr((d.data()['country'] ?? '').toString())}',
                      style: tsTitleMd(color: kText)),
                  Text([d.id, (d.data()['phone'] ?? '').toString()].where((x) => x.isNotEmpty).join('  ·  '), style: tsBodySm(color: kTextSub)),
                ])),
                IconButton(icon: Icon(Icons.edit_outlined, color: kSecondary), tooltip: tr('Edit'),
                    onPressed: () => _edit(context, d)),
                IconButton(icon: Icon(Icons.delete_outline_rounded, color: kRed), tooltip: tr('Remove'),
                    onPressed: () async { await d.reference.delete(); await _syncCountries(); }),
              ]),
            ),
        ]);
      },
    ), fab: FloatingActionButton.extended(
      onPressed: () => _add(context),
      backgroundColor: kSecondary, foregroundColor: kOnAccent,
      icon: const Icon(Icons.person_add_alt_1_rounded),
      label: Text(tr('Add wekil'), style: const TextStyle(fontWeight: FontWeight.w700)),
    ));
  }
}

// ═══════════════════════════════════════════════════════════
// 4. WEKIL — the service providers of his country (add, edit, show / hide)
//   anonymous_services where country == ISO code; customers contact the wekil
// ═══════════════════════════════════════════════════════════
class WekilProvidersScreen extends StatelessWidget {
  final String country;
  const WekilProvidersScreen({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    final code = codeOfCountry(country);
    return _pageScaffold(context, '${flagOf(country)} ${tr('Service providers')}', StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('anonymous_services').where('country', isEqualTo: code).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(tr('Could not load requests'), style: tsBodySm(color: kTextSub)));
        if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
        final docs = snap.data!.docs.toList()
          ..sort((a, b) => serviceText(a.data(), 'publicName').toLowerCase().compareTo(serviceText(b.data(), 'publicName').toLowerCase()));
        return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
          Text(tr('Customers see these providers, but WhatsApp and call go to you as wekil.'), style: tsBodySm(color: kTextSub)),
          const SizedBox(height: 12),
          if (docs.isEmpty) Padding(padding: const EdgeInsets.only(top: 30),
              child: Center(child: Text(tr('No service providers yet'), style: tsBodyLg(color: kTextSub)))),
          for (final d in docs) Builder(builder: (context) {
            final m = d.data();
            final live = m['available'] == true;
            final imgs = serviceImages(m);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 52, height: 52,
                    child: imgs.isNotEmpty ? Image.network(imgs.first, fit: BoxFit.cover, cacheWidth: 160,
                        errorBuilder: (_, __, ___) => Container(color: kTintGreen)) : Container(color: kTintGreen,
                        child: Icon(Icons.storefront_rounded, color: kInkGreen)))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(serviceText(m, 'publicName'), maxLines: 1, overflow: TextOverflow.ellipsis, style: tsTitleMd(color: kText)),
                  Text([serviceSubLabel(m), serviceStr(m['city']), serviceStr(m['whatsapp'])].where((x) => x.isNotEmpty).join(' · '),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: tsBodySm(color: kTextSub)),
                ])),
                Switch(value: live, activeThumbColor: kHabGreen,
                    onChanged: (v) => d.reference.update({'available': v, 'status': v ? 'approved' : 'paused', 'updatedAt': FieldValue.serverTimestamp()})),
                IconButton(icon: Icon(Icons.edit_outlined, color: kSecondary),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceFormScreen(docId: d.id, existing: m, wekilCode: code)))),
              ]),
            );
          }),
        ]);
      },
    ), fab: FloatingActionButton.extended(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceFormScreen(wekilCode: code))),
      backgroundColor: kSecondary, foregroundColor: kOnAccent,
      icon: const Icon(Icons.add_business_outlined),
      label: Text(tr('Add service provider'), style: const TextStyle(fontWeight: FontWeight.w700)),
    ));
  }
}

/// Only the wekil (or admin) adds service providers; everyone else is told whom to contact.
Future<String?> wekilCodeOrExplain(BuildContext context) async {
  if (_isAdmin) return 'ADMIN';
  final code = await myWekilCode();
  if (code.isNotEmpty) return code;
  if (!context.mounted) return null;
  if (!context.mounted) return null;
  await showDialog(context: context, builder: (ctx) => AlertDialog(
    backgroundColor: kCard,
    title: Text(tr('Habesha Hub Services'), style: tsTitleLg(color: kText)),
    content: Text(tr('Service providers are added by our wekil. Do you offer a service? Contact us and we add you.'), style: tsBodyLg(color: kText)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancel'), style: tsBodySm(color: kTextSub))),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: kSecondary, foregroundColor: kOnAccent),
        onPressed: () {
          Navigator.pop(ctx);
          emailSupport(subject: 'Service provider', body: tr('Hi, I offer a service and want to be on Habesha Hub'));
        },
        child: Text(tr('Email')),
      ),
    ],
  ));
  return null;
}

/// Bottom of a provider page: "Book now" opens WhatsApp to the wekil of that country
/// (or Habesha Hub's own number) with the service name, e.g. "Decoration 2". No login needed.
class WekilContactBar extends StatelessWidget {
  final Map<String, dynamic> data;
  final Widget Function()? fallback; // not used any more; kept so old callers still compile
  const WekilContactBar({super.key, required this.data, this.fallback});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: wekilPhones(),
      builder: (context, snap) {
        final code = serviceStr(data['country']);
        var phone = snap.data?[code] ?? '';
        if (phone.replaceAll(RegExp(r'[^0-9]'), '').length < 8) phone = '+47 973 74 482';
        final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
        final name = serviceText(data, 'publicName'), city = serviceStr(data['city']);
        final msg = '${tr('Hi Habesha Hub Services! I want to book')}: $name${city.isEmpty ? '' : ' ($city)'}. ${tr('Please call me back.')}';
        return SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${tr('Book through Habesha Hub Services')} · $phone', style: tsBodySm(color: kTextSub)),
            const SizedBox(height: 6),
            SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () => launchUrl(Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(msg)}'), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.chat_rounded),
              label: Text(tr('Book now on WhatsApp'), style: const TextStyle(fontWeight: FontWeight.w800)))),
          ]),
        ));
      },
    );
  }
}

/// Admin, or the wekil of that country (ISO code; '' = any country): may add and edit service providers.
Future<bool> canManageServices([String code = '']) async {
  if (_isAdmin) return true;
  final mine = await myWekilCode();
  return mine.isNotEmpty && (code.isEmpty || mine == code);
}

/// Shows its child only to the admin and the wekil of [country] (everyone else sees nothing).
class WekilOnly extends StatelessWidget {
  final Widget child;
  final String country; // ISO code; '' = any wekil
  const WekilOnly({super.key, required this.child, this.country = ''});
  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: canManageServices(country),
        builder: (_, snap) => snap.data == true ? child : const SizedBox.shrink(),
      );
}
