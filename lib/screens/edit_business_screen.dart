import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';

class EditBusinessScreen extends StatefulWidget {
  final Business business;
  final String docId;

  const EditBusinessScreen({
    super.key,
    required this.business,
    required this.docId,
  });

  @override
  State<EditBusinessScreen> createState() => _EditBusinessScreenState();
}

class _EditBusinessScreenState extends State<EditBusinessScreen> {
  final _db = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _addrCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _imgCtrl;
  late TextEditingController _websiteCtrl;

  late String _category;
  late double? _lat;
  late double? _lng;
  late List<Map<String, String>> _hours;

  bool _saving = false;
  bool _deleting = false;
  bool _geocoding = false;
  String _geoStatus = '';

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
    final b = widget.business;
    _nameCtrl = TextEditingController(text: b.name);
    _descCtrl = TextEditingController(text: b.description);
    _addrCtrl = TextEditingController(text: b.address);
    _phoneCtrl = TextEditingController(text: b.phone);
    _imgCtrl = TextEditingController(text: b.imageUrl);
    _websiteCtrl = TextEditingController(text: b.website ?? '');
    _category = b.category;
    _lat = b.lat != 0 ? b.lat : null;
    _lng = b.lng != 0 ? b.lng : null;

    // Load opening hours
    if (b.openingHours.isNotEmpty) {
      _hours = b.openingHours.entries
          .map((e) => {
                'days': e.key,
                'open': e.value == 'Stengt'
                    ? '09:00'
                    : e.value.split(' - ').first.trim(),
                'close': e.value == 'Stengt'
                    ? '18:00'
                    : e.value.split(' - ').last.trim(),
                'closed': e.value == 'Stengt' ? 'true' : 'false',
              })
          .toList();
    } else {
      _hours = [
        {
          'days': 'Man - Fre',
          'open': '09:00',
          'close': '18:00',
          'closed': 'false'
        },
        {
          'days': 'Lørdag',
          'open': '10:00',
          'close': '16:00',
          'closed': 'false'
        },
        {'days': 'Søndag', 'open': '11:00', 'close': '15:00', 'closed': 'true'},
      ];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    _imgCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

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
            '✓ Posisjon: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}');
      } else {
        setState(() => _geoStatus = '⚠ Adresse ikke funnet');
      }
    } catch (_) {
      setState(() => _geoStatus = '⚠ Kunne ikke finne posisjon');
    } finally {
      setState(() => _geocoding = false);
    }
  }

  Map<String, String> _buildOpeningHours() {
    final Map<String, String> result = {};
    for (final row in _hours) {
      result[row['days']!] = row['closed'] == 'true'
          ? 'Stengt'
          : '${row['open']} - ${row['close']}';
    }
    return result;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_lat == null && _addrCtrl.text.isNotEmpty) {
        await _geocodeAddress();
      }
      await _db.collection('businesses').doc(widget.docId).update({
        'name': _nameCtrl.text.trim(),
        'category': _category,
        'description': _descCtrl.text.trim(),
        'address': _addrCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'imageUrl': _imgCtrl.text.trim(),
        'lat': _lat ?? 59.9139,
        'lng': _lng ?? 10.7522,
        'openingHours': _buildOpeningHours(),
        'website': _websiteCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Keep status as-is (don't reset to pending on edit)
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✓ Bedrift oppdatert!'),
          backgroundColor: kGreen,
        ));
        Navigator.pop(context, true); // return true = reload needed
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Feil: $e')));
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Slett bedrift', style: tsHeadlineSm()),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.warning_amber_rounded, color: kRed, size: 48),
          const SizedBox(height: 12),
          Text(
            'Er du sikker på at du vil slette "${widget.business.name}"?\n\nDette kan ikke angres.',
            style: tsBodyLg(),
            textAlign: TextAlign.center,
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Avbryt', style: tsBodySm()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Ja, slett', style: tsTitleMd(color: kRed)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await _db.collection('businesses').doc(widget.docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.business.name} er slettet'),
          backgroundColor: kSurfaceContainerHigh,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _deleting = false);
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
        title: Text('Rediger bedrift', style: tsTitleLg(color: kSecondary)),
        elevation: 0,
        actions: [
          // Delete button in app bar
          IconButton(
            onPressed: _deleting ? null : _delete,
            icon: _deleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(color: kRed, strokeWidth: 2))
                : const Icon(Icons.delete_outline_rounded, color: kRed),
            tooltip: 'Slett bedrift',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Basic Info ──────────────────────────
                    Text('BEDRIFTSNAVN', style: tsLabel()),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      style: tsBodyLg(color: kOnSurface),
                      validator: (v) => v!.isEmpty ? 'Påkrevd' : null,
                      decoration:
                          const InputDecoration(hintText: 'Bedriftsnavn'),
                    ),
                    const SizedBox(height: 16),

                    // ── Category ────────────────────────────
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
                          onTap: () =>
                              setState(() => _category = cat['name'] as String),
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
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(cat['icon'] as IconData,
                                      color:
                                          sel ? kSecondary : kOnSurfaceVariant,
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Text(cat['name'] as String,
                                      style: tsLabel(
                                          color: sel
                                              ? kSecondary
                                              : kOnSurfaceVariant)),
                                ]),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── Description ─────────────────────────
                    Text('BESKRIVELSE', style: tsLabel()),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: tsBodyLg(color: kOnSurface),
                      validator: (v) => v!.isEmpty ? 'Påkrevd' : null,
                      decoration:
                          const InputDecoration(hintText: 'Beskrivelse...'),
                    ),
                    const SizedBox(height: 16),

                    // ── Address ─────────────────────────────
                    Text('ADRESSE', style: tsLabel()),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addrCtrl,
                          style: tsBodyLg(color: kOnSurface),
                          validator: (v) => v!.isEmpty ? 'Påkrevd' : null,
                          decoration: const InputDecoration(
                            hintText: 'Gateadresse, postnummer, by',
                            prefixIcon: Icon(Icons.location_on_rounded,
                                color: kSecondary),
                          ),
                          onChanged: (_) => setState(() {
                            _lat = null;
                            _geoStatus = '';
                          }),
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
                    ]),
                    if (_geoStatus.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(_geoStatus,
                          style: tsBodySm(
                              color: _geoStatus.startsWith('✓')
                                  ? kGreen
                                  : kOnSurfaceVariant)),
                    ],
                    if (_lat != null) ...[
                      const SizedBox(height: 4),
                      Text(
                          'Koordinater: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                          style: tsBodySm(color: kSecondary)),
                    ],
                    const SizedBox(height: 16),

                    // ── Phone ───────────────────────────────
                    Text('TELEFON', style: tsLabel()),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: tsBodyLg(color: kOnSurface),
                      decoration: const InputDecoration(
                        hintText: '+47 00 00 00 00',
                        prefixIcon:
                            Icon(Icons.phone_rounded, color: kSecondary),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Opening Hours ───────────────────────
                    Text('ÅPNINGSTIDER', style: tsLabel()),
                    const SizedBox(height: 10),
                    ..._hours.asMap().entries.map((entry) {
                      final i = entry.key;
                      final row = entry.value;
                      final closed = row['closed'] == 'true';
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
                              Row(children: [
                                Text(row['days']!, style: tsTitleMd()),
                                const Spacer(),
                                Text('Stengt',
                                    style: tsBodySm(
                                        color: closed
                                            ? kRed
                                            : kOnSurfaceVariant
                                                .withOpacity(0.4))),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setState(() => _hours[i]
                                      ['closed'] = closed ? 'false' : 'true'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 44,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: closed
                                          ? kRed.withOpacity(0.3)
                                          : kGreen.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Stack(children: [
                                      AnimatedPositioned(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        left: closed ? 2 : 22,
                                        top: 2,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: closed ? kRed : kGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                              ]),
                              if (!closed) ...[
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(
                                      child: _timeField(
                                    label: 'Åpner',
                                    value: row['open']!,
                                    onChanged: (v) =>
                                        setState(() => _hours[i]['open'] = v),
                                  )),
                                  const SizedBox(width: 12),
                                  const Text('—',
                                      style:
                                          TextStyle(color: kOnSurfaceVariant)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: _timeField(
                                    label: 'Stenger',
                                    value: row['close']!,
                                    onChanged: (v) =>
                                        setState(() => _hours[i]['close'] = v),
                                  )),
                                ]),
                              ],
                            ]),
                      );
                    }),

                    const SizedBox(height: 16),

                    // ── Image URL ───────────────────────────
                    Text('BILDE URL', style: tsLabel()),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _imgCtrl,
                      keyboardType: TextInputType.url,
                      style: tsBodyLg(color: kOnSurface),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'https://...',
                        prefixIcon:
                            Icon(Icons.image_outlined, color: kSecondary),
                      ),
                    ),
                    if (_imgCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _imgCtrl.text,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              height: 80,
                              color: kSurfaceContainer,
                              child: const Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      color: kOnSurfaceVariant))),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    Text('NETTSIDE (valgfritt)', style: tsLabel()),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _websiteCtrl,
                      keyboardType: TextInputType.url,
                      style: tsBodyLg(color: kOnSurface),
                      decoration: const InputDecoration(
                        hintText: 'https://www.dinbedrift.no',
                        prefixIcon:
                            Icon(Icons.language_rounded, color: kSecondary),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Save Button ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              color: kSurfaceContainer,
              child: goldButton(
                _saving ? '' : 'Lagre endringer',
                _saving ? null : _save,
                loading: _saving,
                icon: Icons.save_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeField({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final parts = value.split(':');
        final initial =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                  primary: kSecondary, surface: kSurfaceContainer),
            ),
            child: child!,
          ),
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
}
