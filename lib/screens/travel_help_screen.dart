import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../services/notification_service.dart';

class TravelHelpScreen extends StatefulWidget {
  const TravelHelpScreen({super.key});

  @override
  State<TravelHelpScreen> createState() => _TravelHelpScreenState();
}

class _TravelHelpScreenState extends State<TravelHelpScreen> {
  final _db = FirebaseFirestore.instance;
  String _selectedService = '';
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  String _fromCountry = '';
  String _toCountry = 'Ethiopia';
  String _travelDate = '';
  bool _sending = false;
  bool _sent = false;

  final _destinations = ['Ethiopia', 'Eritrea', 'Uganda', 'Kenya', 'Other'];

  Future<void> _submit() async {
    if (_selectedService.isEmpty || _nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in name and email'), backgroundColor: kRed));
      return;
    }
    setState(() => _sending = true);
    try {
    await _db.collection('travel_requests').add({
      'service': _selectedService,
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'fromCountry': _fromCountry,
      'toCountry': _toCountry,
      'travelDate': _travelDate,
      'details': _detailsCtrl.text.trim(),
      'userId': FirebaseAuth.instance.currentUser?.uid ?? 'guest',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Notification will be added later

    setState(() { _sending = false; _sent = true; });
    } catch (e) {
      print('Travel request error: ' + e.toString());
      setState(() => _sending = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ' + e.toString()), backgroundColor: kRed));
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
            title: Text(t('travel_help_title'), style: tsTitleMd(color: kSecondary)),
          ),
          body: _sent ? _buildSuccess() : _buildForm(t),
        );
      },
    );
  }

  Widget _buildSuccess() {
    final t = languageNotifier.t;
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_rounded, color: kGreen, size: 80),
        const SizedBox(height: 24),
        Text(t('travel_success'), style: tsHeadlineMd(color: kSecondary)),
        const SizedBox(height: 12),
        Text(t('travel_success_desc'),
            style: tsBodyLg(), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('support@habesha-hub.no', style: tsTitleMd(color: kSecondary)),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: kSecondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text(t('back'), style: tsTitleMd(color: const Color(0xFF1A1200))),
        ),
      ]),
    ));
  }

  Widget _buildForm(String Function(String) t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF004D40), Color(0xFF00897B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            const Text('🌍', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('travel_help_header'), style: tsTitleMd(color: Colors.white)),
              const SizedBox(height: 4),
              Text(t('travel_help_desc'),
                  style: tsBodySm(color: Colors.white70)),
            ])),
          ]),
        ),
        const SizedBox(height: 24),

        // Service selection
        Text(t('travel_what_help'), style: tsHeadlineSm(color: kSecondary)),
        const SizedBox(height: 12),

        _serviceCard('✈️', t('travel_flight_title'), t('travel_flight_desc'), 'flight'),
        _serviceCard('🛂', t('travel_visa_title'), t('travel_visa_desc'), 'visa'),
        _serviceCard('✈️🛂', t('travel_package_title'), t('travel_package_desc'), 'package'),
        _serviceCard('🏨', t('travel_hotel_title'), t('travel_hotel_desc'), 'hotel'),

        if (_selectedService.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          Text(t('travel_contact'), style: tsHeadlineSm(color: kSecondary)),
          const SizedBox(height: 12),

          Text('FULL NAME', style: tsLabel()),
          const SizedBox(height: 8),
          TextField(controller: _nameCtrl, style: tsBodyLg(color: kOnSurface), decoration: const InputDecoration(hintText: 'Your full name', prefixIcon: Icon(Icons.person_rounded, color: kSecondary))),
          const SizedBox(height: 16),

          Text('EMAIL', style: tsLabel()),
          const SizedBox(height: 8),
          TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: tsBodyLg(color: kOnSurface), decoration: const InputDecoration(hintText: 'your@email.com', prefixIcon: Icon(Icons.email_rounded, color: kSecondary))),
          const SizedBox(height: 16),

          Text('PHONE (optional)', style: tsLabel()),
          const SizedBox(height: 8),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, style: tsBodyLg(color: kOnSurface), decoration: const InputDecoration(hintText: '+47 xxx xx xxx', prefixIcon: Icon(Icons.phone_rounded, color: kSecondary))),
          const SizedBox(height: 16),

          if (_selectedService == 'flight' || _selectedService == 'package') ...[
            Text('TRAVELING FROM', style: tsLabel()),
            const SizedBox(height: 8),
            TextField(controller: TextEditingController(text: _fromCountry),
              onChanged: (v) => _fromCountry = v,
              style: tsBodyLg(color: kOnSurface),
              decoration: const InputDecoration(hintText: 'e.g. Oslo, Norway', prefixIcon: Icon(Icons.flight_takeoff_rounded, color: kSecondary))),
            const SizedBox(height: 16),

            Text('DESTINATION', style: tsLabel()),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _toCountry,
              dropdownColor: kSurfaceContainerHigh,
              style: tsBodyLg(color: kOnSurface),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.flight_land_rounded, color: kSecondary)),
              items: _destinations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _toCountry = v ?? 'Ethiopia'),
            ),
            const SizedBox(height: 16),

            Text('TRAVEL DATE', style: tsLabel()),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => _travelDate = v,
              style: tsBodyLg(color: kOnSurface),
              decoration: const InputDecoration(hintText: 'e.g. August 2026', prefixIcon: Icon(Icons.calendar_today_rounded, color: kSecondary))),
            const SizedBox(height: 16),
          ],

          Text('ADDITIONAL DETAILS', style: tsLabel()),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsCtrl,
            maxLines: 4,
            style: tsBodyLg(color: kOnSurface),
            decoration: InputDecoration(
              hintText: _selectedService == 'visa'
                  ? 'Your nationality, passport details, travel dates...'
                  : 'Number of passengers, preferences, budget...',
            ),
          ),
          const SizedBox(height: 24),

          // Pricing info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('💰 Service Fees', style: tsTitleMd(color: kSecondary)),
              const SizedBox(height: 8),
              Text('✈️ Flight booking: 300 NOK service fee', style: tsBodySm()),
              Text('🛂 Visa assistance: 500 NOK', style: tsBodySm()),
              Text('📦 Package (flight + visa): 700 NOK', style: tsBodySm()),
              Text('🏨 Accommodation: Free', style: tsBodySm()),
            ]),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: kSecondary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _sending
                  ? const CircularProgressIndicator(color: Color(0xFF1A1200), strokeWidth: 2)
                  : Text(t('travel_send'), style: tsTitleMd(color: const Color(0xFF1A1200))),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _serviceCard(String emoji, String title, String desc, String key) {
    final selected = _selectedService == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedService = key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? kSecondary.withOpacity(0.1) : kSurfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? kSecondary : kSecondary.withOpacity(0.1), width: selected ? 1.5 : 0.5),
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: tsTitleMd(color: selected ? kSecondary : kOnSurface)),
            Text(desc, style: tsBodySm(color: kOnSurfaceVariant)),
          ])),
          if (selected) const Icon(Icons.check_circle_rounded, color: kSecondary),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }
}
