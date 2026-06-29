import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _db = FirebaseFirestore.instance;
  String _selectedCategory = 'Alle';

  final _categories = [
    {'key': 'Alle', 'emoji': '🌍', 'label': 'all'},
    {'key': 'Bryllup', 'emoji': '💒', 'label': 'cat_wedding'},
    {'key': 'Musikk', 'emoji': '🎵', 'label': 'cat_music'},
    {'key': 'Mat', 'emoji': '🍽️', 'label': 'cat_food'},
    {'key': 'Kultur', 'emoji': '🎭', 'label': 'cat_culture'},
    {'key': 'Business', 'emoji': '💼', 'label': 'cat_business'},
    {'key': 'Sport', 'emoji': '⚽', 'label': 'cat_sport'},
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

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
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('events_title'),
                            style: tsHeadlineMd(color: kSecondary)),
                        Text(t('events_subtitle'), style: tsBodySm()),
                      ]),
                  const Spacer(),
                  StreamBuilder(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (_, snap) {
                      if (snap.data == null) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () => _showCreateEvent(context, t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                              color: kSecondary,
                              borderRadius: BorderRadius.circular(100)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.add_rounded,
                                color: Color(0xFF1A1200), size: 18),
                            const SizedBox(width: 4),
                            Text(t('new_event'),
                                style: tsTitleMd(color: const Color(0xFF1A1200))
                                    .copyWith(fontSize: 13)),
                          ]),
                        ),
                      );
                    },
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
                      onTap: () =>
                          setState(() => _selectedCategory = cat['key']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? kSecondary : kSurfaceContainerHigh,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(cat['emoji']!,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(label,
                              style: tsLabel(
                                  color: sel
                                      ? const Color(0xFF342800)
                                      : kOnSurfaceVariant)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Events list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('events').orderBy('date').snapshots(),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: kSecondary, strokeWidth: 1.5));
                    }
                    var docs = snap.data!.docs;
                    if (_selectedCategory != 'Alle') {
                      docs = docs
                          .where((d) =>
                              (d.data() as Map<String, dynamic>)['category'] ==
                              _selectedCategory)
                          .toList();
                    }
                    if (docs.isEmpty) {
                      return Center(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            const Text('🎭', style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 16),
                            Text(t('no_events'), style: tsTitleLg()),
                            const SizedBox(height: 8),
                            Text(t('come_back'), style: tsBodySm()),
                          ]));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        return _EventCard(
                            docId: docs[i].id, data: data, db: _db);
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

  void _showCreateEvent(BuildContext context, String Function(String) t) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    File? pickedImage;
    String selectedCat = 'Kultur';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurfaceContainer,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          builder: (_, ctrl) => SingleChildScrollView(
            controller: ctrl,
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: kOutlineVariant,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(t('create_event'), style: tsHeadlineSm(color: kSecondary)),
              const SizedBox(height: 20),
              Text(t('event_title'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(
                  controller: titleCtrl,
                  style: tsBodyLg(color: kOnSurface),
                  decoration: InputDecoration(hintText: t('events_title'))),
              const SizedBox(height: 16),
              Text(t('event_category'), style: tsLabel()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _categories.where((c) => c['key'] != 'Alle').map((cat) {
                  final sel = selectedCat == cat['key'];
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedCat = cat['key']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? kSecondary : kSurfaceContainerHigh,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text('${cat['emoji']} ${cat['key']}',
                          style: tsLabel(
                              color: sel
                                  ? const Color(0xFF342800)
                                  : kOnSurfaceVariant)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(t('date_label'), style: tsLabel()),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: ThemeData.dark().copyWith(
                          colorScheme:
                              const ColorScheme.dark(primary: kSecondary)),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: kSurfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: kSecondary, size: 18),
                    const SizedBox(width: 10),
                    Text(DateFormat('dd. MMMM yyyy', 'nb').format(selectedDate),
                        style: tsBodyLg(color: kOnSurface)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Text(t('event_location'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(
                  controller: locationCtrl,
                  style: tsBodyLg(color: kOnSurface),
                  decoration: const InputDecoration(
                      hintText: 'Kampala, Uganda',
                      prefixIcon: Icon(Icons.location_on_rounded,
                          color: kSecondary))),
              const SizedBox(height: 16),
              Text(t('event_description'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: tsBodyLg(color: kOnSurface),
                  decoration: InputDecoration(hintText: t('describe_need'))),
              const SizedBox(height: 16),
              Text('Event Image', style: tsLabel()),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (ctx2, setImg) => GestureDetector(
                  onTap: () async {
                    final p = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (p != null) { pickedImage = File(p.path); setModalState(() {}); }
                  },
                  child: Container(
                    height: 140, width: double.infinity,
                    decoration: BoxDecoration(color: kSurfaceContainerHigh, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.3))),
                    child: pickedImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(pickedImage!, fit: BoxFit.cover, width: double.infinity, height: 140))
                      : const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_photo_alternate_rounded, color: kSecondary, size: 36), SizedBox(height: 8), Text('Tap to add image', style: TextStyle(color: kSecondary))])),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.isEmpty || locationCtrl.text.isEmpty) {
                      return;
                    }
                    try {
                      String imageUrl = '';
                      if (pickedImage != null) {
                        final ref = FirebaseStorage.instance.ref().child('events/\${DateTime.now().millisecondsSinceEpoch}.jpg');
                        await ref.putFile(pickedImage!);
                        imageUrl = await ref.getDownloadURL();
                      }
                      await _db.collection('events').add({
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'category': selectedCat,
                        'location': locationCtrl.text.trim(),
                        'date': Timestamp.fromDate(selectedDate),
                        'imageUrl': imageUrl,
                        'interestedCount': 0,
                        'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      print('Event error: ' + e.toString());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(t('publish_event'),
                      style: tsTitleMd(color: const Color(0xFF1A1200))),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final FirebaseFirestore db;

  const _EventCard({required this.docId, required this.data, required this.db});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        final date = (data['date'] as Timestamp?)?.toDate();
        final hasImage = (data['imageUrl'] ?? '').isNotEmpty;
        final interested = data['interestedCount'] ?? 0;
        final isUpcoming = date != null && date.isAfter(DateTime.now());
        final isAdmin = FirebaseAuth.instance.currentUser?.email ==
            'samuelefriem@gmail.com';
        final isOwner = FirebaseAuth.instance.currentUser?.uid == data['createdBy'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: kSurfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kSecondary.withOpacity(0.1), width: 0.5),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (hasImage)
              GestureDetector(
                onTap: () => showDialog(context: context, builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: InteractiveViewer(child: Image.network(data['imageUrl'], fit: BoxFit.contain)),
                  ),
                )),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(data['imageUrl'],
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox()),
                ),
              )
            else
              Container(
                height: 100,
                decoration: BoxDecoration(
                    color: kPrimaryContainer.withOpacity(0.3),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16))),
                child: Center(
                    child: Text(_categoryEmoji(data['category'] ?? ''),
                        style: const TextStyle(fontSize: 48))),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: kSecondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(100)),
                        child: Text(data['category'] ?? '',
                            style: tsLabel(color: kSecondary)),
                      ),
                      const Spacer(),
                      if (date != null) ...[
                        const Icon(Icons.calendar_today_rounded,
                            color: kOnSurfaceVariant, size: 13),
                        const SizedBox(width: 4),
                        Text(DateFormat('dd. MMM yyyy').format(date),
                            style: tsLabel(color: kOnSurfaceVariant)),
                      ],
                    ]),
                    const SizedBox(height: 10),
                    Text(data['title'] ?? '', style: tsHeadlineSm()),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          color: kSecondary, size: 14),
                      const SizedBox(width: 4),
                      Text(data['location'] ?? '', style: tsBodySm()),
                    ]),
                    const SizedBox(height: 8),
                    if ((data['description'] ?? '').isNotEmpty)
                      Text(data['description'],
                          style: tsBodySm(color: kOnSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 14),
                    Row(children: [
                      Icon(Icons.people_rounded,
                          color: kSecondary.withOpacity(0.7), size: 16),
                      const SizedBox(width: 4),
                      Text('$interested ${t("interested_count")}',
                          style: tsBodySm()),
                      const Spacer(),
                      if (isUpcoming)
                        GestureDetector(
                          onTap: () async {
                            await db
                                .collection('events')
                                .doc(docId)
                                .update({'interestedCount': interested + 1});
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(t('interested_snack'),
                                  style: tsBodySm(color: kOnSurface)),
                              backgroundColor: kGreen,
                              behavior: SnackBarBehavior.floating,
                            ));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                color: kSecondary,
                                borderRadius: BorderRadius.circular(100)),
                            child: Text(t('interested'),
                                style: tsTitleMd(color: const Color(0xFF1A1200))
                                    .copyWith(fontSize: 12)),
                          ),
                        ),
                      if (isAdmin || isOwner) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async =>
                              await db.collection('events').doc(docId).delete(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                                color: kRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(100)),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: kRed, size: 16),
                          ),
                        ),
                      ],
                    ]),
                  ]),
            ),
          ]),
        );
      },
    );
  }

  String _categoryEmoji(String cat) {
    switch (cat) {
      case 'Bryllup':
        return '💒';
      case 'Musikk':
        return '🎵';
      case 'Mat':
        return '🍽️';
      case 'Kultur':
        return '🎭';
      case 'Business':
        return '💼';
      case 'Sport':
        return '⚽';
      default:
        return '🌍';
    }
  }
}
