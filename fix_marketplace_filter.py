with open('lib/screens/marketplace_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """                  if (_selectedCategory != 'All') {
                    docs = docs.where((d) => (d.data() as Map)['category'] == _selectedCategory).toList();
                  }"""

new = """                  if (_selectedCategory != 'All') {
                    docs = docs.where((d) => (d.data() as Map)['category'] == _selectedCategory).toList();
                  }
                  if (_cityFilter.isNotEmpty) {
                    docs = docs.where((d) => ((d.data() as Map)['city'] ?? '').toString().toLowerCase().contains(_cityFilter)).toList();
                  }"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed")
else:
    print("❌ Not found - searching...")
    idx = content.find("_selectedCategory != 'All'")
    print(repr(content[idx-10:idx+150]))

with open('lib/screens/marketplace_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
