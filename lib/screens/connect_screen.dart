import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import 'guest_chat_screen.dart';
import '../models/business.dart';
import 'auth_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});
  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _db = FirebaseFirestore.instance;
  String _selectedInterest = 'All';

  final _interests = [
    {'key': 'All', 'emoji': '🌍', 'label': 'all'},
    {'key': 'IT', 'emoji': '💻', 'label': 'connect_it'},
    {'key': 'Business', 'emoji': '💼', 'label': 'cat_business'},
    {'key': 'Restaurant', 'emoji': '🍽️', 'label': 'restaurant'},
    {'key': 'Music', 'emoji': '🎵', 'label': 'cat_music'},
    {'key': 'Health', 'emoji': '🏥', 'label': 'connect_health'},
    {'key': 'Education', 'emoji': '📚', 'label': 'connect_education'},
    {'key': 'Other', 'emoji': '✨', 'label': 'other'},
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        final user = FirebaseAuth.instance.currentUser;
        return Scaffold(
          backgroundColor: kSurface,
          body: SafeArea(
            child: Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t('connect_title'), style: tsHeadlineMd(color: kSecondary)),
                      Text(t('connect_subtitle'), style: tsBodySm()),
                    ]),
                  ),
                  if (user != null) ...[
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConnectInboxScreen(userId: user.uid))),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: kSurfaceContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: kSecondary.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded, color: kSecondary, size: 18),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showCreateProfile(context, user, t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(100)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.person_rounded, color: Color(0xFF1A1200), size: 16),
                          const SizedBox(width: 4),
                          Text(t('connect_my_profile'), style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 12)),
                        ]),
                      ),
                    ),
                  ],
                ]),
              ),

              // Interest filter
              SizedBox(
                height: 44,
                child: ClipRect(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _interests.length,
                  itemBuilder: (_, i) {
                    final item = _interests[i];
                    final sel = _selectedInterest == item['key'];
                    final label = t(item['label']!);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedInterest = item['key']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? kSecondary : kSurfaceContainerHigh,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(item['emoji']!, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(label, style: tsLabel(color: sel ? const Color(0xFF342800) : kOnSurfaceVariant).copyWith(fontSize: 9)),
                        ]),
                      ),
                    );
                  },
                ),
                ),
              ),
              const SizedBox(height: 12),

              // Profiles list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('connect_profiles').snapshots(),
                  builder: (_, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
                    var docs = snap.data!.docs;
                    if (_selectedInterest != 'All') {
                      docs = docs.where((d) {
                        final interests = List<String>.from((d.data() as Map)['interests'] ?? []);
                        return interests.contains(_selectedInterest);
                      }).toList();
                    }
                    if (docs.isEmpty) {
                      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('🤝', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        Text(t('connect_no_profiles'), style: tsTitleLg()),
                        const SizedBox(height: 8),
                        Text(t('connect_be_first'), style: tsBodySm()),
                      ]));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final isMe = user?.uid == data['userId'];
                        return _ConnectCard(
                          key: ValueKey(docs[i].id),
                          docId: docs[i].id,
                          data: data,
                          isMe: isMe,
                          isLoggedIn: user != null,
                          t: t,
                          onMessage: () => _openChat(context, data, t, user),
                          onEdit: isMe ? () => _showCreateProfile(context, user!, t, existing: data, docId: docs[i].id) : null,
                          onDelete: isMe ? () => _db.collection('connect_profiles').doc(docs[i].id).delete() : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  void _openChat(BuildContext context, Map<String, dynamic> data, String Function(String) t, User? user) {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('login_register')), backgroundColor: kSecondary.withOpacity(0.9), behavior: SnackBarBehavior.floating));
      return;
    }
    final uid1 = user.uid;
    final uid2 = data['userId'] ?? '';
    if (uid1 == uid2) return; // Can't chat with yourself
    final sortedId = uid1.compareTo(uid2) < 0 ? uid1 + '_' + uid2 : uid2 + '_' + uid1;
    final fakeBusiness = Business(
      id: 'connect_' + sortedId,
      name: data['name'] ?? 'User',
      category: 'Other',
      description: data['bio'] ?? '',
      address: data['city'] ?? '',
      lat: 0, lng: 0,
      imageUrl: '',
      phone: '',
      rating: 0,
      isOpen: true,
      isPremium: false,
      openingHours: {},
      ownerId: data['userId'] ?? '',
      ownerEmail: data['email'] ?? '',
      ownerName: data['name'] ?? '',
      country: '',
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => GuestChatScreen(business: fakeBusiness)));
  }

  void _showCreateProfile(BuildContext context, User user, String Function(String) t, {Map<String, dynamic>? existing, String? docId}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? user.displayName ?? '');
    final bioCtrl = TextEditingController(text: existing?['bio'] ?? '');
    final cityCtrl = TextEditingController(text: existing?['city'] ?? '');
    final List<String> selectedInterests = List<String>.from(existing?['interests'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          builder: (_, ctrl) => SingleChildScrollView(
            controller: ctrl,
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kOutlineVariant, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(existing != null ? t('connect_edit_profile') : t('connect_create_profile'), style: tsHeadlineSm(color: kSecondary)),
              const SizedBox(height: 20),
              Text(t('connect_name'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: nameCtrl, style: tsBodyLg(color: kOnSurface), decoration: InputDecoration(hintText: t('connect_name_hint'))),
              const SizedBox(height: 16),
              Text(t('connect_city'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: cityCtrl, style: tsBodyLg(color: kOnSurface), decoration: const InputDecoration(hintText: 'Oslo, Kampala, Addis...')),
              const SizedBox(height: 16),
              Text(t('connect_bio'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: bioCtrl, maxLines: 3, style: tsBodyLg(color: kOnSurface), decoration: InputDecoration(hintText: t('connect_bio_hint'))),
              const SizedBox(height: 16),
              Text(t('connect_interests'), style: tsLabel()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _interests.where((i) => i['key'] != 'All').map((item) {
                  final sel = selectedInterests.contains(item['key']);
                  final label = t(item['label']!);
                  return GestureDetector(
                    onTap: () => setModal(() {
                      if (sel) selectedInterests.remove(item['key']);
                      else selectedInterests.add(item['key']!);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? kSecondary : kSurfaceContainerHigh,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text('${item['emoji']} $label', style: tsLabel(color: sel ? const Color(0xFF342800) : kOnSurfaceVariant)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;
                    final profileData = {
                      'name': nameCtrl.text.trim(),
                      'city': cityCtrl.text.trim(),
                      'bio': bioCtrl.text.trim(),
                      'interests': selectedInterests,
                    };
                    if (docId != null) {
                      await _db.collection('connect_profiles').doc(docId).update(profileData);
                    } else {
                      final existing2 = await _db.collection('connect_profiles').where('userId', isEqualTo: user.uid).get();
                      if (existing2.docs.isNotEmpty) {
                        await existing2.docs.first.reference.update(profileData);
                      } else {
                        await _db.collection('connect_profiles').add({
                          ...profileData,
                          'userId': user.uid,
                          'email': user.email ?? '',
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(t('connect_save'), style: tsTitleMd(color: const Color(0xFF1A1200))),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ConnectCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool isMe;
  final bool isLoggedIn;
  final String Function(String) t;
  final VoidCallback onMessage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ConnectCard({super.key, required this.docId, required this.data, required this.isMe, required this.isLoggedIn, required this.t, required this.onMessage, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final interests = List<String>.from(data['interests'] ?? []);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMe ? kSecondary.withOpacity(0.3) : kSecondary.withOpacity(0.08), width: isMe ? 1 : 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: kPrimaryContainer,
            child: Text((data['name'] ?? 'U')[0].toUpperCase(), style: tsHeadlineSm(color: kSecondary)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(data['name'] ?? '', style: tsTitleMd(), overflow: TextOverflow.ellipsis)),
              if (isMe) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: kSecondary.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
                  child: Text(t('connect_you'), style: tsLabel()),
                ),
              ],
            ]),
            if ((data['city'] ?? '').isNotEmpty)
              Row(children: [
                const Icon(Icons.location_on_rounded, color: kSecondary, size: 12),
                const SizedBox(width: 3),
                Flexible(child: Text(data['city'], style: tsBodySm(), overflow: TextOverflow.ellipsis)),
              ]),
          ])),
          if (!isMe && isLoggedIn) ...[
            GestureDetector(
              onTap: onMessage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(100)),
                child: Text(t('connect_message'), style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 12)),
              ),
            ),
          ],
          if (isMe) ...[
            if (onEdit != null)
              GestureDetector(onTap: onEdit, child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.edit_rounded, color: kSecondary, size: 18))),
            if (onDelete != null)
              GestureDetector(onTap: onDelete, child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.delete_outline_rounded, color: kRed, size: 18))),
          ],
        ]),
        if ((data['bio'] ?? '').isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(data['bio'], style: tsBodySm(color: kOnSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
        if (interests.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: interests.map((i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: kSurfaceContainerHigh, borderRadius: BorderRadius.circular(100)),
              child: Text(i, style: tsLabel(color: kOnSurfaceVariant)),
            )).toList(),
          ),
        ],
      ]),
    );
  }
}

