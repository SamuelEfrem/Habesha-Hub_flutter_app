import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../utils/theme_notifier.dart';
import '../utils/translations.dart';
import 'auth_screen.dart';

// ═══════════════════════════════════════════════════════════
// HOME SHOPS (ቤት ዕዳጋ) — small sellers who sell from home.
//   homeShops/{id}               the shop (only approved shops are public)
//   homeShops/{id}/products/{id} its products
//   app_config/homeShops         { holidayBanner: bool } — admin switch
// The app never handles money and never stores an address (area only).
// ═══════════════════════════════════════════════════════════

final _db = FirebaseFirestore.instance;
CollectionReference<Map<String, dynamic>> get _shops => _db.collection('homeShops');

bool get _isAdmin {
  final u = FirebaseAuth.instance.currentUser;
  return u != null && (u.uid == 'W3z67R3wiXUVvcPFDS0oxgfaDlj1' || u.email == 'samuelefriem@gmail.com');
}

String _s(dynamic v) => v == null ? '' : v.toString().trim();

const _cats = ['food', 'coffee', 'clothes', 'beauty', 'crafts'];
String _catLabel(String k) => switch (k) {
      'food' => tr('Spices & food'),
      'coffee' => tr('Coffee & incense'),
      'clothes' => tr('Clothes'),
      'beauty' => tr('Beauty'),
      'crafts' => tr('Crafts'),
      _ => tr('Other'),
    };
IconData _catIcon(String k) => switch (k) {
      'food' => Icons.soup_kitchen_outlined,
      'coffee' => Icons.coffee_outlined,
      'clothes' => Icons.checkroom_outlined,
      'beauty' => Icons.spa_outlined,
      'crafts' => Icons.palette_outlined,
      _ => Icons.storefront_outlined,
    };
Color _catTint(String k) => switch (k) {
      'food' => kTintRed,
      'coffee' => kTintYellow,
      'clothes' => kTintGreen,
      'beauty' => kTintBlue,
      _ => kTintYellow,
    };
Color _catInk(String k) => switch (k) {
      'food' => kInkRed,
      'coffee' => kInkYellow,
      'clothes' => kInkGreen,
      'beauty' => kInkBlue,
      _ => kInkYellow,
    };
String _availLabel(String a) => a == 'order' ? tr('Order 1 day before') : tr('Available now');
String _statusLabel(String s) => switch (s) {
      'approved' => tr('Live'),
      'paused' => tr('Paused'),
      'rejected' => tr('Not approved'),
      _ => tr('Waiting for approval'),
    };

/// "+47 912 34 567" → "4791234567" (for wa.me and tel:)
String _digits(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

Widget _avatar(Map d, double size) {
  final url = _s(d['photoUrl']), name = _s(d['name']), cat = _s(d['category']);
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: _catTint(cat)),
    clipBehavior: Clip.antiAlias,
    alignment: Alignment.center,
    child: url.isNotEmpty
        ? CachedNetworkImage(imageUrl: url, width: size, height: size, fit: BoxFit.cover, memCacheWidth: (size * 3).round(),
            errorWidget: (_, __, ___) => Icon(_catIcon(cat), color: _catInk(cat)))
        : Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
            style: TextStyle(fontFamily: kFontHeadline, fontSize: size * 0.42, fontWeight: FontWeight.w800, color: _catInk(cat))),
  );
}

Widget _chip(String label, {Color? bg, Color? fg, IconData? icon, Color? dot}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg ?? kCard, borderRadius: BorderRadius.circular(100)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot != null) ...[Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)), const SizedBox(width: 6)],
        if (icon != null) ...[Icon(icon, size: 15, color: fg ?? kText), const SizedBox(width: 5)],
        Text(label, style: tsBodySm(color: fg ?? kText).copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );

/// Only real accounts may open a shop: guests log in first.
Future<User?> _realUser(BuildContext context) async {
  var u = FirebaseAuth.instance.currentUser;
  if (u == null || u.isAnonymous) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true)));
    u = FirebaseAuth.instance.currentUser;
  }
  return (u == null || u.isAnonymous) ? null : u;
}

// ═══════════════════════════════════════════════════════════
// SCREEN 1 — list
// ═══════════════════════════════════════════════════════════
class HomeShopsScreen extends StatefulWidget {
  const HomeShopsScreen({super.key});
  @override
  State<HomeShopsScreen> createState() => _HomeShopsScreenState();
}

