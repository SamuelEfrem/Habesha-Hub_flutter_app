import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});
  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final _db = FirebaseFirestore.instance;
  String _selectedCategory = 'All';

  final _categories = [
    {'key': 'All', 'emoji': '🌍', 'label': 'all'},
    {'key': 'Wedding', 'emoji': '💒', 'label': 'cat_wedding'},
    {'key': 'Job', 'emoji': '💼', 'label': 'cat_job'},
    {'key': 'Food', 'emoji': '🍽️', 'label': 'cat_food'},
    {'key': 'General', 'emoji': '💬', 'label': 'cat_general'},
    {'key': 'Tips', 'emoji': '💡', 'label': 'cat_tips'},
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        return Scaffold(
          backgroundColor: kSurface,
          body: SafeArea(
            child: Column(children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t('forum_title'), style: tsHeadlineMd(color: kSecondary)),
                    Text(t('forum_subtitle'), style: tsBodySm()),
                  ]),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showCreatePost(context, t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(100)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.add_rounded, color: Color(0xFF1A1200), size: 18),
                        const SizedBox(width: 4),
                        Text(t('new_post'), style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 13)),
                      ]),
                    ),
                  ),
                ]),
              ),

              // Category filter
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final sel = _selectedCategory == cat['key'];
                    final label = t(cat['label']!);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat['key']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? kSecondary : kSurfaceContainerHigh,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(cat['emoji']!, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(label, style: tsLabel(color: sel ? const Color(0xFF342800) : kOnSurfaceVariant)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Posts list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('forum').orderBy('createdAt', descending: true).snapshots(),
                  builder: (_, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
                    var docs = snap.data!.docs;
                    if (_selectedCategory != 'All') {
                      docs = docs.where((d) => (d.data() as Map<String, dynamic>)['category'] == _selectedCategory).toList();
                    }
                    if (docs.isEmpty) {
                      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('💬', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        Text(t('no_posts'), style: tsTitleLg()),
                        const SizedBox(height: 8),
                        Text(t('be_first_post'), style: tsBodySm()),
                      ]));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        return _ForumPostCard(docId: docs[i].id, data: data, db: _db);
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

  void _showCreatePost(BuildContext context, String Function(String) t) async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final nickname = user?.displayName ?? prefs.getString('nickname') ?? t('guest');

    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String selectedCat = 'General';
    File? selectedImage;
    bool isUploading = false;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          builder: (_, ctrl) => SingleChildScrollView(
            controller: ctrl,
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kOutlineVariant, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(t('new_post'), style: tsHeadlineSm(color: kSecondary)),
              const SizedBox(height: 4),
              Text('${t("posting_as")}: $nickname', style: tsBodySm(color: kOnSurfaceVariant)),
              const SizedBox(height: 20),

              Text(t('post_title'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: titleCtrl, style: tsBodyLg(color: kOnSurface), decoration: InputDecoration(hintText: t('post_hint'))),
              const SizedBox(height: 16),

              Text(t('event_category'), style: tsLabel()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _categories.where((c) => c['key'] != 'All').map((cat) {
                  final sel = selectedCat == cat['key'];
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedCat = cat['key']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? kSecondary : kSurfaceContainerHigh,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text('${cat['emoji']} ${cat['key']}', style: tsLabel(color: sel ? const Color(0xFF342800) : kOnSurfaceVariant)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              Text(t('post_body'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                style: tsBodyLg(color: kOnSurface),
                decoration: InputDecoration(hintText: t('post_body_hint')),
              ),
              const SizedBox(height: 16),

              // Bilde
              Text('BILDE (valgfritt)', style: tsLabel()),
              const SizedBox(height: 8),
              if (selectedImage != null)
                Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ])
              else
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (picked != null) setModalState(() => selectedImage = File(picked.path));
                  },
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: kSurfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kSecondary.withOpacity(0.3), width: 0.5),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.add_photo_alternate_rounded, color: kSecondary, size: 24),
                      const SizedBox(width: 8),
                      Text('Legg til bilde', style: tsBodySm(color: kSecondary)),
                    ]),
                  ),
                ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUploading ? null : () async {
                    if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
                    setModalState(() => isUploading = true);

                    String? imageUrl;
                    if (selectedImage != null) {
                      final ref = FirebaseStorage.instance.ref('forum/${DateTime.now().millisecondsSinceEpoch}.jpg');
                      await ref.putFile(selectedImage!);
                      imageUrl = await ref.getDownloadURL();
                    }

                    await _db.collection('forum').add({
                      'title': titleCtrl.text.trim(),
                      'body': bodyCtrl.text.trim(),
                      'category': selectedCat,
                      'nickname': nickname,
                      'userId': user?.uid ?? 'guest',
                      'likes': 0,
                      'commentCount': 0,
                      'imageUrl': imageUrl,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    setModalState(() => isUploading = false);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isUploading
                      ? const CircularProgressIndicator(color: Color(0xFF1A1200), strokeWidth: 2)
                      : Text(t('publish_post'), style: tsTitleMd(color: const Color(0xFF1A1200))),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ForumPostCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final FirebaseFirestore db;

  const _ForumPostCard({required this.docId, required this.data, required this.db});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final likes = data['likes'] ?? 0;
        final commentCount = data['commentCount'] ?? 0;
        final hasImage = (data['imageUrl'] ?? '').isNotEmpty;

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForumPostScreen(docId: docId, data: data, db: db))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: kSurfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kSecondary.withOpacity(0.08), width: 0.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Image
              if (hasImage)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(data['imageUrl'], height: 160, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox()),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: kSecondary.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
                      child: Text(data['category'] ?? '', style: tsLabel(color: kSecondary)),
                    ),
                    const Spacer(),
                    if (createdAt != null)
                      Text(_timeAgo(createdAt), style: tsLabel(color: kOnSurfaceVariant.withOpacity(0.5))),
                  ]),
                  const SizedBox(height: 10),
                  Text(data['title'] ?? '', style: tsTitleMd()),
                  const SizedBox(height: 6),
                  if ((data['body'] ?? '').isNotEmpty)
                    Text(data['body'], style: tsBodySm(color: kOnSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: kSurfaceContainerHigh,
                      child: Text((data['nickname'] ?? 'G')[0].toUpperCase(), style: tsLabel(color: kSecondary).copyWith(fontSize: 10)),
                    ),
                    const SizedBox(width: 6),
                    Text(data['nickname'] ?? 'Gjest', style: tsBodySm()),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async => await db.collection('forum').doc(docId).update({'likes': likes + 1}),
                      child: Row(children: [
                        const Icon(Icons.favorite_border_rounded, color: kRed, size: 16),
                        const SizedBox(width: 4),
                        Text('$likes', style: tsBodySm()),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    Row(children: [
                      const Icon(Icons.comment_outlined, color: kOnSurfaceVariant, size: 16),
                      const SizedBox(width: 4),
                      Text('$commentCount', style: tsBodySm()),
                    ]),
                  ]),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class ForumPostScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final FirebaseFirestore db;

  const ForumPostScreen({super.key, required this.docId, required this.data, required this.db});

  @override
  State<ForumPostScreen> createState() => _ForumPostScreenState();
}

