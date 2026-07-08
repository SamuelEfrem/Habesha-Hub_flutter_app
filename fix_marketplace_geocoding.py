# Add marketplace_search_city translation
with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    'marketplace_edit': {"
new = """    'marketplace_search_city': {
      'Norsk': 'Søk etter by...',
      'Tigrinya': 'ከተማ ድለ...',
      'English': 'Search by city...',
      'Amharic': 'በከተማ ፈልግ...'
    },
    'marketplace_edit': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Translation added")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# Check if geocoding is in pubspec
with open('pubspec.yaml', 'r') as f:
    pubspec = f.read()

if 'geocoding' not in pubspec:
    print("⚠️ geocoding not in pubspec.yaml - needs to be added")
    print("Add this to dependencies: geocoding: ^3.0.0")
else:
    print("✅ geocoding already in pubspec")
print("Done!")