class _HomeShopsScreenState extends State<HomeShopsScreen> {
  final _search = TextEditingController();
  String _query = '', _cat = '', _myCity = '';

  @override
  void initState() {
    super.initState();
    _findCity();
  }

  /// The user's city, only if location is already allowed (we don't ask here)
  Future<void> _findCity() async {
    try {
      final p = await Geolocator.checkPermission();
      if (p != LocationPermission.always && p != LocationPermission.whileInUse) return;
      final pos = await Geolocator.getLastKnownPosition();
      if (pos == null) return;
      final pm = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (pm.isNotEmpty && mounted) setState(() => _myCity = (pm.first.locality ?? '').toLowerCase());
    } catch (_) {}
  }

  Future<void> _openShop() async {
    final u = await _realUser(context);
    if (u == null || !mounted) return;
    final mine = await _shops.where('ownerId', isEqualTo: u.uid).limit(1).get();
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => ShopFormScreen(shopId: mine.docs.isEmpty ? null : mine.docs.first.id)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) {
        final me = FirebaseAuth.instance.currentUser;
        return Scaffold(
          backgroundColor: kBg,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openShop,
            backgroundColor: kSecondary,
            foregroundColor: kOnAccent,
            icon: const Icon(Icons.add_business_outlined),
            label: Text(tr('Open your shop'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: SafeArea(
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  _circleBtn(Icons.arrow_back_rounded, () => Navigator.pop(context), tr('Back')),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('Home shops'), style: TextStyle(fontFamily: kFontHeadline, fontSize: 26, fontWeight: FontWeight.w800, color: kText)),
                    Text('ቤት ዕዳጋ · ${tr('made by our community')}', style: tsBodySm(color: kTextSub)),
                  ])),
                ]),
              )),
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(26)),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                    style: tsBodyLg(color: kText),
                    decoration: InputDecoration(
                      hintText: tr('Berbere, injera, netela…'),
                      prefixIcon: Icon(Icons.search_rounded, color: kTextSub),
                      filled: false, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              )),
              SliverToBoxAdapter(child: SizedBox(
                height: 44,
                child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                  _catPick('', tr('All')),
                  for (final c in _cats) _catPick(c, _catLabel(c)),
                ]),
              )),
              SliverToBoxAdapter(child: _HolidayBanner()),
              // my own shop (any status) so the owner can find it again
              if (me != null && !me.isAnonymous)
                SliverToBoxAdapter(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _shops.where('ownerId', isEqualTo: me.uid).limit(1).snapshots(),
                  builder: (_, snap) {
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) return const SizedBox.shrink();
                    final d = docs.first.data();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tr('My shop'), style: tsTitleLg(color: kText)),
                        const SizedBox(height: 8),
                        _ShopTile(id: docs.first.id, d: d, status: _s(d['status'])),
                      ]),
                    );
                  },
                )),
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Text(tr('Near you'), style: TextStyle(fontFamily: kFontHeadline, fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
              )),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _shops.where('status', isEqualTo: 'approved').snapshots(),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 2))));
                  }
                  var docs = snap.data!.docs.where((doc) {
                    final d = doc.data();
                    if (_cat.isNotEmpty && _s(d['category']) != _cat) return false;
                    if (_query.isEmpty) return true;
                    final hay = [d['name'], d['description'], d['area'], d['city'], ...(d['productNames'] as List? ?? [])]
                        .map(_s).join(' ').toLowerCase();
                    return hay.contains(_query);
                  }).toList();
                  // the user's city first, then "available now" before "on order"
                  int rank(Map d) => (_myCity.isNotEmpty && _s(d['city']).toLowerCase() == _myCity ? 0 : 2) +
                      (_s(d['availability']) == 'order' ? 1 : 0);
                  docs.sort((a, b) => rank(a.data()).compareTo(rank(b.data())));
                  if (docs.isEmpty) {
                    return SliverToBoxAdapter(child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 120),
                      child: Column(children: [
                        Icon(Icons.storefront_outlined, size: 48, color: kTextSub),
                        const SizedBox(height: 10),
                        Text(tr('No home shops here yet. Be the first!'), textAlign: TextAlign.center, style: tsTitleMd(color: kText)),
                      ]),
                    ));
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    sliver: SliverList.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ShopTile(id: docs[i].id, d: docs[i].data()),
                    ),
                  );
                },
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _catPick(String k, String label) {
    final on = _cat == k;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: on ? kSecondary : kCard,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => setState(() => _cat = k),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text(label, style: tsTitleMd(color: on ? kOnAccent : kText).copyWith(fontSize: 14))),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
}

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

