import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../utils/translations.dart';
import 'services_screen.dart';
import 'payment.dart';

// ═══════════════════════════════════════════════════════════
// PROVIDER EXTRAS
//   • reviews (stars + comment after a completed booking)
//   • share link  (https://habesha-hub.no/p/cameraman-1)
//   • favorite services
//   • admin statistics
// ═══════════════════════════════════════════════════════════

/// Public, stable key for a provider — built from the public name only
/// (never from the document ID, which contains the real name).
String providerSlug(Map<String, dynamic> data) {
  final s = serviceStr(data['publicName']).toLowerCase()
      .replaceAll('æ', 'ae').replaceAll('ø', 'o').replaceAll('å', 'a')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return s.isEmpty ? 'provider' : s;
}

// ───────────────────────────────────────────────────────────
// SHARE
// ───────────────────────────────────────────────────────────
void shareProvider(Map<String, dynamic> data) {
  final name = serviceText(data, 'publicName');
  final url = 'https://habesha-hub.no/p/${providerSlug(data)}';
  Share.share('$name — Habesha Hub\n${tr('See photos, videos and book here')}:\n$url');
}

// ───────────────────────────────────────────────────────────
// FAVORITES (stored on the phone)
// ───────────────────────────────────────────────────────────
class FavoriteServices {
  static const _key = 'fav_services';
  static final ValueNotifier<Set<String>> slugs = ValueNotifier<Set<String>>({});
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      slugs.value = (p.getStringList(_key) ?? []).toSet();
    } catch (_) {}
  }

  static Future<void> toggle(String slug) async {
    final next = Set<String>.from(slugs.value);
    next.contains(slug) ? next.remove(slug) : next.add(slug);
    slugs.value = next;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_key, next.toList());
    } catch (_) {}
  }
}

class FavoriteServiceButton extends StatefulWidget {
  final Map<String, dynamic> data;
  final Color color;
  const FavoriteServiceButton({super.key, required this.data, this.color = kSecondary});
  @override
  State<FavoriteServiceButton> createState() => _FavoriteServiceButtonState();
}

class _FavoriteServiceButtonState extends State<FavoriteServiceButton> {
  @override
  void initState() {
    super.initState();
    FavoriteServices.load();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Set<String>>(
    valueListenable: FavoriteServices.slugs,
    builder: (_, favs, __) {
      final slug = providerSlug(widget.data);
      final on = favs.contains(slug);
      return IconButton(
        tooltip: tr('My favorites'),
        icon: Icon(on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: on ? kRed : widget.color),
        onPressed: () {
          FavoriteServices.toggle(slug);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(on ? tr('Removed from favorites') : tr('Saved to favorites')),
            duration: const Duration(seconds: 1)));
        },
      );
    },
  );
}

class FavoriteServicesScreen extends StatelessWidget {
  const FavoriteServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    FavoriteServices.load();
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Text(tr('Favorite services'), style: tsTitleMd(color: kSecondary)),
      ),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: FavoriteServices.slugs,
        builder: (_, favs, __) => StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('anonymous_services')
              .where('available', isEqualTo: true).snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
            }
            final docs = snap.data!.docs.where((d) =>
                favs.contains(providerSlug(d.data() as Map<String, dynamic>))).toList();
            if (docs.isEmpty) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.favorite_border_rounded, color: kTextSub, size: 56),
                  const SizedBox(height: 12),
                  Text(tr('No favorite services yet'), style: tsTitleLg(), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(tr('Tap the heart on a provider to save it here.'),
                      style: tsBodySm(), textAlign: TextAlign.center),
                ]),
              ));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final imgs = serviceImages(d);
                return GestureDetector(
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(
                    builder: (_) => ServiceProviderScreen(docId: docs[i].id, data: d))),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                        child: SizedBox(width: 90, height: 90, child: imgs.isEmpty
                          ? Container(color: kCardHigh, child: Icon(Icons.image_rounded, color: kTextSub))
                          : Image.network(imgs.first, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: kCardHigh))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(serviceText(d, 'publicName'), style: tsTitleMd()),
                        const SizedBox(height: 2),
                        Text('${serviceStr(d['city'])}', style: tsBodySm(color: kTextSub)),
                        RatingLine(data: d),
                      ])),
                      FavoriteServiceButton(data: d),
                    ]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// REVIEWS
