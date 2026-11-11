import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/share_helper.dart';
import '../utils/translations.dart';
import 'auth_screen.dart';
import 'member_screens.dart';
import 'services_screen.dart';
import 'notices_screen.dart';

// Events: concerts, DJs, church and community events.
// The app never sells tickets: "Buy ticket" opens the organizer's own https page.
// Verified organizers publish at once, everyone else waits for the admin.

final _db = FirebaseFirestore.instance;
final _events = _db.collection('events');
const _adminUid = 'W3z67R3wiXUVvcPFDS0oxgfaDlj1';

const kEventCategories = [
  ('concert', 'Concert', Icons.mic_external_on_outlined),
  ('dj', 'DJ / party', Icons.nightlife_outlined),
  ('church', 'Church', Icons.church_outlined),
  ('community', 'Community', Icons.groups_outlined),
  ('other', 'Other', Icons.event_outlined),
];

String _s(dynamic v) => v == null ? '' : v.toString();
DateTime? _date(dynamic v) => v is Timestamp ? v.toDate() : null;
bool _isAdmin() {
  final u = FirebaseAuth.instance.currentUser;
  return u != null && (u.uid == _adminUid || u.email == 'samuelefriem@gmail.com');
}

const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String eventDay(DateTime d) => '${tr(_days[d.weekday - 1])} ${d.day}. ${tr(_months[d.month - 1])}';
String eventTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String _catLabel(String k) => tr(kEventCategories.firstWhere((c) => c.$1 == k, orElse: () => kEventCategories.last).$2);

/// Friday 00:00 to Monday 00:00 of this weekend (or the coming one, Monday to Thursday)
(DateTime, DateTime) weekendRange([DateTime? now]) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final fri = today.add(Duration(days: n.weekday >= 5 ? -(n.weekday - 5) : 5 - n.weekday));
  return (fri, fri.add(const Duration(days: 3)));
}

bool isHttpsLink(String s) {
  final u = Uri.tryParse(s.trim());
  return u != null && u.scheme == 'https' && u.host.contains('.');
}

/// Approved events that have not ended (they disappear by themselves the day after)
Query<Map<String, dynamic>> upcomingEvents() => _events
    .where('status', isEqualTo: 'approved')
    .where('startAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 6))))
    .orderBy('startAt')
    .limit(120);

Future<bool> _loggedIn(BuildContext context) async {
  var u = FirebaseAuth.instance.currentUser;
  if (u == null || u.isAnonymous) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true)));
    u = FirebaseAuth.instance.currentUser;
  }
  return u != null && !u.isAnonymous;
}

Future<void> openEventForm(BuildContext context, {String? docId, Map<String, dynamic>? existing}) async {
  if (!await ensureMember(context) || !context.mounted) return;
  Navigator.push(context, MaterialPageRoute(builder: (_) => EventFormScreen(docId: docId, existing: existing)));
}

// ── Home: one line about this weekend, only when there is something ──
class WeekendEventsCard extends StatelessWidget {
  const WeekendEventsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: upcomingEvents().snapshots(),
      builder: (_, snap) {
        final (from, to) = weekendRange();
        final docs = (snap.data?.docs ?? []).where((d) {
          final t = _date(d.data()['startAt']);
          return t != null && !t.isBefore(from) && t.isBefore(to);
        }).toList();
        if (docs.isEmpty) return const SizedBox.shrink();
        final e = docs.first.data(), t = _date(e['startAt'])!;
        final who = _s(e['artistName']).isNotEmpty ? _s(e['artistName']) : _s(e['title']);
        // a small pill: one short line, centred
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Center(child: Material(
            color: kTintGreen,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen())),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🎵', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Flexible(child: Text(
                    '${tr('This weekend')}: $who · ${tr(_days[t.weekday - 1])}${docs.length > 1 ? '  +${docs.length - 1}' : ''}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: kFontBody, fontSize: 12, fontWeight: FontWeight.w700, color: kInkGreen))),
                  Icon(Icons.chevron_right_rounded, color: kInkGreen, size: 16),
                ]),
              ),
            ),
          )),
        );
      },
    );
  }
}

