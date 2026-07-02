with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    'route_oslo_addis': {"
new = """    'travel_help_title': {
      'Norsk': 'Reisehjelp',
      'Tigrinya': 'ሓገዝ ጉዕዞ',
      'English': 'Travel Assistance',
      'Amharic': 'የጉዞ እርዳታ'
    },
    'travel_help_header': {
      'Norsk': 'Habesha Reisehjelp',
      'Tigrinya': 'ሓገዝ ጉዕዞ ሃበሻ',
      'English': 'Habesha Travel Help',
      'Amharic': 'የሃበሻ የጉዞ እርዳታ'
    },
    'travel_help_desc': {
      'Norsk': 'Vi hjelper deg med fly, visum og overnatting.',
      'Tigrinya': 'ናብ ነፈርቲ፡ ቪዛን ምሕዳርን ንሕግዘካ።',
      'English': 'We help you book flights, get visa, and find accommodation.',
      'Amharic': 'ትኬት፣ ቪዛ እና መኝታ ቤት ለማግኘት እንረዳዎታለን።'
    },
    'travel_what_help': {
      'Norsk': 'Hva trenger du hjelp med?',
      'Tigrinya': 'ብምንታይ ሓገዝ ትደሊ?',
      'English': 'What do you need help with?',
      'Amharic': 'ምን እርዳታ ይፈልጋሉ?'
    },
    'travel_flight_title': {
      'Norsk': 'Flybestilling',
      'Tigrinya': 'ምትእዛዝ ነፈርቲ',
      'English': 'Flight Booking',
      'Amharic': 'የበረራ ቦታ ማስያዝ'
    },
    'travel_flight_desc': {
      'Norsk': 'Vi bestiller flyet for deg + 300 NOK serviceavgift',
      'Tigrinya': 'ነፈርቲ ንትእዝዘልካ + 300 NOK ክፍሊት',
      'English': 'We book your flight + service fee 300 NOK',
      'Amharic': 'ትኬቱን እናስያዝን + 300 NOK የአገልግሎት ክፍያ'
    },
    'travel_visa_title': {
      'Norsk': 'Visumhjelp',
      'Tigrinya': 'ሓገዝ ቪዛ',
      'English': 'Visa Assistance',
      'Amharic': 'የቪዛ እርዳታ'
    },
    'travel_visa_desc': {
      'Norsk': 'Hjelp med visumsøknad til Etiopia/Uganda',
      'Tigrinya': 'ሓገዝ ናብ ቪዛ ናብ ኢትዮጵያ/ኡጋንዳ',
      'English': 'Help with visa application to Ethiopia/Uganda',
      'Amharic': 'ወደ ኢትዮጵያ/ዩጋንዳ ቪዛ ማውጣት እርዳታ'
    },
    'travel_package_title': {
      'Norsk': 'Fly + Visum Pakke',
      'Tigrinya': 'ነፈርቲ + ቪዛ ፓኬጅ',
      'English': 'Flight + Visa Package',
      'Amharic': 'ትኬት + ቪዛ ጥቅል'
    },
    'travel_package_desc': {
      'Norsk': 'Komplett reisepakke — beste verdi',
      'Tigrinya': 'ምሉእ ጥቅሊ ጉዕዞ — ዝበለጸ ክብሪ',
      'English': 'Complete travel package — best value',
      'Amharic': 'ሙሉ የጉዞ ጥቅል — ምርጥ ዋጋ'
    },
    'travel_hotel_title': {
      'Norsk': 'Overnatting',
      'Tigrinya': 'ምሕዳር',
      'English': 'Accommodation Help',
      'Amharic': 'የመኝታ እርዳታ'
    },
    'travel_hotel_desc': {
      'Norsk': 'Finn Habesha hoteller/hostels på destinasjonen',
      'Tigrinya': 'ሃበሻ ሆቴላት/ሆስቴላት ኣብ ዕላማ ርኸብ',
      'English': 'Find Habesha hotels/hostels at destination',
      'Amharic': 'በመዳረሻ ሃበሻ ሆቴሎችን/ሆስቴሎችን ፈልግ'
    },
    'travel_contact': {
      'Norsk': 'Dine kontaktdetaljer',
      'Tigrinya': 'ናይ ርክብ ሓበሬታኻ',
      'English': 'Your Contact Details',
      'Amharic': 'የእርስዎ የመገናኛ ዝርዝሮች'
    },
    'travel_send': {
      'Norsk': 'Send forespørsel',
      'Tigrinya': 'ሕቶ ሰዳ',
      'English': 'Send Request',
      'Amharic': 'ጥያቄ ላክ'
    },
    'travel_success': {
      'Norsk': 'Forespørsel sendt!',
      'Tigrinya': 'ሕቶ ተሰዲዱ!',
      'English': 'Request Sent!',
      'Amharic': 'ጥያቄ ተልኳል!'
    },
    'travel_success_desc': {
      'Norsk': 'Vi kontakter deg innen 24 timer.',
      'Tigrinya': 'ኣብ ውሽጢ 24 ሰዓት ክንረኽበካ ኢና።',
      'English': 'We will contact you within 24 hours.',
      'Amharic': 'በ24 ሰዓት ውስጥ እናናግርዎታለን።'
    },
    'travel_help_btn': {
      'Norsk': 'Trenger du hjelp med bestilling? Kontakt oss',
      'Tigrinya': 'ሓገዝ ምትእዛዝ ትደሊ? ተወከሰና',
      'English': 'Need help booking? Contact us',
      'Amharic': 'እርዳታ ይፈልጋሉ? ያግኙን'
    },
    'route_oslo_addis': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Travel help translations added")
else:
    print("❌ Pattern not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
