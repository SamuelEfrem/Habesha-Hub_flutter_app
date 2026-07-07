with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    'connect_title': {"
new = """    'connect_education': {
      'Norsk': 'Utdanning',
      'Tigrinya': 'ትምህርቲ',
      'English': 'Education',
      'Amharic': 'ትምህርት'
    },
    'connect_you': {
      'Norsk': 'Deg',
      'Tigrinya': 'ንስኻ',
      'English': 'You',
      'Amharic': 'አንተ'
    },
    'connect_create_profile': {
      'Norsk': 'Lag Connect-profil',
      'Tigrinya': 'ፕሮፋይል ፍጠር',
      'English': 'Create Connect Profile',
      'Amharic': 'መገለጫ ፍጠር'
    },
    'connect_edit_profile': {
      'Norsk': 'Rediger profil',
      'Tigrinya': 'ፕሮፋይል ኣርም',
      'English': 'Edit Profile',
      'Amharic': 'መገለጫ አርም'
    },
    'connect_name': {
      'Norsk': 'NAVN',
      'Tigrinya': 'ስም',
      'English': 'NAME',
      'Amharic': 'ስም'
    },
    'connect_name_hint': {
      'Norsk': 'Ditt navn',
      'Tigrinya': 'ስምካ',
      'English': 'Your name',
      'Amharic': 'ስምህ'
    },
    'connect_city': {
      'Norsk': 'BY',
      'Tigrinya': 'ከተማ',
      'English': 'CITY',
      'Amharic': 'ከተማ'
    },
    'connect_bio': {
      'Norsk': 'BIO / FERDIGHETER',
      'Tigrinya': 'ብዛዕባኻ',
      'English': 'BIO / SKILLS',
      'Amharic': 'ስለራስህ'
    },
    'connect_bio_hint': {
      'Norsk': 'Fortell om deg selv og hva du kan tilby...',
      'Tigrinya': 'ብዛዕባኻን እንታይ ክትብጽሕ ትኽእልን ንገር...',
      'English': 'Tell people about yourself and what you can offer...',
      'Amharic': 'ስለራስህ እና ምን ማقdinat እንደምትችל ንገር...'
    },
    'connect_interests': {
      'Norsk': 'INTERESSER',
      'Tigrinya': 'ዝፈትዎ',
      'English': 'INTERESTS',
      'Amharic': 'ፍላጎቶች'
    },
    'connect_save': {
      'Norsk': 'Lagre profil',
      'Tigrinya': 'ፕሮፋይል ሓዝ',
      'English': 'Save Profile',
      'Amharic': 'መገለጫ አስቀምጥ'
    },
    'connect_title': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Connect translations added")
else:
    print("❌ Pattern not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