// ── List ──
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _city = '', _cat = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        title: Text(tr('Events'), style: tsTitleMd(color: kText).copyWith(fontSize: 18)),
        actions: [
          IconButton(
            tooltip: tr('Become an organizer'),
            icon: Icon(Icons.verified_outlined, color: kText),
            onPressed: () async {
              if (await _loggedIn(context) && context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizerApplyScreen()));
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kHabGreen,
        foregroundColor: Colors.white,
        onPressed: () => openEventForm(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(tr('Add event')),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: upcomingEvents().snapshots(),
        builder: (_, snap) {
          if (snap.hasError) return Center(child: Text(tr('Could not load events'), style: tsBodySm(color: kTextSub)));
          if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kHabGreen, strokeWidth: 2));
          final all = snap.data!.docs;
          final cities = {for (final d in all) _s(d.data()['city'])}..removeWhere((c) => c.isEmpty);
          final docs = all.where((d) {
            final e = d.data();
            return (_city.isEmpty || _s(e['city']) == _city) && (_cat.isEmpty || _s(e['category']) == _cat);
          }).toList();
          final (from, to) = weekendRange();
          bool weekend(QueryDocumentSnapshot<Map<String, dynamic>> d) {
            final t = _date(d.data()['startAt']);
            return t != null && !t.isBefore(from) && t.isBefore(to);
          }
          final wk = docs.where(weekend).toList(), later = docs.where((d) => !weekend(d)).toList();
          return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 96), children: [
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                _chip(tr('All'), _cat.isEmpty, () => setState(() => _cat = '')),
                for (final c in kEventCategories) _chip(tr(c.$2), _cat == c.$1, () => setState(() => _cat = _cat == c.$1 ? '' : c.$1), icon: c.$3),
              ]),
            ),
            if (cities.length > 1) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  _chip(tr('All cities'), _city.isEmpty, () => setState(() => _city = ''), icon: Icons.location_on_outlined),
                  for (final c in (cities.toList()..sort())) _chip(c, _city == c, () => setState(() => _city = _city == c ? '' : c)),
                ]),
              ),
            ],
            if (docs.isEmpty) Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(children: [
                Icon(Icons.event_outlined, color: kTextSub, size: 48),
                const SizedBox(height: 12),
                Text(tr('No events yet. Add the first one!'), textAlign: TextAlign.center, style: tsTitleMd(color: kTextSub)),
              ]),
            ),
            if (wk.isNotEmpty) ...[_section(tr('This weekend')), for (final d in wk) EventCard(doc: d)],
            if (later.isNotEmpty) ...[_section(tr('Upcoming')), for (final d in later) EventCard(doc: d)],
          ]);
        },
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 18, 0, 8),
    child: Text(t, style: tsHeadlineSm(color: kText)),
  );

  Widget _chip(String label, bool on, VoidCallback tap, {IconData? icon}) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      avatar: icon == null ? null : Icon(icon, size: 16, color: on ? Colors.white : kText),
      label: Text(label),
      selected: on,
      onSelected: (_) => tap(),
      selectedColor: kHabGreen,
      labelStyle: TextStyle(color: on ? Colors.white : kText, fontWeight: FontWeight.w600),
      showCheckmark: false,
    ),
  );
}

class EventCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const EventCard({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final e = doc.data(), t = _date(e['startAt']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(docId: doc.id))),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 88, height: 112, child: _flyer(_s(e['flyerUrl']))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_s(e['title']), maxLines: 2, overflow: TextOverflow.ellipsis, style: tsTitleMd(color: kText)),
                if (_s(e['artistName']).isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(_s(e['artistName']), maxLines: 1, overflow: TextOverflow.ellipsis, style: tsBodySm(color: kInkGreen).copyWith(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
                if (t != null) _line(Icons.schedule_rounded, '${eventDay(t)} · ${eventTime(t)}'),
                _line(Icons.location_on_outlined, [_s(e['venue']), _s(e['city'])].where((x) => x.isNotEmpty).join(' · ')),
                if (_s(e['discountCode']).isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: kTintRed, borderRadius: BorderRadius.circular(100)),
                    child: Text('🏷 ${_s(e['discountText']).isNotEmpty ? _s(e['discountText']) : tr('Discount')}',
                        style: tsBodySm(color: kInkRed).copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ])),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _line(IconData i, String t) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(children: [
      Icon(i, size: 15, color: kTextSub),
      const SizedBox(width: 5),
      Expanded(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: tsBodySm(color: kTextSub))),
    ]),
  );
}