// ── Connect Inbox ─────────────────────────────────────────
class ConnectInboxScreen extends StatelessWidget {
  final String userId;
  const ConnectInboxScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurfaceContainer,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Text(languageNotifier.t('connect_messages'), style: tsTitleMd(color: kSecondary)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('chats').where('businessId', isGreaterThanOrEqualTo: 'connect_').snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
          final docs = snap.data!.docs.where((d) {
            final bid = d.data() is Map ? (d.data() as Map)['businessId'] ?? '' : '';
            return bid.toString().contains(userId);
          }).toList();

          if (docs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('💬', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(languageNotifier.t('connect_no_messages'), style: tsTitleLg()),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final lastMsg = data['lastMessage'] ?? '';
              final senderName = data['guestName'] ?? data['nickname'] ?? 'User';
              final businessId = data['businessId'] ?? '';

              return GestureDetector(
                onTap: () {
                  final fakeBusiness = Business(
                    id: businessId,
                    name: senderName,
                    category: 'Other',
                    description: '',
                    address: '',
                    lat: 0, lng: 0,
                    imageUrl: '',
                    phone: '',
                    rating: 0,
                    isOpen: true,
                    isPremium: false,
                    openingHours: {},
                    ownerId: userId,
                    ownerEmail: '',
                    ownerName: '',
                    country: '',
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GuestChatScreen(business: fakeBusiness)));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kSurfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kSecondary.withOpacity(0.1)),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: kPrimaryContainer,
                      child: Text(senderName[0].toUpperCase(), style: tsTitleMd(color: kSecondary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(senderName, style: tsTitleMd()),
                      Text(lastMsg, style: tsBodySm(color: kOnSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 14),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: kSurfaceContainerHigh,
                            title: const Text('Delete chat?'),
                            content: const Text('This cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: kRed))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await db.collection('chats').doc(docs[i].id).delete();
                        }
                      },
                      child: const Icon(Icons.delete_outline_rounded, color: kRed, size: 18),
                    ),
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
