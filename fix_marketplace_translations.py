with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    'connect_messages': {"
new = """    'marketplace_title': {
      'Norsk': 'Marked',
      'Tigrinya': 'ዕዳጋ',
      'English': 'Marketplace',
      'Amharic': 'ገበያ'
    },
    'marketplace_subtitle': {
      'Norsk': 'Kjøp og selg brukte ting',
      'Tigrinya': 'ዝተጠቕሙ ኣቓሑ ሸሙ ወይ ግዙ',
      'English': 'Buy and sell second-hand items',
      'Amharic': 'የሁለተኛ ዕቃዎችን ይሸጡ ወይ ይግዙ'
    },
    'marketplace_browse': {
      'Norsk': 'Utforsk',
      'Tigrinya': 'ፈልጥ',
      'English': 'Browse',
      'Amharic': 'ዳስስ'
    },
    'marketplace_sell': {
      'Norsk': 'Selg',
      'Tigrinya': 'ሸይጥ',
      'English': 'Sell',
      'Amharic': 'ሸጥ'
    },
    'marketplace_add': {
      'Norsk': 'Legg ut annonse',
      'Tigrinya': 'ኣዊጅ ወጻ',
      'English': 'Add Listing',
      'Amharic': 'ማስታወቂያ ጨምር'
    },
    'marketplace_empty': {
      'Norsk': 'Ingen annonser ennå',
      'Tigrinya': 'ገና ኣዊጅ የለን',
      'English': 'No listings yet',
      'Amharic': 'እስካሁን ማስታወቂያ የለም'
    },
    'marketplace_be_first': {
      'Norsk': 'Vær den første til å selge noe!',
      'Tigrinya': 'ቀዳማይ ሸያጢ ኹን!',
      'English': 'Be the first to sell something!',
      'Amharic': 'የመጀመሪያው ሻጭ ሁን!'
    },
    'marketplace_add_photo': {
      'Norsk': 'Legg til bilde',
      'Tigrinya': 'ስእሊ ወስኽ',
      'English': 'Add photo',
      'Amharic': 'ፎቶ ጨምር'
    },
    'marketplace_title_field': {
      'Norsk': 'TITTEL',
      'Tigrinya': 'ኣርእስቲ',
      'English': 'TITLE',
      'Amharic': 'ርዕስ'
    },
    'marketplace_title_hint': {
      'Norsk': 'f.eks. iPhone 12, sofa...',
      'Tigrinya': 'ንጠቢ iPhone 12, መቐመጢ...',
      'English': 'e.g. iPhone 12, sofa...',
      'Amharic': 'ለምሳሌ iPhone 12, ሶፋ...'
    },
    'marketplace_price': {
      'Norsk': 'PRIS',
      'Tigrinya': 'ዋጋ',
      'English': 'PRICE',
      'Amharic': 'ዋጋ'
    },
    'marketplace_desc': {
      'Norsk': 'BESKRIVELSE',
      'Tigrinya': 'መግለጺ',
      'English': 'DESCRIPTION',
      'Amharic': 'መግለጫ'
    },
    'marketplace_desc_hint': {
      'Norsk': 'Beskriv gjenstanden...',
      'Tigrinya': 'ነቲ ኣቓሕ ግለጸሉ...',
      'English': 'Describe the item...',
      'Amharic': 'ዕቃውን ግለጽ...'
    },
    'marketplace_publish': {
      'Norsk': 'Publiser annonse',
      'Tigrinya': 'ኣዊጅ ኣውጽእ',
      'English': 'Publish Listing',
      'Amharic': 'ማስታወቂያ አሳትም'
    },
    'market_all': {
      'Norsk': 'Alle',
      'Tigrinya': 'ኩሉ',
      'English': 'All',
      'Amharic': 'ሁሉ'
    },
    'market_clothes': {
      'Norsk': 'Klær',
      'Tigrinya': 'ክዳን',
      'English': 'Clothes',
      'Amharic': 'ልብስ'
    },
    'market_electronics': {
      'Norsk': 'Elektronikk',
      'Tigrinya': 'ኤሌክትሮኒክስ',
      'English': 'Electronics',
      'Amharic': 'ኤሌክትሮኒክስ'
    },
    'market_furniture': {
      'Norsk': 'Møbler',
      'Tigrinya': 'ኣቑሑ ቤት',
      'English': 'Furniture',
      'Amharic': 'የቤት እቃዎች'
    },
    'market_food': {
      'Norsk': 'Mat',
      'Tigrinya': 'መግቢ',
      'English': 'Food',
      'Amharic': 'ምግብ'
    },
    'market_books': {
      'Norsk': 'Bøker',
      'Tigrinya': 'መጻሕፍቲ',
      'English': 'Books',
      'Amharic': 'መጻሕፍት'
    },
    'market_other': {
      'Norsk': 'Annet',
      'Tigrinya': 'ካልእ',
      'English': 'Other',
      'Amharic': 'ሌላ'
    },
    'connect_messages': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Marketplace translations added")
else:
    print("❌ Not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
