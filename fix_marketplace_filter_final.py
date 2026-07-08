with open('lib/screens/marketplace_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find("_selectedCategory != 'All'")
end = content.find(".toList();", idx) + len(".toList();")
old = content[idx-18:end]
print("Found:", repr(old))

new = old + """
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

content = content[:idx-18] + new + content[end:]
print("✅ Filters added")

with open('lib/screens/marketplace_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
