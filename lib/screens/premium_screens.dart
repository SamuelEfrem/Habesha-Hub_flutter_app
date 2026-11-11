import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/business.dart';
import '../services/premium.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../utils/theme_notifier.dart';
import '../utils/translations.dart';
import 'business_detail_screen.dart';

String _date(DateTime d) => DateFormat('dd.MM.yyyy').format(d);

/// Small "⭐ Premium" pill (Myk style, works in light and dark).
class PremiumBadge extends StatelessWidget {
  final bool onPhoto;
  const PremiumBadge({super.key, this.onPhoto = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
            color: onPhoto ? Colors.black.withValues(alpha: 0.6) : kTintYellow,
            borderRadius: BorderRadius.circular(100)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.star_rounded, size: 13, color: onPhoto ? const Color(0xFFF0BE3C) : kInkYellow),
          const SizedBox(width: 3),
          Text(tr('Premium'), style: TextStyle(fontFamily: kFontBody, fontSize: 11.5, fontWeight: FontWeight.w700,
              color: onPhoto ? Colors.white : kInkYellow)),
        ]),
      );
}

/// Small "🌱 Small business" pill (small / new / home-based businesses).
class SmallBizBadge extends StatelessWidget {
  final bool onPhoto;
  const SmallBizBadge({super.key, this.onPhoto = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
            color: onPhoto ? Colors.black.withValues(alpha: 0.6) : kTintGreen,
            borderRadius: BorderRadius.circular(100)),
        child: Text('🌱 ${tr('Small business')}', style: TextStyle(fontFamily: kFontBody, fontSize: 11.5, fontWeight: FontWeight.w700,
            color: onPhoto ? Colors.white : kInkGreen)),
      );
}

