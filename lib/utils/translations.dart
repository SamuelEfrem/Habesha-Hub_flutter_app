class AppTranslations {
  static String _language = 'English';

  static void setLanguage(String lang) {
    _language = lang;
  }

  static String get(String key) {
    return _translations[key]?[_language] ??
        _translations[key]?['English'] ??
        key;
  }

  static final Map<String, Map<String, String>> _translations = {
    // ── NAVIGASJON ─────────────────────────────────────
    'home': {
      'Norsk': 'Hjem',
      'Tigrinya': 'ገዛ',
      'English': 'Home',
      'Amharic': 'መነሻ'
    },
    'explore': {
      'Norsk': 'Utforsk',
      'Tigrinya': 'ዳህስስ',
      'English': 'Explore',
      'Amharic': 'ያስሱ'
    },
    'chat': {
      'Norsk': 'Meldinger',
      'Tigrinya': 'ዕላል',
      'English': 'Messages',
      'Amharic': 'መልዕክቶች'
    },
    'favorites': {
      'Norsk': 'Favoritter',
      'Tigrinya': 'ዝፈትዎም',
      'English': 'Favorites',
      'Amharic': 'ተወዳጆች'
    },
    'profile': {
      'Norsk': 'Profil',
      'Tigrinya': 'ፕሮፋይል',
      'English': 'Profile',
      'Amharic': 'መገለጫ'
    },

    // ── HJEM ──────────────────────────────────────────
    'find_here': {
      'Norsk': 'Finn her',
      'Tigrinya': 'ኣብዚ ድለ',
      'English': 'Find here',
      'Amharic': 'እዚህ ይፈልጉ'
    },
    'searching': {
      'Norsk': 'Søker...',
      'Tigrinya': 'ምንዳይ...',
      'English': 'Searching...',
      'Amharic': 'በመፈለግ ላይ...'
    },
    'search_nearby': {
      'Norsk': 'Søk i nærheten',
      'Tigrinya': 'ኣብዚ ተዊቕካ ኣብ ጥቃኻ ዘሎ ትካላት ርከብ',
      'English': 'Tap to search nearby',
      'Amharic': 'በአካባቢ ለመፈለግ ይጫኑ'
    },
    'businesses_found': {
      'Norsk': 'bedrifter funnet',
      'Tigrinya': 'ንግዳዊ ትካላት ተረኺቡ',
      'English': 'businesses found',
      'Amharic': 'ድርጅቶች ተገኝተዋል'
    },
    'search_hint': {
      'Norsk': 'Søk etter restaurant, frisør eller butikk...',
      'Tigrinya': 'ቤት መግቢ፡ መስተኻኸሊ ጸጕሪ ወይ ድኳን ድለ...',
      'English': 'Search for restaurant, barber or shop...',
      'Amharic': 'ምግብ ቤት፣ ፀጉር ቤት ወይም መደብር ይፈልጉ...'
    },
    'no_businesses': {
      'Norsk': 'Ingen bedrifter funnet',
      'Tigrinya': 'ዝተረኽቡ ትካላት የለዉን',
      'English': 'No businesses found',
      'Amharic': 'ምንም ድርጅት አልተገኘም'
    },
    'refresh': {
      'Norsk': 'Oppdater',
      'Tigrinya': 'ኣሐድስ',
      'English': 'Refresh',
      'Amharic': 'አድስ'
    },

    // ── KATEGORIER ───────────────────────────────────
    'all': {
      'Norsk': 'Alle',
      'Tigrinya': 'ኵሉ',
      'English': 'All',
      'Amharic': 'ሁሉም'
    },
    'restaurant': {
      'Norsk': 'Restaurant',
      'Tigrinya': 'ቤት ምግቢ',
      'English': 'Restaurant',
      'Amharic': 'ምግብ ቤት'
    },
    'shop': {
      'Norsk': 'Butikk',
      'Tigrinya': 'ዱኳን',
      'English': 'Shop',
      'Amharic': 'መደብር'
    },
    'cafe': {
      'Norsk': 'Kafé',
      'Tigrinya': 'ካፈ',
      'English': 'Café',
      'Amharic': 'ካፌ'
    },
    'barber': {
      'Norsk': 'Frisør',
      'Tigrinya': 'መስተኻኸሊ ጸጉሪ',
      'English': 'Barbery',
      'Amharic': 'ፀጉር ቤት'
    },
    'club': {
      'Norsk': 'Club',
      'Tigrinya': 'ክለብ',
      'English': 'Club',
      'Amharic': 'ክለብ'
    },
    'clinic': {
      'Norsk': 'Klinikk',
      'Tigrinya': 'ሕክምና',
      'English': 'Clinic',
      'Amharic': 'ክሊኒክ'
    },
    'other': {
      'Norsk': 'Annet',
      'Tigrinya': 'ካልእ',
      'English': 'Other',
      'Amharic': 'ሌላ'
    },

    // ── UTFORSK ──────────────────────────────────────
    'explore_title': {
      'Norsk': 'Utforsk',
      'Tigrinya': 'ዳህስስ',
      'English': 'Explore',
      'Amharic': 'ያስሱ'
    },
    'explore_desc': {
      'Norsk': 'Finn Habesha bedrifter i hele verden',
      'Tigrinya': 'ኣብ መላእ ዓለም ዚርከባ ትካላት ሓበሻ ርኸቡ',
      'English': 'Find Habesha businesses worldwide',
      'Amharic': 'በዓለም ዙሪያ የሃበሻ ድርጅቶችን ያግኙ'
    },
    'all_cities': {
      'Norsk': 'Alle byer',
      'Tigrinya': 'ኵለን ከተማታት',
      'English': 'All cities',
      'Amharic': 'ሁሉም ከተሞች'
    },
    'search_in': {
      'Norsk': 'Søk i',
      'Tigrinya': 'ኣብ ዝስዕብ ድለ',
      'English': 'Search in',
      'Amharic': 'ፈልግ በ'
    },
    'select_country': {
      'Norsk': 'Velg et land for å utforske',
      'Tigrinya': 'ክትድህስሶ እትደሊ ሃገር ምረጽ',
      'English': 'Select a country to explore',
      'Amharic': 'ለመፈለግ ሀገር ይምረጡ'
    },
    'no_businesses_country': {
      'Norsk': 'Ingen bedrifter i dette landet',
      'Tigrinya': 'ኣብዚ ሃገር እዚ ዋላ ሓንቲ ትካል የለን',
      'English': 'No businesses in this country',
      'Amharic': 'በዚህ ሀገር ምንም ድርጅት የለም'
    },

    // ── BEDRIFT-DETALJER ──────────────────────────────
    'info_tab': {
      'Norsk': 'INFO',
      'Tigrinya': 'ሓበሬታ',
      'English': 'INFO',
      'Amharic': 'መረጃ'
    },
    'chat_tab': {
      'Norsk': 'CHAT',
      'Tigrinya': 'ዕላል',
      'English': 'CHAT',
      'Amharic': 'ቻት'
    },
    'open_now': {
      'Norsk': 'ÅPEN NÅ',
      'Tigrinya': 'ሕጂ ኽፉት እዩ',
      'English': 'OPEN NOW',
      'Amharic': 'አሁን ክፍት ነው'
    },
    'closed': {
      'Norsk': 'STENGT',
      'Tigrinya': 'ዕጹው',
      'English': 'CLOSED',
      'Amharic': 'ተዘግቷል'
    },
    'closes_at': {
      'Norsk': 'Stenger',
      'Tigrinya': 'ኣብ X ይዕጾ',
      'English': 'Closes at',
      'Amharic': 'ይዘጋል'
    },
    'opens_at': {
      'Norsk': 'Åpner',
      'Tigrinya': 'ዝኽፈተሉ ሳዓት',
      'English': 'Opens at',
      'Amharic': 'ይከፈታል'
    },
    'closed_today': {
      'Norsk': 'Stengt i dag',
      'Tigrinya': 'ሎሚ ዕጹው እዩ',
      'English': 'Closed today',
      'Amharic': 'ዛሬ ተዘግቷል'
    },
    'no_opening_hours': {
      'Norsk': 'Åpningstider ikke oppgitt',
      'Tigrinya': 'ናይ ስራሕ ሰዓታት ኣይተዋህበን',
      'English': 'Opening hours not provided',
      'Amharic': 'የስራ ሰዓት አልተሰጠም'
    },
    'view_menu': {
      'Norsk': 'Vis meny',
      'Tigrinya': 'ዝርዝር ርአ',
      'English': 'View menu',
      'Amharic': 'ምናሌ ይመልከቱ'
    },
    'menu_not_available': {
      'Norsk': 'Meny ikke tilgjengelig',
      'Tigrinya': 'ዝርዝር መግቢ ኣይተረከበን',
      'English': 'Menu not available',
      'Amharic': 'ምናሌ አይገኝም'
    },
    'upload_menu': {
      'Norsk': 'Last opp meny',
      'Tigrinya': 'ሜኑ ጽዓን',
      'English': 'Upload menu',
      'Amharic': 'ምናሌ ይጫኑ'
    },
    'uploading': {
      'Norsk': 'Laster opp...',
      'Tigrinya': 'ይጽዕን ኣሎ...',
      'English': 'Uploading...',
      'Amharic': 'በመጫን ላይ...'
    },
    'want_upload_menu': {
      'Norsk': 'Vil du laste opp meny?',
      'Tigrinya': 'ሜኑ ክትጽዕኑ ትደልዩ ዲኹም?',
      'English': 'Want to upload a menu?',
      'Amharic': 'ምናሌ መጫን ይፈልጋሉ?'
    },
    'contact_for_premium': {
      'Norsk': 'Kontakt oss for å oppgradere til Premium',
      'Tigrinya': 'ናብ ፕሪሚየም ንምምሕያሽ ምሳና ተራኸቡ',
      'English': 'Contact us to upgrade to Premium',
      'Amharic': 'ወደ ፕሪሚየም ለማሻሻል ያግኙን'
    },
    'full_address': {
      'Norsk': 'FULL ADRESSE',
      'Tigrinya': 'ምሉእ ኣድራሻ',
      'English': 'FULL ADDRESS',
      'Amharic': 'ሙሉ አድራሻ'
    },
    'no_address': {
      'Norsk': 'Adresse ikke oppgitt',
      'Tigrinya': 'ኣድራሻ ኣይተዋህበን',
      'English': 'Address not provided',
      'Amharic': 'አድራሻ አልተሰጠም'
    },
    'map': {
      'Norsk': 'Kart',
      'Tigrinya': 'ካርታ',
      'English': 'Map',
      'Amharic': '지도'
    },
    'call': {
      'Norsk': 'Ring',
      'Tigrinya': 'ደውሉ',
      'English': 'Call',
      'Amharic': 'ይደውሉ'
    },
    'web': {
      'Norsk': 'Web',
      'Tigrinya': 'ወብሳይት',
      'English': 'Web',
      'Amharic': 'ድህረ ገፅ'
    },
    'no_website': {
      'Norsk': 'Ingen nettside registrert',
      'Tigrinya': 'ዝተመዝገበ መርበብ ሓበሬታ የለን',
      'English': 'No website registered',
      'Amharic': 'ምንም ድህረ ገፅ አልተመዘገበም'
    },
    'open_map': {
      'Norsk': 'Åpne kart',
      'Tigrinya': 'ካርታ ክፈት',
      'English': 'Open map',
      'Amharic': '지도 ክፈት'
    },
    'no_description': {
      'Norsk': 'Ingen beskrivelse tilgjengelig',
      'Tigrinya': 'ዝኾነ መግለጺ የለን',
      'English': 'No description available',
      'Amharic': 'ምንም መግለጫ የለም'
    },
    'premium_partner': {
      'Norsk': 'Premium Partner',
      'Tigrinya': 'ፕሪሚየም መሻርኽቲ',
      'English': 'Premium Partner',
      'Amharic': 'ፕሪሚየም አጋር'
    },
    'verified_business': {
      'Norsk': 'VERIFIED BUSINESS',
      'Tigrinya': 'ዝተረጋገጸ ትካል',
      'English': 'VERIFIED BUSINESS',
      'Amharic': 'የተረጋገጠ ድርጅት'
    },
    'priority_booking': {
      'Norsk': 'PRIORITY BOOKING',
      'Tigrinya': 'ቀዳምነት ዝወሃቦ ምዕዳግ',
      'English': 'PRIORITY BOOKING',
      'Amharic': 'ቀዳሚ ቦታ ማስያዝ'
    },
    'digital_menu': {
      'Norsk': 'DIGITAL MENU ACCESS',
      'Tigrinya': 'ናይ ዲጂታል ሜኑ መእተዊ',
      'English': 'DIGITAL MENU ACCESS',
      'Amharic': 'ዲጂታል ምናሌ'
    },
    'rate_business': {
      'Norsk': 'Vurder denne bedriften',
      'Tigrinya': 'ነዚ ትካል እዚ ዓቐን ሃብ',
      'English': 'Rate this business',
      'Amharic': 'ይህን ድርጅት ይገምግሙ'
    },
    'your_rating': {
      'Norsk': 'Din vurdering',
      'Tigrinya': 'ናትካ ዓቐን ምዕቃን',
      'English': 'Your rating',
      'Amharic': 'የእርስዎ ግምገማ'
    },
    'submit_rating': {
      'Norsk': 'Send vurdering',
      'Tigrinya': 'ደረጃ ምሃብ ኣቕርብ',
      'English': 'Submit rating',
      'Amharic': 'ግምገማ ያስገቡ'
    },
    'gave_stars': {
      'Norsk': 'Du ga',
      'Tigrinya': 'ሂብካ',
      'English': 'You gave',
      'Amharic': 'ሰጡ'
    },
    'stars': {
      'Norsk': 'stjerner',
      'Tigrinya': 'ኮኾብ',
      'English': 'stars',
      'Amharic': 'ኮከቦች'
    },
    'edit': {
      'Norsk': 'Rediger',
      'Tigrinya': 'ምምሕያሽ',
      'English': 'Edit',
      'Amharic': 'አርትዕ'
    },
    'delete_business': {
      'Norsk': 'Slett bedrift',
      'Tigrinya': 'ትካል ደምስስ',
      'English': 'Delete business',
      'Amharic': 'ድርጅት ሰርዝ'
    },
    'are_you_sure': {
      'Norsk': 'Er du sikker?',
      'Tigrinya': 'ርግጸኛ ዲኻ/ኺ?',
      'English': 'Are you sure?',
      'Amharic': 'እርግጠኛ ነዎት?'
    },
    'cancel': {
      'Norsk': 'Avbryt',
      'Tigrinya': 'ሰርዝ',
      'English': 'Cancel',
      'Amharic': 'ሰርዝ'
    },
    'delete': {
      'Norsk': 'Slett',
      'Tigrinya': 'ደምስስ',
      'English': 'Delete',
      'Amharic': 'ሰርዝ'
    },

    // ── CHAT ─────────────────────────────────────────
    'chatting_as': {
      'Norsk': 'Chatter som:',
      'Tigrinya': 'ከምዚ ዝስዕብ ኮይኑ ይዘራረብ ኣሎ፦',
      'English': 'Chatting as:',
      'Amharic': 'እንደ ቻት ያደርጋሉ:'
    },
    'type_message': {
      'Norsk': 'Skriv en melding...',
      'Tigrinya': 'መልእኽቲ ጽሓፍ...',
      'English': 'Write a message...',
      'Amharic': 'መልዕክት ይጻፉ...'
    },
    'no_messages': {
      'Norsk': 'Ingen meldinger ennå.\nVær den første til å skrive!',
      'Tigrinya': 'ክሳዕ ሕጂ መልእኽትታት የለዉን። ቀዳማይ ጽሓፊ ኩን!',
      'English': 'No messages yet.\nBe the first to write!',
      'Amharic': 'እስካሁን ምንም መልዕክት የለም። ቀዳሚ ይሁኑ!'
    },

    // ── MELDINGER ────────────────────────────────────
    'messages_title': {
      'Norsk': 'Meldinger',
      'Tigrinya': 'መልእኽትታት',
      'English': 'Messages',
      'Amharic': 'መልዕክቶች'
    },
    'no_chats': {
      'Norsk': 'Ingen meldinger ennå',
      'Tigrinya': 'ክሳዕ ሕጂ መልእኽትታት የለዉን',
      'English': 'No messages yet',
      'Amharic': 'እስካሁን ምንም መልዕክት የለም'
    },
    'start_chat': {
      'Norsk': 'Gå til en bedrift og start en chat!',
      'Tigrinya': 'ናብ ሓደ ትካል ኬድካ ዕላል ጀምር!',
      'English': 'Go to a business and start a chat!',
      'Amharic': 'ወደ ድርጅት ሂደው ቻት ይጀምሩ!'
    },

    // ── FAVORITTER ───────────────────────────────────
    'favorites_title': {
      'Norsk': 'Favoritter',
      'Tigrinya': 'ፍቱዋት',
      'English': 'Favorites',
      'Amharic': 'ተወዳጆች'
    },
    'no_favorites': {
      'Norsk': 'Ingen favoritter ennå',
      'Tigrinya': 'ክሳዕ ሕጂ ፍቱዋት የለዉን',
      'English': 'No favorites yet',
      'Amharic': 'እስካሁን ምንም ተወዳጅ የለም'
    },
    'tap_heart': {
      'Norsk': 'Trykk ♥ på en bedrift for å lagre den',
      'Tigrinya': 'ንምዕቓብ ♥ ጠውቕ',
      'English': 'Tap ♥ on a business to save it',
      'Amharic': 'ለማስቀመጥ ♥ ይጫኑ'
    },

    // ── PROFIL ───────────────────────────────────────
    'guest': {
      'Norsk': 'Gjest',
      'Tigrinya': 'ጋሻ',
      'English': 'Guest',
      'Amharic': 'እንግዳ'
    },
    'login_for_access': {
      'Norsk': 'Logg inn for å få full tilgang',
      'Tigrinya': 'ምሉእ መሰል ንምርካብ እተው',
      'English': 'Log in to get full access',
      'Amharic': 'ሙሉ ተደራሽነት ለማግኘት ይግቡ'
    },
    'login_register': {
      'Norsk': 'Logg inn / Registrer deg',
      'Tigrinya': 'እቶ / ተመዝገብ',
      'English': 'Log in / Register',
      'Amharic': 'ይግቡ / ይመዝገቡ'
    },
    'login_for_business': {
      'Norsk': 'Logg inn for å registrere bedrift, se dine bedrifter og mer.',
      'Tigrinya': 'ትካል ንምምዝጋብ እተዉ',
      'English': 'Log in to register a business, see your businesses and more.',
      'Amharic': 'ድርጅት ለመመዝገብ ይግቡ'
    },
    'login': {
      'Norsk': 'Logg inn',
      'Tigrinya': 'እቶ',
      'English': 'Log in',
      'Amharic': 'ይግቡ'
    },
    'nickname': {
      'Norsk': 'Kallenavn',
      'Tigrinya': 'ቅጽል ስም',
      'English': 'Nickname',
      'Amharic': 'ቅጽል ስም'
    },
    'nickname_hint': {
      'Norsk': 'Ditt kallenavn i chat...',
      'Tigrinya': 'ናይ ቻት ቅጽል ስምካ...',
      'English': 'Your chat nickname...',
      'Amharic': 'የቻት ቅጽል ስምዎ...'
    },
    'language': {
      'Norsk': 'Language',
      'Tigrinya': 'ቋንቋ',
      'English': 'Language',
      'Amharic': 'ቋንቋ'
    },
    'save': {
      'Norsk': 'Lagre',
      'Tigrinya': 'ዓቕብ',
      'English': 'Save',
      'Amharic': 'አስቀምጥ'
    },
    'saved': {
      'Norsk': 'Lagret!',
      'Tigrinya': 'ተዓቂቡ!',
      'English': 'Saved!',
      'Amharic': 'ተቀምጧል!'
    },
    'register_business': {
      'Norsk': 'Registrer din bedrift',
      'Tigrinya': 'ንካልካ መዝግብ',
      'English': 'Register Your Business',
      'Amharic': 'ድርጅትዎን ያስመዝግቡ'
    },
    'my_businesses': {
      'Norsk': 'Mine bedrifter',
      'Tigrinya': 'ናተይ ትካላት',
      'English': 'My businesses',
      'Amharic': 'የእኔ ድርጅቶች'
    },
    'no_businesses_yet': {
      'Norsk': 'Du har ingen bedrifter ennå.',
      'Tigrinya': 'ክሳዕ ሕጂ ዋላ ሓንቲ ትካላት የብልኩምን',
      'English': 'You have no businesses yet.',
      'Amharic': 'እስካሁን ምንም ድርጅት የለዎትም።'
    },
    'active': {
      'Norsk': 'AKTIV',
      'Tigrinya': 'ንጡፍ',
      'English': 'ACTIVE',
      'Amharic': 'ንቁ'
    },
    'premium': {
      'Norsk': 'PREMIUM',
      'Tigrinya': 'ፕሪሚየም',
      'English': 'PREMIUM',
      'Amharic': 'ፕሪሚየም'
    },
    'help_support': {
      'Norsk': 'Help & Support',
      'Tigrinya': 'ሓገዝን ደገፍን',
      'English': 'Help & Support',
      'Amharic': 'እርዳታ'
    },
    'logout': {
      'Norsk': 'Logg ut',
      'Tigrinya': 'ካብ መእተዊ ውጻእ',
      'English': 'Log out',
      'Amharic': 'ይውጡ'
    },
    'logged_out': {
      'Norsk': 'Du er logget ut',
      'Tigrinya': 'ወጺእካ ኣለኻ',
      'English': 'You are logged out',
      'Amharic': 'ወጥተዋል'
    },
    'sure_logout': {
      'Norsk': 'Er du sikker på at du vil logge ut?',
      'Tigrinya': 'ካብ ሕሳብካ ክትወጽእ ከም እትደሊ ርግጸኛ ዲኻ?',
      'English': 'Are you sure you want to log out?',
      'Amharic': 'እርግጠኛ ነዎት መውጣት ይፈልጋሉ?'
    },
    'delete_account': {
      'Norsk': 'Slett konto',
      'Tigrinya': 'ሕሳብ ሰርዝ',
      'English': 'Delete account',
      'Amharic': 'መለያ ሰርዝ'
    },
    'delete_account_confirm': {
      'Norsk':
          'Er du sikker? All data slettes permanent og kan ikke gjenopprettes.',
      'Tigrinya': 'ርግጸኛ ዲኻ? ኩሉ ዳታ ቀዋሚ ይስረዝ።',
      'English':
          'Are you sure? All data will be permanently deleted and cannot be recovered.',
      'Amharic': 'እርግጠኛ ነዎት? ሁሉም ዳታ ቋሚ ይሰረዛል።'
    },

    // ── REGISTRER BEDRIFT ───────────────────────────
    'register_title': {
      'Norsk': 'Registrer bedrift',
      'Tigrinya': 'ትካል ምምዝጋብ',
      'English': 'Register business',
      'Amharic': 'ድርጅት ያስመዝግቡ'
    },
    'step_of': {
      'Norsk': 'Steg',
      'Tigrinya': 'ስጉምቲ',
      'English': 'Step',
      'Amharic': 'ደረጃ'
    },
    'business_name': {
      'Norsk': 'BEDRIFTSNAVN',
      'Tigrinya': 'ስም ትካል ንግዲ',
      'English': 'BUSINESS NAME',
      'Amharic': 'የድርጅት ስም'
    },
    'category_label': {
      'Norsk': 'KATEGORI',
      'Tigrinya': 'ምድብ',
      'English': 'CATEGORY',
      'Amharic': 'ምድብ'
    },
    'description_label': {
      'Norsk': 'BESKRIVELSE',
      'Tigrinya': 'መግለጺ',
      'English': 'DESCRIPTION',
      'Amharic': 'መግለጫ'
    },
    'address_label': {
      'Norsk': 'ADRESSE',
      'Tigrinya': 'ኣድራሻ',
      'English': 'ADDRESS',
      'Amharic': 'አድራሻ'
    },
    'phone_label': {
      'Norsk': 'TELEFON',
      'Tigrinya': 'ተሌፎን',
      'English': 'PHONE',
      'Amharic': 'ስልክ'
    },
    'opening_hours': {
      'Norsk': 'ÅPNINGSTIDER',
      'Tigrinya': 'ሰዓታት ምኽፋት',
      'English': 'OPENING HOURS',
      'Amharic': 'የስራ ሰዓት'
    },
    'closed_toggle': {
      'Norsk': 'Stengt',
      'Tigrinya': 'ዕጹው (መቐየሪ)',
      'English': 'Closed',
      'Amharic': 'ተዘግቷል'
    },
    'opens_label': {
      'Norsk': 'Åpner',
      'Tigrinya': 'ይኽፈት',
      'English': 'Opens',
      'Amharic': 'ይከፈታል'
    },
    'closes_label': {
      'Norsk': 'Stenger',
      'Tigrinya': 'ይዕጾ',
      'English': 'Closes',
      'Amharic': 'ይዘጋል'
    },
    'image_url': {
      'Norsk': 'BILDE URL',
      'Tigrinya': 'ስእሊ URL',
      'English': 'IMAGE URL',
      'Amharic': 'የምስል URL'
    },
    'website_optional': {
      'Norsk': 'NETTSIDE (valgfritt)',
      'Tigrinya': 'መርበብ ሓበሬታ (ኣማራጺ)',
      'English': 'WEBSITE (optional)',
      'Amharic': 'ድህረ ገፅ (አማራጭ)'
    },
    'submit_approval': {
      'Norsk': 'Send til godkjenning',
      'Tigrinya': 'ንምጽዳቕ ኣቕርብ',
      'English': 'Submit for approval',
      'Amharic': 'ለፍቃድ ያስገቡ'
    },
    'submitted': {
      'Norsk': 'Bedrift sendt til godkjenning!',
      'Tigrinya': 'ትካል ንምጽዳቕ ተረኪቡ!',
      'English': 'Business submitted for approval!',
      'Amharic': 'ድርጅት ለፍቃድ ተልኳል!'
    },
    'next': {
      'Norsk': 'Neste',
      'Tigrinya': 'ዝቕጽል',
      'English': 'Next',
      'Amharic': 'ቀጣይ'
    },
    'back': {
      'Norsk': 'Tilbake',
      'Tigrinya': 'ንድሕሪት',
      'English': 'Back',
      'Amharic': 'ተመለስ'
    },

    // ── INNLOGGING ─────────────────────────────────
    'log_in_tab': {
      'Norsk': 'LOGG INN',
      'Tigrinya': 'እቶ',
      'English': 'LOG IN',
      'Amharic': 'ግቡ'
    },
    'register_tab': {
      'Norsk': 'REGISTRER',
      'Tigrinya': 'ምዝገባ',
      'English': 'REGISTER',
      'Amharic': 'ተመዝገቡ'
    },
    'welcome_back': {
      'Norsk': 'Velkommen tilbake',
      'Tigrinya': 'እንቋዕ ብደሓን መጻእካ',
      'English': 'Welcome back',
      'Amharic': 'እንኳን ደህና መጡ'
    },
    'email_label': {
      'Norsk': 'E-POST',
      'Tigrinya': 'ኢ-መይል',
      'English': 'EMAIL',
      'Amharic': 'ኢሜይል'
    },
    'password_label': {
      'Norsk': 'PASSORD',
      'Tigrinya': 'ፓስዎርድ',
      'English': 'PASSWORD',
      'Amharic': 'የይለፍ ቃል'
    },
    'no_account': {
      'Norsk': 'Har du ikke konto? Registrer deg',
      'Tigrinya': 'ኣካውንት የብልካን ድዩ? ተመዝገብ',
      'English': "Don't have an account? Register",
      'Amharic': 'መለያ የለዎትም? ይመዝገቡ'
    },
    'create_account': {
      'Norsk': 'Opprett konto',
      'Tigrinya': 'ኣካውንት ክፈት',
      'English': 'Create account',
      'Amharic': 'መለያ ይፍጠሩ'
    },
    'have_account': {
      'Norsk': 'Har du allerede konto? Logg inn',
      'Tigrinya': 'ኣካውንት ኣለካ ድዩ? እቶ',
      'English': 'Already have an account? Log in',
      'Amharic': 'መለያ አለዎት? ይግቡ'
    },
    'email_not_verified': {
      'Norsk': 'E-posten er ikke bekreftet',
      'Tigrinya': 'ኢመይል ኣይተረጋገጸን',
      'English': 'Email not verified',
      'Amharic': 'ኢሜይል አልተረጋገጠም'
    },
    'resend': {
      'Norsk': 'Send på nytt',
      'Tigrinya': 'ዳግማይ ስደድ',
      'English': 'Resend',
      'Amharic': 'እንደገና ይላኩ'
    },
    'verify_email': {
      'Norsk': 'Bekreft e-post',
      'Tigrinya': 'ኢ-መይል ኣረጋግጽ',
      'English': 'Verify email',
      'Amharic': 'ኢሜይል ያረጋግጡ'
    },

    // ── KONTAKT ────────────────────────────────────
    'contact_us': {
      'Norsk': 'Kontakt oss',
      'Tigrinya': 'ርኸቡና',
      'English': 'Contact us',
      'Amharic': 'ያግኙን'
    },
    'message_label': {
      'Norsk': 'MELDING',
      'Tigrinya': 'መልእኽቲ',
      'English': 'MESSAGE',
      'Amharic': 'መልዕክት'
    },
    'message_hint': {
      'Norsk': 'Skriv din melding her...',
      'Tigrinya': 'መልእኽትኻ ኣብዚ ጽሓፍ...',
      'English': 'Write your message here...',
      'Amharic': 'መልዕክትዎን ይጻፉ...'
    },
    'send_message': {
      'Norsk': 'Send melding',
      'Tigrinya': 'መልእኽቲ ስደድ',
      'English': 'Send message',
      'Amharic': 'መልዕክት ይላኩ'
    },
    'message_sent': {
      'Norsk': 'Melding sendt!',
      'Tigrinya': 'መልእኽቲ ተላኢኹ!',
      'English': 'Message sent!',
      'Amharic': 'መልዕክት ተልኳል!'
    },
    'will_reply': {
      'Norsk': 'Vi svarer deg så snart som mulig.',
      'Tigrinya': 'ብዝተኻእለ መጠን ቀልጢፍና ክንምልሰልኩም ኢና',
      'English': 'We will reply as soon as possible.',
      'Amharic': 'በተቻለ ፍጥነት እንመልሳለን።'
    },

    // ── EKSTRA ──────────────────────────────────────
    'nearby_desc': {
      'Norsk': 'Trykk på sirkelen for å finne Habesha-bedrifter i nærheten',
      'Tigrinya': 'ናይ ሓበሻ ቢዝነሳት ንምርካብ ኣብቲ ከቢብ ጠውቕ',
      'English': 'Tap the circle to find Habesha businesses nearby',
      'Amharic': 'ቅርበት ያላቸው የሃበሻ ድርጅቶችን ለማግኘት ይጫኑ'
    },
    'set_nickname': {
      'Norsk': 'Sett kallenavn i Profil for å bruke chat',
      'Tigrinya': 'ቻት ንምጥቃም ኣብ ፕሮፋይል ሳጓ ኣቐምጥ',
      'English': 'Set nickname in Profile to use chat',
      'Amharic': 'ቻት ለመጠቀም መገለጫ ላይ ቅጽል ስም ያስቀምጡ'
    },
    'be_first': {
      'Norsk': 'Vær den første til å registrere en!',
      'Tigrinya': 'ንምምዝጋብ ቀዳማይ ኩን!',
      'English': 'Be the first to register one!',
      'Amharic': 'የመጀመሪያ ይሁኑ!'
    },
    'habesha_user': {
      'Norsk': 'Habesha Hub Bruker',
      'Tigrinya': 'ናይ ሓበሻ ሃብ ተጠቃሚ',
      'English': 'Habesha Hub User',
      'Amharic': 'የሃበሻ ሃብ ተጠቃሚ'
    },
    'distance': {
      'Norsk': 'unna',
      'Tigrinya': 'ርሕቀት',
      'English': 'away',
      'Amharic': 'ርቀት'
    },
    'of': {'Norsk': 'av', 'Tigrinya': 'ካብ', 'English': 'of', 'Amharic': 'ከ'},
    'admin_panel': {
      'Norsk': 'Admin Panel',
      'Tigrinya': 'ናይ ምምሕዳር ሰሌዳ',
      'English': 'Admin Panel',
      'Amharic': 'አስተዳዳሪ ፓነል'
    },
    'register_desc': {
      'Norsk': 'Kom i gang med Habesha Hub',
      'Tigrinya': 'ምስ ሓበሻ ሃብ ተሳተፍ',
      'English': 'Get started with Habesha Hub',
      'Amharic': 'ከሃበሻ ሃብ ጋር ይጀምሩ'
    },
    'digital_heritage': {
      'Norsk': 'Establish Your\nDigital Heritage.',
      'Tigrinya': 'ናይ ዲጂታል\nወርሲ ምምስራት',
      'English': 'Establish Your\nDigital Heritage.',
      'Amharic': 'ዲጂታል ቅርስዎን\nያቋቁሙ።'
    },
    'businesses_registered_desc': {
      'Norsk': 'Bedrifter du har registrert.',
      'Tigrinya': 'ዝምዝገብካዮም ንግድታት።',
      'English': 'Businesses you have registered.',
      'Amharic': 'የተመዘገቡ ድርጅቶችዎ።'
    },
    'menu_not_available_yet': {
      'Norsk': 'Meny ikke tilgjengelig ennå',
      'Tigrinya': 'ሜኑ ገና ኣይተጸዓነን',
      'English': 'Menu not available yet',
      'Amharic': 'ምናሌ እስካሁን አይገኝም'
    },
    'pending_review': {
      'Norsk': 'Bedriften er under gjennomgang. Vanligvis 1-2 virkedager.',
      'Tigrinya': 'ቢዝነስ ይምርመር ኣሎ። ብልሙድ 1-2 መዓልቲ ስራሕ ይወስድ።',
      'English': 'Business is under review. Usually 1-2 business days.',
      'Amharic': 'ድርጅቱ በክለሳ ላይ ነው። ብዙውን ጊዜ 1-2 የስራ ቀናት ይወስዳል።'
    },
    'premium_desc': {
      'Norsk': 'Verifisert medlem av Habesha Hub Elite-nettverket.',
      'Tigrinya': 'ናይ ሓበሻ ሃብ ኤሊት ኔትወርክ ዝተረጋገጸ ኣባል።',
      'English': 'Verified member of Habesha Hub Elite network.',
      'Amharic': 'የሃበሻ ሃብ ኤሊት አውታረ መረብ የተረጋገጠ አባል።'
    },

    // ── EVENTS ──────────────────────────────────────
    'events': {
      'Norsk': 'Hendelser',
      'Tigrinya': 'ክስተታት',
      'English': 'Events',
      'Amharic': 'ዝግጅቶች'
    },
    'forum': {
      'Norsk': 'Forum',
      'Tigrinya': 'ፎረም',
      'English': 'Forum',
      'Amharic': 'ፎረም'
    },
    'events_title': {
      'Norsk': 'Hendelser',
      'Tigrinya': 'ክስተታት',
      'English': 'Events',
      'Amharic': 'ዝግጅቶች'
    },
    'events_subtitle': {
      'Norsk': 'Kampala • Addis • Verden',
      'Tigrinya': 'ካምፓላ • ኣዲስ • ዓለም',
      'English': 'Kampala • Addis • World',
      'Amharic': 'ካምፓላ • አዲስ • ዓለም'
    },
    'new_event': {
      'Norsk': 'Ny',
      'Tigrinya': 'ሓዲሽ',
      'English': 'New',
      'Amharic': 'አዲስ'
    },
    'interested': {
      'Norsk': 'Interessert',
      'Tigrinya': 'ተገዳሲ',
      'English': 'Interested',
      'Amharic': 'ፍላጎት አለኝ'
    },
    'interested_count': {
      'Norsk': 'interesserte',
      'Tigrinya': 'ተገደስቲ',
      'English': 'interested',
      'Amharic': 'ፍላጎት አላቸው'
    },
    'no_events': {
      'Norsk': 'Ingen hendelser ennå',
      'Tigrinya': 'ክስተታት የለን',
      'English': 'No events yet',
      'Amharic': 'እስካሁን ምንም ዝግጅት የለም'
    },
    'come_back': {
      'Norsk': 'Kom tilbake snart!',
      'Tigrinya': 'ቀልጢፍካ ተመለስ!',
      'English': 'Come back soon!',
      'Amharic': 'ብዙም ሳይቆዩ ይመለሱ!'
    },
    'create_event': {
      'Norsk': 'Opprett hendelse',
      'Tigrinya': 'ክስተት ፍጠር',
      'English': 'Create event',
      'Amharic': 'ዝግጅት ይፍጠሩ'
    },
    'event_title': {
      'Norsk': 'TITTEL',
      'Tigrinya': 'ኣርእስቲ',
      'English': 'TITLE',
      'Amharic': 'ርዕስ'
    },
    'event_category': {
      'Norsk': 'KATEGORI',
      'Tigrinya': 'ምድብ',
      'English': 'CATEGORY',
      'Amharic': 'ምድብ'
    },
    'event_location': {
      'Norsk': 'STED',
      'Tigrinya': 'ቦታ',
      'English': 'LOCATION',
      'Amharic': 'ቦታ'
    },
    'event_description': {
      'Norsk': 'BESKRIVELSE',
      'Tigrinya': 'መግለጺ',
      'English': 'DESCRIPTION',
      'Amharic': 'መግለጫ'
    },
    'event_image_url': {
      'Norsk': 'BILDE URL (valgfritt)',
      'Tigrinya': 'ስእሊ URL (ኣማራጺ)',
      'English': 'IMAGE URL (optional)',
      'Amharic': 'የምስል URL (አማራጭ)'
    },
    'publish_event': {
      'Norsk': 'Publiser hendelse',
      'Tigrinya': 'ክስተት ኣውጽእ',
      'English': 'Publish event',
      'Amharic': 'ዝግጅት ያትሙ'
    },

    // ── FORUM ──────────────────────────────────────
    'forum_title': {
      'Norsk': 'Forum',
      'Tigrinya': 'ፎረም',
      'English': 'Forum',
      'Amharic': 'ፎረም'
    },
    'forum_subtitle': {
      'Norsk': 'Still spørsmål til fellesskapet',
      'Tigrinya': 'ንሕብረተሰብ ሕተት',
      'English': 'Ask the community',
      'Amharic': 'ማህበረሰቡን ይጠይቁ'
    },
    'new_post': {
      'Norsk': 'Nytt innlegg',
      'Tigrinya': 'ሓዲሽ ጽሑፍ',
      'English': 'New post',
      'Amharic': 'አዲስ ጥያቄ'
    },
    'no_posts': {
      'Norsk': 'Ingen innlegg ennå',
      'Tigrinya': 'ጽሑፋት የለን',
      'English': 'No posts yet',
      'Amharic': 'እስካሁን ምንም ጥያቄ የለም'
    },
    'be_first_post': {
      'Norsk': 'Vær den første til å stille et spørsmål!',
      'Tigrinya': 'ቀዳማይ ሕታሚ ኩን!',
      'English': 'Be the first to ask a question!',
      'Amharic': 'የመጀመሪያ ጥያቄ ጠያቂ ይሁኑ!'
    },
    'post_title': {
      'Norsk': 'TITTEL',
      'Tigrinya': 'ኣርእስቲ',
      'English': 'TITLE',
      'Amharic': 'ርዕስ'
    },
    'post_body': {
      'Norsk': 'INNLEGG',
      'Tigrinya': 'ጽሑፍ',
      'English': 'POST',
      'Amharic': 'ጥያቄ'
    },
    'post_hint': {
      'Norsk': 'Hva lurer du på?',
      'Tigrinya': 'እንታይ ትሓትት?',
      'English': 'What do you want to ask?',
      'Amharic': 'ምን መጠየቅ ይፈልጋሉ?'
    },
    'post_body_hint': {
      'Norsk': 'Beskriv spørsmålet ditt...',
      'Tigrinya': 'ሕቶኻ ግለጽ...',
      'English': 'Describe your question...',
      'Amharic': 'ጥያቄዎን ይግለጹ...'
    },
    'publish_post': {
      'Norsk': 'Publiser innlegg',
      'Tigrinya': 'ጽሑፍ ኣውጽእ',
      'English': 'Publish post',
      'Amharic': 'ጥያቄ ያትሙ'
    },
    'posting_as': {
      'Norsk': 'Poster som',
      'Tigrinya': 'ብስም',
      'English': 'Posting as',
      'Amharic': 'እንደ ይለጥፋሉ'
    },
    'comments': {
      'Norsk': 'Kommentarer',
      'Tigrinya': 'ርእይቶታት',
      'English': 'Comments',
      'Amharic': 'አስተያየቶች'
    },
    'no_comments': {
      'Norsk': 'Ingen kommentarer ennå — vær den første!',
      'Tigrinya': 'ርእይቶ የለን — ቀዳማይ ኩን!',
      'English': 'No comments yet — be the first!',
      'Amharic': 'እስካሁን አስተያየት የለም — የመጀመሪያ ይሁኑ!'
    },
    'write_comment': {
      'Norsk': 'Skriv en kommentar...',
      'Tigrinya': 'ርእይቶ ጽሓፍ...',
      'English': 'Write a comment...',
      'Amharic': 'አስተያየት ይጻፉ...'
    },
    'liked': {
      'Norsk': 'liker dette',
      'Tigrinya': 'ዝፈትዎ',
      'English': 'like this',
      'Amharic': 'ወደዱት'
    },
    'interested_snack': {
      'Norsk': 'Du er interessert! 🎉',
      'Tigrinya': 'ተገዲስካ! 🎉',
      'English': 'You are interested! 🎉',
      'Amharic': 'ፍላጎት አሎት! 🎉'
    },

    // ── BOOKING ──────────────────────────────────────
    'book_time': {
      'Norsk': 'Book tid',
      'Tigrinya': 'ጊዜ ሕዝ',
      'English': 'Book time',
      'Amharic': 'ቀጠሮ ያስይዙ'
    },
    'booking_sent': {
      'Norsk': 'Booking sendt!',
      'Tigrinya': 'ቡኪንግ ተሰዲዱ!',
      'English': 'Booking sent!',
      'Amharic': 'ቀጠሮ ተልኳል!'
    },
    'booking_confirmed': {
      'Norsk': 'Din booking er sendt! De vil bekrefte innen kort tid.',
      'Tigrinya': 'ቡኪንግካ ተሰዲዱ! ብቕልጡፍ ክረጋግጹ እዮም።',
      'English': 'Your booking was sent! They will confirm shortly.',
      'Amharic': 'ቀጠሮዎ ተልኳል! ብዙም ሳይቆዩ ያረጋግጣሉ።'
    },
    'date_label': {
      'Norsk': 'DATO',
      'Tigrinya': 'ዕለት',
      'English': 'DATE',
      'Amharic': 'ቀን'
    },
    'time_label': {
      'Norsk': 'TIDSPUNKT',
      'Tigrinya': 'ሰዓት',
      'English': 'TIME',
      'Amharic': 'ሰዓት'
    },
    'message_to_business': {
      'Norsk': 'MELDING TIL BEDRIFTEN',
      'Tigrinya': 'መልእኽቲ ናብ ትካል',
      'English': 'MESSAGE TO BUSINESS',
      'Amharic': 'ለድርጅቱ መልዕክት'
    },
    'describe_need': {
      'Norsk': 'Beskriv hva du trenger...',
      'Tigrinya': 'እንታይ ከም እትደሊ ግለጽ...',
      'English': 'Describe what you need...',
      'Amharic': 'የሚያስፈልግዎን ይግለጹ...'
    },
    'booking_as': {
      'Norsk': 'Booker som',
      'Tigrinya': 'ቡኪንግ ብስም',
      'English': 'Booking as',
      'Amharic': 'ቀጠሮ በስም'
    },
    'send_booking': {
      'Norsk': 'Send booking',
      'Tigrinya': 'ቡኪንግ ስደድ',
      'English': 'Send booking',
      'Amharic': 'ቀጠሮ ይላኩ'
    },
    'pending': {
      'Norsk': 'Venter',
      'Tigrinya': 'ይጽበ',
      'English': 'Pending',
      'Amharic': 'በመጠበቅ ላይ'
    },
    'approved': {
      'Norsk': 'Godkjent',
      'Tigrinya': 'ተቐቢሉ',
      'English': 'Approved',
      'Amharic': 'ተፈቅዷል'
    },
    'rejected': {
      'Norsk': 'Avslått',
      'Tigrinya': 'ተነጺጉ',
      'English': 'Rejected',
      'Amharic': 'ተቀባይነት አላገኘም'
    },
    'approve': {
      'Norsk': 'Godkjenn',
      'Tigrinya': 'ቀበል',
      'English': 'Approve',
      'Amharic': 'ፍቀድ'
    },
    'reject': {
      'Norsk': 'Avslå',
      'Tigrinya': 'ንጸግ',
      'English': 'Reject',
      'Amharic': 'ውድቅ አድርግ'
    },
    'no_bookings': {
      'Norsk': 'Ingen bookinger ennå',
      'Tigrinya': 'ቡኪንግ የለን',
      'English': 'No bookings yet',
      'Amharic': 'እስካሁን ምንም ቀጠሮ የለም'
    },

    // ── PROFIL KORT ──────────────────────────────────
    'bring_vision': {
      'Norsk': 'Bring your vision to the community.',
      'Tigrinya': 'ራእይካ ናብ ሕብረተሰብ ኣምጽእ።',
      'English': 'Bring your vision to the community.',
      'Amharic': 'ራዕይዎን ለማህበረሰቡ ያቅርቡ።'
    },
    'growth_opportunity': {
      'Norsk': 'VEKSTMULIGHET',
      'Tigrinya': 'ዕድል ዕቤት',
      'English': 'GROWTH OPPORTUNITY',
      'Amharic': 'የዕድገት እድል'
    },
    'list_business_desc': {
      'Norsk':
          'Registrer bedriften din og koble til tusenvis av Habesha-brukere verden over.',
      'Tigrinya': 'ትካልካ መዝጊብካ ምስ ኣሽሓት ናይ ሓበሻ ተጠቀምቲ ዓለም ለኸ ተራኸብ።',
      'English':
          'List your business and connect with thousands of Habesha users worldwide.',
      'Amharic': 'ድርጅትዎን ይዘርዝሩ እና ከሺዎች የሃበሻ ተጠቃሚዎች ጋር ይገናኙ።'
    },

    // ── KATEGORIER EVENT/FORUM ──────────────────────
    'cat_wedding': {
      'Norsk': 'Bryllup',
      'Tigrinya': 'መርዓ',
      'English': 'Wedding',
      'Amharic': 'ሰርግ'
    },
    'cat_music': {
      'Norsk': 'Musikk',
      'Tigrinya': 'ሙዚቃ',
      'English': 'Music',
      'Amharic': 'ሙዚቃ'
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
      'Amharic': 'ንግድ'
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
      'Amharic': 'ስራ'
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

    // ── LAND ────────────────────────────────────────
    'country_norge': {
      'Norsk': 'Norge',
      'Tigrinya': 'ኖርወይ',
      'English': 'Norway',
      'Amharic': 'ኖርዌ'
    },
    'country_uganda': {
      'Norsk': 'Uganda',
      'Tigrinya': 'ኡጋንዳ',
      'English': 'Uganda',
      'Amharic': 'ዩጋንዳ'
    },
    'country_eritrea': {
      'Norsk': 'Eritrea',
      'Tigrinya': 'ኤርትራ',
      'English': 'Eritrea',
      'Amharic': 'ኤርትራ'
    },
    'country_etiopia': {
      'Norsk': 'Etiopia',
      'Tigrinya': 'ኢትዮጵያ',
      'English': 'Ethiopia',
      'Amharic': 'ኢትዮጵያ'
    },
    'country_sverige': {
      'Norsk': 'Sverige',
      'Tigrinya': 'ስዊደን',
      'English': 'Sweden',
      'Amharic': 'ስዊድን'
    },
    'country_nederland': {
      'Norsk': 'Nederland',
      'Tigrinya': 'ነዘርላንድ',
      'English': 'Netherlands',
      'Amharic': 'ኔዘርላንድ'
    },
    'country_frankrike': {
      'Norsk': 'Frankrike',
      'Tigrinya': 'ፈረንሳ',
      'English': 'France',
      'Amharic': 'ፈረንሳይ'
    },
    'country_sveits': {
      'Norsk': 'Sveits',
      'Tigrinya': 'ስዊዘርላንድ',
      'English': 'Switzerland',
      'Amharic': 'ስዊዘርላንድ'
    },
    'country_tyskland': {
      'Norsk': 'Tyskland',
      'Tigrinya': 'ጀርመን',
      'English': 'Germany',
      'Amharic': 'ጀርመን'
    },
    'country_egypt': {
      'Norsk': 'Egypt',
      'Tigrinya': 'ግብጺ',
      'English': 'Egypt',
      'Amharic': 'ግብፅ'
    },
    'country_kenya': {
      'Norsk': 'Kenya',
      'Tigrinya': 'ኬንያ',
      'English': 'Kenya',
      'Amharic': 'ኬንያ'
    },
    'country_danmark': {
      'Norsk': 'Danmark',
      'Tigrinya': 'ዴንማርክ',
      'English': 'Denmark',
      'Amharic': 'ዴንማርክ'
    },
    'country_uk': {
      'Norsk': 'Storbritannia',
      'Tigrinya': 'ዓባይ ብሪጣንያ',
      'English': 'United Kingdom',
      'Amharic': 'ዩናይትድ ኪንግደም'
    },
    'country_belgia': {
      'Norsk': 'Belgia',
      'Tigrinya': 'ቤልጅዬም',
      'English': 'Belgium',
      'Amharic': 'ቤልጂየም'
    },
    'country_italia': {
      'Norsk': 'Italia',
      'Tigrinya': 'ጣልያን',
      'English': 'Italy',
      'Amharic': 'ጣሊያን'
    },
    'country_usa': {
      'Norsk': 'USA',
      'Tigrinya': 'ኣሜሪካ',
      'English': 'USA',
      'Amharic': 'አሜሪካ'
    },
    'country_canada': {
      'Norsk': 'Canada',
      'Tigrinya': 'ካናዳ',
      'English': 'Canada',
      'Amharic': 'ካናዳ'
    },
    'onboard_1_title': {
      'Norsk': 'Velkommen til Habesha Hub',
      'English': 'Welcome to Habesha Hub',
      'Tigrinya': 'እንቋዕ ናብ ሓበሻ ሃብ መጻእካ',
      'Amharic': 'እንኳን ወደ ሃበሻ ሃብ በደህና መጡ'
    },
    'onboard_1_desc': {
      'Norsk':
          'Finn etiopiske og eritreiske bedrifter nær deg og over hele verden',
      'English':
          'Find Ethiopian and Eritrean businesses near you and worldwide',
      'Tigrinya': 'ናይ ኢትዮጵያን ኤርትራን ትካላት ኣብ ቀረባካን ዓለም ለኸን ርኸብ',
      'Amharic': 'የኢትዮጵያ እና ኤርትራ ድርጅቶችን በአካባቢዎ እና በዓለም ዙሪያ ያግኙ'
    },
    'onboard_2_title': {
      'Norsk': 'Utforsk restauranter og butikker',
      'English': 'Explore restaurants and shops',
      'Tigrinya': 'ቤት መግብን ድኳናትን ድለ',
      'Amharic': 'ምግብ ቤቶችን እና መደብሮችን ያስሱ'
    },
    'onboard_2_desc': {
      'Norsk':
          'Bla gjennom hundrevis av Habesha-bedrifter sortert etter kategori og sted',
      'English':
          'Browse hundreds of Habesha businesses sorted by category and location',
      'Tigrinya': 'ብዙሓት ናይ ሓበሻ ትካላት ብዓይነትን ቦታን ደሊ',
      'Amharic': 'በምድብ እና ቦታ የተደራጁ በመቶዎች የሚቆጠሩ የሃበሻ ድርጅቶችን ያስሱ'
    },
    'onboard_3_title': {
      'Norsk': 'Chat og book direkte',
      'English': 'Chat and book directly',
      'Tigrinya': 'ቻት ግበርን ቦኪ ግበርን',
      'Amharic': 'ቀጥታ ያውሩ እና ቀጠሮ ይያዙ'
    },
    'onboard_3_desc': {
      'Norsk': 'Send melding til bedrifter og bestill time direkte i appen',
      'English': 'Message businesses and book appointments directly in the app',
      'Tigrinya': 'ናብ ትካላት መልእኽቲ ስደድን ቀጠሮ ሓዝን',
      'Amharic': 'ለድርጅቶች መልዕክት ይላኩ እና ቀጠሮ ይያዙ'
    },
    'skip': {
      'Norsk': 'Hopp over',
      'English': 'Skip',
      'Tigrinya': 'ሕለፍ',
      'Amharic': 'ዝለል'
    },
    'get_started': {
      'Norsk': 'Kom i gang',
      'English': 'Get Started',
      'Tigrinya': 'ጀምር',
      'Amharic': 'ጀምር'
    },
    'next': {
      'Norsk': 'Neste',
      'English': 'Next',
      'Tigrinya': 'ቀጺሉ',
      'Amharic': 'ቀጣይ'
    },
  };
}
