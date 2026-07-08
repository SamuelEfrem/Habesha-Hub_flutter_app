with open('lib/screens/marketplace_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add state variables
old = "  String _selectedCategory = 'All';"
new = """  String _selectedCategory = 'All';
  String _cityFilter = '';
  String _nameFilter = '';
  bool _locating = false;
  final _citySearchCtrl = TextEditingController();
  final _nameSearchCtrl = TextEditingController();"""

if old in content:
    content = content.replace(old, new)
    print("✅ State variables added")
else:
    print("❌ State not found")

# Add search bars before category filter
old2 = """            const SizedBox(height: 12),
            SizedBox(
              height: 44,"""

new2 = """            // Name search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                height: 42,
                decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.2))),
                child: TextField(
                  controller: _nameSearchCtrl,
                  style: tsBodyLg(color: kOnSurface),
                  onChanged: (v) => setState(() => _nameFilter = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: t('marketplace_search_name'),
                    filled: false,
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search_rounded, color: kSecondary, size: 18),
                    suffixIcon: _nameFilter.isNotEmpty ? GestureDetector(onTap: () { _nameSearchCtrl.clear(); setState(() => _nameFilter = ''); }, child: const Icon(Icons.clear_rounded, color: kOnSurfaceVariant, size: 16)) : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            // City search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.2))),
                    child: TextField(
                      controller: _citySearchCtrl,
                      style: tsBodyLg(color: kOnSurface),
                      onChanged: (v) => setState(() => _cityFilter = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: t('marketplace_search_city'),
                        filled: false,
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.location_on_rounded, color: kSecondary, size: 18),
                        suffixIcon: _cityFilter.isNotEmpty ? GestureDetector(onTap: () { _citySearchCtrl.clear(); setState(() => _cityFilter = ''); }, child: const Icon(Icons.clear_rounded, color: kOnSurfaceVariant, size: 16)) : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _locating ? null : () async {
                    setState(() => _locating = true);
                    try {
                      bool enabled = await Geolocator.isLocationServiceEnabled();
                      if (!enabled) { setState(() => _locating = false); return; }
                      LocationPermission perm = await Geolocator.checkPermission();
                      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
                      if (perm == LocationPermission.denied) { setState(() => _locating = false); return; }
                      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
                      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
                      if (placemarks.isNotEmpty) {
                        final city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? '';
                        _citySearchCtrl.text = city;
                        setState(() { _cityFilter = city.toLowerCase(); _locating = false; });
                      }
                    } catch (e) { setState(() => _locating = false); }
                  },
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(12)),
                    child: _locating
                        ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Color(0xFF1A1200), strokeWidth: 2))
                        : const Icon(Icons.my_location_rounded, color: Color(0xFF1A1200), size: 20),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 12),
            SizedBox(
              height: 44,"""

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ Search bars added")
else:
    print("❌ Category filter not found")

# Add filters to StreamBuilder
old3 = """                  if (_selectedCategory != 'All') {
                    docs = docs.where((d) => (d.data() as Map)['category'] == _selectedCategory).toList();
                  }"""

new3 = """                  if (_selectedCategory != 'All') {
                    docs = docs.where((d) => (d.data() as Map)['category'] == _selectedCategory).toList();
                  }
                  if (_cityFilter.isNotEmpty) {
                    docs = docs.where((d) => ((d.data() as Map)['city'] ?? '').toString().toLowerCase().contains(_cityFilter)).toList();
                  }
                  if (_nameFilter.isNotEmpty) {
                    docs = docs.where((d) {
                      final data = d.data() as Map;
                      final title = (data['title'] ?? '').toString().toLowerCase();
                      final desc = (data['description'] ?? '').toString().toLowerCase();
                      return title.contains(_nameFilter) || desc.contains(_nameFilter);
                    }).toList();
                  }"""

if old3 in content:
    content = content.replace(old3, new3)
    print("✅ Filters applied")
else:
    print("❌ Filter not found")

# Add imports
if 'geolocator' not in content:
    content = content.replace(
        "import 'dart:io';",
        "import 'dart:io';\nimport 'package:geolocator/geolocator.dart';\nimport 'package:geocoding/geocoding.dart';"
    )
    print("✅ Imports added")

with open('lib/screens/marketplace_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
