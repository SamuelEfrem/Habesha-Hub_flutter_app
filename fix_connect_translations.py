with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    'cat_hotel': {"
new = """    'connect_title': {
      'Norsk': 'Koble til',
      'Tigrinya': 'ተራኸብ',
      'English': 'Connect',
      'Amharic': 'ተገናኝ'
    },
    'connect_subtitle': {
      'Norsk': 'Finn folk med samme interesser',
      'Tigrinya': 'ብሓባር ዝሰርሑ ሰባት ርኸብ',
      'English': 'Find people with same interests',
      'Amharic': 'ተመሳሳይ ፍላጎት ያላቸውን ሰዎች ፈልግ'
    },
    'connect_my_profile': {
      'Norsk': 'Min profil',
      'Tigrinya': 'ፕሮፋይለይ',
      'English': 'My Profile',
      'Amharic': 'የእኔ መገለጫ'
    },
    'connect_no_profiles': {
      'Norsk': 'Ingen profiler ennå',
      'Tigrinya': 'ገና ፕሮፋይላት የለን',
      'English': 'No profiles yet',
      'Amharic': 'እስካሁን መገለጫ የለም'
    },
    'connect_be_first': {
      'Norsk': 'Vær den første til å lage en profil!',
      'Tigrinya': 'ቀዳማይ ፕሮፋይል ፍጠር!',
      'English': 'Be the first to create a profile!',
      'Amharic': 'የመጀመሪያ መገለጫ ፍጠር!'
    },
    'connect_message': {
      'Norsk': 'Melding',
      'Tigrinya': 'መልእኽቲ',
      'English': 'Message',
      'Amharic': 'መልዕክት'
    },
    'cat_hotel': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Connect translations added")
else:
    print("❌ Pattern not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