class _ForumPostScreenState extends State<ForumPostScreen> {
  final _commentCtrl = TextEditingController();
  String _nickname = 'Gjest';

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _nickname = user?.displayName ?? prefs.getString('nickname') ?? languageNotifier.t('guest'));
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    final user = FirebaseAuth.instance.currentUser;
    await widget.db.collection('forum').doc(widget.docId).collection('comments').add({
      'text': text,
      'nickname': _nickname,
      'userId': user?.uid ?? 'guest',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await widget.db.collection('forum').doc(widget.docId).update({'commentCount': FieldValue.increment(1)});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        final createdAt = (widget.data['createdAt'] as Timestamp?)?.toDate();
        final likes = widget.data['likes'] ?? 0;
        final hasImage = (widget.data['imageUrl'] ?? '').isNotEmpty;

        return Scaffold(
          backgroundColor: kSurface,
          appBar: AppBar(
            backgroundColor: kSurfaceContainer,
            iconTheme: const IconThemeData(color: kSecondary),
            title: Text(widget.data['category'] ?? t('forum_title'), style: tsTitleMd(color: kSecondary)),
            actions: [
              Builder(builder: (ctx) {
                final user = FirebaseAuth.instance.currentUser;
                final isOwner = user != null && user.uid == widget.data['userId'];
                final isAdmin = user?.email == 'samuelefriem@gmail.com';
                if (!isOwner && !isAdmin) return const SizedBox();
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: kSecondary),
                  color: kSurfaceContainerHigh,
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: kSurfaceContainerHigh,
                          title: const Text('Delete post?'),
                          content: const Text('This cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: kRed))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await widget.db.collection('forum').doc(widget.docId).delete();
                        if (context.mounted) Navigator.pop(context);
                      }
                    } else if (value == 'edit') {
                      final titleCtrl = TextEditingController(text: widget.data['title']);
                      final bodyCtrl = TextEditingController(text: widget.data['body']);
                      await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: kSurfaceContainerHigh,
                          title: const Text('Edit post'),
                          content: Column(mainAxisSize: MainAxisSize.min, children: [
                            TextField(controller: titleCtrl, style: tsBodyLg(color: kOnSurface), decoration: const InputDecoration(labelText: 'Title')),
                            const SizedBox(height: 12),
                            TextField(controller: bodyCtrl, maxLines: 4, style: tsBodyLg(color: kOnSurface), decoration: const InputDecoration(labelText: 'Body')),
                          ]),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () async {
                                await widget.db.collection('forum').doc(widget.docId).update({
                                  'title': titleCtrl.text.trim(),
                                  'body': bodyCtrl.text.trim(),
                                });
                                setState(() {
                                  widget.data['title'] = titleCtrl.text.trim();
                                  widget.data['body'] = bodyCtrl.text.trim();
                                });
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    if (isOwner) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                );
              }),
            ],
          ),
          body: Column(children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Image
                      if (hasImage)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(widget.data['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox()),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: kSurfaceContainerHigh,
                              child: Text((widget.data['nickname'] ?? 'G')[0].toUpperCase(), style: tsTitleMd(color: kSecondary)),
                            ),
                            const SizedBox(width: 10),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(widget.data['nickname'] ?? t('guest'), style: tsTitleMd()),
                              if (createdAt != null)
                                Text(DateFormat('dd. MMM yyyy HH:mm').format(createdAt), style: tsLabel(color: kOnSurfaceVariant.withOpacity(0.5))),
                            ]),
                          ]),
                          const SizedBox(height: 14),
                          Text(widget.data['title'] ?? '', style: tsHeadlineSm()),
                          const SizedBox(height: 10),
                          Text(widget.data['body'] ?? '', style: tsBodyLg()),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () async => await widget.db.collection('forum').doc(widget.docId).update({'likes': likes + 1}),
                            child: Row(children: [
                              const Icon(Icons.favorite_border_rounded, color: kRed, size: 18),
                              const SizedBox(width: 6),
                              Text('$likes ${t("liked")}', style: tsBodySm()),
                            ]),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  Text(t('comments'), style: tsHeadlineSm(color: kSecondary)),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: widget.db.collection('forum').doc(widget.docId).collection('comments').orderBy('createdAt').snapshots(),
                    builder: (_, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
                      final comments = snap.data!.docs;
                      if (comments.isEmpty) return Text(t('no_comments'), style: tsBodySm());
                      return Column(
                        children: comments.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          final time = (d['createdAt'] as Timestamp?)?.toDate();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: kSurfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: kPrimaryContainer,
                                  child: Text((d['nickname'] ?? 'G')[0].toUpperCase(), style: tsLabel(color: kSecondary).copyWith(fontSize: 10)),
                                ),
                                const SizedBox(width: 8),
                                Text(d['nickname'] ?? t('guest'), style: tsTitleMd().copyWith(fontSize: 13)),
                                const Spacer(),
                                if (time != null)
                                  Text(DateFormat('HH:mm').format(time), style: tsLabel(color: kOnSurfaceVariant.withOpacity(0.4))),
                              ]),
                              const SizedBox(height: 8),
                              Text(d['text'] ?? '', style: tsBodyLg()),
                            ]),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: kSurfaceContainer,
              child: Row(children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: kSurfaceContainerHighest, borderRadius: BorderRadius.circular(24)),
                    child: TextField(
                      controller: _commentCtrl,
                      style: tsBodyLg(color: kOnSurface),
                      decoration: InputDecoration(
                        hintText: t('write_comment'),
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendComment,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(color: kSecondary, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Color(0xFF1A1200), size: 20),
                  ),
                ),
              ]),
            ),
          ]),
        );
      },
    );
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }
}