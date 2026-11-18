import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';

// ═══════════════════════════════════════════════════════════
// HABESHA HUB SHOP — our own products (e.g. dropshipping via Shopify).
// Shown as a row at the top of Market > Listings. Only the admin adds them.
// The "Buy" button opens the product in the web shop: payment happens there,
// never in the app.
//
// Firestore  shop_products/{id}: { title, description, price, delivery,
//            imageUrl, buyUrl (https), active (bool), order (number), createdAt }
// ═══════════════════════════════════════════════════════════

final _col = FirebaseFirestore.instance.collection('shop_products');

bool get _admin {
  final u = FirebaseAuth.instance.currentUser;
  return u != null && (u.uid == 'W3z67R3wiXUVvcPFDS0oxgfaDlj1' || u.email == 'samuelefriem@gmail.com');
}

String _l(String en, String ti, String am) {
  final l = languageNotifier.language;
  return l == 'Tigrinya' ? ti : l == 'Amharic' ? am : en;
}

String _s(dynamic v) => (v ?? '').toString();

/// The row in Market. Hidden for users until there is at least one active product.
class ShopProductsRow extends StatelessWidget {
  const ShopProductsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _col.snapshots(),
      builder: (_, snap) {
        final admin = _admin;
        final docs = (snap.data?.docs ?? []).where((d) => admin || d.data()['active'] != false).toList()
          ..sort((a, b) => ((a.data()['order'] ?? 999) as num).compareTo((b.data()['order'] ?? 999) as num));
        if (docs.isEmpty && !admin) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text('Habesha Hub Shop', style: tsTitleMd(color: kText).copyWith(fontSize: 16)),
                const SizedBox(width: 6),
                Icon(Icons.verified_rounded, color: kSecondary, size: 18),
                const Spacer(),
                if (admin) TextButton.icon(
                  onPressed: () => openShopProductForm(context),
                  icon: Icon(Icons.add_rounded, color: kSecondary, size: 18),
                  label: Text(_l('Add', 'ወስኽ', 'ጨምር'), style: tsTitleMd(color: kSecondary)),
                ),
              ]),
            ),
            if (docs.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(_l('Only you see this. Examples below show how it will look; add your first product.',
                    'ንስኻ ጥራይ ኢኻ ትርእዮ። ኣብነታት ከመይ ከም ዝመስል የርእዩ፡ ቀዳማይ ፍርያትካ ወስኽ።',
                    'እርስዎ ብቻ ያዩታል። ምሳሌዎቹ እንዴት እንደሚታይ ያሳያሉ፣ የመጀመሪያ ምርትዎን ይጨምሩ።'),
                    style: tsBodySm(color: kTextSub)),
              ),
              // admin preview while empty: not saved, nobody else sees it
              SizedBox(
                height: 228,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  children: [
                    for (final (emoji, title, price) in const [
                      ('☕', 'Jebena coffee set', '449 kr'),
                      ('💍', 'Wedding hair jewellery', '199 kr'),
                      ('🧵', 'Netela tilet ribbon, 5 m', '149 kr'),
                    ]) Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(width: 150, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 150, height: 150, alignment: Alignment.center,
                          decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(16)),
                          child: Stack(children: [
                            Center(child: Text(emoji, style: const TextStyle(fontSize: 54))),
                            Positioned(left: 6, top: 6, child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(100)),
                              child: Text('Shop ✓', style: TextStyle(color: kOnAccent, fontSize: 10, fontWeight: FontWeight.w800)),
                            )),
                            Positioned(right: 6, top: 6, child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(100)),
                              child: Text(_l('Example', 'ኣብነት', 'ምሳሌ'), style: const TextStyle(color: Colors.white, fontSize: 10)),
                            )),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        Text(price, style: tsTitleMd(color: kText).copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tsBodySm(color: kText).copyWith(fontSize: 13)),
                        Text('🚚 7–15 days', style: tsBodySm(color: kTextSub).copyWith(fontSize: 11.5)),
                      ])),
                    ),
                  ],
                ),
              ),
            ]
            else
              SizedBox(
                height: 228,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _ShopCard(id: docs[i].id, d: docs[i].data()),
                ),
              ),
          ]),
        );
      },
    );
  }
}

