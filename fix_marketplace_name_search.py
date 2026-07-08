with open('lib/screens/marketplace_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add search state
old = "  String _cityFilter = '';\n  bool _locating = false;\n  final _citySearchCtrl = TextEditingController();"
new = "  String _cityFilter = '';\n  String _nameFilter = '';\n  bool _locating = false;\n  final _citySearchCtrl = TextEditingController();\n  final _nameSearchCtrl = TextEditingController();"

if old in content:
    content = content.replace(old, new)
    print("✅ Name filter state added")
else:
    print("❌ State not found")

# Add name search bar after city search bar
old2 = """            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,"""

new2 = """            // Name search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                    suffixIcon: _nameFilter.isNotEmpty
                        ? GestureDetector(onTap: () { _nameSearchCtrl.clear(); setState(() => _nameFilter = ''); }, child: const Icon(Icons.clear_rounded, color: kOnSurfaceVariant, size: 16))
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,"""

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ Name search bar added")
else:
    print("❌ Category filter pattern not found")

# Add name filter to listings
old3 = """                  if (_cityFilter.isNotEmpty) {
                    docs = docs.where((d) => ((d.data() as Map)['city'] ?? '').toString().toLowerCase().contains(_cityFilter)).toList();
                  }"""

new3 = """                  if (_cityFilter.isNotEmpty) {
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
    print("✅ Name filter applied")
else:
    print("❌ Filter pattern not found")

with open('lib/screens/marketplace_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