// Firestore: anonymous_services/{providerId}/reviews/{bookingId}
// Average is calculated by the Cloud Function `updateProviderRating`.
// ───────────────────────────────────────────────────────────
Widget stars(double value, {double size = 16}) => Row(
  mainAxisSize: MainAxisSize.min,
  children: List.generate(5, (i) {
    final full = value >= i + 1;
    final half = !full && value > i + 0.25;
    return Icon(full ? Icons.star_rounded : half ? Icons.star_half_rounded : Icons.star_outline_rounded,
        color: kSecondary, size: size);
  }),
);

class RatingLine extends StatelessWidget {
  final Map<String, dynamic> data;
  const RatingLine({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final count = (data['ratingCount'] is num) ? (data['ratingCount'] as num).toInt() : 0;
    if (count == 0) return const SizedBox.shrink();
    final avg = (data['ratingAvg'] is num) ? (data['ratingAvg'] as num).toDouble() : 0.0;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        stars(avg, size: 14),
        const SizedBox(width: 6),
        Text('${avg.toStringAsFixed(1)} ($count)', style: tsBodySm(color: kTextSub)),
      ]),
    );
  }
}

/// Reviews shown on the provider profile
class ProviderReviews extends StatelessWidget {
  final String providerId;
  final Map<String, dynamic> data;
  const ProviderReviews({super.key, required this.providerId, required this.data});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('anonymous_services')
          .doc(providerId).collection('reviews').limit(50).snapshots(),
      builder: (_, snap) {
        final docs = (snap.data?.docs ?? []).toList()
          ..sort((a, b) {
            final ta = (a.data() as Map)['createdAt'];
            final tb = (b.data() as Map)['createdAt'];
            if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
            return 0;
          });
        double avg = 0;
        if (docs.isNotEmpty) {
          avg = docs.map((d) => ((d.data() as Map)['rating'] as num?)?.toDouble() ?? 0)
              .reduce((a, b) => a + b) / docs.length;
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(tr('Reviews'), style: tsLabel()),
            const SizedBox(width: 10),
            if (docs.isNotEmpty) ...[
              stars(avg),
              const SizedBox(width: 6),
              Text('${avg.toStringAsFixed(1)} (${docs.length})', style: tsBodySm(color: kTextSub)),
            ],
          ]),
          const SizedBox(height: 8),
          if (docs.isEmpty)
            Text(tr('No reviews yet. Customers can review after their booking is completed.'),
                style: tsBodySm(color: kTextSub))
          else
            ...docs.take(10).map((doc) {
              final r = doc.data() as Map<String, dynamic>;
              final rating = (r['rating'] as num?)?.toDouble() ?? 0;
              final name = serviceStr(r['nickname']).isEmpty ? tr('Customer') : serviceStr(r['nickname']);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(name, style: tsTitleMd())),
                    stars(rating, size: 14),
                  ]),
                  if (serviceStr(r['comment']).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(serviceStr(r['comment']), style: tsBodySm()),
                  ],
                ]),
              );
            }),
        ]);
      },
    );
  }
}

/// "Rate this service" card shown on the receipt after the booking is completed / paid
class WriteReviewCard extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> booking;
  const WriteReviewCard({super.key, required this.bookingId, required this.booking});
  @override
  State<WriteReviewCard> createState() => _WriteReviewCardState();
}

class _WriteReviewCardState extends State<WriteReviewCard> {
  int _rating = 0;
  final _ctrl = TextEditingController();
  bool _saving = false;

  String get _providerId => serviceStr(widget.booking['serviceId']);

