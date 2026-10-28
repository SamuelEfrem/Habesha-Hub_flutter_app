import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';
import 'auth_screen.dart';

// ═══════════════════════════════════════════════════════════
// Community help: claim a business, report wrong info, suggest a
// missing business — plus the admin tabs that review them.
//   claims/{id}       → admin approves → business gets this owner
//   reports/{id}      → admin fixes / hides the business
//   suggestions/{id}  → admin approves → becomes a live business
// ═══════════════════════════════════════════════════════════

final _db = FirebaseFirestore.instance;

/// Real (non-guest) account, or ask the user to log in first
Future<User?> _requireLogin(BuildContext context) async {
  var user = FirebaseAuth.instance.currentUser;
  if (user != null && !user.isAnonymous) return user;
  await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true)));
  user = FirebaseAuth.instance.currentUser;
  return (user != null && !user.isAnonymous) ? user : null;
}

void _toast(BuildContext context, String text, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(text, style: tsBodySm(color: Colors.white)),
    backgroundColor: color ?? kGreen,
  ));
}

Widget _sheetHandle() => Center(
      child: Container(
        width: 40, height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: kTextSub.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
      ),
    );

Widget _field(TextEditingController c, String label,
    {String? hint, int lines = 1, TextInputType? type, IconData? icon}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      maxLines: lines,
      keyboardType: type,
      style: tsBodyLg(color: kText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: tsBodySm(color: kTextSub),
        prefixIcon: icon == null ? null : Icon(icon, color: kSecondary, size: 20),
        filled: true,
        fillColor: kCardHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    ),
  );
}

// ── Card on imported businesses: "Is this your business?" ──
class ClaimBusinessCard extends StatelessWidget {
  final Business business;
  const ClaimBusinessCard({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSecondary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showClaimSheet(context, business),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kSecondary.withOpacity(0.4)),
          ),
          child: Row(children: [
            const Icon(Icons.storefront_rounded, color: kSecondary, size: 28),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('Is this your business?'), style: tsTitleLg(color: kText)),
              const SizedBox(height: 2),
              Text(tr('Claim it for free — add photos, opening hours and your menu'),
                  style: tsBodySm(color: kTextSub)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: kSecondary),
          ]),
        ),
      ),
    );
  }
}

Future<void> showClaimSheet(BuildContext context, Business business) async {
  final user = await _requireLogin(context);
  if (user == null || !context.mounted) return;

  // Already asked?
  final mine = await _db.collection('claims')
      .where('userId', isEqualTo: user.uid)
      .where('businessId', isEqualTo: business.id)
      .limit(1).get();
  if (!context.mounted) return;
  if (mine.docs.isNotEmpty) {
    _toast(context, tr('You already sent a claim for this business — we will contact you'), color: kCardHigh);
    return;
  }

  final name = TextEditingController(text: user.displayName ?? '');
  final phone = TextEditingController();
  final role = TextEditingController();
  final message = TextEditingController();
  var sending = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kBg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sheetHandle(),
        Text(tr('Claim this business'), style: tsHeadlineMd(color: kText)),
        const SizedBox(height: 4),
        Text(business.name, style: tsTitleMd(color: kSecondary)),
        const SizedBox(height: 6),
        Text(tr('We check every claim before you get access. This usually takes 1–2 days.'),
            style: tsBodySm(color: kTextSub)),
        const SizedBox(height: 16),
        _field(name, tr('Your name'), icon: Icons.person_rounded),
        _field(phone, tr('Phone number'), type: TextInputType.phone, icon: Icons.phone_rounded),
        _field(role, tr('Your role'), hint: tr('Owner, manager …'), icon: Icons.badge_rounded),
        _field(message, tr('Message (optional)'), lines: 3),
        const SizedBox(height: 4),
        goldButton(tr('Send claim'), sending ? null : () async {
          if (name.text.trim().isEmpty || phone.text.trim().isEmpty) {
            _toast(ctx, tr('Please add your name and phone number'), color: kRed);
            return;
          }
          setSheet(() => sending = true);
          try {
            await _db.collection('claims').add({
              'businessId': business.id,
              'businessName': business.name,
              'businessAddress': business.address,
              'userId': user.uid,
              'email': user.email ?? '',
              'name': name.text.trim(),
              'phone': phone.text.trim(),
              'role': role.text.trim(),
              'message': message.text.trim(),
              'status': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
            });
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) _toast(context, tr('Thank you! We will contact you soon'));
          } catch (e) {
            setSheet(() => sending = false);
            if (ctx.mounted) _toast(ctx, '${tr('Error')}: $e', color: kRed);
          }
        }, loading: sending, icon: Icons.verified_rounded),
      ])),
    )),
  );
}

