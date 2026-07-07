import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';

class GuestChatScreen extends StatefulWidget {
  final Business business;
  const GuestChatScreen({super.key, required this.business});

  @override
  State<GuestChatScreen> createState() => _GuestChatScreenState();
}

class _GuestChatScreenState extends State<GuestChatScreen> {
  final _db = FirebaseFirestore.instance;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _userId = '';
  String _nickname = 'Guest';
  String _chatId = '';
  bool _chatReady = false;

  @override
  void initState() {
    super.initState();
    // For Connect chats, set chatId immediately
    if (widget.business.id.startsWith('connect_')) {
      _chatId = widget.business.id;
    }
    _loadUser();
  }

  Future<void> _loadUser() async {
    // Wait for auth state to be ready
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      user = await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    }
    final prefs = await SharedPreferences.getInstance();
    final uid = user?.uid ?? prefs.getString('userId') ?? 'guest_' + DateTime.now().millisecondsSinceEpoch.toString();
    if (user == null) {
      await prefs.setString('userId', uid);
    }
    final nick = user?.displayName ?? prefs.getString('nickname') ?? 'Guest';
    // For Connect chats, use business.id directly (already contains sorted UIDs)
    final chatId = widget.business.id.startsWith('connect_')
        ? widget.business.id
        : '\${widget.business.id}_\$uid';
    setState(() {
      _userId = uid;
      _nickname = nick;
      _chatId = chatId;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId.isEmpty) return;
    _messageController.clear();

    // Create chat document if not exists
    await _db.collection('chats').doc(_chatId).set({
      'businessId': widget.business.id,
      'businessName': widget.business.name,
      'userId': _userId,
      'nickname': _nickname,
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Add message
    await _db.collection('chats').doc(_chatId).collection('messages').add({
      'text': text,
      'userId': _userId,
      'nickname': _nickname,
      'createdAt': FieldValue.serverTimestamp(),
      'isAdmin': false,
    });
    setState(() {});

    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: kSurfaceContainer,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.business.name, style: tsTitleMd(color: kSecondary)),
          Text('Chat', style: tsBodySm(color: kOnSurfaceVariant)),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: _chatId.isEmpty
              ? const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5))
              : StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('chats')
                      .doc(_chatId)
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .limit(100)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: kOnSurfaceVariant),
                          const SizedBox(height: 16),
                          Text('Send a message to ${widget.business.name}', style: tsBodySm(), textAlign: TextAlign.center),
                        ]),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        // For connect chats: check userId. For business chats: check isAdmin
                        final isMe = widget.business.id.startsWith('connect_')
                            ? (data['userId'] ?? '') == _userId
                            : !((data['isAdmin'] as bool?) ?? false);
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              color: isMe ? kSecondary : kSurfaceContainerHigh,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              data['text'] ?? '',
                              style: tsBodyLg(color: isMe ? const Color(0xFF1A1200) : kOnSurface),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: kSurfaceContainer,
            border: Border(top: BorderSide(color: kSecondary.withOpacity(0.1), width: 0.5)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: tsBodyLg(color: kOnSurface),
                decoration: const InputDecoration(
                  hintText: 'Write a message...',
                  border: InputBorder.none,
                  filled: false,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: kSecondary, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Color(0xFF1A1200), size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
