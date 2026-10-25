import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import 'auth_screen.dart';
import '../utils/translations.dart';

// ═══════════════════════════════════════════════════════════
// MARKETPLACE SCREEN  (ListView + image gallery, no chat)
// ═══════════════════════════════════════════════════════════

/// Reads any Firestore value as a trimmed String (handles int, double, null).
String _s(dynamic v) => v == null ? '' : v.toString().trim();

/// Reads a Firestore value as a list of non-empty Strings (handles String or List).
List<String> _sList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.map(_s).where((e) => e.isNotEmpty).toList();
  final one = _s(v);
  return one.isEmpty ? [] : [one];
}

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _db = FirebaseFirestore.instance;
  String _selectedCategory = 'All';
  String _nameFilter = '';
  bool _locating = false;
  String _cityFilter = '';
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  List<QueryDocumentSnapshot> _allDocs = [];
  List<QueryDocumentSnapshot> _filteredDocs = [];

  final _categories = [
    {'key': 'All',         'emoji': '🌍'},
    {'key': 'Clothes',     'emoji': '👗'},
    {'key': 'Electronics', 'emoji': '📱'},
    {'key': 'Furniture',   'emoji': '🛋️'},
    {'key': 'Food',        'emoji': '🍽️'},
    {'key': 'Books',       'emoji': '📚'},
    {'key': 'Other',       'emoji': '📦'},
  ];

  void _applyFilters() {
    var docs = List<QueryDocumentSnapshot>.from(_allDocs);
    if (_selectedCategory != 'All') {
      docs = docs.where((d) => (d.data() as Map)['category'] == _selectedCategory).toList();
    }
    if (_cityFilter.isNotEmpty) {
      docs = docs.where((d) =>
        ((d.data() as Map)['city'] ?? '').toString().toLowerCase().contains(_cityFilter)).toList();
    }
    if (_nameFilter.isNotEmpty) {
      docs = docs.where((d) {
        final data = d.data() as Map;
        return (data['title'] ?? '').toString().toLowerCase().contains(_nameFilter) ||
               (data['description'] ?? '').toString().toLowerCase().contains(_nameFilter);
      }).toList();
    }
    setState(() => _filteredDocs = docs);
  }

  List<QueryDocumentSnapshot> get _displayDocs {
    final hasFilter = _nameFilter.isNotEmpty || _cityFilter.isNotEmpty || _selectedCategory != 'All';
    return hasFilter ? _filteredDocs : _allDocs;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        final user = FirebaseAuth.instance.currentUser;
        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            backgroundColor: kCard,
            iconTheme: const IconThemeData(color: kSecondary),
            title: Text(t('marketplace_title'), style: tsTitleMd(color: kSecondary)),
            actions: [
              if (user != null)
                GestureDetector(
                  onTap: () => _showAddListing(context, user, t),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(100)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_rounded, color: Color(0xFF1A1200), size: 16),
                      const SizedBox(width: 4),
                      Text(t('marketplace_sell'), style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 12)),
                    ]),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true))),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(100)),
                    child: Text(t('login'),
                      style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 12)),
                  ),
                ),
            ],
          ),
          body: Column(children: [
            // ── Name search ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kSecondary.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _nameCtrl,
                  style: tsBodyLg(color: kText),
                  onChanged: (v) { _nameFilter = v.trim().toLowerCase(); _applyFilters(); },
                  decoration: InputDecoration(
                    hintText: t('marketplace_search_name'),
                    filled: false, border: InputBorder.none,
                    prefixIcon: Icon(Icons.search_rounded, color: kSecondary, size: 18),
                    suffixIcon: _nameFilter.isNotEmpty
                        ? GestureDetector(
                            onTap: () { _nameCtrl.clear(); _nameFilter = ''; _applyFilters(); },
                            child: Icon(Icons.clear_rounded, color: kTextSub, size: 16))
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            // ── City + GPS ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kSecondary.withOpacity(0.2)),
                    ),
                    child: TextField(
                      controller: _cityCtrl,
                      style: tsBodyLg(color: kText),
                      onChanged: (v) { _cityFilter = v.trim().toLowerCase(); _applyFilters(); },
                      decoration: InputDecoration(
                        hintText: t('marketplace_search_city'),
                        filled: false, border: InputBorder.none,
                        prefixIcon: Icon(Icons.location_on_rounded, color: kSecondary, size: 18),
                        suffixIcon: _cityFilter.isNotEmpty
                            ? GestureDetector(
                                onTap: () { _cityCtrl.clear(); _cityFilter = ''; _applyFilters(); },
                                child: Icon(Icons.clear_rounded, color: kTextSub, size: 16))
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _locating ? null : () async {
                    setState(() => _locating = true);
                    try {
                      bool enabled = await Geolocator.isLocationServiceEnabled();
                      if (!enabled) { setState(() => _locating = false); return; }
                      LocationPermission perm = await Geolocator.checkPermission();
                      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
                      if (perm == LocationPermission.denied) { setState(() => _locating = false); return; }
                      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
                      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
                      if (placemarks.isNotEmpty) {
                        final city = placemarks.first.locality ?? '';
                        _cityCtrl.text = city;
                        _cityFilter = city.toLowerCase();
                        _applyFilters();
                      }
                    } catch (_) {}
                    setState(() => _locating = false);
                  },
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(12)),
                    child: _locating
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(color: Color(0xFF1A1200), strokeWidth: 2))
                        : const Icon(Icons.my_location_rounded, color: Color(0xFF1A1200), size: 20),
                  ),
                ),
              ]),
            ),
            // ── Category chips ──────────────────────────
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final sel = _selectedCategory == cat['key'];
                  return GestureDetector(
                    onTap: () { setState(() => _selectedCategory = cat['key']!); _applyFilters(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? kSecondary : kCardHigh,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(cat['emoji']!, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                        Text(
                          t('market_${cat['key']!.toLowerCase()}'),
                          style: tsLabel(color: sel ? Color(0xFF342800) : kTextSub)
                              .copyWith(fontSize: 11),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // ── Listings ────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('marketplace')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (_, snap) {
                  if (!snap.hasData) return const Center(
                    child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
                  _allDocs = snap.data!.docs;
                  final docs = _displayDocs;
                  if (docs.isEmpty) {
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('🛒', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      Text(t('marketplace_empty'), style: tsTitleLg()),
                      const SizedBox(height: 8),
                      Text(t('marketplace_be_first'), style: tsBodySm()),
                    ]));
                  }
                  // ── Group listings per seller ─────────────
                  final groups = <String, List<QueryDocumentSnapshot>>{};
                  for (final doc in docs) {
                    final m = doc.data() as Map<String, dynamic>;
                    final key = _s(m['userId']).isNotEmpty ? _s(m['userId'])
                        : _s(m['sellerName']).isNotEmpty ? 'name:${_s(m['sellerName'])}'
                        : doc.id;
                    groups.putIfAbsent(key, () => []).add(doc);
                  }
                  final keys = groups.keys.toList();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: keys.length,
                    itemBuilder: (_, i) {
                      final list = groups[keys[i]]!;
                      return _SellerCard(
                        key: ValueKey(keys[i]),
                        listings: list,
                        t: t,
                        onOpen: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => SellerProfileScreen(
                            sellerKey: keys[i],
                            initial: list,
                            t: t,
                            onEdit: (docId, data) => _showAddListing(context, user!, t,
                                existing: data, docId: docId),
                            onDelete: (ctx, docId) => _confirmDelete(ctx, docId, t),
                          ))),
                      );
                    },
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, String docId, String Function(String) t) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: kCardHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t('delete_listing'), style: tsHeadlineSm()),
        content: Text(t('delete_listing_confirm'), style: tsBodyLg()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel'), style: tsTitleMd(color: kTextSub))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('delete'), style: tsTitleMd(color: kRed))),
        ],
      ),
    );
    if (ok == true) _db.collection('marketplace').doc(docId).delete();
  }

  void _showAddListing(
    BuildContext context,
    User user,
    String Function(String) t, {
    Map<String, dynamic>? existing,
    String? docId,
  }) {
    final titleCtrl = TextEditingController(text: _s(existing?['title']));
    final descCtrl  = TextEditingController(text: _s(existing?['description']));
    final priceCtrl = TextEditingController(text: _s(existing?['price']));
    final cityCtrl  = TextEditingController(text: _s(existing?['city']));
    final phoneCtrl = TextEditingController(text: _s(existing?['sellerPhone']));
    String selCat = _s(existing?['category']).isEmpty ? 'Other' : _s(existing?['category']);
    File? selImage;
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          expand: false, initialChildSize: 0.92,
          builder: (_, ctrl) => SingleChildScrollView(
            controller: ctrl,
            padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: kOutlineVariant,
                  borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(existing != null ? t('marketplace_edit') : t('marketplace_add'),
                style: tsHeadlineSm(color: kSecondary)),
              const SizedBox(height: 20),
              // Image picker
              GestureDetector(
                onTap: uploading ? null : () async {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery, imageQuality: 80);
                  if (picked != null) setModal(() => selImage = File(picked.path));
                },
                child: Container(
                  height: 160, width: double.infinity,
                  decoration: BoxDecoration(
                    color: kCardHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kSecondary.withOpacity(0.3))),
                  child: selImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(selImage!, fit: BoxFit.cover))
                      : _s(existing?['imageUrl']).isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(_s(existing?['imageUrl']), fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(child: Icon(
                                  Icons.broken_image_rounded, color: kSecondary, size: 36))))
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.add_photo_alternate_rounded,
                                color: kSecondary, size: 36),
                              const SizedBox(height: 8),
                              Text(t('add_photo'), style: tsBodySm(color: kSecondary)),
                            ]),
                ),
              ),
              const SizedBox(height: 16),
              // Category chips
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _categories.where((c) => c['key'] != 'All').map((cat) {
                  final sel = selCat == cat['key'];
                  return GestureDetector(
                    onTap: () => setModal(() => selCat = cat['key']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? kSecondary : kCardHigh,
                        borderRadius: BorderRadius.circular(100)),
                      child: Text('${cat['emoji']} ${cat['key']}',
                        style: tsLabel(color: sel ? Color(0xFF342800) : kTextSub)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _field(titleCtrl, t('marketplace_title_field'), Icons.title_rounded),
              const SizedBox(height: 12),
              _field(descCtrl, t('marketplace_description'),
                Icons.description_rounded, maxLines: 3),
              const SizedBox(height: 12),
              _field(priceCtrl, t('marketplace_price'),
                Icons.payments_rounded, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _field(cityCtrl, t('marketplace_city'), Icons.location_on_rounded),
              const SizedBox(height: 12),
              _field(phoneCtrl, t('phone'),
                Icons.phone_rounded, keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              primaryButton(
                uploading ? '' : t('marketplace_post'),
                uploading ? null : () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  setModal(() => uploading = true);
                  String imageUrl = _s(existing?['imageUrl']);
                  if (selImage != null) {
                    final ref = FirebaseStorage.instance.ref(
                      'marketplace/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
                    await ref.putFile(selImage!);
                    imageUrl = await ref.getDownloadURL();
                  }
                  final payload = {
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'price': priceCtrl.text.trim(),
                    'city': cityCtrl.text.trim(),
                    'category': selCat,
                    'imageUrl': imageUrl,
                    'sellerPhone': phoneCtrl.text.trim(),
                    'sellerName': user.displayName ?? '',
                    'userId': user.uid,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };
                  if (docId != null) {
                    await _db.collection('marketplace').doc(docId).update(payload);
                  } else {
                    payload['createdAt'] = FieldValue.serverTimestamp();
                    await _db.collection('marketplace').add(payload);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                loading: uploading,
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kSecondary.withOpacity(0.15))),
      child: TextField(
        controller: ctrl, maxLines: maxLines, keyboardType: keyboardType,
        style: tsBodyLg(color: kText),
        decoration: InputDecoration(
          hintText: hint, filled: false, border: InputBorder.none,
          prefixIcon: Icon(icon, color: kSecondary, size: 18),
          contentPadding: EdgeInsets.symmetric(
            vertical: maxLines > 1 ? 14 : 12,
            horizontal: maxLines > 1 ? 16 : 0),
        ),
      ),
    );
  }

  @override
  void dispose() { _nameCtrl.dispose(); _cityCtrl.dispose(); super.dispose(); }
}

// ═══════════════════════════════════════════════════════════
// LISTING CARD — full-width ListView card with image gallery
// ═══════════════════════════════════════════════════════════
class _ListingCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool isMe;
  final String Function(String) t;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ListingCard({
    super.key,
    required this.docId,
    required this.data,
    required this.isMe,
    required this.t,
    this.onEdit,
    this.onDelete,
  });
  @override State<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<_ListingCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final t = widget.t;
    final images = <String>[
      ..._sList(d['imageUrl']),
      ..._sList(d['extraImages']),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kSecondary.withOpacity(0.1), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Image ──────────────────────────────────────
        if (images.isNotEmpty)
          GestureDetector(
            onTap: () => _openGallery(context, images),
            child: Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  images[0],
                  height: 220, width: double.infinity, fit: BoxFit.cover,
                  loadingBuilder: (_, child, prog) => prog == null ? child
                      : Container(height: 220, color: kCardHigh,
                          child: const Center(child: CircularProgressIndicator(
                            color: kSecondary, strokeWidth: 1.5))),
                  errorBuilder: (_, __, ___) => Container(height: 140,
                      color: kCardHigh,
                      child: Center(child: Icon(
                        Icons.broken_image_rounded, color: kTextSub, size: 40))),
                ),
              ),
              if (images.length > 1)
                Positioned(bottom: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(100)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.photo_library_rounded, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text('${images.length}', style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  )),
              Positioned(top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kBg.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(100)),
                  child: Text(tr(_s(d['category'])),
                    style: tsLabel(color: kSecondary).copyWith(fontSize: 11)),
                )),
            ]),
          )
        else
          Container(
            height: 120, width: double.infinity,
            decoration: BoxDecoration(
              color: kCardHigh,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
            child: Center(child: Icon(Icons.image_rounded,
              color: kTextSub, size: 48)),
          ),

        // ── Info ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(_s(d['title']),
                style: tsHeadlineSm(), maxLines: 2, overflow: TextOverflow.ellipsis)),
              if (widget.isMe) Row(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(onTap: widget.onEdit,
                  child: const Icon(Icons.edit_rounded, color: kSecondary, size: 18)),
                const SizedBox(width: 12),
                GestureDetector(onTap: widget.onDelete,
                  child: const Icon(Icons.delete_outline_rounded, color: kRed, size: 18)),
              ]),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              if (_s(d['price']).isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: kSecondary, borderRadius: BorderRadius.circular(100)),
                  child: Text(_s(d['price']),
                    style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 13)),
                ),
                const SizedBox(width: 10),
              ],
              if (_s(d['city']).isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.location_on_rounded, color: kTextSub, size: 13),
                  const SizedBox(width: 3),
                  Text(_s(d['city']), style: tsBodySm(color: kTextSub)),
                ]),
            ]),
            if (_s(d['description']).isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(_s(d['description']),
                  style: tsBodySm(color: kTextSub),
                  maxLines: _expanded ? null : 2,
                  overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis),
              ),
              if (_s(d['description']).length > 80)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(_expanded ? tr('Show less') : tr('Read more'),
                      style: tsBodySm(color: kSecondary)),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            // ── Seller row ───────────────────────────────
            Row(children: [
              Icon(Icons.person_outline_rounded, color: kTextSub, size: 14),
              const SizedBox(width: 4),
              Text(_s(d['sellerName']), style: tsBodySm(color: kTextSub)),
              const Spacer(),
              if (_s(d['sellerPhone']).isNotEmpty)
                GestureDetector(
                  onTap: () => _showSellerContact(context, d, widget.t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: kSecondary, borderRadius: BorderRadius.circular(100)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.phone_rounded, color: Color(0xFF1A1200), size: 14),
                      const SizedBox(width: 6),
                      Text(widget.t('contact_seller'),
                        style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 12)),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }

  void _showSellerContact(
    BuildContext context,
    Map<String, dynamic> d,
    String Function(String) t,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(
              color: kOutlineVariant, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: kCardHigh, shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: kSecondary, size: 32),
          ),
          const SizedBox(height: 12),
          Text(_s(d['sellerName']), style: tsHeadlineSm()),
          const SizedBox(height: 4),
          Text(_s(d['title']), style: tsBodySm(color: kTextSub)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardHigh, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.phone_rounded, color: kSecondary, size: 20),
              const SizedBox(width: 12),
              Text(_s(d['sellerPhone']), style: tsTitleMd()),
            ]),
          ),
          const SizedBox(height: 12),
          Text(t('contact_seller_note'),
            style: tsBodySm(color: kTextSub), textAlign: TextAlign.center),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  void _openGallery(BuildContext context, List<String> images) {
    final pageCtrl = PageController();
    int current = 0;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Expanded(
                child: PageView.builder(
                  controller: pageCtrl,
                  itemCount: images.length,
                  onPageChanged: (i) => setD(() => current = i),
                  itemBuilder: (_, i) => InteractiveViewer(
                    child: Image.network(images[i], fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(
                        Icons.broken_image_rounded, color: Colors.white38, size: 60))),
                  ),
                ),
              ),
              if (images.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == current ? 20 : 8, height: 8,
                      decoration: BoxDecoration(
                        color: i == current ? kSecondary : Colors.white38,
                        borderRadius: BorderRadius.circular(100)),
                    )),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SELLER CARD — one card per seller in the main feed