// ═══════════════════════════════════════════════════════════
// FEATURED row on the home screen (only shown when there are premium businesses nearby)
// ═══════════════════════════════════════════════════════════
class FeaturedRow extends StatelessWidget {
  final List<Business> businesses;
  final double lat, lng;
  const FeaturedRow({super.key, required this.businesses, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    final list = premiumFirst(businesses.where((b) => b.premium).toList()).take(10).toList();
    // one premium business is already first in the list below, so the row only shows from 2
    if (list.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('⭐ ${tr('Featured')}', style: TextStyle(fontFamily: kFontHeadline, fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final b = list[i];
              final km = b.distanceTo(lat, lng);
              return Material(
                color: kCard,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => BusinessDetailScreen(business: b, userLat: lat, userLng: lng))),
                  child: SizedBox(width: 150, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(height: 88, width: 150, child: b.imageUrl.isNotEmpty
                        ? CachedNetworkImage(imageUrl: b.imageUrl, fit: BoxFit.cover, memCacheWidth: 450,
                            errorWidget: (_, __, ___) => Container(color: kTintYellow))
                        : Container(color: kTintYellow, alignment: Alignment.center,
                            child: Icon(Icons.storefront_rounded, color: kInkYellow))),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                      child: Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tsTitleMd(color: kText).copyWith(fontSize: 13.5)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
                      child: Text(km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km',
                          style: tsBodySm(color: kTextSub)),
                    ),
                  ])),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MY STATS — monthly numbers for the business owner
// ═══════════════════════════════════════════════════════════
const _statKeys = [
  ('views', Icons.visibility_outlined, 'Profile views'),
  ('calls', Icons.phone_outlined, 'Calls'),
  ('directions', Icons.directions_outlined, 'Directions'),
  ('website', Icons.language_rounded, 'Website'),
  ('chats', Icons.chat_bubble_outline_rounded, 'Messages'),
];

class MyStatsScreen extends StatelessWidget {
  final Business business;
  const MyStatsScreen({super.key, required this.business});

  String _monthName(String key) {
    final p = key.split('-');
    if (p.length != 2) return key;
    return DateFormat('MMMM yyyy').format(DateTime(int.tryParse(p[0]) ?? 2026, int.tryParse(p[1]) ?? 1));
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
          title: Text(tr('My stats'), style: tsTitleMd(color: kText).copyWith(fontSize: 18)),
        ),
        body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('businesses').doc(business.id).collection('stats').get(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
            }
            final months = {for (final d in snap.data?.docs ?? const []) d.id: d.data()};
            final now = statMonth();
            final cur = months[now] ?? const {};
            final older = months.keys.where((k) => k != now).toList()..sort((a, b) => b.compareTo(a));
            int n(Map m, String k) => (m[k] as num?)?.toInt() ?? 0;
            return ListView(padding: const EdgeInsets.all(20), children: [
              Text(business.name, style: tsHeadlineSm(color: kText)),
              const SizedBox(height: 2),
              Text('${tr('This month')} · ${_monthName(now)}', style: tsBodySm(color: kTextSub)),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.9,
                children: [
                  for (final s in _statKeys)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Row(children: [
                          Icon(s.$2, size: 16, color: kSecondary),
                          const SizedBox(width: 6),
                          Expanded(child: Text(tr(s.$3), maxLines: 1, overflow: TextOverflow.ellipsis, style: tsBodySm(color: kTextSub))),
                        ]),
                        const SizedBox(height: 4),
                        Text('${n(cur, s.$1)}', style: TextStyle(fontFamily: kFontHeadline, fontSize: 24, fontWeight: FontWeight.w800, color: kText)),
                      ]),
                    ),
                ],
              ),
              if (!business.premium) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kTintYellow, borderRadius: BorderRadius.circular(16)),
                  child: Text(tr('Premium businesses are shown first and on the home screen, so they get more visits.'),
                      style: tsBodySm(color: kInkYellow)),
                ),
              ],
              if (older.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(tr('Earlier months'), style: tsTitleMd(color: kText)),
                const SizedBox(height: 8),
                for (final k in older.take(12))
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Expanded(child: Text(_monthName(k), style: tsBodyLg(color: kText))),
                      Icon(Icons.visibility_outlined, size: 15, color: kTextSub),
                      const SizedBox(width: 4),
                      Text('${n(months[k]!, 'views')}', style: tsBodySm(color: kText)),
                      const SizedBox(width: 12),
                      Icon(Icons.touch_app_outlined, size: 15, color: kTextSub),
                      const SizedBox(width: 4),
                      Text('${n(months[k]!, 'calls') + n(months[k]!, 'directions') + n(months[k]!, 'website') + n(months[k]!, 'chats')}',
                          style: tsBodySm(color: kText)),
                    ]),
                  ),
              ],
              const SizedBox(height: 10),
              Text(tr('Counted from the start of this feature. Your own visits are not counted.'),
                  style: tsBodySm(color: kTextSub)),
            ]);
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ADMIN — make / extend / remove Premium
// ═══════════════════════════════════════════════════════════
Future<void> showPremiumDialog(BuildContext context, String docId, Business b) async {
  // extending starts from the current end date when it is still running
  final base = b.premium && b.premiumUntil != null ? b.premiumUntil! : DateTime.now();
  String choice = '1m';
  DateTime custom = base.add(const Duration(days: 30));
  bool trial = b.premiumTrial;
  DateTime endFor(String c) => switch (c) {
        '3d' => DateTime(base.year, base.month, base.day + 3, 23, 59),
        '1m' => DateTime(base.year, base.month + 1, base.day, 23, 59),
        '12m' => DateTime(base.year + 1, base.month, base.day, 23, 59),
        _ => DateTime(custom.year, custom.month, custom.day, 23, 59),
      };
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      Widget opt(String key, String label) => RadioListTile<String>(
            contentPadding: EdgeInsets.zero, dense: true, value: key, groupValue: choice,
            activeColor: kSecondary, onChanged: (v) => setS(() { choice = v!; if (choice == '3d') trial = true; }),
            title: Text(label, style: tsBodyLg(color: kText)),
          );
      return AlertDialog(
        backgroundColor: kCard,
        title: Text(b.premium ? tr('Extend Premium') : tr('Make Premium'), style: tsTitleLg(color: kText)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.name, style: tsBodySm(color: kTextSub)),
          const SizedBox(height: 8),
          opt('3d', '🎁 ${tr('3 days free trial')}'),
          opt('1m', tr('1 month')),
          opt('12m', tr('12 months')),
          opt('custom', '${tr('Custom end date')}: ${_date(custom)}'),
          if (choice == 'custom') Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: Icon(Icons.event_rounded, color: kSecondary),
              label: Text(tr('Choose date'), style: tsBodySm(color: kSecondary)),
              onPressed: () async {
                final d = await showDatePicker(context: ctx, initialDate: custom,
                    firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 3)));
                if (d != null) setS(() => custom = d);
              },
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero, activeThumbColor: kHabGreen,
            value: trial, onChanged: (v) => setS(() => trial = v),
            title: Text(tr('Free trial'), style: tsBodyLg(color: kText)),
          ),
          Text('${tr('Ends')}: ${_date(endFor(choice))}', style: tsTitleMd(color: kSecondary)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'), style: tsBodySm(color: kTextSub))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kSecondary, foregroundColor: kOnAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Save')),
          ),
        ],
      );
    }),
  );
  if (ok != true) return;
  await FirebaseFirestore.instance.collection('businesses').doc(docId).update({
    'isPremium': true,
    'premiumUntil': Timestamp.fromDate(endFor(choice)),
    'premiumTrial': trial,
    if (!b.premium) 'premiumSince': FieldValue.serverTimestamp(),
  });
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⭐ ${b.name}: ${tr('Premium until')} ${_date(endFor(choice))}'), backgroundColor: kGreen));
  }
}

