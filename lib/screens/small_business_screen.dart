import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../utils/theme_notifier.dart';
import '../utils/translations.dart';
import '../widgets/business_card.dart';
import 'business_detail_screen.dart';
import 'home_shops_screen.dart';
import 'register_business_screen.dart';

// ═══════════════════════════════════════════════════════════
// SMALL & HOME BUSINESSES — gives small, new and home-based
// Habesha businesses their own place in the app.
//   businesses where smallBiz == true or worksFromHome == true
//   + the Home shops (homeShops, sellers from home)
// Home-based businesses only ever show an area, never the address.
// ═══════════════════════════════════════════════════════════

/// The two switches in the register / edit form (every category).
class SmallBizFields extends StatelessWidget {
  final bool small, fromHome, showFromHome;
  final ValueChanged<bool> onSmall, onFromHome;
  const SmallBizFields({super.key, required this.small, required this.fromHome, required this.showFromHome,
      required this.onSmall, required this.onFromHome});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: BoxDecoration(color: kTintGreen.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero, activeThumbColor: kHabGreen,
          value: small, onChanged: onSmall,
          title: Text('🌱 ${tr('Small or new business')}', style: tsBodyLg(color: kText)),
          subtitle: Text(tr('Shown in "Small & home businesses" so more people find you'), style: tsBodySm(color: kTextSub)),
        ),
        if (showFromHome) SwitchListTile(
          contentPadding: EdgeInsets.zero, activeThumbColor: kHabGreen,
          value: fromHome, onChanged: onFromHome,
          title: Text(tr('Works from home'), style: tsBodyLg(color: kText)),
          subtitle: Text(tr('Then only the area is shown, never your address'), style: tsBodySm(color: kTextSub)),
        ),
      ]),
    );
  }
}

/// Card on the home screen that opens the section.
class SmallBizHomeCard extends StatelessWidget {
  const SmallBizHomeCard({super.key});
  @override
  Widget build(BuildContext context) {
    // one slim line, so the home screen stays calm
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Material(
        color: kTintGreen,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmallBusinessScreen())),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(children: [
              const Text('🌱', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text(tr('Small & home businesses'), maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: tsTitleMd(color: kInkGreen))),
              Icon(Icons.chevron_right_rounded, color: kInkGreen, size: 22),
            ]),
          ),
        ),
      ),
    );
  }
}

class SmallBusinessScreen extends StatefulWidget {
  const SmallBusinessScreen({super.key});
  @override
  State<SmallBusinessScreen> createState() => _SmallBusinessScreenState();
}

class _SmallBusinessScreenState extends State<SmallBusinessScreen> {
  final _db = FirebaseFirestore.instance;
  String _tab = 'biz';
  double _lat = 59.9139, _lng = 10.7522;
  bool _hasPos = false;
  late Future<List<Business>> _load;

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  Future<List<Business>> _fetch() async {
    // the user's position only if location is already allowed (we don't ask here)
    try {
      final p = await Geolocator.checkPermission();
      if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null) { _lat = pos.latitude; _lng = pos.longitude; _hasPos = true; }
      }
    } catch (_) {}
    final col = _db.collection('businesses');
    final res = await Future.wait([
      col.where('smallBiz', isEqualTo: true).limit(300).get(),
      col.where('worksFromHome', isEqualTo: true).limit(300).get(),
    ]);
    final seen = <String>{};
    final list = <Business>[];
    for (final q in res) {
      for (final d in q.docs) {
        if (!seen.add(d.id)) continue;
        final b = Business.fromFirestore(d.data(), d.id);
        if (b.status == 'approved') list.add(b);
      }
    }
    // nearest first when we know where the user is, otherwise A–Z
    if (_hasPos) {
      list.sort((a, b) => a.distanceTo(_lat, _lng).compareTo(b.distanceTo(_lat, _lng)));
    } else {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  Widget _tabBtn(String key, String label) {
    final sel = _tab == key;
    return Expanded(child: Material(
      color: sel ? kSecondary : kCard,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => setState(() => _tab = key),
        child: SizedBox(height: 40, child: Center(child: Text(label,
            style: TextStyle(fontFamily: kFontBody, fontSize: 14, fontWeight: FontWeight.w700, color: sel ? kOnAccent : kText)))),
      ),
    ));
  }

  Widget _bizList() {
    return FutureBuilder<List<Business>>(
      future: _load,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
        }
        final list = snap.data ?? const <Business>[];
        return RefreshIndicator(
          color: kSecondary,
          onRefresh: () async { final f = _fetch(); setState(() => _load = f); await f; },
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 100), children: [
            Text(tr('Small, new and home-based Habesha businesses. Give them a try!'), style: tsBodySm(color: kTextSub)),
            const SizedBox(height: 12),
            if (snap.hasError || list.isEmpty) ...[
              const SizedBox(height: 30),
              const Center(child: Text('🌱', style: TextStyle(fontSize: 40))),
              const SizedBox(height: 8),
              Center(child: Text(tr('Nothing here yet'), style: tsTitleMd(color: kText))),
              const SizedBox(height: 4),
              Center(child: Text(tr('Be the first: register your small business'), textAlign: TextAlign.center, style: tsBodySm(color: kTextSub))),
            ],
            for (final b in list)
              BusinessCard(
                business: b,
                userLat: _lat,
                userLng: _lng,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BusinessDetailScreen(business: b, userLat: _lat, userLng: _lng))),
              ),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: kSecondary),
          title: Text('🌱 ${tr('Small & home businesses')}', style: tsTitleMd(color: kText).copyWith(fontSize: 18)),
        ),
        floatingActionButton: _tab == 'biz' ? FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterBusinessScreen())),
          backgroundColor: kSecondary,
          foregroundColor: kOnAccent,
          icon: const Icon(Icons.add_business_outlined),
          label: Text(tr('Register your business'), style: const TextStyle(fontWeight: FontWeight.w700)),
        ) : null,
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(children: [
              _tabBtn('biz', tr('Small businesses')),
              const SizedBox(width: 8),
              _tabBtn('shops', tr('Home shops')),
            ]),
          ),
          Expanded(child: _tab == 'biz' ? _bizList() : const HomeShopsScreen(embedded: true)),
        ]),
      ),
    );
  }
}