// ═══════════════════════════════════════════════════════════
List<String> _listingImages(Map<String, dynamic> d) =>
    [..._sList(d['imageUrl']), ..._sList(d['extraImages'])];

class _SellerCard extends StatelessWidget {
  final List<QueryDocumentSnapshot> listings;
  final String Function(String) t;
  final VoidCallback onOpen;
  const _SellerCard({super.key, required this.listings, required this.t, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final first = listings.first.data() as Map<String, dynamic>;
    final name  = _s(first['sellerName']).isEmpty ? '?' : _s(first['sellerName']);
    final city  = _s(first['city']);
    final count = listings.length;

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kSecondary.withOpacity(0.1), width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── seller header ────────────────────────────
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kSecondary.withOpacity(0.15),
              child: Text(name[0].toUpperCase(), style: tsTitleMd(color: kSecondary)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: tsTitleMd(), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                '${city.isNotEmpty ? '$city · ' : ''}$count ${t('market_items')}',
                style: tsBodySm(color: kTextSub)),
            ])),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(t('market_see_all'), style: tsBodySm(color: kSecondary)),
              const Icon(Icons.chevron_right_rounded, color: kSecondary, size: 20),
            ]),
          ]),
          const SizedBox(height: 12),
          // ── thumbnails strip ─────────────────────────
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: listings.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final d = listings[i].data() as Map<String, dynamic>;
                return SizedBox(width: 120, child: _ListingThumb(data: d));
              },
            ),
          ),
        ]),
      ),
    );
  }
}