class _ShopCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> d;
  const _ShopCard({required this.id, required this.d});

  @override
  Widget build(BuildContext context) {
    final off = d['active'] == false;
    return GestureDetector(
      onTap: () => _showProduct(context, id, d),
      child: Opacity(
        opacity: off ? 0.45 : 1,
        child: SizedBox(width: 150, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(width: 150, height: 150, child: Stack(fit: StackFit.expand, children: [
              _s(d['imageUrl']).isEmpty
                  ? Container(color: kCardHigh, child: Icon(Icons.image_rounded, color: kTextSub))
                  : CachedNetworkImage(imageUrl: _s(d['imageUrl']), fit: BoxFit.cover, memCacheWidth: 400,
                      errorWidget: (_, __, ___) => Container(color: kCardHigh)),
              Positioned(left: 6, top: 6, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(100)),
                child: Text('Shop ✓', style: TextStyle(color: kOnAccent, fontSize: 10, fontWeight: FontWeight.w800)),
              )),
              if (off) Positioned(right: 6, top: 6, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(100)),
                child: Text(_l('Hidden', 'ሕቡእ', 'የተደበቀ'), style: const TextStyle(color: Colors.white, fontSize: 10)),
              )),
            ])),
          ),
          const SizedBox(height: 8),
          if (_s(d['price']).isNotEmpty)
            Text(_s(d['price']), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: tsTitleMd(color: kText).copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
          Text(_s(d['title']), maxLines: 1, overflow: TextOverflow.ellipsis, style: tsBodySm(color: kText).copyWith(fontSize: 13)),
          if (_s(d['delivery']).isNotEmpty)
            Text('🚚 ${_s(d['delivery'])}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: tsBodySm(color: kTextSub).copyWith(fontSize: 11.5)),
        ])),
      ),
    );
  }
}

/// Product sheet: photo, price, delivery, description and "Buy in the shop"
void _showProduct(BuildContext context, String id, Map<String, dynamic> d) {
  final url = _s(d['buyUrl']);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false, initialChildSize: 0.8,
      builder: (_, ctrl) => ListView(controller: ctrl, padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(ctx).bottom + 20), children: [
        if (_s(d['imageUrl']).isNotEmpty)
          ClipRRect(borderRadius: BorderRadius.circular(18),
              child: AspectRatio(aspectRatio: 1, child: CachedNetworkImage(imageUrl: _s(d['imageUrl']), fit: BoxFit.cover))),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Text(_s(d['title']), style: tsHeadlineSm(color: kText))),
          Icon(Icons.verified_rounded, color: kSecondary, size: 20),
        ]),
        if (_s(d['price']).isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(_s(d['price']), style: tsHeadlineSm(color: kSecondary)),
        ],
        if (_s(d['delivery']).isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('🚚 ${_l('Delivery', 'ምብጻሕ', 'ማድረሻ')}: ${_s(d['delivery'])}', style: tsBodySm(color: kTextSub)),
        ],
        if (_s(d['description']).isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(_s(d['description']), style: tsBodyLg(color: kText)),
        ],
        const SizedBox(height: 18),
        if (url.startsWith('https://'))
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            icon: Icon(Icons.shopping_bag_rounded, color: kOnAccent),
            label: Text(_l('Buy in the Habesha Hub Shop', 'ኣብ Habesha Hub Shop ግዛእ', 'በHabesha Hub Shop ይግዙ'), style: tsTitleMd(color: kOnAccent)),
            style: ElevatedButton.styleFrom(backgroundColor: kSecondary, padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
        const SizedBox(height: 8),
        Text(_l('You pay safely in our web shop. Sold and sent by Habesha Hub.',
                'ኣብ ናይ መርበብ ድኳንና ብውሑስ ትኸፍል። ብHabesha Hub ይሽየጥን ይስደድን።',
                'በድረ-ገጽ ሱቃችን በደህና ይከፍላሉ። በHabesha Hub የሚሸጥና የሚላክ።'),
            textAlign: TextAlign.center, style: tsBodySm(color: kTextSub)),
        if (_admin) ...[
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(ctx); openShopProductForm(context, id: id, d: d); },
              icon: Icon(Icons.edit_rounded, color: kSecondary, size: 18),
              label: Text(_l('Edit', 'ኣርም', 'አርትዕ'), style: tsTitleMd(color: kSecondary)),
            )),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(context: ctx, builder: (c) => AlertDialog(
                  backgroundColor: kCardHigh,
                  title: Text(_l('Delete this product?', 'እዚ ፍርያት ይደምሰስ?', 'ይህ ምርት ይሰረዝ?'), style: tsTitleMd(color: kText)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_l('Cancel', 'ሰርዝ', 'ይቅር'))),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: Text(_l('Delete', 'ደምስስ', 'ሰርዝ'), style: TextStyle(color: kRed))),
                  ],
                ));
                if (ok == true) { await _col.doc(id).delete(); if (ctx.mounted) Navigator.pop(ctx); }
              },
              icon: Icon(Icons.delete_outline_rounded, color: kRed, size: 18),
              label: Text(_l('Delete', 'ደምስስ', 'ሰርዝ'), style: tsTitleMd(color: kRed)),
            )),
          ]),
        ],
      ]),
    ),
  );
}