Widget _flyer(String url, {BoxFit fit = BoxFit.cover}) => url.isEmpty
    ? Container(color: kTintGreen, child: Icon(Icons.music_note_rounded, color: kInkGreen, size: 36))
    : CachedNetworkImage(imageUrl: url, fit: fit,
        placeholder: (_, __) => Container(color: kCard),
        errorWidget: (_, __, ___) => Container(color: kTintGreen, child: Icon(Icons.music_note_rounded, color: kInkGreen)));

// ── Detail ──
class EventDetailScreen extends StatelessWidget {
  final String docId;
  const EventDetailScreen({super.key, required this.docId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _events.doc(docId).snapshots(),
      builder: (_, snap) {
        final e = snap.data?.data();
        if (e == null) {
          return Scaffold(backgroundColor: kBg, appBar: AppBar(backgroundColor: kBg),
              body: Center(child: snap.connectionState == ConnectionState.waiting
                  ? CircularProgressIndicator(color: kHabGreen, strokeWidth: 2)
                  : Text(tr('This event is no longer available'), style: tsBodySm(color: kTextSub))));
        }
        final t = _date(e['startAt']), exp = _date(e['discountExpiresAt']);
        final me = FirebaseAuth.instance.currentUser?.uid;
        final owner = me != null && me == _s(e['organizerId']);
        final ticket = _s(e['ticketUrl']);
        final codeValid = _s(e['discountCode']).isNotEmpty && (exp == null || exp.isAfter(DateTime.now()));
        final place = [_s(e['venue']), _s(e['area']), _s(e['city'])].where((x) => x.isNotEmpty).join(', ');
        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            backgroundColor: kBg,
            title: Text(tr('Event'), style: tsTitleMd(color: kText)),
            actions: [
              IconButton(tooltip: tr('Share'), icon: Icon(Icons.share_outlined, color: kText), onPressed: () => shareText(
                  '🎵 ${_s(e['title'])}${_s(e['artistName']).isNotEmpty ? ' · ${_s(e['artistName'])}' : ''}\n'
                  '${t != null ? '${eventDay(t)} ${eventTime(t)}\n' : ''}$place\n'
                  '${ticket.isNotEmpty ? '$ticket\n' : ''}\nHabesha Hub: https://habesha-hub.no/download.html')),
            ],
          ),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 110), children: [
            GestureDetector(
              onTap: _s(e['flyerUrl']).isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => _FlyerZoom(url: _s(e['flyerUrl'])))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ConstrainedBox(constraints: const BoxConstraints(maxHeight: 420),
                    child: SizedBox(width: double.infinity, child: _flyer(_s(e['flyerUrl']), fit: BoxFit.contain))),
              ),
            ),
            const SizedBox(height: 14),
            if (_s(e['status']) != 'approved') _statusBanner(_s(e['status'])),
            Text(_s(e['title']), style: tsHeadlineMd(color: kText)),
            if (e['organizerVerified'] == true) Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                Icon(Icons.verified_rounded, color: kHabGreen, size: 18),
                const SizedBox(width: 4),
                Text(tr('Verified organizer'), style: tsBodySm(color: kInkGreen).copyWith(fontWeight: FontWeight.w700)),
              ]),
            ),
            if (_s(e['artistName']).isNotEmpty) ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: kTintGreen, child: Icon(Icons.mic_rounded, color: kInkGreen)),
              title: Text(_s(e['artistName']), style: tsTitleMd(color: kText)),
              subtitle: _s(e['artistId']).isEmpty ? null : Text(tr('See artist profile'), style: tsBodySm(color: kInkGreen)),
              trailing: _s(e['artistId']).isEmpty ? null : Icon(Icons.chevron_right_rounded, color: kTextSub),
              onTap: _s(e['artistId']).isEmpty ? null : () async {
                final d = await _db.collection('anonymous_services').doc(_s(e['artistId'])).get();
                if (d.exists && context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceProviderScreen(docId: d.id, data: d.data()!)));
                }
              },
            ),
            const SizedBox(height: 6),
            if (t != null) _info(Icons.schedule_rounded, '${eventDay(t)} · ${eventTime(t)}'),
            if (place.isNotEmpty) _info(Icons.location_on_outlined, place),
            _info(kEventCategories.firstWhere((c) => c.$1 == _s(e['category']), orElse: () => kEventCategories.last).$3, _catLabel(_s(e['category']))),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (place.isNotEmpty) OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(place)}'), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.map_outlined, size: 18), label: Text(tr('Map'))),
              _InterestedButton(eventId: docId, count: (e['interestedCount'] as num?)?.toInt() ?? 0),
            ]),
            if (codeValid) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kTintRed, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${tr('Discount code')}: ${_s(e['discountCode'])}${_s(e['discountText']).isNotEmpty ? ' · ${_s(e['discountText'])}' : ''}',
                        style: tsTitleMd(color: kInkRed)),
                    if (exp != null) Text('${tr('Valid until')} ${eventDay(exp)}', style: tsBodySm(color: kInkRed)),
                  ])),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _s(e['discountCode'])));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Copied'))));
                    },
                    icon: Icon(Icons.copy_rounded, color: kInkRed, size: 18),
                    label: Text(tr('Copy'), style: TextStyle(color: kInkRed, fontWeight: FontWeight.w700))),
                ]),
              ),
            ],
            if (_s(e['description']).isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(tr('About'), style: tsLabel()),
              const SizedBox(height: 6),
              Text(_s(e['description']), style: tsBodyLg(color: kText)),
            ],
            const SizedBox(height: 18),
            if (owner || _isAdmin()) Wrap(spacing: 8, runSpacing: 8, children: [
              if (owner && _s(e['status']) != 'removed') OutlinedButton.icon(
                onPressed: () => openEventForm(context, docId: docId, existing: e),
                icon: const Icon(Icons.edit_outlined, size: 18), label: Text(tr('Edit'))),
              if (_isAdmin() && _s(e['status']) != 'approved') FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kHabGreen),
                onPressed: () => _events.doc(docId).update({'status': 'approved'}),
                child: Text(tr('Approve'))),
              if (_isAdmin() && _s(e['status']) != 'removed') OutlinedButton(
                onPressed: () => _events.doc(docId).update({'status': 'removed'}),
                child: Text(tr('Remove'), style: TextStyle(color: kRed))),
              if (owner) OutlinedButton(
                onPressed: () async {
                  if (await _confirm(context, tr('Delete this event?'))) {
                    await _events.doc(docId).delete();
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: Text(tr('Delete'), style: TextStyle(color: kRed))),
            ]),
            TextButton.icon(
              onPressed: () => _report(context, docId, _s(e['title'])),
              icon: Icon(Icons.flag_outlined, color: kTextSub, size: 18),
              label: Text(tr('Report event'), style: tsBodySm(color: kTextSub))),
          ]),
          bottomNavigationBar: ticket.isEmpty ? null : SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(height: 52, child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white),
              onPressed: () => launchUrl(Uri.parse(ticket), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.confirmation_number_outlined),
              label: Text(tr('Buy ticket'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)))),
          )),
        );
      },
    );
  }

  Widget _statusBanner(String st) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: st == 'removed' ? kTintRed : kTintYellow, borderRadius: BorderRadius.circular(12)),
    child: Text(st == 'removed' ? tr('This event was removed by Habesha Hub') : tr('Waiting for approval'),
        style: tsBodySm(color: st == 'removed' ? kInkRed : kInkYellow).copyWith(fontWeight: FontWeight.w700)),
  );

  Widget _info(IconData i, String t) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(i, size: 18, color: kTextSub),
      const SizedBox(width: 8),
      Expanded(child: Text(t, style: tsBodyLg(color: kText))),
    ]),
  );
}

