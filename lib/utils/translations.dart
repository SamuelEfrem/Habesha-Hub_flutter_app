class AppTranslations {
  static String _language = 'Norsk';

  static void setLanguage(String lang) {
    _language = lang;
  }

  static String get(String key) {
    return _translations[key]?[_language] ??
        _translations[key]?['Norsk'] ??
        key;
  }

  static final Map<String, Map<String, String>> _translations = {
    // ── 1-5 NAVIGASJON ─────────────────────────────────────
    'home': {
      'Norsk': 'Hjem',
      'Tigrinya': 'ገዛ',
      'English': 'Home',
    },
    'explore': {
      'Norsk': 'Utforsk',
      'Tigrinya': 'ዳህስስ',
      'English': 'Explore',
    },
    'chat': {
      'Norsk': 'Chat',
      'Tigrinya': 'ዕላል',
      'English': 'Chat',
    },
    'favorites': {
      'Norsk': 'Favoritter',
      'Tigrinya': 'ዝፈትዎም',
      'English': 'Favorites',
    },
    'profile': {
      'Norsk': 'Profil',
      'Tigrinya': 'ፕሮፋይል',
      'English': 'Profile',
    },

    // ── 6-12 HJEM ──────────────────────────────────────────
    'find_here': {
      'Norsk': 'Finn her',
      'Tigrinya': 'ኣብዚ ድለ',
      'English': 'Find here',
    },
    'searching': {
      'Norsk': 'Søker...',
      'Tigrinya': 'ምንዳይ...',
      'English': 'Searching...',
    },
    'search_nearby': {
      'Norsk': 'Søk i nærheten',
      'Tigrinya': 'ኣብዚ ተዊቕካ ኣብ ጥቃኻ ዘሎ ትካላት ርከብ',
      'English': 'Tap to search nearby',
    },
    'businesses_found': {
      'Norsk': 'bedrifter funnet',
      'Tigrinya': 'ንግዳዊ ትካላት ተረኺቡ',
      'English': 'businesses found',
    },
    'search_hint': {
      'Norsk': 'Søk etter restaurant, frisør eller butikk...',
      'Tigrinya': 'ቤት መግቢ፡ መስተኻኸሊ ጸጕሪ ወይ ድኳን ድለ...',
      'English': 'Search for restaurant, barber or shop...',
    },
    'no_businesses': {
      'Norsk': 'Ingen bedrifter funnet',
      'Tigrinya': 'ዝተረኽቡ ትካላት የለዉን',
      'English': 'No businesses found',
    },
    'refresh': {
      'Norsk': 'Oppdater',
      'Tigrinya': 'ኣሐድስ',
      'English': 'Refresh',
    },

    // ── 13-20 KATEGORIER ───────────────────────────────────
    'all': {
      'Norsk': 'Alle',
      'Tigrinya': 'ኵሉ',
      'English': 'All',
    },
    'restaurant': {
      'Norsk': 'Restaurant',
      'Tigrinya': 'ቤት ምግቢ',
      'English': 'Restaurant',
    },
    'shop': {
      'Norsk': 'Butikk',
      'Tigrinya': 'ዱኳን',
      'English': 'Shop',
    },
    'cafe': {
      'Norsk': 'Kafé',
      'Tigrinya': 'ካፈ',
      'English': 'Café',
    },
    'barber': {
      'Norsk': 'Frisør',
      'Tigrinya': 'መስተኻኸሊ ጸጉሪ',
      'English': 'Barbery',
    },
    'club': {
      'Norsk': 'Club',
      'Tigrinya': 'ክለብ',
      'English': 'Club',
    },
    'clinic': {
      'Norsk': 'Klinikk',
      'Tigrinya': 'ሕክምና',
      'English': 'Clinic',
    },
    'other': {
      'Norsk': 'Annet',
      'Tigrinya': 'ካልእ',
      'English': 'Other',
    },

    // ── 21-26 UTFORSK ──────────────────────────────────────
    'explore_title': {
      'Norsk': 'Utforsk',
      'Tigrinya': 'ዳህስስ',
      'English': 'Explore',
    },
    'explore_desc': {
      'Norsk': 'Finn Habesha bedrifter i hele verden',
      'Tigrinya': 'ኣብ መላእ ዓለም ዚርከባ ትካላት ሓበሻ ርኸቡ',
      'English': 'Find Habesha businesses worldwide',
    },
    'all_cities': {
      'Norsk': 'Alle byer',
      'Tigrinya': 'ኵለን ከተማታት',
      'English': 'All cities',
    },
    'search_in': {
      'Norsk': 'Søk i',
      'Tigrinya': 'ኣብ ዝስዕብ ድለ',
      'English': 'Search in',
    },
    'select_country': {
      'Norsk': 'Velg et land for å utforske',
      'Tigrinya': 'ክትድህስሶ እትደሊ ሃገር ምረጽ',
      'English': 'Select a country to explore',
    },
    'no_businesses_country': {
      'Norsk': 'Ingen bedrifter i dette landet',
      'Tigrinya': 'ኣብዚ ሃገር እዚ ዋላ ሓንቲ ትካል የለን',
      'English': 'No businesses in this country',
    },

    // ── 27-61 BEDRIFT-DETALJE ──────────────────────────────
    'info_tab': {
      'Norsk': 'INFO',
      'Tigrinya': 'ሓበሬታ',
      'English': 'INFO',
    },
    'chat_tab': {
      'Norsk': 'CHAT',
      'Tigrinya': 'ዕላል',
      'English': 'CHAT',
    },
    'open_now': {
      'Norsk': 'ÅPEN NÅ',
      'Tigrinya': 'ሕጂ ኽፉት እዩ',
      'English': 'OPEN NOW',
    },
    'closed': {
      'Norsk': 'STENGT',
      'Tigrinya': 'ዕጹው',
      'English': 'CLOSED',
    },
    'closes_at': {
      'Norsk': 'Stenger',
      'Tigrinya': 'ኣብ X ይዕጾ',
      'English': 'Closes at',
    },
    'opens_at': {
      'Norsk': 'Åpner',
      'Tigrinya': 'ዝኽፈተሉ ሳዓት',
      'English': 'Opens at',
    },
    'closed_today': {
      'Norsk': 'Stengt i dag',
      'Tigrinya': 'ሎሚ ዕጹው እዩ',
      'English': 'Closed today',
    },
    'no_opening_hours': {
      'Norsk': 'Åpningstider ikke oppgitt',
      'Tigrinya': 'ናይ ስራሕ ሰዓታት ኣይተዋህበን',
      'English': 'Opening hours not provided',
    },
    'view_menu': {
      'Norsk': 'Vis meny',
      'Tigrinya': 'ዝርዝር ርአ',
      'English': 'View menu',
    },
    'menu_not_available': {
      'Norsk': 'Meny ikke tilgjengelig',
      'Tigrinya': 'ዝርዝር መግቢ ኣይተረከበን',
      'English': 'Menu not available',
    },
    'upload_menu': {
      'Norsk': 'Last opp meny',
      'Tigrinya': 'ሜኑ ጽዓን',
      'English': 'Upload menu',
    },
    'uploading': {
      'Norsk': 'Laster opp...',
      'Tigrinya': 'ይጽዕን ኣሎ...',
      'English': 'Uploading...',
    },
    'want_upload_menu': {
      'Norsk': 'Vil du laste opp meny?',
      'Tigrinya': 'ሜኑ ክትጽዕኑ ትደልዩ ዲኹም?',
      'English': 'Want to upload a menu?',
    },
    'contact_for_premium': {
      'Norsk': 'Kontakt oss for å oppgradere til Premium',
      'Tigrinya': 'ናብ ፕሪሚየም ንምምሕያሽ ምሳና ተራኸቡ',
      'English': 'Contact us to upgrade to Premium',
    },
    'full_address': {
      'Norsk': 'FULL ADRESSE',
      'Tigrinya': 'ምሉእ ኣድራሻ',
      'English': 'FULL ADDRESS',
    },
    'no_address': {
      'Norsk': 'Adresse ikke oppgitt',
      'Tigrinya': 'ኣድራሻ ኣይተዋህበን',
      'English': 'Address not provided',
    },
    'map': {
      'Norsk': 'Kart',
      'Tigrinya': 'ካርታ',
      'English': 'Map',
    },
    'call': {
      'Norsk': 'Ring',
      'Tigrinya': 'ደውሉ',
      'English': 'Call',
    },
    'web': {
      'Norsk': 'Web',
      'Tigrinya': 'ወብሳይት',
      'English': 'Web',
    },
    'no_website': {
      'Norsk': 'Ingen nettside registrert',
      'Tigrinya': 'ዝተመዝገበ መርበብ ሓበሬታ የለን',
      'English': 'No website registered',
    },
    'open_map': {
      'Norsk': 'Åpne kart',
      'Tigrinya': 'ካርታ ክፈት',
      'English': 'Open map',
    },
    'no_description': {
      'Norsk': 'Ingen beskrivelse tilgjengelig',
      'Tigrinya': 'ዝኾነ መግለጺ የለን',
      'English': 'No description available',
    },
    'premium_partner': {
      'Norsk': 'Premium Partner',
      'Tigrinya': 'ፕሪሚየም መሻርኽቲ',
      'English': 'Premium Partner',
    },
    'verified_business': {
      'Norsk': 'VERIFIED BUSINESS',
      'Tigrinya': 'ዝተረጋገጸ ትካል',
      'English': 'VERIFIED BUSINESS',
    },
    'priority_booking': {
      'Norsk': 'PRIORITY BOOKING',
      'Tigrinya': 'ቀዳምነት ዝወሃቦ ምዕዳግ',
      'English': 'PRIORITY BOOKING',
    },
    'digital_menu': {
      'Norsk': 'DIGITAL MENU ACCESS',
      'Tigrinya': 'ናይ ዲጂታል ሜኑ መእተዊ',
      'English': 'DIGITAL MENU ACCESS',
    },
    'rate_business': {
      'Norsk': 'Vurder denne bedriften',
      'Tigrinya': 'ነዚ ትካል እዚ ዓቐን ሃብ',
      'English': 'Rate this business',
    },
    'your_rating': {
      'Norsk': 'Din vurdering',
      'Tigrinya': 'ናትካ ዓቐን ምዕቃን',
      'English': 'Your rating',
    },
    'submit_rating': {
      'Norsk': 'Send vurdering',
      'Tigrinya': 'ደረጃ ምሃብ ኣቕርብ',
      'English': 'Submit rating',
    },
    'gave_stars': {
      'Norsk': 'Du ga',
      'Tigrinya': 'ሂብካ',
      'English': 'You gave',
    },
    'stars': {
      'Norsk': 'stjerner',
      'Tigrinya': 'ኮኾብ',
      'English': 'stars',
    },
    'edit': {
      'Norsk': 'Rediger',
      'Tigrinya': 'ምምሕያሽ',
      'English': 'Edit',
    },
    'delete_business': {
      'Norsk': 'Slett bedrift',
      'Tigrinya': 'ትካል ደምስስ',
      'English': 'Delete business',
    },
    'are_you_sure': {
      'Norsk': 'Er du sikker?',
      'Tigrinya': 'ርግጸኛ ዲኻ/ኺ?',
      'English': 'Are you sure?',
    },
    'cancel': {
      'Norsk': 'Avbryt',
      'Tigrinya': 'ሰርዝ',
      'English': 'Cancel',
    },
    'delete': {
      'Norsk': 'Slett',
      'Tigrinya': 'ደምስስ',
      'English': 'Delete',
    },

    // ── 62-64 CHAT ─────────────────────────────────────────
    'chatting_as': {
      'Norsk': 'Chatter som:',
      'Tigrinya': 'ከምዚ ዝስዕብ ኮይኑ ይዘራረብ ኣሎ፦',
      'English': 'Chatting as:',
    },
    'type_message': {
      'Norsk': 'Skriv en melding...',
      'Tigrinya': 'መልእኽቲ ጽሓፍ...',
      'English': 'Write a message...',
    },
    'no_messages': {
      'Norsk': 'Ingen meldinger ennå.\nVær den første til å skrive!',
      'Tigrinya': 'ክሳዕ ሕጂ መልእኽትታት የለዉን። ቀዳማይ ጽሓፊ ኩን!',
      'English': 'No messages yet.\nBe the first to write!',
    },

    // ── 65-67 MELDINGER ────────────────────────────────────
    'messages_title': {
      'Norsk': 'Meldinger',
      'Tigrinya': 'መልእኽትታት',
      'English': 'Messages',
    },
    'no_chats': {
      'Norsk': 'Ingen meldinger ennå',
      'Tigrinya': 'ክሳዕ ሕጂ መልእኽትታት የለዉን',
      'English': 'No messages yet',
    },
    'start_chat': {
      'Norsk': 'Gå til en bedrift og start en chat!',
      'Tigrinya': 'ናብ ሓደ ትካል ኬድካ ዕላል ጀምር!',
      'English': 'Go to a business and start a chat!',
    },

    // ── 68-70 FAVORITTER ───────────────────────────────────
    'favorites_title': {
      'Norsk': 'Favoritter',
      'Tigrinya': 'ፍቱዋት',
      'English': 'Favorites',
    },
    'no_favorites': {
      'Norsk': 'Ingen favoritter ennå',
      'Tigrinya': 'ክሳዕ ሕጂ ፍቱዋት የለዉን',
      'English': 'No favorites yet',
    },
    'tap_heart': {
      'Norsk': 'Trykk ♥ på en bedrift for å lagre den',
      'Tigrinya': 'ንምዕቓብ ♥ ጠውቕ',
      'English': 'Tap ♥ on a business to save it',
    },

    // ── 71-89 PROFIL ───────────────────────────────────────
    'guest': {
      'Norsk': 'Gjest',
      'Tigrinya': 'ጋሻ',
      'English': 'Guest',
    },
    'login_for_access': {
      'Norsk': 'Logg inn for å få full tilgang',
      'Tigrinya': 'ምሉእ መሰል ንምርካብ እተው',
      'English': 'Log in to get full access',
    },
    'login_register': {
      'Norsk': 'Logg inn / Registrer deg',
      'Tigrinya': 'እቶ / ተመዝገብ',
      'English': 'Log in / Register',
    },
    'login_for_business': {
      'Norsk': 'Logg inn for å registrere bedrift, se dine bedrifter og mer.',
      'Tigrinya': 'ትካል ንምምዝጋብ እተዉ',
      'English': 'Log in to register a business, see your businesses and more.',
    },
    'login': {
      'Norsk': 'Logg inn',
      'Tigrinya': 'እቶ',
      'English': 'Log in',
    },
    'nickname': {
      'Norsk': 'Kallenavn',
      'Tigrinya': 'ቅጽል ስም',
      'English': 'Nickname',
    },
    'nickname_hint': {
      'Norsk': 'Ditt kallenavn i chat...',
      'Tigrinya': 'ናይ ቻት ቅጽል ስምካ...',
      'English': 'Your chat nickname...',
    },
    'language': {
      'Norsk': 'Language',
      'Tigrinya': 'ቋንቋ',
      'English': 'Language',
    },
    'save': {
      'Norsk': 'Lagre',
      'Tigrinya': 'ዓቕብ',
      'English': 'Save',
    },
    'saved': {
      'Norsk': 'Lagret!',
      'Tigrinya': 'ተዓቂቡ!',
      'English': 'Saved!',
    },
    'register_business': {
      'Norsk': 'Register Your Business',
      'Tigrinya': 'ንካልካ መዝግብ',
      'English': 'Register Your Business',
    },
    'my_businesses': {
      'Norsk': 'Mine bedrifter',
      'Tigrinya': 'ናተይ ትካላት',
      'English': 'My businesses',
    },
    'no_businesses_yet': {
      'Norsk': 'Du har ingen bedrifter ennå.',
      'Tigrinya': 'ክሳዕ ሕጂ ዋላ ሓንቲ ትካላት የብልኩምን',
      'English': 'You have no businesses yet.',
    },
    'active': {
      'Norsk': 'AKTIV',
      'Tigrinya': 'ንጡፍ',
      'English': 'ACTIVE',
    },
    'premium': {
      'Norsk': 'PREMIUM',
      'Tigrinya': 'ፕሪሚየም',
      'English': 'PREMIUM',
    },
    'help_support': {
      'Norsk': 'Help & Support',
      'Tigrinya': 'ሓገዝን ደገፍን',
      'English': 'Help & Support',
    },
    'logout': {
      'Norsk': 'Logg ut',
      'Tigrinya': 'ካብ መእተዊ ውጻእ',
      'English': 'Log out',
    },
    'logged_out': {
      'Norsk': 'Du er logget ut',
      'Tigrinya': 'ወጺእካ ኣለኻ',
      'English': 'You are logged out',
    },
    'sure_logout': {
      'Norsk': 'Er du sikker på at du vil logge ut?',
      'Tigrinya': 'ካብ ሕሳብካ ክትወጽእ ከም እትደሊ ርግጸኛ ዲኻ?',
      'English': 'Are you sure you want to log out?',
    },

    // ── 90-106 REGISTRER BEDRIFT ───────────────────────────
    'register_title': {
      'Norsk': 'Registrer bedrift',
      'Tigrinya': 'ትካል ምምዝጋብ',
      'English': 'Register business',
    },
    'step_of': {
      'Norsk': 'Steg',
      'Tigrinya': 'ስጉምቲ',
      'English': 'Step',
    },
    'business_name': {
      'Norsk': 'BEDRIFTSNAVN',
      'Tigrinya': 'ስም ትካል ንግዲ',
      'English': 'BUSINESS NAME',
    },
    'category_label': {
      'Norsk': 'KATEGORI',
      'Tigrinya': 'ምድብ',
      'English': 'CATEGORY',
    },
    'description_label': {
      'Norsk': 'BESKRIVELSE',
      'Tigrinya': 'መግለጺ',
      'English': 'DESCRIPTION',
    },
    'address_label': {
      'Norsk': 'ADRESSE',
      'Tigrinya': 'ኣድራሻ',
      'English': 'ADDRESS',
    },
    'phone_label': {
      'Norsk': 'TELEFON',
      'Tigrinya': 'ተሌፎን',
      'English': 'PHONE',
    },
    'opening_hours': {
      'Norsk': 'ÅPNINGSTIDER',
      'Tigrinya': 'ሰዓታት ምኽፋት',
      'English': 'OPENING HOURS',
    },
    'closed_toggle': {
      'Norsk': 'Stengt',
      'Tigrinya': 'ዕጹው (መቐየሪ)',
      'English': 'Closed',
    },
    'opens_label': {
      'Norsk': 'Åpner',
      'Tigrinya': 'ይኽፈት',
      'English': 'Opens',
    },
    'closes_label': {
      'Norsk': 'Stenger',
      'Tigrinya': 'ይዕጾ',
      'English': 'Closes',
    },
    'image_url': {
      'Norsk': 'BILDE URL',
      'Tigrinya': 'ስእሊ URL',
      'English': 'IMAGE URL',
    },
    'website_optional': {
      'Norsk': 'NETTSIDE (valgfritt)',
      'Tigrinya': 'መርበብ ሓበሬታ (ኣማራጺ)',
      'English': 'WEBSITE (optional)',
    },
    'submit_approval': {
      'Norsk': 'Send til godkjenning',
      'Tigrinya': 'ንምጽዳቕ ኣቕርብ',
      'English': 'Submit for approval',
    },
    'submitted': {
      'Norsk': 'Bedrift sendt til godkjenning!',
      'Tigrinya': 'ትካል ንምጽዳቕ ተረኪቡ!',
      'English': 'Business submitted for approval!',
    },
    'next': {
      'Norsk': 'Neste',
      'Tigrinya': 'ዝቕጽል',
      'English': 'Next',
    },
    'back': {
      'Norsk': 'Tilbake',
      'Tigrinya': 'ንድሕሪት',
      'English': 'Back',
    },

    // ── 107-117 INNLOGGING ─────────────────────────────────
    'log_in_tab': {
      'Norsk': 'LOGG INN',
      'Tigrinya': 'እቶ',
      'English': 'LOG IN',
    },
    'register_tab': {
      'Norsk': 'REGISTRER',
      'Tigrinya': 'ምዝገባ',
      'English': 'REGISTER',
    },
    'welcome_back': {
      'Norsk': 'Velkommen tilbake',
      'Tigrinya': 'እንቋዕ ብደሓን መጻእካ',
      'English': 'Welcome back',
    },
    'email_label': {
      'Norsk': 'E-POST',
      'Tigrinya': 'ኢ-መይል',
      'English': 'EMAIL',
    },
    'password_label': {
      'Norsk': 'PASSORD',
      'Tigrinya': 'ፓስዎርድ',
      'English': 'PASSWORD',
    },
    'no_account': {
      'Norsk': 'Har du ikke konto? Registrer deg',
      'Tigrinya': 'ኣካውንት የብልካን ድዩ? ተመዝገብ',
      'English': "Don't have an account? Register",
    },
    'create_account': {
      'Norsk': 'Opprett konto',
      'Tigrinya': 'ኣካውንት ክፈት',
      'English': 'Create account',
    },
    'have_account': {
      'Norsk': 'Har du allerede konto? Logg inn',
      'Tigrinya': 'ኣካውንት ኣለካ ድዩ? እቶ',
      'English': 'Already have an account? Log in',
    },
    'email_not_verified': {
      'Norsk': 'E-posten er ikke bekreftet',
      'Tigrinya': 'ኢመይል ኣይተረጋገጸን',
      'English': 'Email not verified',
    },
    'resend': {
      'Norsk': 'Send på nytt',
      'Tigrinya': 'ዳግማይ ስደድ',
      'English': 'Resend',
    },
    'verify_email': {
      'Norsk': 'Bekreft e-post',
      'Tigrinya': 'ኢ-መይል ኣረጋግጽ',
      'English': 'Verify email',
    },

    // ── 118-123 KONTAKT ────────────────────────────────────
    'contact_us': {
      'Norsk': 'Kontakt oss',
      'Tigrinya': 'ርኸቡና',
      'English': 'Contact us',
    },
    'message_label': {
      'Norsk': 'MELDING',
      'Tigrinya': 'መልእኽቲ',
      'English': 'MESSAGE',
    },
    'message_hint': {
      'Norsk': 'Skriv din melding her...',
      'Tigrinya': 'መልእኽትኻ ኣብዚ ጽሓፍ...',
      'English': 'Write your message here...',
    },
    'send_message': {
      'Norsk': 'Send melding',
      'Tigrinya': 'መልእኽቲ ስደድ',
      'English': 'Send message',
    },
    'message_sent': {
      'Norsk': 'Melding sendt!',
      'Tigrinya': 'መልእኽቲ ተላኢኹ!',
      'English': 'Message sent!',
    },
    'will_reply': {
      'Norsk': 'Vi svarer deg så snart som mulig.',
      'Tigrinya': 'ብዝተኻእለ መጠን ቀልጢፍና ክንምልሰልኩም ኢና',
      'English': 'We will reply as soon as possible.',
    },

    // ── EKSTRA NØKLER ──────────────────────────────────────
    'nearby_desc': {
      'Norsk': 'Trykk på sirkelen for å finne Habesha-bedrifter i nærheten',
      'Tigrinya': 'ናይ ሓበሻ ቢዝነሳት ንምርካብ ኣብቲ ከቢብ ጠውቕ',
      'English': 'Tap the circle to find Habesha businesses nearby',
    },
    'set_nickname': {
      'Norsk': 'Sett kallenavn i Profil for å bruke chat',
      'Tigrinya': 'ቻት ንምጥቃም ኣብ ፕሮፋይል ሳጓ ኣቐምጥ',
      'English': 'Set nickname in Profile to use chat',
    },
    'be_first': {
      'Norsk': 'Vær den første til å registrere en!',
      'Tigrinya': 'ንምምዝጋብ ቀዳማይ ኩን!',
      'English': 'Be the first to register one!',
    },
    'habesha_user': {
      'Norsk': 'Habesha Hub Bruker',
      'Tigrinya': 'ናይ ሓበሻ ሃብ ተጠቃሚ',
      'English': 'Habesha Hub User',
    },
    'distance': {
      'Norsk': 'unna',
      'Tigrinya': 'ርሕቀት',
      'English': 'away',
    },
    'of': {
      'Norsk': 'av',
      'Tigrinya': 'ካብ',
      'English': 'of',
    },
    'admin_panel': {
      'Norsk': 'Admin Panel',
      'Tigrinya': 'ናይ ምምሕዳር ሰሌዳ',
      'English': 'Admin Panel',
    },
    'register_desc': {
      'Norsk': 'Kom i gang med Habesha Hub',
      'Tigrinya': 'ምስ ሓበሻ ሃብ ተሳተፍ',
      'English': 'Get started with Habesha Hub',
    },
    'digital_heritage': {
      'Norsk': 'Establish Your\nDigital Heritage.',
      'Tigrinya': 'ናይ ዲጂታል\nወርሲ ምምስራት',
      'English': 'Establish Your\nDigital Heritage.',
    },
    'businesses_registered_desc': {
      'Norsk': 'Bedrifter du har registrert.',
      'Tigrinya': 'ዝምዝገብካዮም ንግድታት።',
      'English': 'Businesses you have registered.',
    },
    'menu_not_available_yet': {
      'Norsk': 'Meny ikke tilgjengelig ennå',
      'Tigrinya': 'ሜኑ ገና ኣይተጸዓነን',
      'English': 'Menu not available yet',
    },
    'pending_review': {
      'Norsk': 'Bedriften er under gjennomgang. Vanligvis 1-2 virkedager.',
      'Tigrinya': 'ቢዝነስ ይምርመር ኣሎ። ብልሙድ 1-2 መዓልቲ ስራሕ ይወስድ።',
      'English': 'Business is under review. Usually 1-2 business days.',
    },
    'premium_desc': {
      'Norsk': 'Verifisert medlem av Habesha Hub Elite-nettverket.',
      'Tigrinya': 'ናይ ሓበሻ ሃብ ኤሊት ኔትወርክ ዝተረጋገጸ ኣባል።',
      'English': 'Verified member of Habesha Hub Elite network.',
    },
  };
}
