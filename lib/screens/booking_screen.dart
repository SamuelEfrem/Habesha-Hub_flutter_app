import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../services/notification_service.dart';

class BookingScreen extends StatefulWidget {
  final Business business;
  const BookingScreen({super.key, required this.business});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _db = FirebaseFirestore.instance;
  final _messageCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '10:00';
  bool _sending = false;
  String _nickname = 'Gjest';

  final _times = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
  ];

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _nickname = user?.displayName ??
        prefs.getString('nickname') ??
        languageNotifier.t('guest'));
  }

  Future<void> _sendBooking() async {
    final t = languageNotifier.t;
    if (_messageCtrl.text.isEmpty) return;
    setState(() => _sending = true);
    final user = FirebaseAuth.instance.currentUser;

    await _db.collection('bookings').add({
      'businessId': widget.business.id,
      'businessName': widget.business.name,
      'ownerId': widget.business.ownerId,
      'ownerEmail': widget.business.ownerEmail,
      'userId': user?.uid ?? 'guest',
      'nickname': _nickname,
      'date': Timestamp.fromDate(_selectedDate),
      'time': _selectedTime,
      'message': _messageCtrl.text.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await NotificationService.sendNotificationToUser(
      userId: widget.business.ownerId,
      title: 'Ny booking! 📅',
      body:
          '$_nickname vil booke ${widget.business.name} - ${DateFormat('dd. MMM').format(_selectedDate)} kl. $_selectedTime',
      data: {'type': 'booking', 'businessId': widget.business.id},
    );

    setState(() => _sending = false);
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: kSurfaceContainerHigh,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            const Icon(Icons.check_circle_rounded, color: kGreen, size: 24),
            const SizedBox(width: 10),
            Text(t('booking_sent'), style: tsHeadlineSm(color: kGreen)),
          ]),
          content: Text(t('booking_confirmed'), style: tsBodyLg()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('OK', style: tsTitleMd(color: kSecondary)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        return Scaffold(
          backgroundColor: kSurface,
          appBar: AppBar(
            backgroundColor: kSurfaceContainer,
            iconTheme: const IconThemeData(color: kSecondary),
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('book_time'), style: tsTitleMd(color: kSecondary)),
              Text(widget.business.name,
                  style: tsBodySm(color: kOnSurfaceVariant)),
            ]),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Business info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: kSecondary.withOpacity(0.2), width: 0.5),
                ),
                child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: kSurfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10)),
                    child: widget.business.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(widget.business.imageUrl,
                                fit: BoxFit.cover))
                        : const Icon(Icons.storefront_rounded,
                            color: kSecondary),
                  ),
                  const SizedBox(width: 14),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.business.name, style: tsTitleMd()),
                        Text(widget.business.category, style: tsBodySm()),
                      ]),
                ]),
              ),
              const SizedBox(height: 24),

              // Date
              Text(t('date_label'), style: tsLabel()),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: ThemeData.dark().copyWith(
                          colorScheme:
                              const ColorScheme.dark(primary: kSecondary)),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: kSurfaceContainer,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: kSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                        DateFormat('EEEE, dd. MMMM yyyy', 'nb')
                            .format(_selectedDate),
                        style: tsBodyLg(color: kOnSurface)),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: kOnSurfaceVariant, size: 14),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // Time
              Text(t('time_label'), style: tsLabel()),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _times.length,
                  itemBuilder: (_, i) {
                    final sel = _selectedTime == _times[i];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTime = _times[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? kSecondary : kSurfaceContainerHigh,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(_times[i],
                            style: tsLabel(
                                color: sel
                                    ? const Color(0xFF342800)
                                    : kOnSurfaceVariant)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Message
              Text(t('message_to_business'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(
                controller: _messageCtrl,
                maxLines: 4,
                style: tsBodyLg(color: kOnSurface),
                decoration: InputDecoration(hintText: t('describe_need')),
              ),
              const SizedBox(height: 12),

              // Booking as
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: kSurfaceContainer,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.person_outline_rounded,
                      color: kSecondary, size: 16),
                  const SizedBox(width: 8),
                  Text('${t("booking_as")}: $_nickname', style: tsBodySm()),
                ]),
              ),
              const SizedBox(height: 28),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sending ? null : _sendBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _sending
                      ? const CircularProgressIndicator(
                          color: Color(0xFF1A1200), strokeWidth: 2)
                      : Text(t('send_booking'),
                          style: tsTitleMd(color: const Color(0xFF1A1200))),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════
// BOOKING LIST SCREEN
// ═══════════════════════════════════════════════════════════
class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        final user = FirebaseAuth.instance.currentUser;
        final isAdmin = user?.email == 'samuelefriem@gmail.com';
        final db = FirebaseFirestore.instance;

        return Scaffold(
          backgroundColor: kSurface,
          appBar: AppBar(
            backgroundColor: kSurfaceContainer,
            iconTheme: const IconThemeData(color: kSecondary),
            title: Text('Bookinger', style: tsTitleMd(color: kSecondary)),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: isAdmin
                ? db
                    .collection('bookings')
                    .orderBy('createdAt', descending: true)
                    .snapshots()
                : db
                    .collection('bookings')
                    .where('ownerId', isEqualTo: user?.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: kSecondary, strokeWidth: 1.5));
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      const Text('📅', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      Text(t('no_bookings'), style: tsTitleLg()),
                    ]));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return _BookingCard(docId: docs[i].id, data: data, db: db);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final FirebaseFirestore db;

  const _BookingCard(
      {required this.docId, required this.data, required this.db});

  @override
  Widget build(BuildContext context) {
    final t = languageNotifier.t;
    final date = (data['date'] as Timestamp?)?.toDate();
    final status = data['status'] ?? 'pending';

    Color statusColor = kOnSurfaceVariant;
    String statusText = t('pending');
    if (status == 'approved') {
      statusColor = kGreen;
      statusText = '${t("approved")} ✓';
    }
    if (status == 'rejected') {
      statusColor = kRed;
      statusText = '${t("rejected")} ✗';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(data['businessName'] ?? '', style: tsTitleMd())),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(100)),
            child: Text(statusText, style: tsLabel(color: statusColor)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.person_outline_rounded, color: kSecondary, size: 14),
          const SizedBox(width: 6),
          Text(data['nickname'] ?? 'Gjest', style: tsBodySm()),
          const SizedBox(width: 16),
          if (date != null) ...[
            const Icon(Icons.calendar_today_rounded,
                color: kSecondary, size: 14),
            const SizedBox(width: 6),
            Text('${DateFormat('dd. MMM').format(date)} kl. ${data['time']}',
                style: tsBodySm()),
          ],
        ]),
        const SizedBox(height: 8),
        Text(data['message'] ?? '',
            style: tsBodySm(color: kOnSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        if (status == 'pending') ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => db
                    .collection('bookings')
                    .doc(docId)
                    .update({'status': 'approved'}),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(
                      child: Text(t('approve'),
                          style:
                              tsTitleMd(color: kGreen).copyWith(fontSize: 13))),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => db
                    .collection('bookings')
                    .doc(docId)
                    .update({'status': 'rejected'}),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      color: kRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(
                      child: Text(t('reject'),
                          style:
                              tsTitleMd(color: kRed).copyWith(fontSize: 13))),
                ),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
}