Future<bool> _confirm(BuildContext context, String q) async => await showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    backgroundColor: kCard,
    content: Text(q, style: tsBodyLg(color: kText)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Yes'), style: TextStyle(color: kRed))),
    ],
  ),
) == true;

Future<void> _report(BuildContext context, String id, String title) async {
  final note = TextEditingController();
  final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
    backgroundColor: kCard,
    title: Text(tr('Report event'), style: tsTitleMd(color: kText)),
    content: TextField(controller: note, maxLines: 3, maxLength: 500,
        decoration: InputDecoration(hintText: tr('What is wrong with this event?'))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Send'))),
    ],
  ));
  if (ok != true) return;
  final u = FirebaseAuth.instance.currentUser;
  await _db.collection('reports').add({
    'businessId': id, 'businessName': title, 'reason': 'event', 'note': note.text.trim(),
    'userId': u == null || u.isAnonymous ? null : u.uid, 'status': 'open', 'kind': 'event',
    'createdAt': FieldValue.serverTimestamp(),
  }).catchError((_) => _db.collection('reports').doc());
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Thank you, we will look at it'))));
}

class _FlyerZoom extends StatelessWidget {
  final String url;
  const _FlyerZoom({required this.url});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
    body: InteractiveViewer(maxScale: 5, child: Center(child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain))),
  );
}

