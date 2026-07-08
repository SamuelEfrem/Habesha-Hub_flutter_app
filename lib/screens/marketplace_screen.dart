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
import 'guest_chat_screen.dart';
import '../models/business.dart';
import 'auth_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _db = FirebaseFirestore.instance;
  String _selectedCategory = 'All';
  String _cityFilter = '';
  String _nameFilter = '';
  bool _locating = false;
  final _citySearchCtrl = TextEditingController();
  final _nameSearchCtrl = TextEditingController();
  List<QueryDocumentSnapshot> _allDocs = [];
  List<QueryDocumentSnapshot> _filteredDocs = [];

  final _categories = [
    {'key': 'All', 'emoji': '🌍'},
    {'key': 'Clothes', 'emoji': '👗'},
    {'key': 'Electronics', 'emoji': '📱'},
    {'key': 'Furniture', 'emoji': '🛋️'},
    {'key': 'Food', 'emoji': '🍽️'},
    {'key': 'Books', 'emoji': '📚'},
    {'key': 'Other', 'emoji': '📦'},
  ];

  void _applyFilters() {
    var docs = List<QueryDocumentSnapshot>.from(_allDocs);
    if (_selectedCategory != 'All') {
      docs = docs.where((d) => (d.data() as Map)['category'] == _selectedCategory).toList();
    }
    if (_cityFilter.isNotEmpty) {
      docs = docs.where((d) => ((d.data() as Map)['city'] ?? '').toString().toLowerCase().contains(_cityFilter)).toList();
    }
    if (_nameFilter.isNotEmpty) {
      docs = docs.where((d) {
        final data = d.data() as Map;
        final title = (data['title'] ?? '').toString().toLowerCase();
        final desc = (data['description'] ?? '').toString().toLowerCase();
        return title.contains(_nameFilter) || desc.contains(_nameFilter);
      }).toList();
    }
    setState(() => _filteredDocs = docs);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        final user = FirebaseAuth.instance.currentUser;
        return Scaffold(
          backgroundColor: kSurface,
          appBar: AppBar(
            backgroundColor: kSurfaceContainer,
            iconTheme: const IconThemeData(color: kSecondary),
            title: Text(t('marketplace_title'), style: tsTitleMd(color: kSecondary)),
            actions: [
              if (user != null) ...[
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarketInboxScreen(userId: user.uid))),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: kSurfaceContainer, shape: BoxShape.circle, border: Border.all(color: kSecondary.withOpacity(0.3))),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: kSecondary, size: 18),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAddListing(context, user, t),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(100)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_rounded, color: Color(0xFF1A1200), size: 16),
                      const SizedBox(width: 4),
                      Text(t('marketplace_sell'), style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 12)),
                    ]),
                  ),
                ),
              ],
            ],
          ),
          body: Column(children: [
            // Name search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                height: 42,
                decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.2))),
                child: TextField(
                  controller: _nameSearchCtrl,
                  style: tsBodyLg(color: kOnSurface),
                  onChanged: (v) { _nameFilter = v.trim().toLowerCase(); _applyFilters(); },
                  decoration: InputDecoration(
                    hintText: t('marketplace_search_name'),
                    filled: false, border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search_rounded, color: kSecondary, size: 18),
                    suffixIcon: _nameFilter.isNotEmpty ? GestureDetector(onTap: () { _nameSearchCtrl.clear(); _nameFilter = ''; _applyFilters(); }, child: const Icon(Icons.clear_rounded, color: kOnSurfaceVariant, size: 16)) : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            // City search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.2))),
                    child: TextField(
                      controller: _citySearchCtrl,
                      style: tsBodyLg(color: kOnSurface),
                      onChanged: (v) { _cityFilter = v.trim().toLowerCase(); _applyFilters(); },
                      decoration: InputDecoration(
                        hintText: t('marketplace_search_city'),
                        filled: false, border: InputBorder.none,
                        prefixIcon: const Icon(Icons.location_on_rounded, color: kSecondary, size: 18),
                        suffixIcon: _cityFilter.isNotEmpty ? GestureDetector(onTap: () { _citySearchCtrl.clear(); _cityFilter = ''; _applyFilters(); }, child: const Icon(Icons.clear_rounded, color: kOnSurfaceVariant, size: 16)) : null,
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
                        _citySearchCtrl.text = city;
                        _cityFilter = city.toLowerCase();
                        _applyFilters();
                        setState(() => _locating = false);
                      }
                    } catch (e) { setState(() => _locating = false); }
                  },
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(12)),
                    child: _locating
                        ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Color(0xFF1A1200), strokeWidth: 2))
                        : const Icon(Icons.my_location_rounded, color: Color(0xFF1A1200), size: 20),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            // Category filter
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final sel = _selectedCategory == cat['key'];
                  return GestureDetector(
                    onTap: () { _selectedCategory = cat['key']!; _applyFilters(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: sel ? kSecondary : kSurfaceContainerHigh, borderRadius: BorderRadius.circular(100)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(cat['emoji']!, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(t('market_${cat['key']!.toLowerCase()}'), style: tsLabel(color: sel ? const Color(0xFF342800) : kOnSurfaceVariant).copyWith(fontSize: 9)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Listings
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('marketplace').snapshots(),
                builder: (_, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
                  _allDocs = snap.data!.docs;
                  if (_filteredDocs.isEmpty && _nameFilter.isEmpty && _cityFilter.isEmpty && _selectedCategory == 'All') {
                    _filteredDocs = _allDocs;
                  } else if (_nameFilter.isEmpty && _cityFilter.isEmpty && _selectedCategory == 'All') {
                    _filteredDocs = _allDocs;
                  }
                  final docs = _filteredDocs.isEmpty && _nameFilter.isEmpty && _cityFilter.isEmpty && _selectedCategory == 'All' ? _allDocs : _filteredDocs;
                  if (docs.isEmpty) {
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('🛒', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      Text(t('marketplace_empty'), style: tsTitleLg()),
                      const SizedBox(height: 8),
                      Text(t('marketplace_be_first'), style: tsBodySm()),
                    ]));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final isMe = user?.uid == data['userId'];
                      return _ListingCard(
                        key: ValueKey(docs[i].id),
                        docId: docs[i].id,
                        data: data,
                        isMe: isMe,
                        t: t,
                        onContact: () => _contactSeller(context, data, user, t, docId: docs[i].id),
                        onEdit: isMe ? () => _showAddListing(context, user!, t, existing: data, docId: docs[i].id) : null,
                        onDelete: isMe ? () => _db.collection('marketplace').doc(docs[i].id).delete() : null,
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

  void _contactSeller(BuildContext context, Map<String, dynamic> data, User? user, String Function(String) t, {String? docId}) {
    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true)));
      return;
    }
    final uid1 = user.uid;
    final uid2 = data['userId'] ?? '';
    if (uid1 == uid2) return;
    final sortedId = uid1.compareTo(uid2) < 0 ? uid1 + '_' + uid2 : uid2 + '_' + uid1;
    final fakeBusiness = Business(
      id: 'market_' + sortedId + (docId != null ? '_' + docId : '_item'),
      name: data['title'] ?? 'Item',
      category: 'Other',
      description: data['description'] ?? '',
      address: data['city'] ?? '',
      lat: 0, lng: 0,
      imageUrl: data['imageUrl'] ?? '',
      phone: '',
      rating: 0,
      isOpen: true,
      isPremium: false,
      openingHours: {},
      ownerId: data['userId'] ?? '',
      ownerEmail: '',
      ownerName: data['sellerName'] ?? '',
      country: '',
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => GuestChatScreen(business: fakeBusiness)));
  }

  void _showAddListing(BuildContext context, User user, String Function(String) t, {Map<String, dynamic>? existing, String? docId}) {
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    final priceCtrl = TextEditingController(text: existing?['price']?.toString() ?? '');
    final cityCtrl = TextEditingController(text: existing?['city'] ?? '');
    String selectedCategory = existing?['category'] ?? 'Other';
    File? selectedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          builder: (_, ctrl) => SingleChildScrollView(
            controller: ctrl,
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kOutlineVariant, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(existing != null ? t('marketplace_edit') : t('marketplace_add'), style: tsHeadlineSm(color: kSecondary)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: isUploading ? null : () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
                  if (picked != null) setModal(() => selectedImage = File(picked.path));
                },
                child: Container(
                  height: 150, width: double.infinity,
                  decoration: BoxDecoration(color: kSurfaceContainerHigh, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.3))),
                  child: selectedImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(selectedImage!, fit: BoxFit.cover))
                      : existing?['imageUrl'] != null && (existing!['imageUrl'] as String).isNotEmpty
                          ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(existing['imageUrl'], fit: BoxFit.cover))
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.add_photo_alternate_rounded, color: kSecondary, size: 36),
                              const SizedBox(height: 8),
                              Text(t('marketplace_add_photo'), style: tsBodySm(color: kSecondary)),
                            ]),
                ),
              ),
              const SizedBox(height: 16),
              Text(t('marketplace_title_field'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: titleCtrl, style: tsBodyLg(color: kOnSurface), decoration: InputDecoration(hintText: t('marketplace_title_hint'))),
              const SizedBox(height: 16),
              Text(t('marketplace_price'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, style: tsBodyLg(color: kOnSurface), decoration: const InputDecoration(hintText: '0', prefixText: 'NOK ')),
              const SizedBox(height: 16),
              Text(t('marketplace_city'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: cityCtrl, style: tsBodyLg(color: kOnSurface), decoration: const InputDecoration(hintText: 'Oslo, Kampala, Addis...', prefixIcon: Icon(Icons.location_on_rounded, color: kSecondary))),
              const SizedBox(height: 16),
              Text(t('marketplace_desc'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, maxLines: 3, style: tsBodyLg(color: kOnSurface), decoration: InputDecoration(hintText: t('marketplace_desc_hint'))),
              const SizedBox(height: 16),
              Text(t('event_category'), style: tsLabel()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _categories.where((c) => c['key'] != 'All').map((cat) {
                  final sel = selectedCategory == cat['key'];
                  return GestureDetector(
                    onTap: () => setModal(() => selectedCategory = cat['key']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: sel ? kSecondary : kSurfaceContainerHigh, borderRadius: BorderRadius.circular(100)),
                      child: Text('${cat['emoji']} ${t('market_${cat['key']!.toLowerCase()}')}', style: tsLabel(color: sel ? const Color(0xFF342800) : kOnSurfaceVariant)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUploading ? null : () async {
                    if (titleCtrl.text.isEmpty) return;
                    setModal(() => isUploading = true);
                    String imageUrl = existing?['imageUrl'] ?? '';
                    if (selectedImage != null) {
                      final ref = FirebaseStorage.instance.ref().child('marketplace/' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg');
                      await ref.putFile(selectedImage!);
                      imageUrl = await ref.getDownloadURL();
                    }
                    final listingData = {
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'price': int.tryParse(priceCtrl.text) ?? 0,
                      'category': selectedCategory,
                      'imageUrl': imageUrl,
                      'city': cityCtrl.text.trim(),
                      'sellerName': user.displayName ?? 'User',
                      'userId': user.uid,
                    };
                    if (docId != null) {
                      await _db.collection('marketplace').doc(docId).update(listingData);
                    } else {
                      await _db.collection('marketplace').add({...listingData, 'createdAt': FieldValue.serverTimestamp()});
                    }
                    setModal(() => isUploading = false);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kSecondary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: isUploading
                      ? const CircularProgressIndicator(color: Color(0xFF1A1200), strokeWidth: 2)
                      : Text(t('marketplace_publish'), style: tsTitleMd(color: const Color(0xFF1A1200))),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _citySearchCtrl.dispose();
    _nameSearchCtrl.dispose();
    super.dispose();
  }
}

class _ListingCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool isMe;
  final String Function(String) t;
  final VoidCallback onContact;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ListingCard({super.key, required this.docId, required this.data, required this.isMe, required this.t, required this.onContact, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] ?? '';
    final price = data['price'] ?? 0;
    return GestureDetector(
      onTap: onContact,
      child: Container(
        decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(14), border: Border.all(color: kSecondary.withOpacity(0.08))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 120, color: kSurfaceContainerHigh, child: const Icon(Icons.image_not_supported_rounded, color: kOnSurfaceVariant, size: 32)))
                : Container(height: 120, color: kSurfaceContainerHigh, child: const Icon(Icons.shopping_bag_rounded, color: kSecondary, size: 40)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data['title'] ?? '', style: tsTitleMd(), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                Expanded(child: Text('NOK $price', style: tsTitleMd(color: kSecondary))),
                if (isMe) ...[
                  if (onEdit != null)
                    GestureDetector(onTap: onEdit, child: const Icon(Icons.edit_rounded, color: kSecondary, size: 14)),
                  const SizedBox(width: 6),
                  if (onDelete != null)
                    GestureDetector(onTap: onDelete, child: const Icon(Icons.delete_outline_rounded, color: kRed, size: 14)),
                ],
              ]),
              if ((data['city'] ?? '').isNotEmpty)
                Row(children: [
                  const Icon(Icons.location_on_rounded, color: kSecondary, size: 10),
                  const SizedBox(width: 2),
                  Flexible(child: Text(data['city'], style: tsBodySm(color: kOnSurfaceVariant).copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              if ((data['sellerName'] ?? '').isNotEmpty)
                Text(data['sellerName'], style: tsBodySm(color: kOnSurfaceVariant).copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }
}

class MarketInboxScreen extends StatelessWidget {
  final String userId;
  const MarketInboxScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurfaceContainer,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Text('Marketplace Messages', style: tsTitleMd(color: kSecondary)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('chats').where('businessId', isGreaterThanOrEqualTo: 'market_').snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
          final docs = snap.data!.docs.where((d) {
            final bid = (d.data() as Map)['businessId'] ?? '';
            return bid.toString().contains(userId);
          }).toList();
          if (docs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('💬', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text('No messages yet', style: tsTitleLg()),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final lastMsg = data['lastMessage'] ?? '';
              final senderName = data['guestName'] ?? data['nickname'] ?? 'User';
              final businessName = data['businessName'] ?? 'Item';
              final businessId = data['businessId'] ?? '';
              return Dismissible(
                key: ValueKey(docs[i].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: kRed.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                ),
                onDismissed: (_) => db.collection('chats').doc(docs[i].id).delete(),
                child: GestureDetector(
                onTap: () {
                  final fakeBusiness = Business(
                    id: businessId, name: businessName, category: 'Other',
                    description: '', address: '', lat: 0, lng: 0,
                    imageUrl: '', phone: '', rating: 0, isOpen: true,
                    isPremium: false, openingHours: {}, ownerId: userId,
                    ownerEmail: '', ownerName: '', country: '',
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GuestChatScreen(business: fakeBusiness)));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.1))),
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: kPrimaryContainer, shape: BoxShape.circle), child: const Center(child: Text('🛒', style: TextStyle(fontSize: 20)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(businessName, style: tsTitleMd()),
                      Text('From: $senderName', style: tsBodySm(color: kSecondary)),
                      Text(lastMsg, style: tsBodySm(color: kOnSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 14),
                  ]),
                ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}