// ── "Report wrong info" ──
const _reportReasons = [
  'Permanently closed',
  'Wrong address or location',
  'Wrong phone or opening hours',
  'Not a Habesha business',
  'Other',
];

Future<void> showReportSheet(BuildContext context, Business business) async {
  String? reason;
  final note = TextEditingController();
  var sending = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kBg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sheetHandle(),
        Text(tr('What is wrong?'), style: tsHeadlineMd(color: kText)),
        const SizedBox(height: 4),
        Text(business.name, style: tsTitleMd(color: kSecondary)),
        const SizedBox(height: 12),
        for (final r in _reportReasons)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: reason == r ? kSecondary.withOpacity(0.15) : kCard,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setSheet(() => reason = r),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(children: [
                    Icon(reason == r ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: kSecondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(tr(r), style: tsBodyLg(color: kText))),
                  ]),
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        _field(note, tr('Details (optional)'), lines: 2),
        goldButton(tr('Send'), (reason == null || sending) ? null : () async {
          setSheet(() => sending = true);
          try {
            await _db.collection('reports').add({
              'businessId': business.id,
              'businessName': business.name,
              'reason': reason,
              'note': note.text.trim(),
              'userId': FirebaseAuth.instance.currentUser?.uid,
              'status': 'open',
              'createdAt': FieldValue.serverTimestamp(),
            });
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) _toast(context, tr('Thank you for helping us keep Habesha Hub correct'));
          } catch (e) {
            setSheet(() => sending = false);
            if (ctx.mounted) _toast(ctx, '${tr('Error')}: $e', color: kRed);
          }
        }, loading: sending),
      ])),
    )),
  );
}

// ── "Suggest a business" ──
class SuggestBusinessScreen extends StatefulWidget {
  final String country;
  const SuggestBusinessScreen({super.key, this.country = ''});
  @override
  State<SuggestBusinessScreen> createState() => _SuggestBusinessScreenState();
}

