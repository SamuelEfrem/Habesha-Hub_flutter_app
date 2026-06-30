import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';
import 'admin_chat_screen.dart';

class BusinessInboxScreen extends StatelessWidget {
  final Business business;
  const BusinessInboxScreen({super.key, required this.business});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurfaceContainer,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(business.name, style: tsTitleMd(color: kSecondary)),
          Text('Innboks', style: tsBodySm(color: kOnSurfaceVariant)),
        ]),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('chats')
            .where('businessId', isEqualTo: business.id)
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
          
          final chats = snap.data!.docs;
          
          if (chats.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: kOnSurfaceVariant),
              const SizedBox(height: 16),
              Text('Ingen meldinger ennå', style: tsTitleLg(), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Kunder vil se meldingene her', style: tsBodySm(), textAlign: TextAlign.center),
            ]));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (_, i) {
              final data = chats[i].data() as Map<String, dynamic>;
              final chatId = chats[i].id;
              final nickname = data['nickname'] ?? 'Guest';
              final lastMsg = data['lastMessage'] ?? '';

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AdminChatScreen(business: business, chatId: chatId),
                )),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kSurfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kSecondary.withOpacity(0.1), width: 0.5),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: kPrimaryContainer.withOpacity(0.3), shape: BoxShape.circle),
                      child: const Icon(Icons.person_rounded, color: kSecondary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(nickname, style: tsTitleMd()),
                      const SizedBox(height: 4),
                      Text(lastMsg, style: tsBodySm(color: kOnSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    const Icon(Icons.chevron_right_rounded, color: kSecondary),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
