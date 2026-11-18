import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
//
// Shopify (automatic): app_config/shop { url: "https://your-shop.myshopify.com",
//            currency: "kr", delivery: "7–15 days" }. Every Shopify shop has a public
//            product list (<url>/products.json), so no key is needed: the products
//            published in Shopify show up here by themselves, "Buy" opens them there.
// ═══════════════════════════════════════════════════════════

final _col = FirebaseFirestore.instance.collection('shop_products');
final _cfg = FirebaseFirestore.instance.collection('app_config').doc('shop');

// products from Shopify, kept for 10 minutes
List<Map<String, dynamic>> _shopifyCache = [];
String _shopifyCacheUrl = '';
DateTime _shopifyCacheAt = DateTime(2000);

String _cleanUrl(String u) {
  var x = u.trim();
  if (x.isEmpty) return '';
  if (!x.startsWith('http')) x = 'https://$x';
  return x.replaceFirst('http://', 'https://').replaceAll(RegExp(r'/+$'), '');
}

String _money(String price, String currency) {
  final p = price.replaceFirst(RegExp(r'\.00$'), '');
  final cur = currency.trim().isEmpty ? 'kr' : currency.trim();
  return (cur == 'kr' || cur == 'NOK' || cur == 'SEK' || cur == 'DKK') ? '$p ${cur == 'NOK' ? 'kr' : cur}' : '$cur $p';
}

/// One Shopify product → the map the cards use. Products tagged "uganda-delivery"
/// (any "<country>-delivery" tag, a local partner) are delivered in that country only.
Map<String, dynamic> _fromShopify(Map<String, dynamic> m, String url, String currency, String delivery) {
  final imgs = (m['images'] as List?) ?? [];
  final vars = (m['variants'] as List?) ?? [];
  final tags = ((m['tags'] is List) ? (m['tags'] as List).map((e) => '$e') : _s(m['tags']).split(','))
      .map((e) => e.trim().toLowerCase()).toList();
  // "<country>-delivery" (e.g. uganda-delivery, ethiopia-delivery): a local partner delivers in that country only
  final local = tags.firstWhere((t) => t.endsWith('-delivery') && t.length > 9, orElse: () => '');
  final country = local.isEmpty ? '' : local.substring(0, local.length - 9).split('-')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  return {
    'title': _s(m['title']),
    'description': _s(m['body_html']).replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&').replaceAll(RegExp(r'\s+'), ' ').trim(),
    'imageUrl': imgs.isEmpty ? '' : _s((imgs.first as Map)['src']),
    'price': vars.isEmpty ? '' : _money(_s((vars.first as Map)['price']), currency),
    'delivery': country.isEmpty ? delivery
        : _l('Delivered in $country (1–3 days)', 'ኣብ $country ይበጽሕ (1–3 መዓልቲ)', 'በ$country ይደርሳል (1–3 ቀን)'),
    'type': _s(m['product_type']).trim(),
    'buyUrl': '$url/products/${_s(m['handle'])}',
    'fromShopify': true,
  };
}

/// First products from the Shopify shop, for the row (empty when there is no shop yet or it fails)
Future<List<Map<String, dynamic>>> fetchShopify(String rawUrl, String currency, String delivery, {bool fresh = false}) async {
  final url = _cleanUrl(rawUrl);
  if (url.isEmpty) return [];
  if (!fresh && url == _shopifyCacheUrl && DateTime.now().difference(_shopifyCacheAt).inMinutes < 10) return _shopifyCache;
  try {
    final r = await http.get(Uri.parse('$url/products.json?limit=30')).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) return [];
    final list = (jsonDecode(r.body)['products'] as List?) ?? [];
    final out = [for (final m in list) _fromShopify(m as Map<String, dynamic>, url, currency, delivery)];
    _shopifyCache = out; _shopifyCacheUrl = url; _shopifyCacheAt = DateTime.now();
    return out;
  } catch (_) {
    return [];
  }
}

