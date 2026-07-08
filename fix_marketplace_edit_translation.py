with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    'marketplace_add': {"
new = """    'marketplace_edit': {
      'Norsk': 'Rediger annonse',
      'Tigrinya': 'ኣዊጅ ኣርም',
      'English': 'Edit Listing',
      'Amharic': 'ማስታወቂያ አርም'
    },
    'marketplace_add': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Edit translation added")
else:
    print("❌ Not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