class _SuggestBusinessScreenState extends State<SuggestBusinessScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  late final _country = TextEditingController(text: widget.country);
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _note = TextEditingController();
  String _category = 'Restaurant';
  bool _sending = false;

  static const _categories = ['Restaurant', 'Cafe', 'Shop', 'Barber', 'Club', 'Clinic', 'Hotel', 'Other'];

  Future<void> _send() async {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty ||
        _city.text.trim().isEmpty || _country.text.trim().isEmpty) {
      _toast(context, tr('Please fill in name, address, city and country'), color: kRed);
      return;
    }
    final user = await _requireLogin(context);
    if (user == null || !mounted) return;
    setState(() => _sending = true);
    // GPS position from the address (so it shows up in "near me")
    double lat = 0, lng = 0;
    try {
      final hits = await locationFromAddress('${_address.text.trim()}, ${_city.text.trim()}, ${_country.text.trim()}');
      if (hits.isNotEmpty) { lat = hits.first.latitude; lng = hits.first.longitude; }
    } catch (_) {}
    try {
      await _db.collection('suggestions').add({
        'name': _name.text.trim(),
        'category': _category,
        'address': '${_address.text.trim()}, ${_city.text.trim()}',
        'country': _country.text.trim(),
        'phone': _phone.text.trim(),
        'website': _website.text.trim(),
        'note': _note.text.trim(),
        'lat': lat,
        'lng': lng,
        'userId': user.uid,
        'email': user.email ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      _toast(context, tr('Thank you! We will check it and add it soon'));
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        _toast(context, '${tr('Error')}: $e', color: kRed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Text(tr('Suggest a business'), style: tsHeadlineSm(color: kText)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        Text(tr('Know a Habesha place that is missing? Tell us and we will add it.'),
            style: tsBodyLg(color: kTextSub)),
        const SizedBox(height: 18),
        _field(_name, tr('Business name'), icon: Icons.storefront_rounded),
        Text(tr('Category'), style: tsTitleMd(color: kTextSub)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in _categories)
            ChoiceChip(
              label: Text(tr(c)),
              selected: _category == c,
              onSelected: (_) => setState(() => _category = c),
              showCheckmark: false,
              selectedColor: kSecondary,
              backgroundColor: kCard,
              side: BorderSide.none,
              labelStyle: TextStyle(fontFamily: kFontBody, fontWeight: FontWeight.w600,
                  color: _category == c ? const Color(0xFF1A1200) : kText),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
        ]),
        const SizedBox(height: 16),
        _field(_address, tr('Street and number'), icon: Icons.place_rounded),
        Row(children: [
          Expanded(child: _field(_city, tr('City'))),
          const SizedBox(width: 10),
          Expanded(child: _field(_country, tr('Country'))),
        ]),
        _field(_phone, tr('Phone (optional)'), type: TextInputType.phone, icon: Icons.phone_rounded),
        _field(_website, tr('Website or Instagram (optional)'), icon: Icons.language_rounded),
        _field(_note, tr('Anything else? (optional)'), lines: 3),
        const SizedBox(height: 8),
        goldButton(tr('Send suggestion'), _sending ? null : _send, loading: _sending, icon: Icons.send_rounded),
      ]),
    );
  }
}

/// Button used in Explore / empty lists
Widget suggestBusinessButton(BuildContext context, {String country = ''}) {
  return TextButton.icon(
    onPressed: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => SuggestBusinessScreen(country: country))),
    icon: const Icon(Icons.add_business_rounded, color: kSecondary, size: 20),
    label: Text(tr('Suggest a business'), style: tsTitleMd(color: kSecondary)),
  );
}

// ═══════════════════════════════════════════════════════════
// ADMIN TABS
// ═══════════════════════════════════════════════════════════

String _when(dynamic ts) => ts is Timestamp ? DateFormat('dd.MM HH:mm').format(ts.toDate()) : '';

Widget _empty(IconData icon, String text) => Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: kTextSub.withOpacity(0.5), size: 52),
        const SizedBox(height: 12),
        Text(text, style: tsTitleMd(color: kText)),
      ]),
    );

Widget _adminCard({required Widget child, Color? edge}) => Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: edge ?? kSecondary, width: 3)),
      ),
      child: child,
    );

Widget _pill(IconData icon, String label, Color color, VoidCallback onTap) => Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: tsTitleMd(color: color).copyWith(fontSize: 12)),
          ]),
        ),
      ),
    );

Widget _line(IconData icon, String text) => text.isEmpty ? const SizedBox.shrink() : Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: kSecondary, size: 15),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: tsBodySm(color: kText))),
      ]),
    );

class ClaimsAdminTab extends StatelessWidget {
  const ClaimsAdminTab({super.key});

