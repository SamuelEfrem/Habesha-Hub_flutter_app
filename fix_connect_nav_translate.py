with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    'connect_title': {"
new = """    'connect': {
      'Norsk': 'Koble til',
      'Tigrinya': 'ተራኸብ',
      'English': 'Connect',
      'Amharic': 'ተገናኝ'
    },
    'connect_title': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Connect nav translation added")
else:
    print("❌ Not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
