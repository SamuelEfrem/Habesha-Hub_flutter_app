import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../utils/language_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import '../utils/translations.dart';

class RegisterBusinessScreen extends StatefulWidget {
  const RegisterBusinessScreen({super.key});

  @override
  State<RegisterBusinessScreen> createState() => _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState extends State<RegisterBusinessScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _db = FirebaseFirestore.instance;
  late AnimationController _stepCtrl;

  int _step = 0;
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  String _category = 'Restaurant';
  String _country = '';
  File? _selectedImage;
  String _uploadedImageUrl = '';
  bool _uploadingImage = false;
  bool _saving = false;
  bool _done = false;
  bool _geocoding = false;
  double? _lat;
  double? _lng;
  String _geoStatus = '';

  // Opening hours — one row per day-group
  final List<Map<String, String>> _hours = [
    {'days': 'Mon - Fri', 'open': '09:00', 'close': '18:00', 'closed': 'false'},
    {'days': 'Saturday', 'open': '10:00', 'close': '16:00', 'closed': 'false'},
    {'days': 'Sunday', 'open': '11:00', 'close': '15:00', 'closed': 'true'},
  ];

  String _catDisplayName(String key) {
    final keyMap = {
      'Restaurant': 'restaurant',
      'Shop': 'shop',
      'Cafe': 'cafe',
      'Barber': 'barber',
      'Club': 'club',
      'Clinic': 'clinic',
      'Photographer': 'cat_photographer',
      'Music': 'cat_music',
      'Decoration': 'cat_decoration',
      'Taxi': 'cat_taxi',
      'Hotel': 'cat_hotel',
      'Hotel': 'cat_hotel',
      'Other': 'other',
    };
    final tKey = keyMap[key];
    if (tKey == null) return tr(key);
    return languageNotifier.t(tKey);
  }
  final _cats = [
    {'name': 'Restaurant', 'icon': Icons.restaurant_rounded},
    {'name': 'Shop', 'icon': Icons.shopping_bag_rounded},
    {'name': 'Cafe', 'icon': Icons.local_cafe_rounded},
    {'name': 'Barber', 'icon': Icons.content_cut_rounded},
    {'name': 'Club', 'icon': Icons.music_note_rounded},
    {'name': 'Clinic', 'icon': Icons.local_hospital_rounded},
    {'name': 'Photographer', 'icon': Icons.camera_alt_rounded},
    {'name': 'Music', 'icon': Icons.queue_music_rounded},
    {'name': 'Decoration', 'icon': Icons.celebration_rounded},
    {'name': 'Taxi', 'icon': Icons.local_taxi_rounded},
    {'name': 'Church', 'icon': Icons.church_rounded},
    {'name': 'Association', 'icon': Icons.groups_rounded},
    {'name': 'Hotel', 'icon': Icons.bed_rounded},
    {'name': 'Hotel', 'icon': Icons.bed_rounded},
    {'name': 'Other', 'icon': Icons.storefront_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _stepCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350), value: 1);
    _checkLoginOnOpen();
  }

  /// If not logged in, redirect to AuthScreen
  Future<void> _checkLoginOnOpen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
              builder: (_) => const AuthScreen(returnOnLogin: true)),
        );
        if (result != true && mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _stepCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    _imgCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    // Only the fields of the visible step exist, so check them before moving on
    if (!_formKey.currentState!.validate()) return;
    if (_step == 1 && _addrCtrl.text.trim().isNotEmpty && _lat == null) {
      // Auto-geocode before proceeding
      await _geocodeAddress();
    }
    await _stepCtrl.reverse();
    setState(() => _step++);
    await _stepCtrl.forward();
  }

  Future<void> _prev() async {
    await _stepCtrl.reverse();
    setState(() => _step--);
    await _stepCtrl.forward();
  }

  /// Convert address string → lat/lng using geocoding package
  Future<void> _geocodeAddress() async {
    var address = _addrCtrl.text.trim();
    if (address.isEmpty) return;
    // "Tank Hill Rd, Kampala" alone can match a street in another country
    if (_country.isNotEmpty && !address.toLowerCase().contains(_country.toLowerCase())) {
      address = '$address, $_country';
    }
    setState(() {
      _geocoding = true;
      _geoStatus = tr('Finding coordinates...');
    });
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        _lat = locations.first.latitude;
        _lng = locations.first.longitude;
        setState(() => _geoStatus =
            '✓ ${tr('Location found')}: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}');
      } else {
        setState(
            () => _geoStatus = tr('⚠ Address not found. Check and try again.'));
      }
    } catch (e) {
      setState(
          () => _geoStatus = tr('⚠ Could not find location. Check the address.'));
    } finally {
      setState(() => _geocoding = false);
    }
  }

  /// For owners standing in their business (or when the address can't be found, e.g. plus codes)
  Future<void> _useMyLocation() async {
    setState(() {
      _geocoding = true;
      _geoStatus = tr('Finding coordinates...');
    });
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() => _geoStatus = tr('⚠ Could not find location. Check the address.'));
        return;
      }
      final p = await Geolocator.getCurrentPosition();
      _lat = p.latitude;
      _lng = p.longitude;
      setState(() => _geoStatus =
          '✓ ${tr('Location found')}: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}');
    } catch (_) {
      setState(() => _geoStatus = tr('⚠ Could not find location. Check the address.'));
    } finally {
      setState(() => _geocoding = false);
    }
  }

  Map<String, String> _buildOpeningHours() {
    final Map<String, String> result = {};
    for (final row in _hours) {
      if (row['closed'] == 'true') {
        result[row['days']!] = 'Closed';
      } else {
        result[row['days']!] = '${row['open']} - ${row['close']}';
      }
    }
    return result;
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1600);
    if (picked == null) return;
    setState(() { _selectedImage = File(picked.path); _uploadingImage = true; });
    try {
      final ref = FirebaseStorage.instance.ref().child('businesses/' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg');
      await ref.putFile(_selectedImage!);
      _uploadedImageUrl = await ref.getDownloadURL();
      setState(() => _uploadingImage = false);
    } catch (e) {
      setState(() => _uploadingImage = false);
      print('Upload error: ' + e.toString());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Name and address sit on earlier steps; send the user back if one is empty
    final missingStep = _nameCtrl.text.trim().isEmpty ? 0
        : (_addrCtrl.text.trim().isEmpty || _country.isEmpty) ? 1 : -1;
    if (missingStep >= 0) {
      await _stepCtrl.reverse();
      setState(() => _step = missingStep);
      await _stepCtrl.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) => _formKey.currentState?.validate());
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('You must log in to register a business'))));
      return;
    }
    setState(() => _saving = true);
    try {
      // Geocode if not done
      if (_lat == null || _lng == null) {
        await _geocodeAddress();
      }
      // Never save a made-up pin: without a real location the business would show in the wrong city
      if (_lat == null || _lng == null) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('Address not found on the map. Write street, number and city, or tap "Use my current location".'))));
        return;
      }

      await _db.collection('businesses').add({
        'name': _nameCtrl.text.trim(),
        'category': _category,
        'description': _descCtrl.text.trim(),
        'address': _addrCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'imageUrl': _uploadedImageUrl,
        'lat': _lat,
        'lng': _lng,
        'rating': 0.0,
        'isOpen': false,
        'isPremium': false,
        'ownerId': user.uid,
        'ownerName': user.displayName ?? '',
        'ownerEmail': user.email ?? '',
        'openingHours': _buildOpeningHours(),
        'website': _websiteCtrl.text.trim(),
        'country': _country,
        'status': 'pending', // ← must be approved by admin
      });
      setState(() {
        _saving = false;
        _done = true;
      });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${tr('Error')}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        iconTheme: IconThemeData(color: kSecondary),
        title: Text(tr('Register business'), style: tsTitleLg(color: kSecondary)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: kCardHigh,
            valueColor: AlwaysStoppedAnimation<Color>(kSecondary),
            minHeight: 2,
          ),
        ),
      ),
      body: _done ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kCard,
                border:
                    Border.all(color: kSecondary.withOpacity(0.4), width: 1.5),
              ),
              child:
                  Icon(Icons.check_rounded, size: 48, color: kSecondary),
            ),
            const SizedBox(height: 24),
            Text(tr('Business sent for approval!'),
                style: tsHeadlineSm(), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: kSecondary.withOpacity(0.2), width: 0.5),
              ),
              child: Column(children: [
                Icon(Icons.pending_outlined, color: kSecondary, size: 28),
                const SizedBox(height: 8),
                Text(
                  tr('Your business is being reviewed by Habesha Hub. We will email you when it is approved and published. Usually 1–2 business days.'),
                  style: tsBodySm(),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
            const SizedBox(height: 32),
            goldButton(tr('Back'), () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: FadeTransition(
                opacity: _stepCtrl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step indicator
                    Row(
                        children: List.generate(
                            3,
                            (i) => Expanded(
                                    child: Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: i <= _step
                                        ? kSecondary
                                        : kCardHigh,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                )))),
                    const SizedBox(height: 6),
                    Text('${tr('Step')} ${_step + 1} / 3', style: tsBodySm()),
                    const SizedBox(height: 24),
                    if (_step == 0) _buildStep1(),
                    if (_step == 1) _buildStep2(),
                    if (_step == 2) _buildStep3(),
                  ],
                ),
              ),
            ),
          ),
          // Bottom navigation
          Container(
            padding: const EdgeInsets.all(16),
            color: kCard,
            child: Row(children: [
              if (_step > 0) ...[
                Expanded(
                    child: OutlinedButton(
                  onPressed: _prev,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: kSecondary.withOpacity(0.4), width: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    foregroundColor: kSecondary,
                  ),
                  child: Text(tr('Back'), style: tsLabel()),
                )),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: _step < 2
                    ? goldButton(tr('Next'), _next)
                    : primaryButton(
                        tr('Send for approval'), _saving ? null : _submit,
                        loading: _saving),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── STEP 1: Name + Category ────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
            text: TextSpan(style: tsHeadlineMd(), children: [
          TextSpan(text: tr('Establish Your\n')),
          TextSpan(
              text: tr('Digital Heritage.'),
              style: TextStyle(color: kSecondary, fontStyle: FontStyle.italic)),
        ])),
        const SizedBox(height: 6),
        Text(tr('Register your business in the Habesha Hub network.'),
            style: tsBodySm()),
        const SizedBox(height: 24),
        Text(tr('BUSINESS NAME'), style: tsLabel()),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameCtrl,
          style: tsBodyLg(color: kText),
          validator: (v) => v!.isEmpty ? tr('Required') : null,
          decoration:
              InputDecoration(hintText: tr('e.g. Addis Fine Dining')),
        ),
        const SizedBox(height: 20),
        Text(tr('CATEGORY'), style: tsLabel()),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 3.2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: _cats.map((cat) {
            final sel = _category == cat['name'];
            return GestureDetector(
              onTap: () => setState(() => _category = cat['name'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: sel
                      ? kPrimaryContainer.withOpacity(0.3)
                      : kCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: sel
                          ? kSecondary.withOpacity(0.5)
                          : Colors.transparent,
                      width: 0.5),
                ),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(cat['icon'] as IconData,
                      color: sel ? kSecondary : kTextSub, size: 16),
                  const SizedBox(width: 8),
                  Text(_catDisplayName(cat['name'] as String),
                      style:
                          tsLabel(color: sel ? kSecondary : kTextSub)),
                ]),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── STEP 2: Address + Phone + Opening Hours ────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('Contact information'), style: tsHeadlineSm()),
        const SizedBox(height: 24),

        Text(tr('COUNTRY'), style: tsLabel()),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _country.isEmpty ? null : _country,
          dropdownColor: kCard,
          style: tsBodyLg(color: kText),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.flag_rounded, color: kSecondary),
            hintText: tr('Select country'),
          ),
          validator: (v) => v == null || v.isEmpty ? tr('Required') : null,
          items: [
            'Uganda', 'Ethiopia', 'Eritrea', 'Egypt', 'Kenya', 'South Sudan', 'Rwanda', 'Angola',
            'Norway', 'Sweden', 'Denmark', 'UK', 'Germany',
            'Netherlands', 'France', 'Belgium', 'Switzerland', 'Italy',
            'USA', 'Canada',
          ].map((c) => DropdownMenuItem(value: c, child: Text(tr(c)))).toList(),
          onChanged: (v) => setState(() => _country = v ?? ''),
        ),
        const SizedBox(height: 16),

        Text(tr('DESCRIPTION'), style: tsLabel()),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descCtrl,
          maxLines: 3,
          style: tsBodyLg(color: kText),
          validator: (v) => v!.isEmpty ? tr('Required') : null,
          decoration:
              InputDecoration(hintText: tr('Describe your business...')),
        ),
        const SizedBox(height: 16),

        Text(tr('ADDRESS'), style: tsLabel()),
        const SizedBox(height: 4),
        Text(
            tr('Enter the full address incl. postcode and city for the correct map location.'),
            style: tsBodySm(color: kTextSub.withOpacity(0.6))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _addrCtrl,
                style: tsBodyLg(color: kText),
                validator: (v) => v!.isEmpty ? tr('Required') : null,
                // A changed address needs a new pin
                onChanged: (_) {
                  if (_lat != null || _geoStatus.isNotEmpty) {
                    setState(() { _lat = null; _lng = null; _geoStatus = ''; });
                  }
                },
                decoration: InputDecoration(
                  hintText: tr('Street 15, 0190 Oslo'),
                  prefixIcon:
                      Icon(Icons.location_on_rounded, color: kSecondary),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _geocodeAddress,
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: kSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _geocoding
                    ? Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                            color: kOnAccent, strokeWidth: 2))
                    : Icon(Icons.my_location_rounded,
                        color: kOnAccent, size: 22),
              ),
            ),
          ],
        ),
        if (_geoStatus.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(_geoStatus,
              style: tsBodySm(
                  color:
                      _geoStatus.startsWith('✓') ? kGreen : kTextSub)),
        ],
        TextButton.icon(
          onPressed: _geocoding ? null : _useMyLocation,
          icon: Icon(Icons.gps_fixed_rounded, size: 16, color: kSecondary),
          label: Text(tr('Use my current location'), style: tsBodySm(color: kSecondary)),
        ),
        const SizedBox(height: 8),

        Text(tr('PHONE'), style: tsLabel()),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: tsBodyLg(color: kText),
          decoration: InputDecoration(
            hintText: '+47 00 00 00 00',
            prefixIcon: Icon(Icons.phone_rounded, color: kSecondary),
          ),
        ),
        const SizedBox(height: 24),

        // Opening hours
        Text(tr('OPENING HOURS'), style: tsLabel()),
        const SizedBox(height: 10),
        ..._hours.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          final isClosed = row['closed'] == 'true';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(row['days']!, style: tsTitleMd()),
                    const Spacer(),
                    Row(children: [
                      Text(tr('Closed'),
                          style: tsBodySm(
                              color: isClosed
                                  ? kRed
                                  : kTextSub.withOpacity(0.5))),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() =>
                            _hours[i]['closed'] = isClosed ? 'false' : 'true'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isClosed
                                ? kRed.withOpacity(0.3)
                                : kGreen.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Stack(children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 200),
                              left: isClosed ? 2 : 22,
                              top: 2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isClosed ? kRed : kGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                  ],
                ),
                if (!isClosed) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: _timeField(
                      label: tr('Opens'),
                      value: row['open']!,
                      onChanged: (v) => setState(() => _hours[i]['open'] = v),
                    )),
                    const SizedBox(width: 12),
                    Text('—', style: TextStyle(color: kTextSub)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _timeField(
                      label: tr('Closes'),
                      value: row['close']!,
                      onChanged: (v) => setState(() => _hours[i]['close'] = v),
                    )),
                  ]),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _timeField(
      {required String label,
      required String value,
      required Function(String) onChanged}) {
    return GestureDetector(
      onTap: () async {
        final parts = value.split(':');
        final initial =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(
                    primary: kSecondary, surface: kCard),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onChanged(
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kCardHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: tsLabel(color: kTextSub).copyWith(fontSize: 9)),
          const SizedBox(height: 2),
          Row(children: [
            Icon(Icons.access_time_rounded, color: kSecondary, size: 14),
            const SizedBox(width: 5),
            Text(value, style: tsTitleMd()),
          ]),
        ]),
      ),
    );
  }

  // ── STEP 3: Image ──────────────────────────────────────────
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('Image'), style: tsHeadlineSm()),
        const SizedBox(height: 6),
        Text(tr('Add an image for your business.'), style: tsBodySm()),
        const SizedBox(height: 24),

        Text(tr('IMAGE'), style: tsLabel()),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _uploadingImage ? null : _pickAndUploadImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              ),
            child: _uploadingImage
                ? Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 2))
                : _selectedImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, height: 180, width: double.infinity, fit: BoxFit.cover))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate_rounded, color: kSecondary, size: 40),
                        const SizedBox(height: 8),
                        Text(tr('Tap to upload an image'), style: tsBodySm(color: kSecondary)),
                      ]),
          ),
        ),
        const SizedBox(height: 20),

        const SizedBox(height: 16),

        Text(tr('WEBSITE (optional)'), style: tsLabel()),
        const SizedBox(height: 4),
        Text(tr('URL of the business\'s website'),
            style: tsBodySm(color: kTextSub.withOpacity(0.6))),
        const SizedBox(height: 8),
        TextFormField(
          controller: _websiteCtrl,
          keyboardType: TextInputType.url,
          style: tsBodyLg(color: kText),
          decoration: InputDecoration(
            hintText: tr('https://www.yourbusiness.com'),
            prefixIcon: Icon(Icons.language_rounded, color: kSecondary),
          ),
        ),
        const SizedBox(height: 20),

        // Summary of what will be submitted
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(12),
            ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.pending_outlined, color: kSecondary, size: 16),
              const SizedBox(width: 8),
              Text(tr('Approval process'), style: tsTitleMd(color: kSecondary)),
            ]),
            const SizedBox(height: 8),
            Text(
              tr('After you submit, the Habesha Hub team will review your business. This usually takes 1–2 business days. You will receive an email when it is approved.'),
              style: tsBodySm(),
            ),
          ]),
        ),
      ],
    );
  }
}
