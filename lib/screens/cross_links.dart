import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';
import 'home_shops_screen.dart';
import 'marketplace_screen.dart';
import 'services_catalog.dart';
import 'services_screen.dart';

// Services (people who do a job) and Market (things to buy) stay separate,
// but link to each other where they overlap, and the home search finds both.

/// A small card that sends the user to the other section
Widget crossLinkCard(BuildContext context, {required String emoji, required String text, required VoidCallback onTap}) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Material(
    color: kTintBlue,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: tsBodySm(color: kText).copyWith(fontWeight: FontWeight.w600))),
          Icon(Icons.arrow_forward_rounded, color: kInkBlue, size: 20),
        ]),
      ),
    ),
  ),
);

/// Opens a Services group in the user's saved country/city
Future<void> openServiceGroup(BuildContext context, String groupKey, {String sub = ''}) async {
  final g = serviceGroup(groupKey);
  if (g == null) return;
  final (country, city) = await ServiceLocation.load();
  if (!context.mounted) return;
  Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceGroupScreen(group: g, country: country, city: city, initialSub: sub)));
}

void openMarket(BuildContext context, {String tab = 'listings', String? category}) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => MarketplaceScreen(initialTab: tab, initialCategory: category)));

// ── Home search: services, market items and home shops that match ──

class _Cache {
  static DateTime? at;
  static List<QueryDocumentSnapshot<Map<String, dynamic>>> services = [], items = [], shops = [];
}

class CrossSearchResults extends StatefulWidget {
  final String query;
  const CrossSearchResults({super.key, required this.query});
  @override
  State<CrossSearchResults> createState() => _CrossSearchResultsState();
}

class _CrossSearchResultsState extends State<CrossSearchResults> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_Cache.at != null && DateTime.now().difference(_Cache.at!).inMinutes < 10) return;
    setState(() => _loading = true);
    try {
      final db = FirebaseFirestore.instance;
      final (country, _) = await ServiceLocation.load();   // services: the user's country only
      final r = await Future.wait([
        db.collection('anonymous_services').where('country', isEqualTo: country).where('available', isEqualTo: true).get(),
        db.collection('marketplace').orderBy('createdAt', descending: true).limit(300).get(),
        db.collection('homeShops').where('status', isEqualTo: 'approved').get(),
      ]);
      _Cache.services = r[0].docs;
      _Cache.items = r[1].docs.where((d) => d.data()['approved'] != false && '${d.data()['status'] ?? ''}' != 'done').toList();
      _Cache.shops = r[2].docs;
      _Cache.at = DateTime.now();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  static bool _has(Iterable<dynamic> fields, String q) => fields.map((e) => '${e ?? ''}').join(' ').toLowerCase().contains(q);

  @override
  Widget build(BuildContext context) {
    final q = widget.query.trim().toLowerCase();
    if (q.length < 2) return const SizedBox.shrink();
    if (_loading) return const SizedBox.shrink();
    final svc = _Cache.services.where((d) {
      final e = d.data();
      return _has([e['publicName'], e['description'], e['city'], tr(serviceSubLabel(e)), serviceSubLabel(e)], q);
    }).take(3).toList();
    final items = _Cache.items.where((d) {
      final e = d.data();
      return _has([e['title'], e['description'], e['city'], e['category']], q);
    }).take(3).toList();
    final shops = _Cache.shops.where((d) {
      final e = d.data();
      return _has([e['name'], e['description'], e['city'], ...(e['productNames'] as List? ?? [])], q);
    }).take(3).toList();
    if (svc.isEmpty && items.isEmpty && shops.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('Also on Habesha Hub'), style: tsTitleMd(color: kText)),
        const SizedBox(height: 8),
        for (final d in svc) _row(Icons.handshake_outlined, tr('Service'), serviceText(d.data(), 'publicName'),
            [serviceSubLabel(d.data()), '${d.data()['city'] ?? ''}'],
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceProviderScreen(docId: d.id, data: d.data())))),
        for (final d in items) _row(Icons.sell_outlined, tr('Market'), '${d.data()['title'] ?? ''}',
            [tr('${d.data()['category'] ?? ''}'), '${d.data()['city'] ?? ''}'], () => openMarketListing(context, d.id)),
        for (final d in shops) _row(Icons.storefront_outlined, tr('Home shops'), '${d.data()['name'] ?? ''}',
            ['${d.data()['city'] ?? ''}'],
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopProfileScreen(shopId: d.id)))),
      ]),
    );
  }

  Widget _row(IconData icon, String kind, String title, List<String> sub, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: kCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: kTintGreen, shape: BoxShape.circle),
                child: Icon(icon, color: kInkGreen, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: tsTitleMd(color: kText)),
              Text([kind, ...sub.where((s) => s.trim().isNotEmpty)].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: tsBodySm(color: kTextSub)),
            ])),
            Icon(Icons.chevron_right_rounded, color: kTextSub),
          ]),
        ),
      ),
    ),
  );
}
