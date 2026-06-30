with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """    'other': {"""

new = """    'cat_photographer': {
      'Norsk': 'Fotograf',
      'Tigrinya': 'ፎቶግራፈር',
      'English': 'Photographer',
      'Amharic': 'ፎቶግራፈር'
    },
    'cat_music': {
      'Norsk': 'Musikk',
      'Tigrinya': 'ሙዚቃ',
      'English': 'Music',
      'Amharic': 'ሙዚቃ'
    },
    'cat_decoration': {
      'Norsk': 'Dekorasjon',
      'Tigrinya': 'ጌጥ',
      'English': 'Decoration',
      'Amharic': 'ጌጣጌጥ'
    },
    'cat_taxi': {
      'Norsk': 'Taxi',
      'Tigrinya': 'ታክሲ',
      'English': 'Taxi',
      'Amharic': 'ታክሲ'
    },
    'other': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Category translations added")
else:
    print("❌ Pattern not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