class _HolidayBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('app_config').doc('homeShops').snapshots(),
      builder: (_, snap) {
        if (snap.data?.data()?['holidayBanner'] != true) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kTintYellow, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Icon(Icons.celebration_outlined, color: kInkYellow, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('Order early for the holidays'), style: tsTitleLg(color: kText)),
              const SizedBox(height: 2),
              Text(tr('Shops get busy before the holiday. Ask in good time.'), style: tsBodySm(color: kText)),
            ])),
          ]),
        );
      },
    );
  }
}

class _ShopTile extends StatelessWidget {
  final String id;
  final Map<String, dynamic> d;
  final String? status; // shown on the owner's own shop
  const _ShopTile({required this.id, required this.d, this.status});

  @override
  Widget build(BuildContext context) {
    final avail = _s(d['availability']);
    final where = [_s(d['area']), _s(d['city'])].where((e) => e.isNotEmpty).join(', ');
    return Material(
      color: kCard,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopProfileScreen(shopId: id))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            _avatar(d, 60),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_s(d['name'])} · ${_catLabel(_s(d['category']))}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: tsTitleLg(color: kText)),
              const SizedBox(height: 2),
              Text([_s(d['description']), where].where((e) => e.isNotEmpty).join(' · '),
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: tsBodySm(color: kTextSub)),
              const SizedBox(height: 6),
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(
                    color: avail == 'order' ? kTextSub : kInkGreen, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(_availLabel(avail), style: tsBodySm(color: avail == 'order' ? kTextSub : kInkGreen)
                    .copyWith(fontWeight: FontWeight.w700)),
                if (status != null) ...[
                  const Spacer(),
                  _chip(_statusLabel(status!), bg: status == 'approved' ? kTintGreen : kTintYellow),
                ],
              ]),
            ])),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SCREEN 2 — shop profile
