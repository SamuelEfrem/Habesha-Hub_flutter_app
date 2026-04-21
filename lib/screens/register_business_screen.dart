import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

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
  bool _saving = false;
  bool _done = false;
  bool _geocoding = false;
  double? _lat;
  double? _lng;
  String _geoStatus = '';

  // Opening hours — one row per day-group
  final List<Map<String, String>> _hours = [
    {'days': 'Man - Fre', 'open': '09:00', 'close': '18:00', 'closed': 'false'},
    {'days': 'Lørdag', 'open': '10:00', 'close': '16:00', 'closed': 'false'},
    {'days': 'Søndag', 'open': '11:00', 'close': '15:00', 'closed': 'true'},
  ];

  final _cats = [
    {'name': 'Restaurant', 'icon': Icons.restaurant_rounded},
    {'name': 'Butikk', 'icon': Icons.shopping_bag_rounded},
    {'name': 'Kafé', 'icon': Icons.local_cafe_rounded},
    {'name': 'Frisør', 'icon': Icons.content_cut_rounded},
    {'name': 'Club', 'icon': Icons.music_note_rounded},
    {'name': 'Klinikk', 'icon': Icons.local_hospital_rounded},
    {'name': 'Annet', 'icon': Icons.storefront_rounded},
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
    final address = _addrCtrl.text.trim();
    if (address.isEmpty) return;
    setState(() {
      _geocoding = true;
      _geoStatus = 'Finner koordinater...';
    });
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        _lat = locations.first.latitude;
        _lng = locations.first.longitude;
        setState(() => _geoStatus =
            '✓ Posisjon funnet: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}');
      } else {
        setState(
            () => _geoStatus = '⚠ Adresse ikke funnet. Sjekk og prøv igjen.');
      }
    } catch (e) {
      setState(
          () => _geoStatus = '⚠ Kunne ikke finne posisjon. Sjekk adressen.');
    } finally {
      setState(() => _geocoding = false);
    }
  }

  Map<String, String> _buildOpeningHours() {
    final Map<String, String> result = {};
    for (final row in _hours) {
      if (row['closed'] == 'true') {
        result[row['days']!] = 'Stengt';
      } else {
        result[row['days']!] = '${row['open']} - ${row['close']}';
      }
    }
    return result;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Du må logge inn for å registrere bedrift')));
      return;
    }
    setState(() => _saving = true);
    try {
      // Geocode if not done
      if (_lat == null || _lng == null) {
        await _geocodeAddress();
      }

      await _db.collection('businesses').add({
        'name': _nameCtrl.text.trim(),
        'category': _category,
        'description': _descCtrl.text.trim(),
        'address': _addrCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'imageUrl': _imgCtrl.text.trim(),
        'lat': _lat ?? 59.9139, // fallback: Oslo center
        'lng': _lng ?? 10.7522,
        'rating': 0.0,
        'isOpen': false,
        'isPremium': false,
        'ownerId': user.uid,
        'ownerName': user.displayName ?? '',
        'ownerEmail': user.email ?? '',
        'openingHours': _buildOpeningHours(),
        'website': _websiteCtrl.text.trim(),
        'status': 'pending', // ← must be approved by admin
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _saving = false;
        _done = true;
      });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Feil: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurfaceContainer,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Text('Registrer bedrift', style: tsTitleLg(color: kSecondary)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: kSurfaceContainerHigh,
            valueColor: const AlwaysStoppedAnimation<Color>(kSecondary),
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
                color: kSurfaceContainer,
                border:
                    Border.all(color: kSecondary.withOpacity(0.4), width: 1.5),
              ),
              child:
                  const Icon(Icons.check_rounded, size: 48, color: kSecondary),
            ),
            const SizedBox(height: 24),
            Text('Bedrift sendt til godkjenning!',
                style: tsHeadlineSm(), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kSurfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: kSecondary.withOpacity(0.2), width: 0.5),
              ),
              child: Column(children: [
                const Icon(Icons.pending_outlined, color: kSecondary, size: 28),
                const SizedBox(height: 8),
                Text(
                  'Bedriften din er under gjennomgang av Habesha Hub. Vi sender deg en e-post når den er godkjent og publisert. Vanligvis 1-2 virkedager.',
                  style: tsBodySm(),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
            const SizedBox(height: 32),
            goldButton('Tilbake', () => Navigator.pop(context)),
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
                                        : kSurfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                )))),
                    const SizedBox(height: 6),
                    Text('Steg ${_step + 1} av 3', style: tsBodySm()),
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
            color: kSurfaceContainer,
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
                  child: Text('Tilbake', style: tsLabel()),
                )),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: _step < 2
                    ? goldButton('Neste', _next)
                    : primaryButton(
                        'Send til godkjenning', _saving ? null : _submit,
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
          const TextSpan(text: 'Establish Your\n'),
          TextSpan(
              text: 'Digital Heritage.',
              style: TextStyle(color: kSecondary, fontStyle: FontStyle.italic)),
        ])),
        const SizedBox(height: 6),
        Text('Registrer bedriften din i Habesha Hub-nettverket.',
            style: tsBodySm()),
        const SizedBox(height: 24),
        Text('BEDRIFTSNAVN', style: tsLabel()),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameCtrl,
          style: tsBodyLg(color: kOnSurface),
          validator: (v) => v!.isEmpty ? 'Påkrevd' : null,
          decoration:
              const InputDecoration(hintText: 'f.eks. Addis Fine Dining'),
        ),
        const SizedBox(height: 20),
        Text('KATEGORI', style: tsLabel()),
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
                      : kSurfaceContainer,
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
                      color: sel ? kSecondary : kOnSurfaceVariant, size: 16),
                  const SizedBox(width: 8),
                  Text(cat['name'] as String,
                      style:
                          tsLabel(color: sel ? kSecondary : kOnSurfaceVariant)),
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
        Text('Kontaktinformasjon', style: tsHeadlineSm()),
        const SizedBox(height: 24),

        Text('BESKRIVELSE', style: tsLabel()),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descCtrl,
          maxLines: 3,
          style: tsBodyLg(color: kOnSurface),
          validator: (v) => v!.isEmpty ? 'Påkrevd' : null,
          decoration:
              const InputDecoration(hintText: 'Beskriv bedriften din...'),
        ),
        const SizedBox(height: 16),

        Text('ADRESSE', style: tsLabel()),
        const SizedBox(height: 4),
        Text(
            'Skriv full adresse inkl. postnummer og by for riktig kartplassering.',
            style: tsBodySm(color: kOnSurfaceVariant.withOpacity(0.6))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _addrCtrl,
                style: tsBodyLg(color: kOnSurface),
                validator: (v) => v!.isEmpty ? 'Påkrevd' : null,
                decoration: const InputDecoration(
                  hintText: 'Grønlandsleiret 15, 0190 Oslo',
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
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                            color: kSurface, strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded,
                        color: kSurface, size: 22),
              ),
            ),
          ],
        ),
        if (_geoStatus.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(_geoStatus,
              style: tsBodySm(
                  color:
                      _geoStatus.startsWith('✓') ? kGreen : kOnSurfaceVariant)),
        ],
        const SizedBox(height: 16),

        Text('TELEFON', style: tsLabel()),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: tsBodyLg(color: kOnSurface),
          decoration: const InputDecoration(
            hintText: '+47 00 00 00 00',
            prefixIcon: Icon(Icons.phone_rounded, color: kSecondary),
          ),
        ),
        const SizedBox(height: 24),

        // Opening hours
        Text('ÅPNINGSTIDER', style: tsLabel()),
        const SizedBox(height: 10),
        ..._hours.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          final isClosed = row['closed'] == 'true';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kSurfaceContainer,
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
                      Text('Stengt',
                          style: tsBodySm(
                              color: isClosed
                                  ? kRed
                                  : kOnSurfaceVariant.withOpacity(0.5))),
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
                      label: 'Åpner',
                      value: row['open']!,
                      onChanged: (v) => setState(() => _hours[i]['open'] = v),
                    )),
                    const SizedBox(width: 12),
                    const Text('—', style: TextStyle(color: kOnSurfaceVariant)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _timeField(
                      label: 'Stenger',
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
                colorScheme: const ColorScheme.dark(
                    primary: kSecondary, surface: kSurfaceContainer),
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
          color: kSurfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: tsLabel(color: kOnSurfaceVariant).copyWith(fontSize: 9)),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.access_time_rounded, color: kSecondary, size: 14),
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
        Text('Bilde', style: tsHeadlineSm()),
        const SizedBox(height: 6),
        Text('Legg til en bilde-URL for bedriften din.', style: tsBodySm()),
        const SizedBox(height: 24),

        Text('BILDE URL', style: tsLabel()),
        const SizedBox(height: 8),
        TextFormField(
          controller: _imgCtrl,
          keyboardType: TextInputType.url,
          style: tsBodyLg(color: kOnSurface),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'https://...',
            prefixIcon: Icon(Icons.image_outlined, color: kSecondary),
          ),
        ),
        if (_imgCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _imgCtrl.text,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: kSurfaceContainer,
                  child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: kOnSurfaceVariant, size: 40))),
            ),
          ),
        ],
        const SizedBox(height: 20),

        const SizedBox(height: 16),

        Text('NETTSIDE (valgfritt)', style: tsLabel()),
        const SizedBox(height: 4),
        Text('URL til bedriftens nettside',
            style: tsBodySm(color: kOnSurfaceVariant.withOpacity(0.6))),
        const SizedBox(height: 8),
        TextFormField(
          controller: _websiteCtrl,
          keyboardType: TextInputType.url,
          style: tsBodyLg(color: kOnSurface),
          decoration: const InputDecoration(
            hintText: 'https://www.dinbedrift.no',
            prefixIcon: Icon(Icons.language_rounded, color: kSecondary),
          ),
        ),
        const SizedBox(height: 20),

        // Summary of what will be submitted
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSurfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kSecondary.withOpacity(0.15), width: 0.5),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.pending_outlined, color: kSecondary, size: 16),
              const SizedBox(width: 8),
              Text('Godkjenningsprosess', style: tsTitleMd(color: kSecondary)),
            ]),
            const SizedBox(height: 8),
            Text(
              'Etter innsending vil Habesha Hub-teamet gjennomgå bedriften din. Dette tar vanligvis 1-2 virkedager. Du vil motta e-post når den er godkjent.',
              style: tsBodySm(),
            ),
          ]),
        ),
      ],
    );
  }
}