// "Interested": one per person; the count is kept by a Cloud Function, the reminder comes on the day
class _InterestedButton extends StatelessWidget {
  final String eventId;
  final int count;
  const _InterestedButton({required this.eventId, required this.count});

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    final ref = u == null || u.isAnonymous ? null : _events.doc(eventId).collection('interested').doc(u.uid);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref?.snapshots(),
      builder: (_, snap) {
        final on = snap.data?.exists == true;
        return FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: on ? kHabGreen : kTintGreen, foregroundColor: on ? Colors.white : kInkGreen),
          onPressed: () async {
            if (ref == null) {
              if (!await _loggedIn(context)) return;
              final u2 = FirebaseAuth.instance.currentUser!;
              await _events.doc(eventId).collection('interested').doc(u2.uid).set({'at': FieldValue.serverTimestamp()});
              return;
            }
            on ? await ref.delete() : await ref.set({'at': FieldValue.serverTimestamp()});
            if (!on && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('We will remind you on the day'))));
            }
          },
          icon: Icon(on ? Icons.star_rounded : Icons.star_border_rounded, size: 18),
          label: Text('${tr('Interested')} · $count'),
        );
      },
    );
  }
}

// ── Create / edit ──
class EventFormScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existing;
  const EventFormScreen({super.key, this.docId, this.existing});
  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _title = TextEditingController(), _artist = TextEditingController(), _venue = TextEditingController(),
      _city = TextEditingController(), _area = TextEditingController(), _desc = TextEditingController(),
      _ticket = TextEditingController(), _code = TextEditingController(), _codeText = TextEditingController();
  String _cat = 'concert', _artistId = '', _flyerUrl = '', _error = '';
  DateTime? _day, _codeExp;
  TimeOfDay? _time;
  File? _flyerFile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = _s(e['title']); _artist.text = _s(e['artistName']); _venue.text = _s(e['venue']);
      _city.text = _s(e['city']); _area.text = _s(e['area']); _desc.text = _s(e['description']);
      _ticket.text = _s(e['ticketUrl']); _code.text = _s(e['discountCode']); _codeText.text = _s(e['discountText']);
      _cat = _s(e['category']).isEmpty ? 'concert' : _s(e['category']); _artistId = _s(e['artistId']); _flyerUrl = _s(e['flyerUrl']);
      final t = _date(e['startAt']);
      if (t != null) { _day = DateTime(t.year, t.month, t.day); _time = TimeOfDay(hour: t.hour, minute: t.minute); }
      _codeExp = _date(e['discountExpiresAt']);
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _artist, _venue, _city, _area, _desc, _ticket, _code, _codeText]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    final ticket = _ticket.text.trim();
    String miss = '';
    if (_title.text.trim().isEmpty || _venue.text.trim().isEmpty || _city.text.trim().isEmpty) miss = tr('Please write the title, venue and city');
    else if (_day == null || _time == null) miss = tr('Please choose the date and start time');
    else if (_flyerFile == null && _flyerUrl.isEmpty) miss = tr('Please add the flyer');
    else if (ticket.isNotEmpty && !isHttpsLink(ticket)) miss = tr('The ticket link must start with https://');
    if (miss.isNotEmpty) { setState(() => _error = miss); return; }
    final u = FirebaseAuth.instance.currentUser!;
    setState(() { _saving = true; _error = ''; });
    try {
      var flyer = _flyerUrl;
      if (_flyerFile != null) {
        final ref = FirebaseStorage.instance.ref('events/${u.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(_flyerFile!, SettableMetadata(contentType: 'image/jpeg'));
        flyer = await ref.getDownloadURL();
      }
      final admin = _isAdmin();
      final verified = admin || (await _db.collection('users').doc(u.uid).get()).data()?['verifiedOrganizer'] == true;
      final start = DateTime(_day!.year, _day!.month, _day!.day, _time!.hour, _time!.minute);
      final data = <String, dynamic>{
        'title': _title.text.trim(), 'artistName': _artist.text.trim(), 'artistId': _artistId, 'category': _cat,
        'startAt': Timestamp.fromDate(start), 'venue': _venue.text.trim(), 'city': _city.text.trim(), 'area': _area.text.trim(),
        'description': _desc.text.trim(), 'flyerUrl': flyer, 'ticketUrl': ticket,
        'discountCode': _code.text.trim(), 'discountText': _codeText.text.trim(),
        'discountExpiresAt': _codeExp == null ? null : Timestamp.fromDate(DateTime(_codeExp!.year, _codeExp!.month, _codeExp!.day, 23, 59)),
        'organizerVerified': verified, 'status': verified ? 'approved' : 'pending', 'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.docId == null) {
        await _events.add({...data, 'organizerId': u.uid, 'interestedCount': 0, 'createdAt': FieldValue.serverTimestamp()});
      } else {
        await _events.doc(widget.docId).update({...data, if (!admin) 'organizerId': u.uid});
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(verified
          ? tr('The event is published')
          : tr('Thank you! Habesha Hub checks the event and publishes it soon'))));
      Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = tr('Could not save. Check your internet and try again.'); });
    }
  }

  Widget _field(TextEditingController c, String label, {int lines = 1, TextInputType? type, String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(controller: c, maxLines: lines, keyboardType: type, style: tsBodyLg(color: kText),
        decoration: InputDecoration(labelText: label, hintText: hint)),
  );

  Widget _pick(IconData i, String label, VoidCallback tap) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), alignment: Alignment.centerLeft),
      onPressed: tap, icon: Icon(i, size: 18), label: Text(label, style: tsBodyLg(color: kText))),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: Text(widget.docId == null ? tr('Add event') : tr('Edit event'), style: tsTitleMd(color: kText))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        GestureDetector(
          onTap: () async {
            final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1600);
            if (x != null && mounted) setState(() => _flyerFile = File(x.path));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 200, color: kCard,
              child: _flyerFile != null
                  ? Image.file(_flyerFile!, fit: BoxFit.contain)
                  : _flyerUrl.isNotEmpty
                      ? _flyer(_flyerUrl, fit: BoxFit.contain)
                      : Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.add_photo_alternate_outlined, color: kTextSub, size: 40),
                          const SizedBox(height: 6),
                          Text(tr('Add the flyer (a photo of a paper poster is fine)'), textAlign: TextAlign.center, style: tsBodySm(color: kTextSub)),
                        ])),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _field(_title, tr('Title')),
        FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: _db.collection('anonymous_services').where('category', isEqualTo: 'music').where('available', isEqualTo: true).get(),
          builder: (_, snap) {
            final artists = snap.data?.docs ?? [];
            if (artists.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<String>(
                value: artists.any((d) => d.id == _artistId) ? _artistId : '',
                decoration: InputDecoration(labelText: tr('Artist profile (optional)')),
                items: [
                  DropdownMenuItem(value: '', child: Text(tr('No profile'))),
                  for (final d in artists) DropdownMenuItem(value: d.id, child: Text(serviceStr(d.data()['publicName']))),
                ],
                onChanged: (v) => setState(() {
                  _artistId = v ?? '';
                  final a = artists.where((d) => d.id == _artistId);
                  if (a.isNotEmpty) _artist.text = serviceStr(a.first.data()['publicName']);
                }),
              ),
            );
          },
        ),
        _field(_artist, tr('Artist name')),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            value: _cat,
            decoration: InputDecoration(labelText: tr('Category')),
            items: [for (final c in kEventCategories) DropdownMenuItem(value: c.$1, child: Text(tr(c.$2)))],
            onChanged: (v) => setState(() => _cat = v ?? 'concert'),
          ),
        ),
        _pick(Icons.calendar_today_outlined, _day == null ? tr('Date') : eventDay(_day!), () async {
          final d = await showDatePicker(context: context, initialDate: _day ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 400)));
          if (d != null) setState(() => _day = d);
        }),
        _pick(Icons.schedule_outlined, _time == null ? tr('Start time') : _time!.format(context), () async {
          final t = await showTimePicker(context: context, initialTime: _time ?? const TimeOfDay(hour: 20, minute: 0));
          if (t != null) setState(() => _time = t);
        }),
        _field(_venue, tr('Venue name')),
        _field(_city, tr('City')),
        _field(_area, tr('Area')),
        _field(_desc, tr('Description'), lines: 4),
        _field(_ticket, tr('Ticket link'), type: TextInputType.url, hint: 'https://'),
        Text(tr('Discount (optional)'), style: tsLabel()),
        const SizedBox(height: 8),
        _field(_code, tr('Discount code')),
        _field(_codeText, tr('Discount text'), hint: tr('e.g. 10% off')),
        _pick(Icons.event_busy_outlined, _codeExp == null ? tr('Code valid until') : '${tr('Valid until')} ${eventDay(_codeExp!)}', () async {
          final d = await showDatePicker(context: context, initialDate: _codeExp ?? _day ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 400)));
          if (d != null) setState(() => _codeExp = d);
        }),
        Text(tr('Habesha Hub never sells tickets. Buyers pay on your own ticket page.'), style: tsBodySm(color: kTextSub)),
        if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error, style: tsBodySm(color: kRed))),
        const SizedBox(height: 14),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52)),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '…' : tr('Save')),
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 20),
      ]),
    );
  }
}