// ═══════════════════════════════════════════════════════════
class ShopProfileScreen extends StatefulWidget {
  final String shopId;
  const ShopProfileScreen({super.key, required this.shopId});
  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  bool _saved = false;
  static const _favKey = 'fav_home_shops';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _saved = (p.getStringList(_favKey) ?? []).contains(widget.shopId));
    });
  }

  Future<void> _toggleSave() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_favKey) ?? [];
    _saved ? list.remove(widget.shopId) : list.add(widget.shopId);
    await p.setStringList(_favKey, list);
    if (mounted) setState(() => _saved = !_saved);
  }

  Future<void> _report(Map d) async {
    final reasons = [tr('Wrong or fake information'), tr('Not allowed to sell'), tr('Rude or unsafe'), tr('Other')];
    String? pick;
    final note = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
      title: Text(tr('Report shop'), style: tsHeadlineSm(color: kText)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final r in reasons)
          RadioListTile<String>(value: r, groupValue: pick, onChanged: (v) => set(() => pick = v),
              title: Text(r, style: tsBodyLg(color: kText)), contentPadding: EdgeInsets.zero, activeColor: kSecondary),
        TextField(controller: note, maxLines: 3, maxLength: 500,
            decoration: InputDecoration(hintText: tr('More details (optional)'))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
        FilledButton(onPressed: pick == null ? null : () => Navigator.pop(ctx, true), child: Text(tr('Send'))),
      ],
    )));
    if (ok != true || pick == null) return;
    try {
      await _db.collection('reports').add({
        'businessId': widget.shopId,
        'businessName': '🏠 ${_s(d['name'])}',
        'reason': pick,
        'note': note.text.trim(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'status': 'open',
        'kind': 'homeShop',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Thank you. We will look at it.'))));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Could not send. Try again.'))));
    }
  }

  void _whatsApp(Map d) {
    final n = _digits(_s(d['whatsapp']).isNotEmpty ? _s(d['whatsapp']) : _s(d['phone']));
    if (n.isEmpty) return;
    final text = '${tr('Hi, I saw your shop on Habesha Hub')} (${_s(d['name'])}). ';
    launchUrl(Uri.parse('https://wa.me/$n?text=${Uri.encodeComponent(text)}'), mode: LaunchMode.externalApplication);
  }

  void _call(Map d) {
    final n = _s(d['phone']).isNotEmpty ? _s(d['phone']) : _s(d['whatsapp']);
    if (n.isEmpty) return;
    launchUrl(Uri.parse('tel:${n.replaceAll(' ', '')}'));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _shops.doc(widget.shopId).snapshots(),
        builder: (context, snap) {
          final d = snap.data?.data();
          if (d == null) {
            return Scaffold(backgroundColor: kBg, appBar: AppBar(),
                body: Center(child: snap.hasData ? Text(tr('This shop is not available.'), style: tsTitleMd(color: kText))
                    : CircularProgressIndicator(color: kSecondary, strokeWidth: 2)));
          }
          final cat = _s(d['category']);
          final mine = FirebaseAuth.instance.currentUser?.uid == _s(d['ownerId']);
          final status = _s(d['status']);
          final where = [_s(d['area']), _s(d['city'])].where((e) => e.isNotEmpty).join(', ');
          final rating = (d['ratingCount'] is num && d['ratingCount'] > 0) ? ' · ★ ${(d['rating'] as num).toStringAsFixed(1)}' : '';
          return Scaffold(
            backgroundColor: kBg,
            body: CustomScrollView(slivers: [
              SliverToBoxAdapter(child: Stack(clipBehavior: Clip.none, children: [
                Container(height: 150, color: _catTint(cat),
                    alignment: Alignment.center, child: Icon(_catIcon(cat), size: 64, color: _catInk(cat).withOpacity(0.35))),
                Positioned(left: 16, top: MediaQuery.paddingOf(context).top + 8,
                    child: _circleBtn(Icons.arrow_back_rounded, () => Navigator.pop(context), tr('Back'), bg: kBg)),
                Positioned(right: 16, top: MediaQuery.paddingOf(context).top + 8, child: Row(children: [
                  _circleBtn(_saved ? Icons.favorite_rounded : Icons.favorite_border_rounded, _toggleSave,
                      _saved ? tr('Saved') : tr('Save'), bg: kBg, fg: _saved ? kHabRed : kText),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: tr('More'),
                    color: kBg,
                    onSelected: (v) { if (v == 'report') _report(d); },
                    itemBuilder: (_) => [PopupMenuItem(value: 'report', child: Row(children: [
                      Icon(Icons.flag_outlined, color: kRed, size: 20), const SizedBox(width: 10), Text(tr('Report shop'))]))],
                    child: Container(width: 44, height: 44, decoration: BoxDecoration(color: kBg, shape: BoxShape.circle),
                        child: Icon(Icons.more_horiz_rounded, color: kText)),
                  ),
                ])),
                Positioned(left: 20, bottom: -40, child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: kBg, shape: BoxShape.circle),
                  child: _avatar(d, 84),
                )),
              ])),
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (mine || _isAdmin) Padding(padding: const EdgeInsets.only(bottom: 8),
                      child: _chip(_statusLabel(status), bg: status == 'approved' ? kTintGreen : kTintYellow)),
                  Text(_s(d['name']), style: TextStyle(fontFamily: kFontHeadline, fontSize: 26, fontWeight: FontWeight.w800, color: kText)),
                  const SizedBox(height: 2),
                  Text('${_catLabel(cat)}${where.isNotEmpty ? ' · $where' : ''}$rating', style: tsBodyLg(color: kTextSub)),
                  if (_s(d['description']).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(_s(d['description']), style: tsBodyLg(color: kText)),
                  ],
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip(_availLabel(_s(d['availability'])), bg: _s(d['availability']) == 'order' ? kCard : kTintGreen,
                        dot: _s(d['availability']) == 'order' ? kTextSub : kInkGreen),
                    if (d['pickup'] == true) _chip(tr('Pickup'), icon: Icons.storefront_outlined),
                    if (d['delivery'] == true) _chip(tr('Delivery'), icon: Icons.local_shipping_outlined),
                  ]),
                  if (mine) _OwnerControls(id: widget.shopId, d: d),
                  if (_isAdmin && !mine) _AdminControls(id: widget.shopId, status: status),
                  const SizedBox(height: 18),
                  Text(tr('Products'), style: TextStyle(fontFamily: kFontHeadline, fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
                  const SizedBox(height: 10),
                ]),
              )),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _shops.doc(widget.shopId).collection('products').orderBy('order').snapshots(),
                builder: (_, ps) {
                  final items = ps.data?.docs ?? [];
                  if (items.isEmpty) {
                    return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20),
                        child: Text(tr('No products yet.'), style: tsBodyLg(color: kTextSub))));
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 12, childAspectRatio: 0.74),
                      delegate: SliverChildBuilderDelegate((_, i) => _ProductCard(p: items[i].data()), childCount: items.length),
                    ),
                  );
                },
              ),
            ]),
            bottomNavigationBar: Container(
              color: kCard,
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Icon(Icons.verified_user_outlined, size: 16, color: kTextSub),
                  const SizedBox(width: 6),
                  Expanded(child: Text(tr('You pay the seller directly · Address is shared after you agree'),
                      style: tsBodySm(color: kTextSub))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: SizedBox(height: 52, child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white),
                    onPressed: () => _whatsApp(d),
                    icon: const Icon(Icons.chat_outlined),
                    label: Text(tr('Order on WhatsApp'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ))),
                  const SizedBox(width: 10),
                  _circleBtn(Icons.call_outlined, () => _call(d), tr('Call'), bg: kCardHigh),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> p;
  const _ProductCard({required this.p});
  @override
  Widget build(BuildContext context) {
    final url = _s(p['photoUrl']);
    return Container(
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: url.isEmpty
            ? Container(color: kCardHigh, alignment: Alignment.center, child: Icon(Icons.image_outlined, color: kTextSub))
            : CachedNetworkImage(imageUrl: url, width: double.infinity, fit: BoxFit.cover, memCacheWidth: 500)),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_s(p['name']), maxLines: 1, overflow: TextOverflow.ellipsis, style: tsTitleMd(color: kText)),
            if (_s(p['price']).isNotEmpty) Text('${_s(p['price'])} kr', style: tsTitleMd(color: kInkGreen)),
            if (_s(p['description']).isNotEmpty)
              Text(_s(p['description']), maxLines: 2, overflow: TextOverflow.ellipsis, style: tsBodySm(color: kTextSub)),
          ]),
        ),
      ]),
    );
  }
}