  Future<void> _approve(BuildContext context, QueryDocumentSnapshot doc) async {
    final c = doc.data() as Map<String, dynamic>;
    await _db.collection('businesses').doc(c['businessId']).update({
      'ownerId': c['userId'],
      'ownerEmail': c['email'] ?? '',
      'ownerName': c['name'] ?? '',
      if ((c['phone'] ?? '').toString().isNotEmpty) 'ownerPhone': c['phone'],
    });
    await doc.reference.update({'status': 'approved', 'reviewedAt': FieldValue.serverTimestamp()});
    if (context.mounted) _toast(context, '✓ ${c['name']} now owns ${c['businessName']}');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('claims').where('status', isEqualTo: 'pending').snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _empty(Icons.verified_user_rounded, 'No claims to review');
        return ListView(padding: const EdgeInsets.all(16), children: [
          for (final d in docs) Builder(builder: (_) {
            final c = d.data() as Map<String, dynamic>;
            return _adminCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('${c['businessName'] ?? ''}', style: tsTitleLg(color: kText))),
                Text(_when(c['createdAt']), style: tsBodySm(color: kTextSub)),
              ]),
              _line(Icons.place_rounded, '${c['businessAddress'] ?? ''}'),
              const SizedBox(height: 6),
              _line(Icons.person_rounded, [c['name'], c['role']].where((s) => (s ?? '').toString().isNotEmpty).join('  ·  ')),
              _line(Icons.phone_rounded, '${c['phone'] ?? ''}'),
              _line(Icons.email_rounded, '${c['email'] ?? ''}'),
              _line(Icons.chat_rounded, '${c['message'] ?? ''}'),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _pill(Icons.check_rounded, 'Approve owner', kGreen, () => _approve(context, d)),
                _pill(Icons.close_rounded, 'Reject', kRed, () => d.reference.update({'status': 'rejected'})),
              ]),
            ]));
          }),
        ]);
      },
    );
  }
}

class ReportsAdminTab extends StatelessWidget {
  const ReportsAdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('reports').where('status', isEqualTo: 'open').snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _empty(Icons.flag_rounded, 'No reports');
        return ListView(padding: const EdgeInsets.all(16), children: [
          for (final d in docs) Builder(builder: (_) {
            final r = d.data() as Map<String, dynamic>;
            return _adminCard(edge: kRed, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('${r['businessName'] ?? ''}', style: tsTitleLg(color: kText))),
                Text(_when(r['createdAt']), style: tsBodySm(color: kTextSub)),
              ]),
              const SizedBox(height: 4),
              Text('${r['reason'] ?? ''}', style: tsTitleMd(color: kRed)),
              _line(Icons.notes_rounded, '${r['note'] ?? ''}'),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _pill(Icons.visibility_off_rounded, 'Hide business', kRed, () async {
                  await _db.collection('businesses').doc(r['businessId']).update({'status': 'rejected'});
                  await d.reference.update({'status': 'resolved', 'action': 'hidden'});
                }),
                _pill(Icons.check_rounded, 'Fixed / ignore', kGreen,
                    () => d.reference.update({'status': 'resolved'})),
              ]),
            ]));
          }),
        ]);
      },
    );
  }
}

class SuggestionsAdminTab extends StatelessWidget {
  const SuggestionsAdminTab({super.key});