// ── Become an organizer ──
class OrganizerApplyScreen extends StatefulWidget {
  const OrganizerApplyScreen({super.key});
  @override
  State<OrganizerApplyScreen> createState() => _OrganizerApplyScreenState();
}

class _OrganizerApplyScreenState extends State<OrganizerApplyScreen> {
  final _name = TextEditingController(), _city = TextEditingController(), _link = TextEditingController(), _contact = TextEditingController();
  String _msg = '';
  bool _busy = false;

  @override
  void dispose() { for (final c in [_name, _city, _link, _contact]) { c.dispose(); } super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: Text(tr('Become an organizer'), style: tsTitleMd(color: kText))),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.collection('users').doc(u.uid).snapshots(),
        builder: (_, us) {
          if (us.data?.data()?['verifiedOrganizer'] == true) {
            return _done(Icons.verified_rounded, tr('You are a verified organizer. Your events are published at once.'));
          }
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _db.collection('organizerApplications').doc(u.uid).snapshots(),
            builder: (_, ap) {
              if (ap.data?.data()?['status'] == 'pending') return _done(Icons.hourglass_top_rounded, tr('Thank you! Habesha Hub will look at your application soon.'));
              return ListView(padding: const EdgeInsets.all(20), children: [
                Text(tr('Verified organizers and artists publish their events at once. Others wait for a short check.'), style: tsBodyLg(color: kText)),
                const SizedBox(height: 16),
                for (final (c, l, h) in [(_name, tr('Name of the organizer or artist'), null), (_city, tr('City'), null),
                    (_link, tr('Instagram or TikTok link'), 'https://'), (_contact, tr('Phone (WhatsApp) or email'), null)])
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: c, style: tsBodyLg(color: kText),
                      decoration: InputDecoration(labelText: l, hintText: h))),
                if (_msg.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_msg, style: tsBodySm(color: kRed))),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
                  onPressed: _busy ? null : () async {
                    if (_name.text.trim().isEmpty || _city.text.trim().isEmpty || _contact.text.trim().isEmpty) {
                      setState(() => _msg = tr('Please fill in name, city and contact'));
                      return;
                    }
                    setState(() { _busy = true; _msg = ''; });
                    try {
                      await _db.collection('organizerApplications').doc(u.uid).set({
                        'name': _name.text.trim(), 'city': _city.text.trim(), 'link': _link.text.trim(), 'contact': _contact.text.trim(),
                        'email': u.email ?? '', 'status': 'pending', 'createdAt': FieldValue.serverTimestamp(),
                      });
                    } catch (_) {
                      if (mounted) setState(() => _msg = tr('Could not save. Check your internet and try again.'));
                    }
                    if (mounted) setState(() => _busy = false);
                  },
                  child: Text(tr('Send')),
                ),
              ]);
            },
          );
        },
      ),
    );
  }

  Widget _done(IconData i, String t) => Center(child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(i, color: kHabGreen, size: 52),
      const SizedBox(height: 14),
      Text(t, textAlign: TextAlign.center, style: tsTitleMd(color: kText)),
    ]),
  ));
}

