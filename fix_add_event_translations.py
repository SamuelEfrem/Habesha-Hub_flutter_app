with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    'cat_photographer': {"
new = """    'cat_wedding': {
      'Norsk': 'Bryllup',
      'Tigrinya': 'ሰርሐ ሰሚዐ',
      'English': 'Wedding',
      'Amharic': 'ሰርግ'
    },
    'cat_food': {
      'Norsk': 'Mat',
      'Tigrinya': 'መግቢ',
      'English': 'Food',
      'Amharic': 'ምግብ'
    },
    'cat_culture': {
      'Norsk': 'Kultur',
      'Tigrinya': 'ባህሊ',
      'English': 'Culture',
      'Amharic': 'ባህል'
    },
    'cat_business': {
      'Norsk': 'Business',
      'Tigrinya': 'ቢዝነስ',
      'English': 'Business',
      'Amharic': 'ቢዝነስ'
    },
    'cat_sport': {
      'Norsk': 'Sport',
      'Tigrinya': 'ስፖርት',
      'English': 'Sport',
      'Amharic': 'ስፖርት'
    },
    'cat_job': {
      'Norsk': 'Jobb',
      'Tigrinya': 'ስራሕ',
      'English': 'Job',
      'Amharic': 'ሥራ'
    },
    'cat_general': {
      'Norsk': 'Generelt',
      'Tigrinya': 'ሓፈሻዊ',
      'English': 'General',
      'Amharic': 'አጠቃላይ'
    },
    'cat_tips': {
      'Norsk': 'Tips',
      'Tigrinya': 'ምኽሪ',
      'English': 'Tips',
      'Amharic': 'ምክር'
    },
    'cat_photographer': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Event/forum translations added")
else:
    print("❌ Pattern not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