  Future<void> _approve(BuildContext context, QueryDocumentSnapshot doc) async {
    final s = doc.data() as Map<String, dynamic>;
    final ref = await _db.collection('businesses').add({
      'name': s['name'] ?? '',
      'category': s['category'] ?? 'Other',
      'description': '',
      'address': s['address'] ?? '',
      'country': s['country'] ?? '',
      'lat': (s['lat'] ?? 0).toDouble(),
      'lng': (s['lng'] ?? 0).toDouble(),
      'phone': s['phone'] ?? '',
      'website': (s['website'] ?? '').toString().isEmpty ? null : s['website'],
      'imageUrl': '', 'rating': 0, 'ratingCount': 0,
      'isOpen': false, 'isPremium': false, 'pdfMenuUrl': null,
      'openingHours': {}, 'galleryImages': [], 'promoVideoUrl': null,
      'ownerId': '', 'ownerEmail': '', 'ownerName': '',
      'status': 'approved', 'source': 'suggestion',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await doc.reference.update({'status': 'approved', 'businessId': ref.id});
    if (context.mounted) _toast(context, '✓ ${s['name']} is live');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('suggestions').where('status', isEqualTo: 'pending').snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _empty(Icons.add_business_rounded, 'No suggestions');
        return ListView(padding: const EdgeInsets.all(16), children: [
          for (final d in docs) Builder(builder: (_) {
            final s = d.data() as Map<String, dynamic>;
            final noGps = (s['lat'] ?? 0) == 0;
            return _adminCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('${s['name'] ?? ''}', style: tsTitleLg(color: kText))),
                Text(_when(s['createdAt']), style: tsBodySm(color: kTextSub)),
              ]),
              Text('${s['category'] ?? ''}  ·  ${s['country'] ?? ''}', style: tsBodySm(color: kSecondary)),
              _line(Icons.place_rounded, '${s['address'] ?? ''}'),
              if (noGps) _line(Icons.warning_amber_rounded, 'No GPS position found — edit the address after approving'),
              _line(Icons.phone_rounded, '${s['phone'] ?? ''}'),
              _line(Icons.language_rounded, '${s['website'] ?? ''}'),
              _line(Icons.notes_rounded, '${s['note'] ?? ''}'),
              _line(Icons.person_rounded, 'Suggested by ${s['email'] ?? ''}'),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _pill(Icons.check_rounded, 'Approve & publish', kGreen, () => _approve(context, d)),
                _pill(Icons.close_rounded, 'Reject', kRed, () => d.reference.update({'status': 'rejected'})),
              ]),
            ]));
          }),
        ]);
      },
    );
  }
}

// ── Codes that unlock paid content (sent to the customer on WhatsApp) ──
class UnlockCodesAdminTab extends StatefulWidget {
  const UnlockCodesAdminTab({super.key});
  @override
  State<UnlockCodesAdminTab> createState() => _UnlockCodesAdminTabState();
}

class _UnlockCodesAdminTabState extends State<UnlockCodesAdminTab> {
  final _phone = TextEditingController(text: '+47');
  String _product = 'theory_pro';
  bool _busy = false;

  static const _products = {'theory_pro': '🚗 Driving theory (450)', 'lang_pro': '🗣️ Languages'};
  // No 0/O or 1/I so codes are easy to read out
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _special = '!#@\$%&?+';   // no * _ ~ (WhatsApp formatting)

  final _rnd = Random.secure();
  // HH + 8 characters with 2 special characters at random places
  String _newCode() {
    final c = List.generate(6, (_) => _chars[_rnd.nextInt(_chars.length)]);
    for (var i = 0; i < 2; i++) {
      c.insert(_rnd.nextInt(c.length + 1), _special[_rnd.nextInt(_special.length)]);
    }
    return 'HH${c.join()}';
  }

  String get _cleanPhone {
    var p = _phone.text.replaceAll(RegExp(r'[^\d+]'), '');
    if (p.startsWith('00')) p = '+${p.substring(2)}';
    if (!p.startsWith('+') && p.length == 8) p = '+47$p';   // Norwegian number without country code
    return p;
  }

