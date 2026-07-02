with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix category list to English keys
old1 = "children: ['All', 'Restaurant', 'Cafe', 'Shop', 'Barber', 'Club', 'Clinic', 'Photographer', 'Music', 'Dekorasjon', 'Taxi', 'Annet'].map((cat) {"
new1 = "children: ['All', 'Restaurant', 'Cafe', 'Shop', 'Barber', 'Club', 'Clinic', 'Photographer', 'Music', 'Decoration', 'Taxi', 'Other'].map((cat) {"

if old1 in content:
    content = content.replace(old1, new1)
    print("✅ Category list fixed")
else:
    print("❌ Category list not found")

# Fix display text to use translations
old2 = "                        child: Text(cat, style: tsLabel(color: sel ? const Color(0xFF342800) : kOnSurfaceVariant)),"
new2 = """                        child: Text(_explorecat(cat), style: tsLabel(color: sel ? const Color(0xFF342800) : kOnSurfaceVariant)),"""

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ Display text fixed")
else:
    print("❌ Display text not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