/// Owner: edit, "available now / on order", pause — without a new approval
class _OwnerControls extends StatelessWidget {
  final String id;
  final Map<String, dynamic> d;
  const _OwnerControls({required this.id, required this.d});
  @override
  Widget build(BuildContext context) {
    final status = _s(d['status']), avail = _s(d['availability']);
    final live = status == 'approved' || status == 'paused';
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('Your shop'), style: tsTitleMd(color: kText)),
        const SizedBox(height: 8),
        if (live) ...[
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'now', label: Text(tr('Available now'))),
              ButtonSegment(value: 'order', label: Text(tr('On order'))),
            ],
            selected: {avail == 'order' ? 'order' : 'now'},
            onSelectionChanged: (v) => _shops.doc(id).update({'availability': v.first, 'updatedAt': FieldValue.serverTimestamp()}),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopFormScreen(shopId: id))),
            icon: const Icon(Icons.edit_outlined), label: Text(tr('Edit shop'))),
          if (live)
            OutlinedButton.icon(
              onPressed: () => _shops.doc(id).update({
                'status': status == 'paused' ? 'approved' : 'paused', 'updatedAt': FieldValue.serverTimestamp()}),
              icon: Icon(status == 'paused' ? Icons.play_arrow_rounded : Icons.pause_rounded),
              label: Text(status == 'paused' ? tr('Open the shop again') : tr('Pause the shop'))),
        ]),
        if (!live) Padding(padding: const EdgeInsets.only(top: 8),
            child: Text(tr('Habesha Hub checks the shop before it is shown to others.'), style: tsBodySm(color: kTextSub))),
      ]),
    );
  }
}

