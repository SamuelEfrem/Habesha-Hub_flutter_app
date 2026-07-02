# Check and fix forum_screen.dart
with open('lib/screens/forum_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

for search in ["== 'Alle'", "'Kultur'", "selectedCat", "'Generelt'", "'Bryllup'"]:
    idx = content.find(search)
    if idx >= 0:
        print(f"Found '{search}': " + repr(content[idx-10:idx+50]))

print("\n---fixing---")
content = content.replace("String _selectedCategory = 'Alle';", "String _selectedCategory = 'All';")
content = content.replace("_selectedCategory == cat['key']", "_selectedCategory == cat['key']")
content = content.replace("_selectedCategory != 'Alle'", "_selectedCategory != 'All'")
content = content.replace("c['key'] != 'Alle'", "c['key'] != 'All'")
content = content.replace("selectedCat = 'Generelt'", "selectedCat = 'General'")
content = content.replace("{'key': 'Alle',", "{'key': 'All',")
content = content.replace("{'key': 'Bryllup',", "{'key': 'Wedding',")
content = content.replace("{'key': 'Jobb',", "{'key': 'Job',")
content = content.replace("{'key': 'Mat',", "{'key': 'Food',")
content = content.replace("{'key': 'Generelt',", "{'key': 'General',")
content = content.replace("{'key': 'Tips',", "{'key': 'Tips',")

with open('lib/screens/forum_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
