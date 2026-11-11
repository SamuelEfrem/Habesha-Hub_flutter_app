import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';

// ═══════════════════════════════════════════════════════════
// CHAT with premium businesses — the owner's inbox and replies.
//   chats/{bizId_userId} { businessId, userId, ownerId, userName, lastText, ownerUnread, updatedAt }
//   chats/{id}/messages/{id} { text, userId, nickname, fromBusiness?, createdAt }
// ═══════════════════════════════════════════════════════════

class BusinessInbox extends StatelessWidget {
  final Business business;
  const BusinessInbox({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('chats')
          .where('ownerId', isEqualTo: uid).where('businessId', isEqualTo: business.id).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(tr('Could not load messages'), style: tsBodySm(color: kTextSub)));
        if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
        int ms(dynamic t) => t is Timestamp ? t.millisecondsSinceEpoch : 0;
        final docs = snap.data!.docs.toList()
          ..sort((a, b) => ms(b.data()['updatedAt']).compareTo(ms(a.data()['updatedAt'])));
        if (docs.isEmpty) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.chat_bubble_outline_rounded, color: kTextSub, size: 48),
              const SizedBox(height: 10),
              Text(tr('No messages from customers yet'), textAlign: TextAlign.center, style: tsBodyLg(color: kTextSub)),
            ]),
          ));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final name = (d['userName'] ?? '').toString().trim();
            final shown = name.isEmpty ? tr('Customer') : name;
            final unread = d['ownerUnread'] == true;
            final ts = d['updatedAt'];
            return Material(
              color: kCard,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChatThreadScreen(chatId: docs[i].id, business: business, title: shown))),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    CircleAvatar(backgroundColor: kTintGreen, child: Text(shown.characters.first.toUpperCase(),
                        style: TextStyle(color: kInkGreen, fontWeight: FontWeight.w800))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(shown, style: tsTitleMd(color: kText)),
                      Text((d['lastText'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: tsBodySm(color: unread ? kText : kTextSub).copyWith(fontWeight: unread ? FontWeight.w700 : null)),
                    ])),
                    if (ts is Timestamp) Text(DateFormat('dd.MM HH:mm').format(ts.toDate()), style: tsBodySm(color: kTextSub)),
                    if (unread) Container(margin: const EdgeInsets.only(left: 8), width: 9, height: 9,
                        decoration: BoxDecoration(color: kSecondary, shape: BoxShape.circle)),
                  ]),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// One conversation, seen by the business owner (answers as the business).
class ChatThreadScreen extends StatefulWidget {
  final String chatId, title;
  final Business business;
  const ChatThreadScreen({super.key, required this.chatId, required this.business, required this.title});
  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _ctrl = TextEditingController();
  late final DocumentReference<Map<String, dynamic>> _chat =
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

  @override
  void initState() {
    super.initState();
    _chat.update({'ownerUnread': false}).catchError((_) {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (text.isEmpty || uid == null) return;
    _ctrl.clear();
    await _chat.collection('messages').add({
      'text': text, 'userId': uid, 'nickname': widget.business.name, 'fromBusiness': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _chat.set({'updatedAt': FieldValue.serverTimestamp(), 'lastText': text, 'ownerUnread': false}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg, surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: kSecondary),
        title: Text(widget.title, style: tsTitleMd(color: kText).copyWith(fontSize: 18)),
      ),
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _chat.collection('messages').orderBy('createdAt', descending: true).limit(200).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
            final docs = snap.data!.docs;
            return ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final m = docs[i].data();
                final mine = m['userId'] == uid;
                final ts = m['createdAt'];
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: mine ? kSecondary : kCard, borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text((m['text'] ?? '').toString(), style: tsBodyLg(color: mine ? kOnAccent : kText)),
                      if (ts is Timestamp) Text(DateFormat('HH:mm').format(ts.toDate()),
                          style: tsBodySm(color: mine ? kOnAccent.withValues(alpha: 0.7) : kTextSub).copyWith(fontSize: 11)),
                    ]),
                  ),
                );
              },
            );
          },
        )),
        SafeArea(top: false, child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          color: kCard,
          child: Row(children: [
            Expanded(child: Container(
              decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _ctrl,
                style: tsBodyLg(color: kText),
                minLines: 1, maxLines: 4,
                decoration: InputDecoration(hintText: tr('Write an answer'), border: InputBorder.none, filled: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              ),
            )),
            const SizedBox(width: 10),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: kSecondary, foregroundColor: kOnAccent),
              onPressed: _send, icon: const Icon(Icons.send_rounded),
            ),
          ]),
        )),
      ]),
    );
  }
}