class _AdminControls extends StatelessWidget {
  final String id, status;
  const _AdminControls({required this.id, required this.status});
  @override
  Widget build(BuildContext context) {
    Future<void> set(String s) => _shops.doc(id).update({'status': s, 'reviewedAt': FieldValue.serverTimestamp()});
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(children: [
        if (status != 'approved') Expanded(child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white),
          onPressed: () => set('approved'), icon: const Icon(Icons.check_rounded), label: Text(tr('Approve')))),
        if (status != 'approved' && status != 'rejected') const SizedBox(width: 10),
        if (status != 'rejected') Expanded(child: OutlinedButton.icon(
          onPressed: () => set('rejected'), icon: Icon(Icons.block_rounded, color: kRed),
          label: Text(tr('Reject'), style: TextStyle(color: kRed)))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SCREEN 3 — open / edit your shop
// ═══════════════════════════════════════════════════════════
class _ProductDraft {
  String? id;
  final name = TextEditingController(), price = TextEditingController(), description = TextEditingController();
  String photoUrl = '';
  File? photo;
  _ProductDraft();
}

class ShopFormScreen extends StatefulWidget {
  final String? shopId; // null = new shop
  const ShopFormScreen({super.key, this.shopId});
  @override
  State<ShopFormScreen> createState() => _ShopFormScreenState();
}

class _ShopFormScreenState extends State<ShopFormScreen> {
  final _name = TextEditingController(), _area = TextEditingController(), _city = TextEditingController();
  final _desc = TextEditingController(), _whatsapp = TextEditingController(text: '+47 '), _phone = TextEditingController();
  String _cat = 'food', _photoUrl = '', _availability = 'now', _error = '';
  File? _photo;
  bool _pickup = true, _delivery = false, _loading = true, _saving = false;
  final List<_ProductDraft> _products = [];
  final List<String> _removed = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.shopId != null) {
      final doc = await _shops.doc(widget.shopId).get();
      final d = doc.data() ?? {};
      _name.text = _s(d['name']);
      _area.text = _s(d['area']);
      _city.text = _s(d['city']);
      _desc.text = _s(d['description']);
      _whatsapp.text = _s(d['whatsapp']);
      _phone.text = _s(d['phone']);
      _cat = _cats.contains(_s(d['category'])) ? _s(d['category']) : 'food';
      _photoUrl = _s(d['photoUrl']);
      _availability = _s(d['availability']) == 'order' ? 'order' : 'now';
      _pickup = d['pickup'] != false;
      _delivery = d['delivery'] == true;
      final ps = await _shops.doc(widget.shopId).collection('products').orderBy('order').get();
      for (final p in ps.docs) {
        final pd = _ProductDraft()..id = p.id..photoUrl = _s(p.data()['photoUrl']);
        pd.name.text = _s(p.data()['name']);
        pd.price.text = _s(p.data()['price']);
        pd.description.text = _s(p.data()['description']);
        _products.add(pd);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<File?> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
    return x == null ? null : File(x.path);
  }

  Future<String> _upload(String uid, File f) async {
    final ref = FirebaseStorage.instance.ref('homeShops/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(f, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> _submit() async {
    final user = await _realUser(context);
    if (user == null) return;
    if (_name.text.trim().isEmpty || _area.text.trim().isEmpty || _digits(_whatsapp.text).length < 7) {
      setState(() => _error = tr('Please write the shop name, area and a WhatsApp number.'));
      return;
    }
    setState(() { _saving = true; _error = ''; });
    try {
      if (_photo != null) _photoUrl = await _upload(user.uid, _photo!);
      final names = <String>[];
      for (final p in _products) {
        if (p.photo != null) p.photoUrl = await _upload(user.uid, p.photo!);
        if (p.name.text.trim().isNotEmpty) names.add(p.name.text.trim());
      }
      final data = <String, dynamic>{
        'ownerId': user.uid,
        'name': _name.text.trim(),
        'category': _cat,
        'area': _area.text.trim(),
        'city': _city.text.trim(),
        'description': _desc.text.trim(),
        'whatsapp': _whatsapp.text.trim(),
        'phone': _phone.text.trim(),
        'pickup': _pickup,
        'delivery': _delivery,
        'availability': _availability,
        'photoUrl': _photoUrl,
        'productNames': names,
        'status': 'pending', // every change is checked again before it is shown
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final DocumentReference<Map<String, dynamic>> ref;
      if (widget.shopId == null) {
        ref = _shops.doc();
        await ref.set({...data, 'rating': 0, 'ratingCount': 0, 'createdAt': FieldValue.serverTimestamp()});
      } else {
        ref = _shops.doc(widget.shopId);
        await ref.update(data);
      }
      // products after the shop is pending (the rules only allow product changes then)
      for (final id in _removed) {
        await ref.collection('products').doc(id).delete();
      }
      for (var i = 0; i < _products.length; i++) {
        final p = _products[i];
        if (p.name.text.trim().isEmpty) continue;
        final pref = p.id == null ? ref.collection('products').doc() : ref.collection('products').doc(p.id);
        await pref.set({
          'name': p.name.text.trim(),
          'price': p.price.text.trim(),
          'description': p.description.text.trim(),
          'photoUrl': p.photoUrl,
          'order': i,
        });
      }
      if (!mounted) return;
      await showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text(tr('Sent for approval'), style: tsHeadlineSm(color: kText)),
        content: Text(tr('Thank you! Habesha Hub checks your shop before it is shown. You can see the status under Home shops > My shop.'),
            style: tsBodyLg(color: kText)),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('OK')))],
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('home shop save: $e');
      if (mounted) setState(() { _saving = false; _error = tr('Could not save. Check your internet and try again.'); });
    }
  }

  Future<void> _deleteShop() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(tr('Delete shop'), style: tsHeadlineSm(color: kText)),
      content: Text(tr('Your shop and all products will be removed.'), style: tsBodyLg(color: kText)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Delete'), style: TextStyle(color: kRed))),
      ],
    ));
    if (ok != true) return;
    await _shops.doc(widget.shopId).delete();
    if (mounted) Navigator.pop(context);
  }

  InputDecoration _dec(String label, {String? hint, IconData? icon}) =>
      InputDecoration(labelText: label, hintText: hint, prefixIcon: icon == null ? null : Icon(icon, color: kTextSub));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.shopId == null ? tr('Open your shop') : tr('Edit shop')),
            Text(tr('Free · checked before it goes live'), style: tsBodySm(color: kTextSub)),
          ]),
          actions: [
            if (widget.shopId != null)
              IconButton(tooltip: tr('Delete shop'), onPressed: _deleteShop, icon: Icon(Icons.delete_outline_rounded, color: kRed)),
          ],
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 2))
            : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
                Center(child: GestureDetector(
                  onTap: () async { final f = await _pick(); if (f != null) setState(() => _photo = f); },
                  child: Stack(children: [
                    Container(
                      width: 104, height: 104,
                      decoration: BoxDecoration(color: _catTint(_cat), shape: BoxShape.circle),
                      clipBehavior: Clip.antiAlias,
                      child: _photo != null
                          ? Image.file(_photo!, fit: BoxFit.cover)
                          : _photoUrl.isNotEmpty
                              ? CachedNetworkImage(imageUrl: _photoUrl, fit: BoxFit.cover)
                              : Icon(_catIcon(_cat), size: 40, color: _catInk(_cat)),
                    ),
                    Positioned(right: 0, bottom: 0, child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: kSecondary, shape: BoxShape.circle),
                      child: Icon(Icons.photo_camera_outlined, size: 18, color: kOnAccent))),
                  ]),
                )),
                const SizedBox(height: 6),
                Center(child: Text(tr('Photo or logo'), style: tsBodySm(color: kTextSub))),
                const SizedBox(height: 16),
                TextField(controller: _name, decoration: _dec(tr('Shop name'), icon: Icons.storefront_outlined)),
                const SizedBox(height: 14),
                Text(tr('Category'), style: tsTitleMd(color: kText)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final c in _cats)
                    ChoiceChip(
                      label: Text(_catLabel(c)),
                      selected: _cat == c,
                      onSelected: (_) => setState(() => _cat = c),
                      selectedColor: kSecondary,
                      labelStyle: TextStyle(color: _cat == c ? kOnAccent : kText, fontWeight: FontWeight.w600),
                      showCheckmark: false,
                    ),
                ]),
                const SizedBox(height: 14),
                TextField(controller: _desc, maxLines: 3, maxLength: 300,
                    decoration: _dec(tr('Short text about your shop'), hint: tr('What do you make? When can people order?'))),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: TextField(controller: _area, decoration: _dec(tr('Area'), hint: tr('e.g. Grønland'), icon: Icons.place_outlined))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _city, decoration: _dec(tr('City'), hint: 'Oslo'))),
                ]),
                Padding(padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(tr('Only the area is shown. Never write your street address.'), style: tsBodySm(color: kTextSub))),
                const SizedBox(height: 14),
                TextField(controller: _whatsapp, keyboardType: TextInputType.phone,
                    decoration: _dec(tr('WhatsApp number'), icon: Icons.chat_outlined)),
                const SizedBox(height: 10),
                TextField(controller: _phone, keyboardType: TextInputType.phone,
                    decoration: _dec(tr('Phone for calls (optional)'), icon: Icons.call_outlined)),
                const SizedBox(height: 10),
                SwitchListTile(value: _pickup, onChanged: (v) => setState(() => _pickup = v),
                    title: Text(tr('Pickup'), style: tsTitleMd(color: kText)), contentPadding: EdgeInsets.zero),
                SwitchListTile(value: _delivery, onChanged: (v) => setState(() => _delivery = v),
                    title: Text(tr('Delivery'), style: tsTitleMd(color: kText)), contentPadding: EdgeInsets.zero),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'now', label: Text(tr('Available now'))),
                    ButtonSegment(value: 'order', label: Text(tr('Order 1 day before'))),
                  ],
                  selected: {_availability},
                  onSelectionChanged: (v) => setState(() => _availability = v.first),
                ),
                const SizedBox(height: 22),
                Row(children: [
                  Expanded(child: Text(tr('Products'), style: TextStyle(fontFamily: kFontHeadline, fontSize: 20, fontWeight: FontWeight.w800, color: kText))),
                  TextButton.icon(onPressed: () => setState(() => _products.add(_ProductDraft())),
                      icon: const Icon(Icons.add_rounded), label: Text(tr('Add product'))),
                ]),
                for (var i = 0; i < _products.length; i++) _productEditor(i),
                if (_products.isEmpty)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(tr('Add what you sell, with a photo and price.'), style: tsBodySm(color: kTextSub))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kTintYellow, borderRadius: BorderRadius.circular(18)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline_rounded, color: kInkYellow),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr('You are responsible for following the rules. Selling food regularly from home needs registration with Mattilsynet.'),
                          style: tsBodyLg(color: kText)),
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () => launchUrl(Uri.parse('https://www.mattilsynet.no/mat/produksjon-og-salg-av-mat/salg-av-mat-fra-privatpersoner'),
                            mode: LaunchMode.externalApplication),
                        child: Text(tr('Read more'), style: TextStyle(color: kInkYellow, fontWeight: FontWeight.w700)),
                      ),
                    ])),
                  ]),
                ),
                if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error, style: tsBodyLg(color: kRed))),
                const SizedBox(height: 18),
                goldButton(tr('Send for approval'), _saving ? null : _submit, loading: _saving, icon: Icons.send_rounded),
              ]),
      ),
    );
  }

  Widget _productEditor(int i) {
    final p = _products[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () async { final f = await _pick(); if (f != null) setState(() => p.photo = f); },
          child: Container(
            width: 76, height: 76,
            decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(14)),
            clipBehavior: Clip.antiAlias,
            child: p.photo != null
                ? Image.file(p.photo!, fit: BoxFit.cover)
                : p.photoUrl.isNotEmpty
                    ? CachedNetworkImage(imageUrl: p.photoUrl, fit: BoxFit.cover)
                    : Icon(Icons.add_a_photo_outlined, color: kTextSub),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(children: [
          TextField(controller: p.name, decoration: InputDecoration(hintText: tr('Product name'), isDense: true)),
          const SizedBox(height: 6),
          TextField(controller: p.price, keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: tr('Price'), suffixText: 'kr', isDense: true)),
          const SizedBox(height: 6),
          TextField(controller: p.description, decoration: InputDecoration(hintText: tr('Description (optional)'), isDense: true)),
        ])),
        IconButton(
          tooltip: tr('Delete'),
          onPressed: () => setState(() { if (p.id != null) _removed.add(p.id!); _products.removeAt(i); }),
          icon: Icon(Icons.close_rounded, color: kTextSub),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    for (final c in [_name, _area, _city, _desc, _whatsapp, _phone]) {
      c.dispose();
    }
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════
// ADMIN TAB — approve / reject shops, holiday banner switch
// ═══════════════════════════════════════════════════════════
class HomeShopsAdminTab extends StatelessWidget {
  const HomeShopsAdminTab({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('app_config').doc('homeShops').snapshots(),
        builder: (_, snap) => SwitchListTile(
          value: snap.data?.data()?['holidayBanner'] == true,
          onChanged: (v) => _db.collection('app_config').doc('homeShops').set({'holidayBanner': v}, SetOptions(merge: true)),
          title: Text(tr('Holiday banner'), style: tsTitleMd(color: kText)),
          subtitle: Text(tr('Shows "Order early for the holidays" in Home shops'), style: tsBodySm(color: kTextSub)),
        ),
      ),
      const SizedBox(height: 8),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _shops.snapshots(),
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          const order = {'pending': 0, 'approved': 1, 'paused': 2, 'rejected': 3};
          docs.sort((a, b) => (order[_s(a.data()['status'])] ?? 0).compareTo(order[_s(b.data()['status'])] ?? 0));
          if (docs.isEmpty) return Padding(padding: const EdgeInsets.all(24), child: Text(tr('No home shops yet.'), style: tsBodyLg(color: kTextSub)));
          return Column(children: [
            for (final doc in docs)
              Padding(padding: const EdgeInsets.only(bottom: 10),
                  child: _ShopTile(id: doc.id, d: doc.data(), status: _s(doc.data()['status']))),
          ]);
        },
      ),
    ]);
  }
}
