import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../services/notification_service.dart';

class HotelBookingScreen extends StatefulWidget {
  final Business business;
  const HotelBookingScreen({super.key, required this.business});

  @override
  State<HotelBookingScreen> createState() => _HotelBookingScreenState();
}

class _HotelBookingScreenState extends State<HotelBookingScreen> {
  final _db = FirebaseFirestore.instance;
  final _messageCtrl = TextEditingController();
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 2));
  int _guests = 1;
  bool _sending = false;
  bool _sent = false;
  String _nickname = 'Guest';

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _nickname = user?.displayName ?? prefs.getString('nickname') ?? 'Guest');
  }

  int get _nights => _checkOut.difference(_checkIn).inDays;

  Future<void> _submit() async {
    if (_nights < 1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Check-out must be after check-in'),
        backgroundColor: kRed,
      ));
      return;
    }
    setState(() => _sending = true);
    final user = FirebaseAuth.instance.currentUser;
    await _db.collection('bookings').add({
      'businessId': widget.business.id,
      'businessName': widget.business.name,
      'ownerId': widget.business.ownerId,
      'ownerEmail': widget.business.ownerEmail,
      'userId': user?.uid ?? 'guest',
      'nickname': _nickname,
      'type': 'hotel',
      'checkIn': Timestamp.fromDate(_checkIn),
      'checkOut': Timestamp.fromDate(_checkOut),
      'nights': _nights,
      'guests': _guests,
      'message': _messageCtrl.text.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await NotificationService.sendNotificationToUser(
      userId: widget.business.ownerId,
      title: 'New hotel booking request! 🏨',
      body: '$_nickname wants to book ${widget.business.name} - $_nights nights, $_guests guests',
      data: {'type': 'booking', 'businessId': widget.business.id},
    );
    setState(() { _sending = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
    final t = languageNotifier.t;
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurfaceContainer,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hotel Booking', style: tsTitleMd(color: kSecondary)),
          Text(widget.business.name, style: tsBodySm(color: kOnSurfaceVariant)),
        ]),
      ),
      body: _sent
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_circle_rounded, color: kGreen, size: 64),
              const SizedBox(height: 16),
              Text('Booking request sent!', style: tsHeadlineSm()),
              const SizedBox(height: 8),
              Text('The host will contact you soon.', style: tsBodySm()),
              const SizedBox(height: 24),
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Go back', style: tsTitleMd(color: kSecondary))),
            ]))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Business info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(14), border: Border.all(color: kSecondary.withOpacity(0.2), width: 0.5)),
                  child: Row(children: [
                    Container(width: 48, height: 48, decoration: BoxDecoration(color: kSurfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
                      child: widget.business.imageUrl.isNotEmpty
                          ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(widget.business.imageUrl, fit: BoxFit.cover))
                          : const Icon(Icons.hotel_rounded, color: kSecondary, size: 28)),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.business.name, style: tsTitleMd()),
                      Text(widget.business.address, style: tsBodySm(color: kOnSurfaceVariant)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 24),

                // Check-in
                Text('CHECK-IN', style: tsLabel()),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _checkIn, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setState(() { _checkIn = picked; if (_checkOut.isBefore(_checkIn.add(const Duration(days: 1)))) _checkOut = _checkIn.add(const Duration(days: 1)); });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded, color: kSecondary, size: 18),
                      const SizedBox(width: 10),
                      Text(DateFormat('dd. MMMM yyyy').format(_checkIn), style: tsBodyLg(color: kOnSurface)),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // Check-out
                Text('CHECK-OUT', style: tsLabel()),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _checkOut, firstDate: _checkIn.add(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setState(() => _checkOut = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.3))),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded, color: kSecondary, size: 18),
                      const SizedBox(width: 10),
                      Text(DateFormat('dd. MMMM yyyy').format(_checkOut), style: tsBodyLg(color: kOnSurface)),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // Nights summary
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.nights_stay_rounded, color: kSecondary, size: 20),
                    const SizedBox(width: 8),
                    Text('$_nights night${_nights != 1 ? 's' : ''}', style: tsTitleMd(color: kSecondary)),
                  ]),
                ),
                const SizedBox(height: 16),

                // Guests
                Text('GUESTS', style: tsLabel()),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.people_rounded, color: kSecondary, size: 18),
                    const SizedBox(width: 10),
                    Text('$_guests guest${_guests != 1 ? 's' : ''}', style: tsBodyLg(color: kOnSurface)),
                    const Spacer(),
                    GestureDetector(onTap: () { if (_guests > 1) setState(() => _guests--); }, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: kSurfaceContainerHigh, shape: BoxShape.circle), child: const Icon(Icons.remove_rounded, color: kSecondary, size: 18))),
                    const SizedBox(width: 12),
                    GestureDetector(onTap: () { if (_guests < 10) setState(() => _guests++); }, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: kSurfaceContainerHigh, shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: kSecondary, size: 18))),
                  ]),
                ),
                const SizedBox(height: 16),

                // Message
                Text('MESSAGE (optional)', style: tsLabel()),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageCtrl,
                  maxLines: 3,
                  style: tsBodyLg(color: kOnSurface),
                  decoration: const InputDecoration(hintText: 'Any special requests?'),
                ),
                const SizedBox(height: 24),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: kSecondary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _sending
                        ? const CircularProgressIndicator(color: Color(0xFF1A1200), strokeWidth: 2)
                        : Text('Send Booking Request', style: tsTitleMd(color: const Color(0xFF1A1200))),
                  ),
                ),
              ]),
            ),
    );
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }
}
