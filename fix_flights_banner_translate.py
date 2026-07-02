with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """                          Text('Find Cheap Flights', style: tsTitleMd(color: Colors.white)),
                          Text('Search flights worldwide', style: tsBodySm(color: Colors.white70)),"""

new = """                          Text(t('flights_title'), style: tsTitleMd(color: Colors.white)),
                          Text(t('flights_subtitle'), style: tsBodySm(color: Colors.white70)),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Banner text translated")
else:
    print("❌ Pattern not found")

# Also fix Search button
old2 = "                          child: Text('Search', style: tsLabel(color: Colors.white)),"
new2 = "                          child: Text(t('flights_search'), style: tsLabel(color: Colors.white)),"

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ Search button translated")
else:
    print("❌ Search button not found")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