/// Small square tile: image + title + price
class _ListingThumb extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ListingThumb({required this.data});

  @override
  Widget build(BuildContext context) {
    final imgs  = _listingImages(data);
    final price = _s(data['price']);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(fit: StackFit.expand, children: [
            imgs.isEmpty
                ? Container(color: kCardHigh,
                    child: Icon(Icons.image_rounded, color: kTextSub, size: 32))
                : Image.network(imgs.first, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: kCardHigh,
                      child: Icon(Icons.broken_image_rounded, color: kTextSub, size: 28))),
            if (price.isNotEmpty)
              Positioned(left: 6, bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(100)),
                  child: Text(price, style: tsLabel(color: const Color(0xFF1A1200)).copyWith(fontSize: 10)),
                )),
            if (imgs.length > 1)
              Positioned(right: 6, top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(100)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.photo_library_rounded, color: Colors.white, size: 10),
                    const SizedBox(width: 3),
                    Text('${imgs.length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ]),
                )),
          ]),
        ),
      ),
      const SizedBox(height: 4),
      Text(_s(data['title']), style: tsBodySm(color: kText), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
// SELLER PROFILE — all listings from one seller in a grid
// ═══════════════════════════════════════════════════════════
class SellerProfileScreen extends StatelessWidget {
  final String sellerKey;                       // userId (or "name:…")
  final List<QueryDocumentSnapshot> initial;
  final String Function(String) t;
  final void Function(String docId, Map<String, dynamic> data) onEdit;
  final Future<void> Function(BuildContext ctx, String docId) onDelete;

  const SellerProfileScreen({
    super.key,
    required this.sellerKey,
    required this.initial,
    required this.t,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final first = initial.first.data() as Map<String, dynamic>;
    final name  = _s(first['sellerName']).isEmpty ? '?' : _s(first['sellerName']);
    final byUser = !sellerKey.startsWith('name:') && _s(first['userId']) == sellerKey;

    Widget body(List<QueryDocumentSnapshot> docs) {
      final city = docs.map((d) => _s((d.data() as Map)['city'])).firstWhere(
          (c) => c.isNotEmpty, orElse: () => '');
      return CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: kSecondary.withOpacity(0.15),
              child: Text(name[0].toUpperCase(), style: tsHeadlineSm(color: kSecondary)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: tsHeadlineSm()),
              const SizedBox(height: 2),
              Text('${city.isNotEmpty ? '$city · ' : ''}${docs.length} ${t('market_items')}',
                  style: tsBodySm(color: kTextSub)),
            ])),
          ]),
        )),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 14,
              childAspectRatio: 0.78),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final doc = docs[i];
                final d = doc.data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(
                    builder: (_) => _ListingDetailScreen(
                      docId: doc.id,
                      t: t,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ))),
                  child: _ListingThumb(data: d),
                );
              },
              childCount: docs.length,
            ),
          ),
        ),
      ]);
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Text(name, style: tsTitleMd(color: kSecondary)),
      ),
      body: !byUser
          ? body(initial)
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('marketplace')
                  .where('userId', isEqualTo: sellerKey).snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) return body(initial);
                final docs = snap.data!.docs.toList()
                  ..sort((a, b) {
                    final ta = (a.data() as Map)['createdAt'];
                    final tb = (b.data() as Map)['createdAt'];
                    if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                    return 0;
                  });
                if (docs.isEmpty) {
                  return Center(child: Text(t('marketplace_empty'), style: tsTitleLg()));
                }
                return body(docs);
              },
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// LISTING DETAIL — full card for one listing (live)
// ═══════════════════════════════════════════════════════════
class _ListingDetailScreen extends StatelessWidget {
  final String docId;
  final String Function(String) t;
  final void Function(String docId, Map<String, dynamic> data) onEdit;
  final Future<void> Function(BuildContext ctx, String docId) onDelete;
  const _ListingDetailScreen({
    required this.docId, required this.t, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        iconTheme: const IconThemeData(color: kSecondary),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('marketplace').doc(docId).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
          }
          if (!snap.data!.exists) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
            });
            return const SizedBox.shrink();
          }
          final d = snap.data!.data() as Map<String, dynamic>;
          final isMe = me != null && me == _s(d['userId']);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _ListingCard(
              docId: docId,
              data: d,
              isMe: isMe,
              t: t,
              onEdit: isMe ? () => onEdit(docId, d) : null,
              onDelete: isMe ? () => onDelete(ctx, docId) : null,
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MARKET INBOX SCREEN  (stub — kept for backwards compat)
// ═══════════════════════════════════════════════════════════
class MarketInboxScreen extends StatelessWidget {
  final String userId;
  const MarketInboxScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Text('Inbox', style: tsTitleMd(color: kSecondary)),
      ),
      body: Center(child: Text('Inbox coming soon', style: tsBodyLg())),
    );
  }
}
