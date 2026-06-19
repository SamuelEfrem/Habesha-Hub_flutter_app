import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String _apiKey = 'AIzaSyDlr-jUBRiouKToV9eVF3026yIvP5Ek2q0';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _success = false;
  String _error = '';

  String _name = '';
  String _address = '';
  double _lat = 0;
  double _lng = 0;
  final String _phone = '';
  final String _imageUrl = '';

  String _selectedCategory = 'Restaurant';
  String _description = '';
  bool _isOpen = true;
  bool _isPremium = false;

  final List<String> _categories = [
    'Restaurant',
    'Butikk',
    'Kafé',
    'Frisør',
    'Club',
    'Klinikk',
    'Annet'
  ];

  Future<void> _saveBusiness() async {
    if (_name.isEmpty) {
      setState(() => _error = 'Velg en bedrift fra søket');
      return;
    }
    if (_description.isEmpty) {
      setState(() => _error = 'Legg til en beskrivelse');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      await FirebaseFirestore.instance.collection('businesses').add({
        'name': _name,
        'category': _selectedCategory,
        'description': _description,
        'address': _address,
        'lat': _lat,
        'lng': _lng,
        'phone': _phone,
        'imageUrl': _imageUrl,
        'rating': 0.0,
        'isOpen': _isOpen,
        'isPremium': _isPremium,
        'pdfMenuUrl': null,
        'openingHours': {},
        'source': 'google_places',
      });
      setState(() {
        _success = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Feil ved lagring: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return _buildSuccess();
    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1B1B),
        title: const Text('Admin — Registrer bedrift',
            style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Søk bedrift på Google',
                style: TextStyle(
                    color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GooglePlaceAutoCompleteTextField(
              textEditingController: _searchController,
              googleAPIKey: _apiKey,
              inputDecoration: InputDecoration(
                hintText: 'F.eks. Addis Kitchen Oslo...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: const Color(0xFF20201F),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              debounceTime: 400,
              countries: const [],
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (Prediction prediction) {
                setState(() {
                  _name = prediction.description?.split(',').first ?? '';
                  _address = prediction.description ?? '';
                  _lat = double.tryParse(prediction.lat ?? '0') ?? 0;
                  _lng = double.tryParse(prediction.lng ?? '0') ?? 0;
                  _searchController.text = _name;
                });
              },
              itemClick: (Prediction prediction) {
                _searchController.text = prediction.description ?? '';
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _searchController.text.length),
                );
              },
              seperatedBuilder: const Divider(color: Colors.white12),
              containerHorizontalPadding: 10,
              itemBuilder: (context, index, Prediction prediction) {
                return Container(
                  color: const Color(0xFF20201F),
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    const Icon(Icons.location_on,
                        color: Color(0xFFD4AF37), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(prediction.description ?? '',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ),
                  ]),
                );
              },
              isCrossBtnShown: true,
              textStyle: const TextStyle(color: Colors.white),
            ),
            if (_name.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF20201F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.check_circle,
                          color: Color(0xFFD4AF37), size: 18),
                      SizedBox(width: 8),
                      Text('Hentet fra Google',
                          style: TextStyle(
                              color: Color(0xFFD4AF37), fontSize: 12)),
                    ]),
                    const SizedBox(height: 8),
                    Text(_name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(_address,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13)),
                    if (_lat != 0) ...[
                      const SizedBox(height: 4),
                      Text(
                          'GPS: ${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11)),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            const Text('Kategori',
                style: TextStyle(
                    color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF20201F),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                            color: selected ? Colors.black : Colors.white,
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Beskrivelse',
                style: TextStyle(
                    color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              onChanged: (v) => setState(() => _description = v),
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Kort beskrivelse av bedriften...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: const Color(0xFF20201F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              const Text('Premium bedrift',
                  style: TextStyle(
                      color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
              const Spacer(),
              Switch(
                value: _isPremium,
                onChanged: (v) => setState(() => _isPremium = v),
                activeThumbColor: const Color(0xFFD4AF37),
              ),
            ]),
            Row(children: [
              const Text('Åpen nå',
                  style: TextStyle(
                      color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
              const Spacer(),
              Switch(
                value: _isOpen,
                onChanged: (v) => setState(() => _isOpen = v),
                activeThumbColor: const Color(0xFFD4AF37),
              ),
            ]),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_error,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBusiness,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Lagre bedrift',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 80),
          const SizedBox(height: 20),
          const Text('Bedrift registrert!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$_name er nå tilgjengelig for brukere.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 14)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() {
              _success = false;
              _name = '';
              _address = '';
              _lat = 0;
              _lng = 0;
              _description = '';
              _searchController.clear();
            }),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000)),
            child: const Text('Registrer en til',
                style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tilbake',
                style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ]),
      ),
    );
  }
}
