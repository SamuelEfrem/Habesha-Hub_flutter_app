import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/contact.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';

// Messages from Habesha Hub to one person: "you are registered", and what to fix before approval.
// The admin writes them; a Cloud Function sends the push.

final _notices = FirebaseFirestore.instance.collection('notices');

Stream<int> unreadNotices() {
  final u = FirebaseAuth.instance.currentUser;
  if (u == null || u.isAnonymous) return Stream.value(0);
  return _notices.where('toUid', isEqualTo: u.uid).where('read', isEqualTo: false).snapshots().map((s) => s.size);
}

/// Profile row with the number of unread messages
class NoticesRow extends StatelessWidget {
  const NoticesRow({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: unreadNotices(),
      builder: (_, snap) {
        final n = snap.data ?? 0;
        return Material(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticesScreen())),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(children: [
                Icon(Icons.mark_email_unread_outlined, color: kText),
                const SizedBox(width: 14),
                Expanded(child: Text(tr('Messages from Habesha Hub'), style: tsTitleMd(color: kText))),
                if (n > 0) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(100)),
                  child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                Icon(Icons.chevron_right_rounded, color: kTextSub),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: Text(tr('Messages from Habesha Hub'), style: tsTitleMd(color: kText))),
      body: u == null || u.isAnonymous
          ? Center(child: Text(tr('Log in to see your messages'), style: tsBodySm(color: kTextSub)))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _notices.where('toUid', isEqualTo: u.uid).limit(100).snapshots(),
              builder: (_, snap) {
                if (snap.hasError) return Center(child: Text(tr('Could not load messages. Try again later.'), style: tsBodySm(color: kTextSub)));
                if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kHabGreen, strokeWidth: 2));
                final docs = (snap.data?.docs ?? []).toList()
                  ..sort((a, b) {
                    final x = a.data()['createdAt'], y = b.data()['createdAt'];
                    return x is Timestamp && y is Timestamp ? y.compareTo(x) : 0;
                  });
                if (docs.isEmpty) return Center(child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.mark_email_read_outlined, color: kHabGreen, size: 56),
                    const SizedBox(height: 14),
                    Text(tr('No messages yet'), style: tsTitleMd(color: kText)),
                    const SizedBox(height: 8),
                    Text(tr('Here you get messages from Habesha Hub, for example when your business, service or event is published, or if something needs to be fixed.'),
                        textAlign: TextAlign.center, style: tsBodySm(color: kTextSub)),
                    const SizedBox(height: 18),
                    _waButton(''),
                  ]),
                ));
                // opening the list marks the messages as read
                for (final d in docs) {
                  if (d.data()['read'] == false) d.reference.update({'read': true}).catchError((_) {});
                }
                return ListView(padding: const EdgeInsets.all(16), children: [
                  for (final d in docs) _NoticeCard(data: d.data()),
                ]);
              },
            ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NoticeCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final t = data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : null;
    final fix = data['kind'] == 'fix';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: fix ? kTintYellow : kCard, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(fix ? Icons.build_circle_outlined : Icons.check_circle_outline_rounded, color: fix ? kInkYellow : kHabGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(fix ? tr('Please fix before approval') : data['kind'] == 'registered' ? tr('You are registered') : '${data['title'] ?? ''}', style: tsTitleMd(color: kText))),
          if (t != null) Text('${t.day}.${t.month}.', style: tsBodySm(color: kTextSub)),
        ]),
        if ('${data['refName'] ?? ''}'.isNotEmpty) Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${data['refName']}', style: tsBodySm(color: kTextSub).copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 6),
        SelectableText('${data['body'] ?? ''}', style: tsBodyLg(color: kText)),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: _waButton('${data['refName'] ?? ''}')),
      ]),
    );
  }
}

/// Answer Habesha Hub by e-mail (support@habesha-hub.no)
Widget _waButton(String about) => OutlinedButton.icon(
  onPressed: () => emailSupport(subject: about.isEmpty ? 'Habesha Hub' : 'Habesha Hub: $about'),
  icon: const Icon(Icons.email_outlined, size: 18),
  label: Text(about.isEmpty ? tr('Contact us by email') : tr('Reply by email')),
);

/// Admin: write to the person who registered something, before approving it
Future<void> sendNoticeDialog(BuildContext context, {required String toUid, required String refName, required String refType, required String refId}) async {
  if (toUid.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No owner to write to')));
    return;
  }
  final ctrl = TextEditingController();
  // English + Tigrinya, so everyone understands
  const templates = [
    'The address is wrong or incomplete. Please correct it. · ኣድራሻ ጌጋ ወይ ዘይምሉእ እዩ። በጃኹም ኣዐርይዎ።',
    'Please add a clear photo. · በጃኹም ንጹር ስእሊ ወስኹ።',
    'The phone or WhatsApp number is missing or wrong (use country code, e.g. +47). · ቁጽሪ ቴሌፎን ወይ ዋትስኣፕ የለን ወይ ጌጋ እዩ (ምስ ኮድ ሃገር፡ ን.ኣ. +47)።',
    'Please write a short description of what you offer. · በጃኹም ብዛዕባ እተቕርብዎ ሓጺር መግለጺ ጽሓፉ።',
    'The opening hours are missing. · ሰዓታት ስራሕ የለዉን።',
  ];
  final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
    backgroundColor: kCard,
    title: Text('Message to the owner', style: tsTitleMd(color: kText)),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(refName, style: tsBodySm(color: kTextSub)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final t in templates) ActionChip(label: Text(t, style: const TextStyle(fontSize: 12)),
            onPressed: () => setD(() => ctrl.text = ctrl.text.isEmpty ? t : '${ctrl.text}\n$t')),
      ]),
      const SizedBox(height: 10),
      TextField(controller: ctrl, maxLines: 5, maxLength: 1000, decoration: const InputDecoration(hintText: 'What should they fix?')),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
      FilledButton(style: FilledButton.styleFrom(backgroundColor: kHabGreen), onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
    ],
  )));
  if (ok != true || ctrl.text.trim().isEmpty) return;
  await _notices.add({
    'toUid': toUid, 'title': 'Please fix before approval', 'body': ctrl.text.trim(), 'kind': 'fix',
    'refType': refType, 'refId': refId, 'refName': refName, 'read': false, 'createdAt': FieldValue.serverTimestamp(),
  });
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent')));
}
