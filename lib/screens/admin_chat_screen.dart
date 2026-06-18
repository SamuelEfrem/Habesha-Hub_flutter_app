import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';

class AdminChatScreen extends StatefulWidget {
  final Business business;
  final String chatId;

  const AdminChatScreen({
    super.key,
    required this.business,
    required this.chatId,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _db = FirebaseFirestore.instance;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    final user = FirebaseAuth.instance.currentUser;
    await _db
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': text,
      'userId': user?.uid ?? 'admin',
      'nickname': widget.business.name,
      'createdAt': FieldValue.serverTimestamp(),
      'isAdmin': true,
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurfaceContainer,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.business.name, style: tsTitleMd(color: kSecondary)),
          Text('Chat med bruker', style: tsBodySm(color: kOnSurfaceVariant)),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('chats')
                .doc(widget.chatId)
                .collection('messages')
                .orderBy('createdAt', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: kSecondary, strokeWidth: 1.5));
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return Center(
                    child: Text('Ingen meldinger ennå', style: tsBodySm()));
              }
              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final isAdmin = data['isAdmin'] == true;
                  final time = data['createdAt'] as Timestamp?;
                  return _buildBubble(
                    text: data['text'] ?? '',
                    nickname: data['nickname'] ?? 'Bruker',
                    isMe: isAdmin,
                    time: time?.toDate(),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: kSurfaceContainer,
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: kSurfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: _messageController,
                  style: tsBodyLg(color: kOnSurface),
                  decoration: InputDecoration(
                      hintText: 'Svar bruker...',
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12)),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: kSecondary, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded,
                    color: Color(0xFF1A1200), size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBubble({
    required String text,
    required String nickname,
    required bool isMe,
    DateTime? time,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? kPrimaryContainer : kSurfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(nickname,
                style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isMe ? kOnSurface.withOpacity(0.6) : kSecondary,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(text, style: tsBodyLg()),
            if (time != null) ...[
              const SizedBox(height: 3),
              Text(DateFormat('HH:mm').format(time),
                  style: TextStyle(
                      fontFamily: kFontBody,
                      fontSize: 10,
                      color: isMe
                          ? kOnSurface.withOpacity(0.35)
                          : kOnSurfaceVariant.withOpacity(0.4))),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