  Future<void> _create() async {
    // Empty (or only "+47") = the code belongs to the first user who uses it
    var phone = _cleanPhone;
    if (phone.replaceAll('+', '').length <= 3) phone = '';
    if (phone.isNotEmpty && phone.replaceAll('+', '').length < 8) {
      _toast(context, 'Write the full phone number, e.g. +47 412 34 567 — or leave it empty', color: kRed);
      return;
    }
    setState(() => _busy = true);
    var code = _newCode();
    while ((await _db.collection('unlock_codes').doc(code).get()).exists) { code = _newCode(); }
    await _db.collection('unlock_codes').doc(code).set({
      'product': _product, 'phone': phone, 'used': false, 'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() => _busy = false);
    if (!mounted) return;
    if (phone.isNotEmpty) {
      _sendOnWhatsApp(code, phone, _product);
    } else {
      Clipboard.setData(ClipboardData(text: code));
      _toast(context, 'Code $code copied — works for the first user who types it');
    }
  }

  void _sendOnWhatsApp(String code, String phone, String product) {
    final what = product == 'theory_pro' ? '450 extra driving theory questions' : 'the extra language topics';
    final msg = 'Habesha Hub 🔓\nYour code: $code\n\nOpen Games & Tools → Life Tools → "Unlock" and type the code. '
        'It works for one person only.\nThis unlocks $what.\n\n'
        'ኮድካ: $code — ኣብ Games & Tools → Life Tools → "ክፈት ብኮድ" ኣእትዎ።';
    launchUrl(Uri.parse('https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(msg)}'),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _adminCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('New code', style: tsTitleLg(color: kText)),
        const SizedBox(height: 4),
        Text('Works once. With a phone number: only that number (SMS check). Empty: the first user who types it.',
            style: tsBodySm(color: kTextSub)),
        const SizedBox(height: 12),
        _field(_phone, 'Customer phone number (optional)', type: TextInputType.phone, icon: Icons.phone_rounded),
        Wrap(spacing: 8, children: [
          for (final e in _products.entries)
            ChoiceChip(
              label: Text(e.value), selected: _product == e.key, showCheckmark: false,
              onSelected: (_) => setState(() => _product = e.key),
              selectedColor: kSecondary, backgroundColor: kCardHigh, side: BorderSide.none,
              labelStyle: TextStyle(fontFamily: kFontBody, fontWeight: FontWeight.w600,
                  color: _product == e.key ? const Color(0xFF1A1200) : kText),
            ),
        ]),
        const SizedBox(height: 12),
        goldButton('Make code', _busy ? null : _create, loading: _busy, icon: Icons.key_rounded),
      ])),
      const SizedBox(height: 8),
      Text('Codes', style: tsTitleMd(color: kTextSub)),
      const SizedBox(height: 8),
      StreamBuilder<QuerySnapshot>(
        stream: _db.collection('unlock_codes').orderBy('createdAt', descending: true).limit(50).snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
          if (snap.data!.docs.isEmpty) return _empty(Icons.key_rounded, 'No codes yet');
          return Column(children: [
            for (final d in snap.data!.docs) Builder(builder: (_) {
              final c = d.data() as Map<String, dynamic>;
              final master = c['master'] == true;
              final used = c['used'] == true && !master;
              return _adminCard(edge: master ? kPrimaryContainer : used ? kGreen : kSecondary, child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SelectableText(d.id, style: tsTitleLg(color: kText).copyWith(letterSpacing: 2)),
                  Text(master
                          ? '👑 MASTER KEY · unlocks everything · reusable'
                          : '${_products[c['product']] ?? c['product']}  ·  ${(c['phone'] ?? '').toString().isEmpty ? 'any one user' : c['phone']}${c['usedPhone'] != null ? '  →  ${c['usedPhone']}' : ''}',
                      style: tsBodySm(color: master ? kSecondary : kTextSub)),
                  Text(master
                          ? 'Used ${c['uses'] ?? 0} times${c['lastUsedAt'] != null ? ' · last ${_when(c['lastUsedAt'])}' : ''}'
                          : used ? '✓ Used ${_when(c['usedAt'])}' : 'Not used yet · ${_when(c['createdAt'])}',
                      style: tsBodySm(color: used ? kGreen : kSecondary)),
                ])),
                if (!used) ...[
                  IconButton(tooltip: 'Copy',
                      onPressed: () { Clipboard.setData(ClipboardData(text: d.id)); _toast(context, '${d.id} copied'); },
                      icon: const Icon(Icons.copy_rounded, color: kSecondary)),
                  if ((c['phone'] ?? '').toString().isNotEmpty)
                    IconButton(tooltip: 'Send on WhatsApp',
                        onPressed: () => _sendOnWhatsApp(d.id, '${c['phone']}', '${c['product']}'),
                        icon: const Icon(Icons.send_rounded, color: kSecondary)),
                  IconButton(tooltip: 'Delete',
                      onPressed: () => d.reference.delete(),
                      icon: const Icon(Icons.delete_outline_rounded, color: kRed)),
                ],
              ]));
            }),
          ]);
        },
      ),
    ]);
  }
}