/// All products, page by page (250 each); [onPage] gets the list so far
Future<void> fetchShopifyAll(String rawUrl, String currency, String delivery, void Function(List<Map<String, dynamic>>) onPage) async {
  final url = _cleanUrl(rawUrl);
  if (url.isEmpty) return;
  final all = <Map<String, dynamic>>[];
  for (var page = 1; page <= 40; page++) {
    try {
      final r = await http.get(Uri.parse('$url/products.json?limit=250&page=$page')).timeout(const Duration(seconds: 25));
      if (r.statusCode != 200) break;
      final list = (jsonDecode(r.body)['products'] as List?) ?? [];
      all.addAll([for (final m in list) _fromShopify(m as Map<String, dynamic>, url, currency, delivery)]);
      onPage(List.of(all));
      if (list.length < 250) break;
    } catch (_) {
      break;
    }
  }
}

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
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _cfg.snapshots(),
      builder: (_, cfgSnap) {
        final cfg = cfgSnap.data?.data() ?? const <String, dynamic>{};
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchShopify(_s(cfg['url']), _s(cfg['currency']), _s(cfg['delivery']).isEmpty ? '7–15 days' : _s(cfg['delivery'])),
          builder: (_, shopify) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _col.snapshots(),
      builder: (_, snap) {
        final admin = _admin;
        final docs = (snap.data?.docs ?? []).where((d) => admin || d.data()['active'] != false).toList()
          ..sort((a, b) => ((a.data()['order'] ?? 999) as num).compareTo((b.data()['order'] ?? 999) as num));
        final items = <(String, Map<String, dynamic>)>[
          for (final d in docs) (d.id, d.data()),
          for (final p in shopify.data ?? const <Map<String, dynamic>>[]) ('', p),
        ];
        if (items.isEmpty && !admin) return const SizedBox.shrink();
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
                if ((shopify.data ?? const []).isNotEmpty) TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopAllScreen(cfg: cfg))),
                  child: Text(_l('See all', 'ኩሉ ርአ', 'ሁሉንም ይዩ'), style: tsTitleMd(color: kSecondary)),
                ),
                if (admin) IconButton(
                  tooltip: 'Shopify',
                  onPressed: () => _shopifySettings(context, cfg),
                  icon: Icon(Icons.link_rounded, color: _s(cfg['url']).isEmpty ? kTextSub : kSecondary),
                ),
                if (admin) TextButton.icon(
                  onPressed: () => openShopProductForm(context),
                  icon: Icon(Icons.add_rounded, color: kSecondary, size: 18),
                  label: Text(_l('Add', 'ወስኽ', 'ጨምር'), style: tsTitleMd(color: kSecondary)),
                ),
              ]),
            ),
            if (items.isEmpty) ...[
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
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _ShopCard(id: items[i].$1, d: items[i].$2),
                ),
              ),
          ]),
        );
      },
          ),
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
        if (_admin && d['fromShopify'] == true) ...[
          const SizedBox(height: 14),
          Text(_l('From Shopify: change it in Shopify, the app updates by itself.',
                  'ካብ Shopify፦ ኣብ Shopify ቀይሮ፡ ኣፕ ባዕሉ ይሕደስ።', 'ከShopify፦ በShopify ይቀይሩት፣ መተግበሪያው ራሱ ይታደሳል።'),
              textAlign: TextAlign.center, style: tsBodySm(color: kTextSub)),
        ],
        if (_admin && d['fromShopify'] != true) ...[
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


/// Admin: connect the Shopify shop (address, currency, delivery text) and test it
void _shopifySettings(BuildContext context, Map<String, dynamic> cfg) {
  final url = TextEditingController(text: _s(cfg['url']));
  final cur = TextEditingController(text: _s(cfg['currency']).isEmpty ? 'kr' : _s(cfg['currency']));
  final del = TextEditingController(text: _s(cfg['delivery']).isEmpty ? '7–15 days' : _s(cfg['delivery']));
  String msg = '';
  bool busy = false;
  showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
    backgroundColor: kCardHigh,
    title: Text(_l('Connect Shopify', 'Shopify ኣራኽብ', 'Shopifyን ያገናኙ'), style: tsHeadlineSm(color: kText)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_l('Paste the address of your shop. Products you publish in Shopify then show up here by themselves.',
              'ኣድራሻ ድኳንካ ለጥፍ። ኣብ Shopify እተውጽኦም ፍርያት ባዕሎም ኣብዚ ይርኣዩ።',
              'የሱቅዎን አድራሻ ይለጥፉ። በShopify የሚያወጧቸው ምርቶች ራሳቸው እዚህ ይታያሉ።'),
          style: tsBodySm(color: kTextSub)),
      const SizedBox(height: 12),
      TextField(controller: url, keyboardType: TextInputType.url, style: tsBodyLg(color: kText),
          decoration: const InputDecoration(labelText: 'https://your-shop.myshopify.com')),
      TextField(controller: cur, style: tsBodyLg(color: kText),
          decoration: InputDecoration(labelText: _l('Currency (kr, USD, EUR…)', 'ባጤራ', 'ምንዛሬ'))),
      TextField(controller: del, style: tsBodyLg(color: kText),
          decoration: InputDecoration(labelText: _l('Delivery time', 'ግዜ ምብጻሕ', 'የማድረሻ ጊዜ'))),
      if (msg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(msg, style: tsBodySm(color: kText))),
    ])),
    actions: [
      TextButton(
        onPressed: busy ? null : () async {
          set(() { busy = true; msg = ''; });
          final found = await fetchShopify(url.text, cur.text, del.text, fresh: true);
          set(() { busy = false; msg = found.isEmpty
              ? _l('No products found. Check the address, and that products are published in Shopify.',
                   'ፍርያት ኣይተረኽበን። ኣድራሻ ርአ።', 'ምርት አልተገኘም። አድራሻውን ያረጋግጡ።')
              : '✓ ${found.length} ${_l('products found', 'ፍርያት ተረኺቦም', 'ምርቶች ተገኝተዋል')}'; });
        },
        child: Text(_l('Test', 'ፈትን', 'ሞክር')),
      ),
      TextButton(
        onPressed: () async {
          await _cfg.set({'url': _cleanUrl(url.text), 'currency': cur.text.trim(), 'delivery': del.text.trim(),
              'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
          _shopifyCacheUrl = '';
          if (ctx.mounted) Navigator.pop(ctx);
        },
        child: Text(_l('Save', 'ዕቀብ', 'አስቀምጥ'), style: TextStyle(color: kSecondary, fontWeight: FontWeight.w800)),
      ),
    ],
  )));
}


