import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/share_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../utils/theme_notifier.dart';
import '../utils/translations.dart';
import 'auth_screen.dart';
import 'marketplace_screen.dart';

// ═══════════════════════════════════════════════════════════
// HOUSING (Market > Housing) — rent out or look for apartments and rooms.
//   housing/{id}  status: pending → approved (by the admin) → rented; rejected
// Its own collection so the rules can really keep pending listings private
// (the Market collection is readable by everyone and filtered in the app).
// The app never handles money and never stores an exact address.
// ═══════════════════════════════════════════════════════════

final _db = FirebaseFirestore.instance;
CollectionReference<Map<String, dynamic>> get _col => _db.collection('housing');

bool get _isAdmin {
  final u = FirebaseAuth.instance.currentUser;
  return u != null && (u.uid == 'W3z67R3wiXUVvcPFDS0oxgfaDlj1' || u.email == 'samuelefriem@gmail.com');
}

String _s(dynamic v) => v == null ? '' : v.toString().trim();
num? _n(dynamic v) => v is num ? v : num.tryParse(_s(v).replaceAll(RegExp(r'[^0-9.]'), ''));
String _digits(String p) => p.replaceAll(RegExp(r'[^0-9]'), '');

const _types = ['forRent', 'room', 'looking', 'shortTerm'];
String _typeLabel(String k) => switch (k) {
      'room' => tr('Room for rent'),
      'looking' => tr('Looking for housing'),
      'shortTerm' => tr('Short-term'),
      _ => tr('For rent'),
    };
IconData _typeIcon(String k) => switch (k) {
      'room' => Icons.bed_outlined,
      'looking' => Icons.person_search_outlined,
      'shortTerm' => Icons.event_outlined,
      _ => Icons.home_outlined,
    };

/// Countries with their currency (the price is per month in this currency)
const _countries = [
  ('NO', 'Norway', 'kr'), ('SE', 'Sweden', 'SEK'), ('DK', 'Denmark', 'DKK'), ('DE', 'Germany', 'EUR'),
  ('NL', 'Netherlands', 'EUR'), ('IT', 'Italy', 'EUR'), ('CH', 'Switzerland', 'CHF'), ('GB', 'United Kingdom', 'GBP'),
  ('US', 'United States', 'USD'), ('CA', 'Canada', 'CAD'), ('ER', 'Eritrea', 'ERN'), ('ET', 'Ethiopia', 'ETB'),
  ('UG', 'Uganda', 'UGX'), ('KE', 'Kenya', 'KES'), ('SS', 'South Sudan', 'SSP'),
];
String _countryName(String code) => tr(_countries.firstWhere((c) => c.$1 == code, orElse: () => ('', code, '')).$2);
String _currency(String code) => _countries.firstWhere((c) => c.$1 == code, orElse: () => ('', '', '')).$3;

String _money(num? v, String cur) {
  if (v == null || v == 0) return '';
  final s = v.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
  return cur == 'kr' ? '$s kr' : '$s $cur';
}

/// "2026-12-01" → "01.12.2026"
String _date(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

bool _looking(Map d) => _s(d['type']) == 'looking';
List<String> _photos(Map d) => ((d['photos'] as List?) ?? []).map(_s).where((e) => e.isNotEmpty).toList();

String _priceLine(Map d) {
  final cur = _s(d['currency']);
  if (_looking(d)) {
    final b = _money(_n(d['budget']), cur);
    return b.isEmpty ? '' : '${tr('Budget')} $b ${tr('/ month')}';
  }
  final p = _money(_n(d['rentMonth']), cur);
  if (p.isEmpty) return '';
  return _s(d['type']) == 'shortTerm' ? p : '$p ${tr('/ month')}';
}

String _sizeLine(Map d) {
  final r = _n(d['rooms']), m = _n(d['sizeM2']);
  return [
    if (r != null && r > 0) '${r.round()} ${tr('rooms')}',
    if (m != null && m > 0) '${m.round()} m²',
  ].join(' · ');
}

Widget _chip(String label, {Color? bg, Color? fg, IconData? icon}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg ?? kCard, borderRadius: BorderRadius.circular(100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 15, color: fg ?? kText), const SizedBox(width: 5)],
        Text(label, style: tsBodySm(color: fg ?? kText).copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );

Widget _circleBtn(IconData icon, VoidCallback onTap, String tooltip, {Color? bg, Color? fg}) => Tooltip(
      message: tooltip,
      child: Material(
        color: bg ?? kCard,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, color: fg ?? kText, size: 22)),
        ),
      ),
    );

Future<User?> _realUser(BuildContext context) async {
  var u = FirebaseAuth.instance.currentUser;
  if (u == null || u.isAnonymous) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true)));
    u = FirebaseAuth.instance.currentUser;
  }
  return (u == null || u.isAnonymous) ? null : u;
}

