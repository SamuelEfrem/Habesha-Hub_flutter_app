with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    'market_other': {"
new = """    'marketplace_city': {
      'Norsk': 'BY / STED',
      'Tigrinya': 'ከተማ / ቦታ',
      'English': 'CITY / LOCATION',
      'Amharic': 'ከተማ / ቦታ'
    },
    'market_other': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ City translation added")
else:
    print("❌ Not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
