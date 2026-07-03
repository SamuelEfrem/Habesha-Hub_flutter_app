# Add booking translations
with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    'cat_hotel': {"
new = """    'favorites_title': {
      'Norsk': 'Mine favoritter',
      'Tigrinya': 'ዝፈትዎም ትካላት',
      'English': 'My Favorites',
      'Amharic': 'የምወዳቸው'
    },
    'hotel_booking': {
      'Norsk': 'Hotellbestilling',
      'Tigrinya': 'ቡኪንግ ሆቴል',
      'English': 'Hotel Booking',
      'Amharic': 'የሆቴል ቦታ ማስያዝ'
    },
    'check_in': {
      'Norsk': 'INNSJEKK',
      'Tigrinya': 'ምእታው',
      'English': 'CHECK-IN',
      'Amharic': 'መግቢያ'
    },
    'check_out': {
      'Norsk': 'UTSJEKK',
      'Tigrinya': 'ምውጻእ',
      'English': 'CHECK-OUT',
      'Amharic': 'መውጫ'
    },
    'guests': {
      'Norsk': 'GJESTER',
      'Tigrinya': 'እንግዶት',
      'English': 'GUESTS',
      'Amharic': 'እንግዶች'
    },
    'special_requests': {
      'Norsk': 'MELDING (valgfritt)',
      'Tigrinya': 'መልእኽቲ (ምርጫ)',
      'English': 'MESSAGE (optional)',
      'Amharic': 'መልዕክት (አማራጭ)'
    },
    'send_booking': {
      'Norsk': 'Send bookingforespørsel',
      'Tigrinya': 'ሕቶ ቡኪንግ ስደድ',
      'English': 'Send Booking Request',
      'Amharic': 'የቦታ ማስያዝ ጥያቄ ላክ'
    },
    'booking_sent': {
      'Norsk': 'Forespørsel sendt!',
      'Tigrinya': 'ሕቶ ተሰዲዱ!',
      'English': 'Booking request sent!',
      'Amharic': 'ጥያቄ ተልኳል!'
    },
    'host_contact': {
      'Norsk': 'Verten kontakter deg snart.',
      'Tigrinya': 'ወናኒ ቀልጢፉ ክረኽበካ እዩ።',
      'English': 'The host will contact you soon.',
      'Amharic': 'አስተናጋጁ በቅርቡ ያናግርዎታል።'
    },
    'go_back': {
      'Norsk': 'Gå tilbake',
      'Tigrinya': 'ንኡድ',
      'English': 'Go back',
      'Amharic': 'ተመለስ'
    },
    'nights': {
      'Norsk': 'netter',
      'Tigrinya': 'ለይቲ',
      'English': 'nights',
      'Amharic': 'ምሽቶች'
    },
    'night': {
      'Norsk': 'natt',
      'Tigrinya': 'ለይቲ',
      'English': 'night',
      'Amharic': 'ምሽት'
    },
    'cat_hotel': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Booking/favorites translations added")
else:
    print("❌ Pattern not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