// ═══════════════════════════════════════════════════════════
// LIST with filters
// ═══════════════════════════════════════════════════════════
/// Opens the form for a new housing listing (guests log in first).
Future<void> openHousingForm(BuildContext context) async {
  final u = await _realUser(context);
  if (u == null || !context.mounted) return;
  Navigator.push(context, MaterialPageRoute(builder: (_) => const HousingFormScreen()));
}

class HousingScreen extends StatefulWidget {
  /// true = shown as a tab inside the Market (no own header / back button)
  final bool embedded;
  const HousingScreen({super.key, this.embedded = false});
  @override
  State<HousingScreen> createState() => _HousingScreenState();
}

class _HousingScreenState extends State<HousingScreen> {
  String _type = '', _city = '';
  num? _maxPrice;
  int _minRooms = 0;
  bool _furnishedOnly = false;
  final _cityCtrl = TextEditingController(), _priceCtrl = TextEditingController();

  bool _match(Map<String, dynamic> d) {
    if (_type.isNotEmpty && _s(d['type']) != _type) return false;
    if (_city.isNotEmpty) {
      final hay = '${_s(d['city'])} ${_s(d['area'])} ${_s(d['wantedArea'])}'.toLowerCase();
      if (!hay.contains(_city)) return false;
    }
    if (_maxPrice != null) {
      final p = _n(_looking(d) ? d['budget'] : d['rentMonth']);
      if (p == null || p > _maxPrice!) return false;
    }
    if (_minRooms > 0 && (_n(d['rooms']) ?? 0) < _minRooms) return false;
    if (_furnishedOnly && d['furnished'] != true) return false;
    return true;
  }

  Future<void> _add() => openHousingForm(context);

  @override
  Widget build(BuildContext context) {
    // the standalone Housing page now lives in Market > Housing
    if (!widget.embedded) return const MarketplaceScreen(initialTab: 'housing');
    final weekAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
    return AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) {
        final me = FirebaseAuth.instance.currentUser;
        return Scaffold(
          backgroundColor: kBg,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _add,
            backgroundColor: kSecondary,
            foregroundColor: kOnAccent,
            icon: const Icon(Icons.add_home_outlined),
            label: Text(tr('Add housing'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: SafeArea(
            top: !widget.embedded,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _col.where('status', isEqualTo: 'approved').orderBy('createdAt', descending: true).snapshots(),
              builder: (_, live) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                // rented listings stay visible for 7 days, then they are hidden
                stream: _col.where('status', isEqualTo: 'rented').where('rentedAt', isGreaterThan: weekAgo)
                    .orderBy('rentedAt', descending: true).snapshots(),
                builder: (_, rented) {
                  final docs = [...?live.data?.docs, ...?rented.data?.docs].where((d) => _match(d.data())).toList();
                  return CustomScrollView(slivers: [
                    if (!widget.embedded) SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(children: [
                        _circleBtn(Icons.arrow_back_rounded, () => Navigator.pop(context), tr('Back')),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tr('Housing'), style: TextStyle(fontFamily: kFontHeadline, fontSize: 26, fontWeight: FontWeight.w800, color: kText)),
                          Text(tr('Apartments and rooms in the community'), style: tsBodySm(color: kTextSub)),
                        ])),
                      ]),
                    )),
                    SliverToBoxAdapter(child: SizedBox(
                      height: 56,
                      child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), children: [
                        _pick(tr('All'), _type.isEmpty, () => setState(() => _type = '')),
                        for (final t in _types) _pick(_typeLabel(t), _type == t, () => setState(() => _type = t), icon: _typeIcon(t)),
                      ]),
                    )),
                    SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Row(children: [
                        Expanded(flex: 3, child: _field(_cityCtrl, tr('City or area'), Icons.place_outlined,
                            (v) => setState(() => _city = v.trim().toLowerCase()))),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: _field(_priceCtrl, tr('Max price'), Icons.payments_outlined,
                            (v) => setState(() => _maxPrice = _n(v)), number: true)),
                      ]),
                    )),
                    SliverToBoxAdapter(child: SizedBox(
                      height: 52,
                      child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 10, 16, 0), children: [
                        for (final r in [1, 2, 3, 4])
                          _pick(r == 4 ? '4+ ${tr('rooms')}' : '$r+ ${tr('rooms')}', _minRooms == r,
                              () => setState(() => _minRooms = _minRooms == r ? 0 : r)),
                        _pick(tr('Furnished'), _furnishedOnly, () => setState(() => _furnishedOnly = !_furnishedOnly),
                            icon: Icons.chair_outlined),
                      ]),
                    )),
                    if (me != null && !me.isAnonymous)
                      SliverToBoxAdapter(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _col.where('ownerId', isEqualTo: me.uid).snapshots(),
                        builder: (_, mine) {
                          final ds = mine.data?.docs ?? [];
                          if (ds.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(tr('My listings'), style: tsTitleLg(color: kText)),
                              const SizedBox(height: 8),
                              for (final d in ds) Padding(padding: const EdgeInsets.only(bottom: 10),
                                  child: _HousingCard(id: d.id, d: d.data(), showStatus: true)),
                            ]),
                          );
                        },
                      )),
                    SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('${docs.length} ${tr('listings')}', style: tsTitleMd(color: kTextSub)),
                    )),
                    if (!live.hasData && !live.hasError)
                      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 2))))
                    else if (docs.isEmpty)
                      SliverToBoxAdapter(child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                        child: Column(children: [
                          Icon(Icons.home_work_outlined, size: 48, color: kTextSub),
                          const SizedBox(height: 10),
                          Text(tr('No housing listings yet.'), textAlign: TextAlign.center, style: tsTitleMd(color: kText)),
                        ]),
                      ))
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                        sliver: SliverList.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _HousingCard(id: docs[i].id, d: docs[i].data()),
                        ),
                      ),
                  ]);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pick(String label, bool on, VoidCallback onTap, {IconData? icon}) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: on ? kSecondary : kCard,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[Icon(icon, size: 16, color: on ? kOnAccent : kText), const SizedBox(width: 6)],
                Text(label, style: tsTitleMd(color: on ? kOnAccent : kText).copyWith(fontSize: 13)),
              ]),
            ),
          ),
        ),
      );

  Widget _field(TextEditingController c, String hint, IconData icon, ValueChanged<String> onChanged, {bool number = false}) =>
      Container(
        height: 48,
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(24)),
        child: TextField(
          controller: c,
          onChanged: onChanged,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          style: tsBodyLg(color: kText),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: kTextSub, size: 20),
            filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      );

  @override
  void dispose() {
    _cityCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }
}

