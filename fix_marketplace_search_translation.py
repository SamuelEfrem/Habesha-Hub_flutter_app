with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    'marketplace_search_city': {"
new = """    'marketplace_search_name': {
      'Norsk': 'Søk etter produkt...',
      'Tigrinya': 'ቦርዳ፡ ዓቕሚ... ድለ',
      'English': 'Search for product...',
      'Amharic': 'ምርት ፈልግ...'
    },
    'marketplace_search_city': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Name search translation added")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