  DocumentReference get _ref => FirebaseFirestore.instance
      .collection('anonymous_services').doc(_providerId)
      .collection('reviews').doc(widget.bookingId);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _rating == 0) return;
    setState(() => _saving = true);
    try {
      await _ref.set({
        'userId':    user.uid,
        'nickname':  (user.displayName ?? '').split(' ').first,
        'rating':    _rating,
        'comment':   _ctrl.text.trim(),
        'lang':      languageNotifier.language,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('Error')}: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_providerId.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: _ref.snapshots(),
      builder: (_, snap) {
        final existing = snap.data?.data() as Map<String, dynamic>?;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kSecondary.withOpacity(0.3))),
          child: existing != null
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('Thank you for your review!'), style: tsTitleMd(color: kSecondary)),
                const SizedBox(height: 6),
                stars(((existing['rating'] as num?) ?? 0).toDouble()),
                if (serviceStr(existing['comment']).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(serviceStr(existing['comment']), style: tsBodySm()),
                ],
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('How was the service?'), style: tsTitleMd(color: kSecondary)),
                const SizedBox(height: 8),
                Row(children: List.generate(5, (i) => IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: kSecondary, size: 32),
                ))),
                const SizedBox(height: 8),
                TextField(
                  controller: _ctrl,
                  maxLines: 3,
                  maxLength: 500,
                  style: tsBodyLg(color: kText),
                  decoration: InputDecoration(hintText: tr('Write a short review (optional)')),
                ),
                const SizedBox(height: 8),
                goldButton(tr('Send review'), (_rating == 0 || _saving) ? null : _save,
                    loading: _saving, icon: Icons.send_rounded),
              ]),
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────────
// ADMIN STATISTICS
// ───────────────────────────────────────────────────────────
class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      backgroundColor: kCard,
      iconTheme: const IconThemeData(color: kSecondary),
      title: Text('Statistics', style: tsTitleMd(color: kSecondary)),
    ),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('service_bookings').snapshots(),
      builder: (_, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}', style: tsBodySm(color: kRed)));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
        final all = snap.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();

        final byStatus = <String, int>{};
        final revenue = <String, Map<String, double>>{};   // month → currency → sum
        final perService = <String, int>{};
        final payFrom = <String, int>{};
        final now = DateTime.now();
        int last30 = 0, paidCount = 0;

        for (final b in all) {
          final st = serviceStr(b['status']).isEmpty ? 'created' : serviceStr(b['status']);
          byStatus[st] = (byStatus[st] ?? 0) + 1;
          final name = serviceStr(b['serviceName']);
          if (name.isNotEmpty) perService[name] = (perService[name] ?? 0) + 1;
          final pc = serviceStr(b['payCountry']);
          if (pc.isNotEmpty) payFrom[pc] = (payFrom[pc] ?? 0) + 1;
          final created = b['createdAt'] is Timestamp ? (b['createdAt'] as Timestamp).toDate() : null;
          if (created != null && now.difference(created).inDays <= 30) last30++;
          if (b['paid'] == true) {
            paidCount++;
            final when = b['paidAt'] is Timestamp ? (b['paidAt'] as Timestamp).toDate() : (created ?? now);
            final month = '${when.year}-${when.month.toString().padLeft(2, '0')}';
            final cur = serviceStr(b['currency']).isEmpty ? '?' : serviceStr(b['currency']);
            final amount = double.tryParse(serviceStr(b['amount']).replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
            revenue.putIfAbsent(month, () => {});
            revenue[month]![cur] = (revenue[month]![cur] ?? 0) + amount;
          }
        }
        final months = revenue.keys.toList()..sort((a, b) => b.compareTo(a));
        final top = perService.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final countries = payFrom.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        Widget tile(String label, String value, Color c) => Expanded(child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: tsHeadlineSm(color: c)),
            const SizedBox(height: 2),
            Text(label, style: tsBodySm(color: kTextSub)),
          ]),
        ));
        Widget section(String title, List<Widget> rows) => Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: tsTitleMd(color: kSecondary)),
            const SizedBox(height: 8),
            if (rows.isEmpty) Text('—', style: tsBodySm(color: kTextSub)) else ...rows,
          ]),
        );
        Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(k, style: tsBodySm(color: kText))),
            Text(v, style: tsTitleMd()),
          ]),
        );

        return ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            tile('Bookings total', '${all.length}', kSecondary),
            const SizedBox(width: 10),
            tile('Last 30 days', '$last30', kGreen),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            tile('Waiting', '${byStatus['created'] ?? 0}', kTextSub),
            const SizedBox(width: 10),
            tile('Paid', '$paidCount', kGreen),
            const SizedBox(width: 10),
            tile('Cancelled', '${byStatus['cancelled'] ?? 0}', kRed),
          ]),
          section('Income per month (paid)', months.map((m) =>
            row(m, revenue[m]!.entries.map((e) => '${e.value.toStringAsFixed(0)} ${e.key}').join('  ·  '))).toList()),
          section('Most booked services', top.take(10).map((e) => row(e.key, '${e.value}')).toList()),
          section('Customers pay from', countries.map((e) =>
            row('${payCountry(e.key).flag}  ${payCountry(e.key).name}', '${e.value}')).toList()),
          section('Status', byStatus.entries.map((e) => row(e.key, '${e.value}')).toList()),
        ]);
      },
    ),
  );
}