/// All shop products: search, categories (product type) and a two-column grid
class ShopAllScreen extends StatefulWidget {
  final Map<String, dynamic> cfg;
  const ShopAllScreen({super.key, required this.cfg});
  @override
  State<ShopAllScreen> createState() => _ShopAllScreenState();
}

class _ShopAllScreenState extends State<ShopAllScreen> {
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;
  String _q = '', _type = '';

  @override
  void initState() {
    super.initState();
    final c = widget.cfg;
    fetchShopifyAll(_s(c['url']), _s(c['currency']), _s(c['delivery']).isEmpty ? '7–15 days' : _s(c['delivery']),
        (list) { if (mounted) setState(() => _all = list); }).whenComplete(() { if (mounted) setState(() => _loading = false); });
  }

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final p in _all) {
      final t = _s(p['type']);
      if (t.isNotEmpty) counts[t] = (counts[t] ?? 0) + 1;
    }
    final types = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final q = _q.toLowerCase();
    final list = _all.where((p) => (_type.isEmpty || p['type'] == _type)
        && (q.isEmpty || _s(p['title']).toLowerCase().contains(q) || _s(p['type']).toLowerCase().contains(q))).toList();
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        iconTheme: IconThemeData(color: kSecondary),
        title: Row(children: [
          Text('Habesha Hub Shop', style: tsTitleMd(color: kText).copyWith(fontSize: 17)),
          const SizedBox(width: 6),
          Icon(Icons.verified_rounded, color: kSecondary, size: 18),
        ]),
      ),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            height: 46,
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(100)),
            child: TextField(
              style: tsBodyLg(color: kText),
              onChanged: (v) => setState(() => _q = v.trim()),
              decoration: InputDecoration(
                hintText: _l('Search the shop…', 'ኣብ ድኳን ድለ…', 'በሱቁ ይፈልጉ…'),
                filled: false, border: InputBorder.none,
                prefixIcon: Icon(Icons.search_rounded, color: kSecondary, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        )),
        if (types.length > 1) SliverToBoxAdapter(child: SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            children: [
              for (final t in ['', ...types]) Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: _type == t ? kSecondary : kCard,
                  borderRadius: BorderRadius.circular(100),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () => setState(() => _type = t),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                      child: Text(t.isEmpty ? '${_l('All', 'ኩሉ', 'ሁሉም')}  ${_all.length}' : '$t  ${counts[t]}',
                          style: tsLabel(color: _type == t ? kOnAccent : kText).copyWith(fontSize: 12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )),
        if (_all.isEmpty && _loading)
          SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5)))
        else if (list.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: Center(
              child: Text(_l('Nothing found', 'ዋላ ሓንቲ ኣይተረኽበን', 'ምንም አልተገኘም'), style: tsTitleMd(color: kTextSub))))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 18, childAspectRatio: 0.66),
              delegate: SliverChildBuilderDelegate((_, i) {
                final d = list[i];
                return GestureDetector(
                  onTap: () => _showProduct(context, '', d),
                  behavior: HitTestBehavior.opaque,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity, color: Colors.white,
                        child: _s(d['imageUrl']).isEmpty
                            ? Icon(Icons.image_rounded, color: kTextSub)
                            : CachedNetworkImage(imageUrl: _s(d['imageUrl']), fit: BoxFit.contain, memCacheWidth: 400,
                                errorWidget: (_, __, ___) => Container(color: kCardHigh)),
                      ),
                    )),
                    const SizedBox(height: 8),
                    if (_s(d['price']).isNotEmpty)
                      Text(_s(d['price']), maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: tsTitleMd(color: kText).copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(_s(d['title']), maxLines: 1, overflow: TextOverflow.ellipsis, style: tsBodySm(color: kText).copyWith(fontSize: 13)),
                    Text('🚚 ${_s(d['delivery'])}', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: tsBodySm(color: kTextSub).copyWith(fontSize: 11.5)),
                  ]),
                );
              }, childCount: list.length),
            ),
          ),
        if (_loading && _all.isNotEmpty) SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5)),
        )),
      ]),
    );
  }
}