Future<void> removePremium(BuildContext context, String docId, Business b) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kCard,
      title: Text(tr('Remove Premium'), style: tsTitleLg(color: kText)),
      content: Text(b.name, style: tsBodyLg(color: kText)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'), style: tsBodySm(color: kTextSub))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: kRed), onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Remove'))),
      ],
    ),
  );
  if (ok != true) return;
  await FirebaseFirestore.instance.collection('businesses').doc(docId).update({'isPremium': false, 'premiumTrial': false});
}

/// Admin tab: all premium businesses with end dates; ending within 7 days on top.
class PremiumAdminTab extends StatelessWidget {
  const PremiumAdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('businesses').where('isPremium', isEqualTo: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
        final all = [for (final d in snap.data!.docs) Business.fromFirestore(d.data(), d.id)];
        final now = DateTime.now(), soon = now.add(const Duration(days: 7));
        int byEnd(Business a, Business b) =>
            (a.premiumUntil ?? DateTime(3000)).compareTo(b.premiumUntil ?? DateTime(3000));
        final expired = all.where((b) => !b.premium).toList()..sort(byEnd);
        final ending = all.where((b) => b.premium && b.premiumUntil != null && b.premiumUntil!.isBefore(soon)).toList()..sort(byEnd);
        final active = all.where((b) => b.premium && !ending.contains(b)).toList()..sort(byEnd);
        if (all.isEmpty) {
          return Center(child: Text(tr('No premium businesses yet'), style: tsBodyLg(color: kTextSub)));
        }
        Widget head(String t, Color c) => Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
              child: Text(t, style: tsTitleMd(color: c)),
            );
        Widget row(Business b, Color edge) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: edge, width: 4))),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tsTitleMd(color: kText)),
                  Text([
                    b.premiumUntil == null ? tr('No end date') : '${tr('Ends')} ${_date(b.premiumUntil!)}',
                    if (b.premiumTrial) tr('Free trial'),
                    if (b.country.isNotEmpty) b.country,
                  ].join('  ·  '), style: tsBodySm(color: kTextSub)),
                ])),
                IconButton(tooltip: tr('Extend Premium'), icon: Icon(Icons.update_rounded, color: kSecondary),
                    onPressed: () => showPremiumDialog(context, b.id, b)),
                IconButton(tooltip: tr('Remove Premium'), icon: Icon(Icons.star_outline_rounded, color: kRed),
                    onPressed: () => removePremium(context, b.id, b)),
              ]),
            );
        return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 40), children: [
          if (ending.isNotEmpty) ...[head('⏰ ${tr('Ends within 7 days')} (${ending.length})', kRed), for (final b in ending) row(b, kRed)],
          if (active.isNotEmpty) ...[head('⭐ ${tr('Active')} (${active.length})', kSecondary), for (final b in active) row(b, kHabGreen)],
          if (expired.isNotEmpty) ...[head('${tr('Expired')} (${expired.length})', kTextSub), for (final b in expired) row(b, kTextSub)],
        ]);
      },
    );
  }
}