String _statusLabel(String s) => switch (s) {
      'approved' => tr('Live'),
      'rented' => tr('Rented'),
      'rejected' => tr('Not approved'),
      _ => tr('Waiting for approval'),
    };

class _HousingCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> d;
  final bool showStatus;
  const _HousingCard({required this.id, required this.d, this.showStatus = false});

  @override
  Widget build(BuildContext context) {
    final photos = _photos(d);
    final status = _s(d['status']);
    final where = [_s(d['area']), _s(d['city'])].where((e) => e.isNotEmpty).join(', ');
    final when = _s(_looking(d) ? d['moveIn'] : d['availableFrom']);
    return Material(
      color: kCard,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HousingDetailScreen(id: id))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            SizedBox(
              height: 170, width: double.infinity,
              child: photos.isEmpty
                  ? Container(color: kTintBlue, alignment: Alignment.center,
                      child: Icon(_typeIcon(_s(d['type'])), size: 48, color: kInkBlue))
                  : CachedNetworkImage(imageUrl: photos.first, fit: BoxFit.cover, memCacheWidth: 900,
                      errorWidget: (_, __, ___) => Container(color: kCardHigh)),
            ),
            Positioned(left: 10, top: 10, child: _chip(_typeLabel(_s(d['type'])), bg: kBg, icon: _typeIcon(_s(d['type'])))),
            if (status == 'rented')
              Positioned.fill(child: Container(
                color: Colors.black.withOpacity(0.5), alignment: Alignment.center,
                child: Text(tr('Rented').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
              )),
            if (showStatus && status != 'approved')
              Positioned(right: 10, top: 10, child: _chip(_statusLabel(status), bg: kTintYellow)),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_priceLine(d).isNotEmpty)
                Text(_priceLine(d), style: TextStyle(fontFamily: kFontHeadline, fontSize: 19, fontWeight: FontWeight.w800, color: kInkGreen)),
              Text(_s(d['title']), maxLines: 1, overflow: TextOverflow.ellipsis, style: tsTitleLg(color: kText)),
              const SizedBox(height: 4),
              Text([_sizeLine(d), where].where((e) => e.isNotEmpty).join(' · '), style: tsBodySm(color: kTextSub)),
              if (when.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('${_looking(d) ? tr('Move-in') : tr('Available from')} ${_date(when)}',
                    style: tsBodySm(color: kText).copyWith(fontWeight: FontWeight.w600)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DETAIL
// ═══════════════════════════════════════════════════════════
class HousingDetailScreen extends StatelessWidget {
  final String id;
  const HousingDetailScreen({super.key, required this.id});

  Future<void> _report(BuildContext context, Map d) async {
    final reasons = [tr('Fake or scam'), tr('Wrong information'), tr('Already rented'), tr('Other')];
    String? pick;
    final note = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
      title: Text(tr('Report listing'), style: tsHeadlineSm(color: kText)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final r in reasons)
          RadioListTile<String>(value: r, groupValue: pick, onChanged: (v) => set(() => pick = v),
              title: Text(r, style: tsBodyLg(color: kText)), contentPadding: EdgeInsets.zero, activeColor: kSecondary),
        TextField(controller: note, maxLines: 3, maxLength: 500, decoration: InputDecoration(hintText: tr('More details (optional)'))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
        FilledButton(onPressed: pick == null ? null : () => Navigator.pop(ctx, true), child: Text(tr('Send'))),
      ],
    )));
    if (ok != true || pick == null) return;
    try {
      await _db.collection('reports').add({
        'businessId': id,
        'businessName': '🏠 ${_s(d['title'])}',
        'reason': pick,
        'note': note.text.trim(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'status': 'open',
        'kind': 'housing',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Thank you. We will look at it.'))));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Could not send. Try again.'))));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(tr('Delete listing'), style: tsHeadlineSm(color: kText)),
      content: Text(tr('The listing will be removed.'), style: tsBodyLg(color: kText)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Delete'), style: TextStyle(color: kRed))),
      ],
    ));
    if (ok != true) return;
    await _col.doc(id).delete();
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _col.doc(id).snapshots(),
        builder: (context, snap) {
          final d = snap.data?.data();
          if (d == null) {
            return Scaffold(backgroundColor: kBg, appBar: AppBar(),
                body: Center(child: snap.hasData ? Text(tr('This listing is not available.'), style: tsTitleMd(color: kText))
                    : CircularProgressIndicator(color: kSecondary, strokeWidth: 2)));
          }
          final photos = _photos(d);
          final mine = FirebaseAuth.instance.currentUser?.uid == _s(d['ownerId']);
          final status = _s(d['status']);
          final looking = _looking(d);
          final cur = _s(d['currency']);
          final where = [_s(d['area']), _s(d['city']), _countryName(_s(d['country']))].where((e) => e.isNotEmpty).join(', ');
          final facts = <(String, String)>[
            if (!looking) ...[
              (tr('Rent per month'), _money(_n(d['rentMonth']), cur)),
              (tr('Deposit'), _money(_n(d['deposit']), cur)),
              (tr('Rooms'), _n(d['rooms']) == null ? '' : '${_n(d['rooms'])!.round()}'),
              (tr('Size'), _n(d['sizeM2']) == null ? '' : '${_n(d['sizeM2'])!.round()} m²'),
              (tr('Available from'), _date(_s(d['availableFrom']))),
              (tr('Furnished'), d['furnished'] == true ? tr('Yes') : tr('No')),
              if (d['pets'] != null) (tr('Pets allowed'), d['pets'] == true ? tr('Yes') : tr('No')),
              if (d['utilities'] != null) (tr('Electricity and water included'), d['utilities'] == true ? tr('Yes') : tr('No')),
            ] else ...[
              (tr('Budget per month'), _money(_n(d['budget']), cur)),
              (tr('Wanted area'), _s(d['wantedArea'])),
              (tr('Move-in'), _date(_s(d['moveIn']))),
              (tr('Number of people'), _s(d['people'])),
            ],
          ].where((f) => f.$2.isNotEmpty).toList();
          final wa = _digits(_s(d['whatsapp'])), phone = _s(d['phone']).isNotEmpty ? _s(d['phone']) : _s(d['whatsapp']);
          return Scaffold(
            backgroundColor: kBg,
            body: CustomScrollView(slivers: [
              SliverToBoxAdapter(child: Stack(children: [
                SizedBox(
                  height: 280,
                  child: photos.isEmpty
                      ? Container(color: kTintBlue, alignment: Alignment.center, child: Icon(_typeIcon(_s(d['type'])), size: 72, color: kInkBlue))
                      : PageView(children: [
                          for (final p in photos) CachedNetworkImage(imageUrl: p, fit: BoxFit.cover, width: double.infinity),
                        ]),
                ),
                Positioned(left: 16, top: MediaQuery.paddingOf(context).top + 8,
                    child: _circleBtn(Icons.arrow_back_rounded, () => Navigator.pop(context), tr('Back'), bg: kBg)),
                Positioned(right: 16, top: MediaQuery.paddingOf(context).top + 8, child: Row(children: [
                  _circleBtn(Icons.share_outlined, () => shareText(
                      '🏠 ${_s(d['title'])}\n${_priceLine(d)}\n$where\n\nhttps://habesha-hub.no/m/$id'), tr('Share'), bg: kBg),
                  const SizedBox(width: 8),
                  _circleBtn(Icons.flag_outlined, () => _report(context, d), tr('Report listing'), bg: kBg, fg: kRed),
                ])),
                if (photos.length > 1)
                  Positioned(right: 16, bottom: 12, child: _chip('${photos.length} ${tr('photos')} →', bg: kBg)),
              ])),
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip(_typeLabel(_s(d['type'])), bg: kTintBlue, icon: _typeIcon(_s(d['type']))),
                    if (status != 'approved' || mine) _chip(_statusLabel(status), bg: status == 'approved' ? kTintGreen : kTintYellow),
                  ]),
                  const SizedBox(height: 10),
                  if (_priceLine(d).isNotEmpty)
                    Text(_priceLine(d), style: TextStyle(fontFamily: kFontHeadline, fontSize: 24, fontWeight: FontWeight.w800, color: kInkGreen)),
                  Text(_s(d['title']), style: TextStyle(fontFamily: kFontHeadline, fontSize: 22, fontWeight: FontWeight.w800, color: kText)),
                  const SizedBox(height: 4),
                  Text(where, style: tsBodyLg(color: kTextSub)),
                  if (_s(d['description']).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_s(d['description']), style: tsBodyLg(color: kText)),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18)),
                    child: Column(children: [
                      for (final f in facts)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Expanded(child: Text(f.$1, style: tsBodyLg(color: kTextSub))),
                            Text(f.$2, style: tsTitleMd(color: kText)),
                          ]),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  // fixed safety note on every housing listing
                  _note(Icons.shield_outlined, tr('Never pay deposit or rent before you have seen the place and signed a contract.')),
                  if (_s(d['country']) == 'NO')
                    _note(Icons.info_outline_rounded,
                        tr("In Norway, the deposit should go to a deposit account (depositumskonto) and can be max 6 months' rent.")),
                  if (_s(d['contactName']).isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('${tr('Contact')}: ${_s(d['contactName'])}', style: tsTitleMd(color: kText)),
                  ],
                  if (mine) _OwnerBar(id: id, status: status),
                  if (_isAdmin && !mine) _AdminBar(id: id, status: status),
                  if (mine || _isAdmin) Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(onPressed: () => _delete(context),
                        icon: Icon(Icons.delete_outline_rounded, color: kRed), label: Text(tr('Delete listing'), style: TextStyle(color: kRed))),
                  ),
                ]),
              )),
            ]),
            bottomNavigationBar: status == 'rented' || (wa.isEmpty && phone.isEmpty) ? null : Container(
              color: kCard,
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
              child: Row(children: [
                if (wa.isNotEmpty) Expanded(child: SizedBox(height: 52, child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white),
                  onPressed: () => launchUrl(Uri.parse('https://wa.me/$wa?text=${Uri.encodeComponent(
                      '${tr('Hi, I saw your housing listing on Habesha Hub')}: ${_s(d['title'])}')}'), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(tr('WhatsApp'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ))),
                if (wa.isNotEmpty && phone.isNotEmpty) const SizedBox(width: 10),
                if (phone.isNotEmpty)
                  wa.isEmpty
                      ? Expanded(child: SizedBox(height: 52, child: FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white),
                          onPressed: () => launchUrl(Uri.parse('tel:${phone.replaceAll(' ', '')}')),
                          icon: const Icon(Icons.call_outlined), label: Text(tr('Call')))))
                      : _circleBtn(Icons.call_outlined, () => launchUrl(Uri.parse('tel:${phone.replaceAll(' ', '')}')), tr('Call'), bg: kCardHigh),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _note(IconData icon, String text) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kTintYellow, borderRadius: BorderRadius.circular(18)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: kInkYellow),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: tsBodyLg(color: kText))),
        ]),
      );
}

