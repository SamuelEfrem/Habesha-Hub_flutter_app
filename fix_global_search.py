with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add global search method to ExploreScreen
old = """  String _explorecat(String key) {"""

new = """  Future<void> _globalSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isSearching = true; _hasSearched = false; });
    try {
      final snap = await _db.collection('businesses')
          .where('status', isEqualTo: 'approved')
          .get();
      final all = snap.docs.map((d) => Business.fromFirestore(d.data(), d.id)).toList();
      final filtered = all.where((b) =>
        b.name.toLowerCase().contains(query.toLowerCase()) ||
        b.category.toLowerCase().contains(query.toLowerCase()) ||
        b.address.toLowerCase().contains(query.toLowerCase()) ||
        b.country.toLowerCase().contains(query.toLowerCase())
      ).toList();
      setState(() {
        _allResults = filtered;
        _results = filtered;
        _isSearching = false;
        _hasSearched = true;
        _selectedCountry = '';
        _selectedCity = '';
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  String _explorecat(String key) {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Global search method added")
else:
    print("❌ Pattern not found")

# Now add a global search bar at the top of ExploreScreen
old2 = """              // Category filter"""

new2 = """              // Global search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.2), width: 0.5)),
                  child: TextField(
                    style: tsBodyLg(color: kOnSurface),
                    onSubmitted: (v) => _globalSearch(v),
                    decoration: InputDecoration(
                      hintText: t('search_hint'),
                      filled: false,
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search_rounded, color: kSecondary, size: 20),
                      suffixIcon: GestureDetector(
                        onTap: () {},
                        child: const Icon(Icons.tune_rounded, color: kSecondary, size: 20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              // Category filter"""

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ Global search bar added to UI")
else:
    print("❌ Category filter pattern not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