// ── Artist profile: their upcoming events ──
class ArtistEvents extends StatelessWidget {
  final String artistId;
  const ArtistEvents({super.key, required this.artistId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _events.where('artistId', isEqualTo: artistId).where('status', isEqualTo: 'approved')
          .where('startAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 6)))).orderBy('startAt').limit(20).snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          Text(tr('Upcoming events'), style: tsLabel()),
          const SizedBox(height: 8),
          for (final d in docs) EventCard(doc: d),
        ]);
      },
    );
  }
}

// ── Admin ──
class EventsAdminTab extends StatelessWidget {
  const EventsAdminTab({super.key});

  Widget _head(String t) => Padding(padding: const EdgeInsets.fromLTRB(4, 18, 0, 8), child: Text(t, style: tsHeadlineSm(color: kText)));

  Widget _eventRow(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final e = d.data(), t = _date(e['startAt']);
    return Card(
      color: kCard,
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(docId: d.id))),
        title: Text(_s(e['title']), style: tsTitleMd(color: kText)),
        subtitle: Text([if (t != null) '${eventDay(t)} ${eventTime(t)}', _s(e['city']), if (e['organizerVerified'] == true) '✓'].join(' · '),
            style: tsBodySm(color: kTextSub)),
        trailing: Wrap(spacing: 4, children: [
          IconButton(tooltip: tr('Message'), icon: Icon(Icons.mark_email_unread_outlined, color: kText),
              onPressed: () => sendNoticeDialog(context, toUid: _s(e['organizerId']), refName: _s(e['title']), refType: 'event', refId: d.id)),
          if (_s(e['status']) == 'pending') IconButton(tooltip: tr('Approve'), icon: Icon(Icons.check_circle_rounded, color: kHabGreen),
              onPressed: () => d.reference.update({'status': 'approved'})),
          IconButton(tooltip: tr('Remove'), icon: Icon(Icons.remove_circle_outline_rounded, color: kRed),
              onPressed: () => d.reference.update({'status': 'removed'})),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      _head(tr('Events waiting for approval')),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _events.where('status', isEqualTo: 'pending').snapshots(),
        builder: (_, s) => Column(children: [
          for (final d in s.data?.docs ?? []) _eventRow(context, d),
          if ((s.data?.docs ?? []).isEmpty) Text(tr('Nothing here'), style: tsBodySm(color: kTextSub)),
        ]),
      ),
      _head(tr('Organizer applications')),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('organizerApplications').where('status', isEqualTo: 'pending').snapshots(),
        builder: (_, s) => Column(children: [
          for (final d in s.data?.docs ?? []) Card(color: kCard, child: ListTile(
            title: Text(_s(d.data()['name']), style: tsTitleMd(color: kText)),
            subtitle: SelectableText('${_s(d.data()['city'])}\n${_s(d.data()['link'])}\n${_s(d.data()['contact'])} · ${_s(d.data()['email'])}', style: tsBodySm(color: kTextSub)),
            isThreeLine: true,
            trailing: Wrap(spacing: 4, children: [
              IconButton(tooltip: tr('Approve'), icon: Icon(Icons.verified_rounded, color: kHabGreen), onPressed: () async {
                final b = _db.batch();
                b.set(_db.collection('users').doc(d.id), {'verifiedOrganizer': true}, SetOptions(merge: true));
                b.update(d.reference, {'status': 'approved'});
                await b.commit();
              }),
              IconButton(tooltip: tr('Reject'), icon: Icon(Icons.close_rounded, color: kRed), onPressed: () => d.reference.update({'status': 'rejected'})),
            ]),
          )),
          if ((s.data?.docs ?? []).isEmpty) Text(tr('Nothing here'), style: tsBodySm(color: kTextSub)),
        ]),
      ),
      _head(tr('Verified organizers')),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('users').where('verifiedOrganizer', isEqualTo: true).snapshots(),
        builder: (_, s) => Column(children: [
          for (final d in s.data?.docs ?? []) Card(color: kCard, child: ListTile(
            title: Text(_s(d.data()['nickname']).isNotEmpty ? _s(d.data()['nickname']) : d.id, style: tsTitleMd(color: kText)),
            trailing: TextButton(
              onPressed: () async {
                if (await _confirm(context, tr('Remove verified status? Their new events will need approval again.'))) {
                  await d.reference.update({'verifiedOrganizer': false});
                }
              },
              child: Text(tr('Remove'), style: TextStyle(color: kRed))),
          )),
          if ((s.data?.docs ?? []).isEmpty) Text(tr('Nothing here'), style: tsBodySm(color: kTextSub)),
        ]),
      ),
      _head(tr('Published events')),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: upcomingEvents().snapshots(),
        builder: (_, s) => Column(children: [
          for (final d in s.data?.docs ?? []) _eventRow(context, d),
          if ((s.data?.docs ?? []).isEmpty) Text(tr('Nothing here'), style: tsBodySm(color: kTextSub)),
        ]),
      ),
      const SizedBox(height: 40),
    ]);
  }
}