/// Admin form: photo, name, price, delivery time, description, shop link, shown / hidden
void openShopProductForm(BuildContext context, {String? id, Map<String, dynamic>? d}) {
  final title = TextEditingController(text: _s(d?['title']));
  final price = TextEditingController(text: _s(d?['price']));
  final delivery = TextEditingController(text: _s(d?['delivery']).isEmpty ? '7–15 days' : _s(d?['delivery']));
  final desc = TextEditingController(text: _s(d?['description']));
  final link = TextEditingController(text: _s(d?['buyUrl']));
  final order = TextEditingController(text: d?['order'] == null ? '' : '${d!['order']}');
  String imageUrl = _s(d?['imageUrl']);
  File? photo;
  bool active = d?['active'] != false, saving = false;
  String error = '';

  Widget field(TextEditingController c, String label, {int lines = 1, TextInputType? type}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(controller: c, maxLines: lines, keyboardType: type, style: tsBodyLg(color: kText),
            decoration: InputDecoration(labelText: label, filled: true, fillColor: kCardHigh,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
      );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kCard,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(builder: (ctx, set) => Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.paddingOf(ctx).bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(id == null ? _l('New shop product', 'ሓድሽ ፍርያት ድኳን', 'አዲስ የሱቅ ምርት') : _l('Edit shop product', 'ፍርያት ድኳን ኣርም', 'የሱቅ ምርት አርትዕ'),
            style: tsHeadlineSm(color: kSecondary)),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () async {
            final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1400, imageQuality: 82);
            if (x != null) set(() => photo = File(x.path));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 120, height: 120, color: kCardHigh,
              child: photo != null ? Image.file(photo!, fit: BoxFit.cover)
                  : imageUrl.isNotEmpty ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                  : Icon(Icons.add_photo_alternate_rounded, color: kSecondary, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 14),
        field(title, _l('Name', 'ስም', 'ስም')),
        field(price, _l('Price with currency (e.g. 449 kr)', 'ዋጋ ምስ ባጤራ (ንኣብነት 449 kr)', 'ዋጋ ከምንዛሬ ጋር (ለምሳሌ 449 kr)')),
        field(delivery, _l('Delivery time', 'ግዜ ምብጻሕ', 'የማድረሻ ጊዜ')),
        field(desc, _l('Description', 'መግለጺ', 'መግለጫ'), lines: 3),
        field(link, _l('Link to the product in the web shop (https://…)', 'መላግቦ ናብቲ ፍርያት ኣብ ድኳን መርበብ (https://…)', 'በድረ-ገጽ ሱቅ ያለው ምርት አገናኝ (https://…)'), type: TextInputType.url),
        field(order, _l('Order in the row (1 = first, optional)', 'ተርታ (1 = ቀዳማይ፡ ኣማራጺ)', 'ቅደም ተከተል (1 = መጀመሪያ፣ አማራጭ)'), type: TextInputType.number),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: active, activeColor: kSecondary,
          title: Text(_l('Shown in the app', 'ኣብ ኣፕ ይርአ', 'በመተግበሪያው ይታያል'), style: tsBodyLg(color: kText)),
          onChanged: (v) => set(() => active = v),
        ),
        if (error.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(error, style: tsBodySm(color: kRed))),
        primaryButton(saving ? '' : _l('Save', 'ዕቀብ', 'አስቀምጥ'), saving ? null : () async {
          final url = link.text.trim();
          if (title.text.trim().isEmpty || (photo == null && imageUrl.isEmpty)) {
            set(() => error = _l('Please add a photo and a name.', 'በጃኻ ስእልን ስምን ወስኽ።', 'እባክዎ ፎቶና ስም ይጨምሩ።'));
            return;
          }
          if (url.isNotEmpty && !url.startsWith('https://')) {
            set(() => error = _l('The link must start with https://', 'መላግቦ ብ https:// ክጅምር ኣለዎ', 'አገናኙ በ https:// መጀመር አለበት'));
            return;
          }
          set(() { saving = true; error = ''; });
          try {
            if (photo != null) {
              final ref = FirebaseStorage.instance.ref('shop/${DateTime.now().millisecondsSinceEpoch}.jpg');
              await ref.putFile(photo!, SettableMetadata(contentType: 'image/jpeg'));
              imageUrl = await ref.getDownloadURL();
            }
            final data = {
              'title': title.text.trim(), 'price': price.text.trim(), 'delivery': delivery.text.trim(),
              'description': desc.text.trim(), 'buyUrl': url, 'imageUrl': imageUrl, 'active': active,
              'order': int.tryParse(order.text.trim()) ?? 999, 'updatedAt': FieldValue.serverTimestamp(),
            };
            if (id == null) {
              await _col.add({...data, 'createdAt': FieldValue.serverTimestamp()});
            } else {
              await _col.doc(id).update(data);
            }
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (_) {
            set(() { saving = false; error = _l('Could not save. Check your internet and try again.', 'ክዕቀብ ኣይከኣለን። ኢንተርነትካ ርአ።', 'ማስቀመጥ አልተቻለም። ኢንተርኔትዎን ያረጋግጡ።'); });
          }
        }),
      ])),
    )),
  );
}
