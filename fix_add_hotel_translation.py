with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    'cat_photographer': {"
new = """    'cat_hotel': {
      'Norsk': 'Hotell/Hostel',
      'Tigrinya': 'ሆቴል/ሆስቴል',
      'English': 'Hotel/Hostel',
      'Amharic': 'ሆቴል/ሆስቴል'
    },
    'cat_photographer': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Hotel translation added")
else:
    print("❌ Pattern not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
