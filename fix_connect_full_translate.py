# Add missing translations
with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    'connect_save': {"
new = """    'connect_messages': {
      'Norsk': 'Meldinger',
      'Tigrinya': 'መልእኽትታት',
      'English': 'Connect Messages',
      'Amharic': 'መልዕክቶች'
    },
    'connect_no_messages': {
      'Norsk': 'Ingen meldinger ennå',
      'Tigrinya': 'ገና መልእኽቲ የለን',
      'English': 'No messages yet',
      'Amharic': 'እስካሁን መልዕክት የለም'
    },
    'connect_it': {
      'Norsk': 'IT',
      'Tigrinya': 'ቴክኖሎጂ',
      'English': 'IT',
      'Amharic': 'ቴክኖሎጂ'
    },
    'connect_health': {
      'Norsk': 'Helse',
      'Tigrinya': 'ጥዕና',
      'English': 'Health',
      'Amharic': 'ጤና'
    },
    'connect_save': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Added connect translations")
else:
    print("❌ Not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
