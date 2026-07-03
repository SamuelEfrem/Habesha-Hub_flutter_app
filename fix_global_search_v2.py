with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "                  onChanged: (v) { setState(() => _searchQuery = v); if (_hasSearched) _filterResults(); },"
new = "                  onChanged: (v) { setState(() => _searchQuery = v); if (_hasSearched) _filterResults(); },\n                  onSubmitted: (v) => _globalSearch(v),"

if old in content:
    content = content.replace(old, new)
    print("✅ onSubmitted added")
else:
    print("❌ Not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