class _OwnerBar extends StatelessWidget {
  final String id, status;
  const _OwnerBar({required this.id, required this.status});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18)),
      child: Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HousingFormScreen(id: id))),
          icon: const Icon(Icons.edit_outlined), label: Text(tr('Edit'))),
        if (status == 'approved')
          OutlinedButton.icon(
            onPressed: () => _col.doc(id).update({'status': 'rented', 'rentedAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()}),
            icon: const Icon(Icons.key_outlined), label: Text(tr('Mark as rented'))),
        if (status == 'rented')
          OutlinedButton.icon(
            onPressed: () => _col.doc(id).update({'status': 'approved', 'rentedAt': null, 'updatedAt': FieldValue.serverTimestamp()}),
            icon: const Icon(Icons.undo_rounded), label: Text(tr('Available again'))),
        if (status == 'pending' || status == 'rejected')
          Text(tr('Habesha Hub checks the listing before it is shown to others.'), style: tsBodySm(color: kTextSub)),
      ]),
    );
  }
}

class _AdminBar extends StatelessWidget {
  final String id, status;
  const _AdminBar({required this.id, required this.status});
  @override
  Widget build(BuildContext context) {
    Future<void> set(String s) => _col.doc(id).update({'status': s, 'reviewedAt': FieldValue.serverTimestamp()});
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(children: [
        if (status != 'approved' && status != 'rented') Expanded(child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white),
          onPressed: () => set('approved'), icon: const Icon(Icons.check_rounded), label: Text(tr('Approve')))),
        if (status != 'approved' && status != 'rented' && status != 'rejected') const SizedBox(width: 10),
        if (status != 'rejected') Expanded(child: OutlinedButton.icon(
          onPressed: () => set('rejected'), icon: Icon(Icons.block_rounded, color: kRed),
          label: Text(tr('Reject'), style: TextStyle(color: kRed)))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FORM — add / edit
// ═══════════════════════════════════════════════════════════
class HousingFormScreen extends StatefulWidget {
  final String? id;
  const HousingFormScreen({super.key, this.id});
  @override
  State<HousingFormScreen> createState() => _HousingFormScreenState();
}

class _HousingFormScreenState extends State<HousingFormScreen> {
  static const _maxPhotos = 10;
  final _title = TextEditingController(), _desc = TextEditingController(), _city = TextEditingController();
  final _area = TextEditingController(), _rent = TextEditingController(), _deposit = TextEditingController();
  final _rooms = TextEditingController(), _size = TextEditingController(), _budget = TextEditingController();
  final _wantedArea = TextEditingController(), _people = TextEditingController();
  final _whatsapp = TextEditingController(text: '+47 '), _phone = TextEditingController(), _name = TextEditingController();
  String _type = 'forRent', _country = 'NO', _availableFrom = '', _moveIn = '', _error = '';
  bool _furnished = false, _loading = true, _saving = false;
  bool? _pets, _utilities;
  final List<String> _kept = [];
  final List<File> _new = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = FirebaseAuth.instance.currentUser;
    _name.text = _s(u?.displayName);
    if (widget.id != null) {
      final d = (await _col.doc(widget.id).get()).data() ?? {};
      _type = _types.contains(_s(d['type'])) ? _s(d['type']) : 'forRent';
      _title.text = _s(d['title']);
      _desc.text = _s(d['description']);
      _country = _s(d['country']).isEmpty ? 'NO' : _s(d['country']);
      _city.text = _s(d['city']);
      _area.text = _s(d['area']);
      _rent.text = _s(d['rentMonth']);
      _deposit.text = _s(d['deposit']);
      _rooms.text = _s(d['rooms']);
      _size.text = _s(d['sizeM2']);
      _availableFrom = _s(d['availableFrom']);
      _furnished = d['furnished'] == true;
      _pets = d['pets'] as bool?;
      _utilities = d['utilities'] as bool?;
      _budget.text = _s(d['budget']);
      _wantedArea.text = _s(d['wantedArea']);
      _moveIn = _s(d['moveIn']);
      _people.text = _s(d['people']);
      _whatsapp.text = _s(d['whatsapp']);
      _phone.text = _s(d['phone']);
      _name.text = _s(d['contactName']);
      _kept.addAll(_photos(d));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDate(bool moveIn) async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, firstDate: now.subtract(const Duration(days: 30)),
        lastDate: now.add(const Duration(days: 730)), initialDate: now);
    if (d == null) return;
    final iso = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    if (mounted) setState(() => moveIn ? _moveIn = iso : _availableFrom = iso);
  }

  Future<void> _submit() async {
    final user = await _realUser(context);
    if (user == null) return;
    final looking = _type == 'looking';
    if (_title.text.trim().isEmpty || _city.text.trim().isEmpty ||
        (_digits(_whatsapp.text).length < 7 && _digits(_phone.text).length < 7) ||
        (!looking && _n(_rent.text) == null)) {
      if (mounted) setState(() => _error = looking
          ? tr('Please write a title, city and a WhatsApp or phone number.')
          : tr('Please write a title, city, price per month and a WhatsApp or phone number.'));
      return;
    }
    if (mounted) setState(() { _saving = true; _error = ''; });
    try {
      final urls = [..._kept];
      for (final f in _new) {
        final ref = FirebaseStorage.instance.ref('housing/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${urls.length}.jpg');
        await ref.putFile(f, SettableMetadata(contentType: 'image/jpeg'));
        urls.add(await ref.getDownloadURL());
      }
      final data = <String, dynamic>{
        'ownerId': user.uid,
        'type': _type,
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'photos': urls,
        'country': _country,
        'currency': _currency(_country),
        'city': _city.text.trim(),
        'area': _area.text.trim(),
        'rentMonth': looking ? null : _n(_rent.text),
        'deposit': looking ? null : _n(_deposit.text),
        'rooms': looking ? null : _n(_rooms.text),
        'sizeM2': looking ? null : _n(_size.text),
        'availableFrom': looking ? '' : _availableFrom,
        'furnished': looking ? false : _furnished,
        'pets': looking ? null : _pets,
        'utilities': looking ? null : _utilities,
        'budget': looking ? _n(_budget.text) : null,
        'wantedArea': looking ? _wantedArea.text.trim() : '',
        'moveIn': looking ? _moveIn : '',
        'people': looking ? _people.text.trim() : '',
        'whatsapp': _whatsapp.text.trim(),
        'phone': _phone.text.trim(),
        'contactName': _name.text.trim(),
        'status': 'pending', // every new or edited listing is checked again
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.id == null) {
        await _col.add({...data, 'createdAt': FieldValue.serverTimestamp()});
      } else {
        await _col.doc(widget.id).update(data);
      }
      if (!mounted) return;
      await showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text(tr('Sent for approval'), style: tsHeadlineSm(color: kText)),
        content: Text(tr('Thank you! Habesha Hub checks your listing before it is shown. You find it under Housing > My listings.'),
            style: tsBodyLg(color: kText)),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('OK')))],
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('housing save: $e');
      if (mounted) setState(() { _saving = false; _error = tr('Could not save. Check your internet and try again.'); });
    }
  }

  InputDecoration _dec(String label, {String? hint, IconData? icon, String? suffix}) =>
      InputDecoration(labelText: label, hintText: hint, suffixText: suffix, prefixIcon: icon == null ? null : Icon(icon, color: kTextSub));

  Widget _yesNo(String label, bool? value, ValueChanged<bool?> set) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(children: [
          Expanded(child: Text(label, style: tsTitleMd(color: kText))),
          SegmentedButton<int>(
            emptySelectionAllowed: true,
            segments: [ButtonSegment(value: 1, label: Text(tr('Yes'))), ButtonSegment(value: 0, label: Text(tr('No')))],
            selected: value == null ? <int>{} : {value ? 1 : 0},
            onSelectionChanged: (v) => set(v.isEmpty ? null : v.first == 1),
          ),
        ]),
      );

  Widget _dateBtn(String label, String iso, bool moveIn) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: OutlinedButton.icon(
          onPressed: () => _pickDate(moveIn),
          icon: const Icon(Icons.event_outlined),
          label: Text(iso.isEmpty ? label : '$label: ${_date(iso)}'),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final looking = _type == 'looking';
    final cur = _currency(_country);
    return AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.id == null ? tr('Add housing') : tr('Edit')),
          Text(tr('Free · checked before it goes live'), style: tsBodySm(color: kTextSub)),
        ])),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 2))
            : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
                Text(tr('Type'), style: tsTitleMd(color: kText)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final t in _types)
                    ChoiceChip(
                      avatar: Icon(_typeIcon(t), size: 18, color: _type == t ? kOnAccent : kText),
                      label: Text(_typeLabel(t)),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                      selectedColor: kSecondary,
                      showCheckmark: false,
                      labelStyle: TextStyle(color: _type == t ? kOnAccent : kText, fontWeight: FontWeight.w600),
                    ),
                ]),
                const SizedBox(height: 16),
                TextField(controller: _title, maxLength: 80, decoration: _dec(tr('Title'),
                    hint: looking ? tr('e.g. Family of 3 looking for a flat') : tr('e.g. 2-room flat near the centre'))),
                TextField(controller: _desc, maxLines: 4, maxLength: 1000, decoration: _dec(tr('Description'))),
                // photos (max 10; optional when looking for housing)
                Text(looking ? tr('Photos (optional)') : tr('Photos'), style: tsTitleMd(color: kText)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (var i = 0; i < _kept.length; i++) _thumb(CachedNetworkImage(imageUrl: _kept[i], fit: BoxFit.cover), () => setState(() => _kept.removeAt(i))),
                    for (var i = 0; i < _new.length; i++) _thumb(Image.file(_new[i], fit: BoxFit.cover), () => setState(() => _new.removeAt(i))),
                    if (_kept.length + _new.length < _maxPhotos)
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          final picked = await ImagePicker().pickMultiImage(imageQuality: 80, maxWidth: 1600);
                          final room = _maxPhotos - _kept.length - _new.length;
                          if (mounted) setState(() => _new.addAll(picked.take(room).map((x) => File(x.path))));
                        },
                        child: Container(
                          width: 96,
                          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_photo_alternate_outlined, color: kText),
                            Text('${_kept.length + _new.length}/$_maxPhotos', style: tsBodySm(color: kTextSub)),
                          ]),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _country,
                  decoration: _dec(tr('Country'), icon: Icons.public),
                  items: [for (final c in _countries) DropdownMenuItem(value: c.$1, child: Text(tr(c.$2)))],
                  onChanged: (v) => setState(() => _country = v ?? 'NO'),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(controller: _city, decoration: _dec(tr('City'), icon: Icons.location_city_outlined))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _area, decoration: _dec(tr('Area'), hint: tr('e.g. Grønland')))),
                ]),
                Padding(padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(tr('Only the area is shown. Never write your street address.'), style: tsBodySm(color: kTextSub))),
                const SizedBox(height: 14),
                if (!looking) ...[
                  Row(children: [
                    Expanded(child: TextField(controller: _rent, keyboardType: TextInputType.number,
                        decoration: _dec(_type == 'shortTerm' ? tr('Price') : tr('Rent per month'), suffix: cur))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _deposit, keyboardType: TextInputType.number,
                        decoration: _dec(tr('Deposit'), suffix: cur))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextField(controller: _rooms, keyboardType: TextInputType.number, decoration: _dec(tr('Rooms')))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _size, keyboardType: TextInputType.number, decoration: _dec(tr('Size'), suffix: 'm²'))),
                  ]),
                  _dateBtn(tr('Available from'), _availableFrom, false),
                  SwitchListTile(value: _furnished, onChanged: (v) => setState(() => _furnished = v),
                      title: Text(tr('Furnished'), style: tsTitleMd(color: kText)), contentPadding: EdgeInsets.zero),
                  _yesNo(tr('Pets allowed'), _pets, (v) => setState(() => _pets = v)),
                  _yesNo(tr('Electricity and water included'), _utilities, (v) => setState(() => _utilities = v)),
                ] else ...[
                  TextField(controller: _budget, keyboardType: TextInputType.number,
                      decoration: _dec(tr('Budget per month'), suffix: cur)),
                  const SizedBox(height: 10),
                  TextField(controller: _wantedArea, decoration: _dec(tr('Wanted area'), icon: Icons.place_outlined)),
                  const SizedBox(height: 10),
                  TextField(controller: _people, keyboardType: TextInputType.number, decoration: _dec(tr('Number of people'))),
                  _dateBtn(tr('Move-in'), _moveIn, true),
                ],
                const SizedBox(height: 18),
                Text(tr('Contact'), style: tsTitleMd(color: kText)),
                const SizedBox(height: 8),
                TextField(controller: _name, decoration: _dec(tr('Your name (shown to others)'), icon: Icons.person_outline)),
                const SizedBox(height: 10),
                TextField(controller: _whatsapp, keyboardType: TextInputType.phone, decoration: _dec(tr('WhatsApp number'), icon: Icons.chat_outlined)),
                const SizedBox(height: 10),
                TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: _dec(tr('Phone for calls (optional)'), icon: Icons.call_outlined)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kTintYellow, borderRadius: BorderRadius.circular(18)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.shield_outlined, color: kInkYellow),
                    const SizedBox(width: 10),
                    Expanded(child: Text(tr('Never pay deposit or rent before you have seen the place and signed a contract.'),
                        style: tsBodyLg(color: kText))),
                  ]),
                ),
                if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error, style: tsBodyLg(color: kRed))),
                const SizedBox(height: 18),
                goldButton(tr('Send for approval'), _saving ? null : _submit, loading: _saving, icon: Icons.send_rounded),
              ]),
      ),
    );
  }

  Widget _thumb(Widget img, VoidCallback remove) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Stack(children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: 96, height: 96, child: img)),
          Positioned(right: 4, top: 4, child: GestureDetector(
            onTap: remove,
            child: Container(padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16)))),
        ]),
      );

  @override
  void dispose() {
    for (final c in [_title, _desc, _city, _area, _rent, _deposit, _rooms, _size, _budget, _wantedArea, _people, _whatsapp, _phone, _name]) {
      c.dispose();
    }
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════
// ADMIN TAB — "Housing": waiting first, approve / reject
// ═══════════════════════════════════════════════════════════
class HousingAdminTab extends StatelessWidget {
  const HousingAdminTab({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _col.snapshots(),
      builder: (_, snap) {
        final docs = [...?snap.data?.docs];
        const order = {'pending': 0, 'approved': 1, 'rented': 2, 'rejected': 3};
        docs.sort((a, b) => (order[_s(a.data()['status'])] ?? 0).compareTo(order[_s(b.data()['status'])] ?? 0));
        if (docs.isEmpty) {
          return Center(child: Text(tr('No housing listings yet.'), style: tsBodyLg(color: kTextSub)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _HousingCard(id: docs[i].id, d: docs[i].data(), showStatus: true),
        );
      },
    );
  }
}
