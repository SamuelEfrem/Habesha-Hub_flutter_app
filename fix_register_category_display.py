with open('lib/screens/register_business_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """                  Text(cat['name'] as String,
                      style:
                          tsLabel(color: sel ? kSecondary : kOnSurfaceVariant)),"""

new = """                  Text(_catDisplayName(cat['name'] as String),
                      style:
                          tsLabel(color: sel ? kSecondary : kOnSurfaceVariant)),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Display text updated")
else:
    print("❌ Pattern not found")

# Add the helper function before _buildStep1 or similar
old2 = "  final _cats = [\n"
new2 = """  String _catDisplayName(String key) {
    const keyMap = {
      'Restaurant': 'restaurant',
      'Shop': 'shop',
      'Cafe': 'cafe',
      'Barber': 'barber',
      'Club': 'club',
      'Clinic': 'clinic',
      'Photographer': 'cat_photographer',
      'Music': 'cat_music',
      'Decoration': 'cat_decoration',
      'Taxi': 'cat_taxi',
      'Other': 'other',
    };
    final tKey = keyMap[key];
    if (tKey == null) return key;
    return languageNotifier.t(tKey);
  }
  final _cats = [
"""

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ Helper function added")
else:
    print("❌ _cats pattern not found")

with open('lib/screens/register_business_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
