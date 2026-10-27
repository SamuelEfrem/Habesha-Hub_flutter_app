class AppTranslations {
  static String _language = 'English';

  static void setLanguage(String lang) {
    _language = (lang == 'Tigrinya' || lang == 'Amharic') ? lang : 'English';
  }

  /// Translate an English UI text to the selected language.
  /// Old Norwegian values stored in Firestore are mapped to English first.
  static String tr(String text) {
    final en = _aliases[text] ?? text;
    if (_language == 'English') return en;
    return _textTr[en]?[_language] ?? en;
  }

  static const Map<String, String> _aliases = {
    'Man - Fre': 'Mon - Fri',
    'Man-Fre': 'Mon - Fri',
    'Lørdag': 'Saturday',
    'Søndag': 'Sunday',
    'Stengt': 'Closed',
    'Butikk': 'Shop',
    'Kafé': 'Cafe',
    'Frisør': 'Barber',
    'Klinikk': 'Clinic',
    'Annet': 'Other',
    'Mandag': 'Monday',
    'Tirsdag': 'Tuesday',
    'Onsdag': 'Wednesday',
    'Torsdag': 'Thursday',
    'Fredag': 'Friday',
    'Man - Søn': 'Mon - Sun',
    'Man - Lør': 'Mon - Sat',
    'Man - Tor': 'Mon - Thu',
    'Lør - Søn': 'Sat - Sun',
    'Fre - Lør': 'Fri - Sat',
    'Tir - Søn': 'Tue - Sun',
    'Tir - Lør': 'Tue - Sat',
    'Etiopia': 'Ethiopia',
    'Norge': 'Norway',
    'Sverige': 'Sweden',
    'Danmark': 'Denmark',
    'Tyskland': 'Germany',
    'Nederland': 'Netherlands',
    'Frankrike': 'France',
    'Belgia': 'Belgium',
    'Sveits': 'Switzerland',
    'Italia': 'Italy',
  };

  static const Map<String, Map<String, String>> _textTr = {
    'Customer': {'Tigrinya': 'ዓሚል', 'Amharic': 'ደንበኛ'},
    'Favorite services': {'Tigrinya': 'ዝፈትዎም ኣገልግሎታት', 'Amharic': 'የምወዳቸው አገልግሎቶች'},
    'How was the service?': {'Tigrinya': 'ኣገልግሎት ከመይ ነይሩ?', 'Amharic': 'አገልግሎቱ እንዴት ነበር?'},
    'No favorite services yet': {'Tigrinya': 'ገና ዝፈትዎ ኣገልግሎት የለን', 'Amharic': 'እስካሁን የሚወዱት አገልግሎት የለም'},
    'No reviews yet. Customers can review after their booking is completed.': {'Tigrinya': 'ገና ርእይቶ የለን። ዓማዊል ድሕሪ ቡኪንጎም ምዝዛሙ ርእይቶ ክህቡ ይኽእሉ።', 'Amharic': 'እስካሁን አስተያየት የለም። ደንበኞች ቦታ ማስያዣቸው ከተጠናቀቀ በኋላ አስተያየት መስጠት ይችላሉ።'},
    'Removed from favorites': {'Tigrinya': 'ካብ ዝፈትዎም ተኣልዩ', 'Amharic': 'ከተወዳጆች ተወግዷል'},
    'Saved to favorites': {'Tigrinya': 'ኣብ ዝፈትዎም ተዓቂቡ', 'Amharic': 'በተወዳጆች ተቀምጧል'},
    'See photos, videos and book here': {'Tigrinya': 'ስእልታትን ቪድዮታትን ርኣዩን ኣብዚ ሓዙን', 'Amharic': 'ፎቶዎችን ቪዲዮዎችን ይመልከቱ እና እዚህ ያስይዙ'},
    'Send review': {'Tigrinya': 'ርእይቶ ልኣኽ', 'Amharic': 'አስተያየት ይላኩ'},
    'Share': {'Tigrinya': 'ኣካፍል', 'Amharic': 'አጋራ'},
    'Tap the heart on a provider to save it here.': {'Tigrinya': 'ኣብዚ ንምዕቃብ ነቲ ልቢ ኣብ ኣቕራቢ ጠውቑ።', 'Amharic': 'እዚህ ለማስቀመጥ በአቅራቢው ላይ ያለውን ልብ ይጫኑ።'},
    'Thank you for your review!': {'Tigrinya': 'ስለ ርእይቶኹም የቐንየልና!', 'Amharic': 'ስለ አስተያየትዎ እናመሰግናለን!'},
    'Write a short review (optional)': {'Tigrinya': 'ሓጺር ርእይቶ ጽሓፉ (ኣማራጺ)', 'Amharic': 'አጭር አስተያየት ይጻፉ (አማራጭ)'},
    '• Email and name\n• Bookings, receipts and payment status\n• Chat messages, reviews and marketplace listings\n• AI assistant questions (answered by Google Gemini)\n• Notification token for push messages\n• GPS (only when searching, not stored)\n• Favorites and settings (only on your phone)': {'Tigrinya': '• ኢመይልን ስምን\n• ቡኪንግታት፡ ቅብሊትን ኩነታት ክፍሊትን\n• መልእኽቲ ዕላል፡ ርእይቶታትን መሸጣን\n• ሕቶታት ኣብ AI ሓጋዚ (ብ Google Gemini ዝምለሱ)\n• ምልክት ንመልእኽቲ ፑሽ\n• GPS (ኣብ ግዜ ምድላይ ጥራይ፡ ኣይዕቀብን)\n• ዝፈትዎም ትካላትን ቅጥዕታትን (ኣብ ስልኪ ጥራይ)', 'Amharic': '• ኢሜይል እና ስም\n• ቦታ ማስያዣዎች፣ ደረሰኞች እና የክፍያ ሁኔታ\n• የውይይት መልዕክቶች፣ አስተያየቶች እና የገበያ ማስታወቂያዎች\n• ለAI ረዳት የሚቀርቡ ጥያቄዎች (በGoogle Gemini የሚመለሱ)\n• ለፑሽ መልዕክቶች ማሳወቂያ ቶከን\n• GPS (ሲፈልጉ ብቻ፣ አይቀመጥም)\n• የሚወዷቸው እና ቅንብሮች (በስልክዎ ላይ ብቻ)'},
    'Payments': {'Tigrinya': 'ክፍሊታት', 'Amharic': 'ክፍያዎች'},
    'We never store card or bank numbers. You pay directly with Vipps, Swish, PayPal, Mobile Money or similar.': {'Tigrinya': 'ቁጽሪ ካርድ ወይ ባንኪ ፈጺምና ኣይንዕቅብን። ብቐጥታ ብ Vipps፡ Swish፡ PayPal፡ Mobile Money ወይ ተመሳሳሊ ትኸፍሉ።', 'Amharic': 'የካርድ ወይም የባንክ ቁጥር ፈጽሞ አናስቀምጥም። በቀጥታ በVipps፣ Swish፣ PayPal፣ Mobile Money ወይም በተመሳሳይ ይከፍላሉ።'},
    'Your rights': {'Tigrinya': 'መሰላትኩም', 'Amharic': 'መብቶችዎ'},
    'You can see, correct or delete your data at any time. Delete your account under Profile, or contact support@habesha-hub.no.': {'Tigrinya': 'ሓበሬታኹም ኣብ ዝኾነ ግዜ ክትርእዩ፡ ክተዐርዩ ወይ ክትድምስሱ ትኽእሉ ኢኹም። ሕሳብኩም ኣብ ፕሮፋይል ደምስሱ፡ ወይ support@habesha-hub.no ተወከሱ።', 'Amharic': 'መረጃዎን በማንኛውም ጊዜ ማየት፣ ማስተካከል ወይም መሰረዝ ይችላሉ። መለያዎን በመገለጫ ስር ይሰርዙ፣ ወይም support@habesha-hub.no ያግኙ።'},
    'Read the full privacy policy': {'Tigrinya': 'ምሉእ ፖሊሲ ብሕታውነት ኣንብብ', 'Amharic': 'ሙሉ የግላዊነት ፖሊሲውን ያንብቡ'},
    'After confirmation you pay with': {'Tigrinya': 'ድሕሪ ምጽዳቕ ትኸፍሉ ብ', 'Amharic': 'ከተረጋገጠ በኋላ የሚከፍሉት በ'},
    'Amount': {'Tigrinya': 'መጠን', 'Amharic': 'መጠን'},
    'Booking no.': {'Tigrinya': 'ቁጽሪ ቡኪንግ', 'Amharic': 'የቦታ ማስያዣ ቁጥር'},
    'Cancelled': {'Tigrinya': 'ተሰሪዙ', 'Amharic': 'ተሰርዟል'},
    'Completed': {'Tigrinya': 'ተዛዚሙ', 'Amharic': 'ተጠናቋል'},
    'Confirmed': {'Tigrinya': 'ጸዲቑ', 'Amharic': 'ጸድቋል'},
    'Copied': {'Tigrinya': 'ተቐዲሑ', 'Amharic': 'ተቀድቷል'},
    'Date': {'Tigrinya': 'ዕለት', 'Amharic': 'ቀን'},
    'How to pay': {'Tigrinya': 'ከመይ ትኸፍሉ', 'Amharic': 'እንዴት እንደሚከፍሉ'},
    'Log in to see your bookings': {'Tigrinya': 'ቡኪንግታትኩም ንምርኣይ እቶ', 'Amharic': 'ቦታ ማስያዣዎችዎን ለማየት ይግቡ'},
    'My bookings': {'Tigrinya': 'ቡኪንግታተይ', 'Amharic': 'የእኔ ቦታ ማስያዣዎች'},
    'No bookings yet': {'Tigrinya': 'ገና ቡኪንግ የለን', 'Amharic': 'እስካሁን ቦታ ማስያዣ የለም'},
    'Notes': {'Tigrinya': 'መዘኻኸሪ', 'Amharic': 'ማስታወሻ'},
    'Paid': {'Tigrinya': 'ተኸፊሉ', 'Amharic': 'ተከፍሏል'},
    'Pay with': {'Tigrinya': 'ክፈል ብ', 'Amharic': 'ይክፈሉ በ'},
    'Payment': {'Tigrinya': 'ክፍሊት', 'Amharic': 'ክፍያ'},
    'Payment received — thank you!': {'Tigrinya': 'ክፍሊት ተቐቢልና — የቐንየልና!', 'Amharic': 'ክፍያ ደርሷል — እናመሰግናለን!'},
    'Receipt': {'Tigrinya': 'ቅብሊት', 'Amharic': 'ደረሰኝ'},
    'Recipient': {'Tigrinya': 'ተቐባሊ', 'Amharic': 'ተቀባይ'},
    'Reference': {'Tigrinya': 'መወከሲ', 'Amharic': 'ማጣቀሻ'},
    'See my booking': {'Tigrinya': 'ቡኪንግይ ርአ', 'Amharic': 'ቦታ ማስያዣዬን ይመልከቱ'},
    'Service': {'Tigrinya': 'ኣገልግሎት', 'Amharic': 'አገልግሎት'},
    'Share receipt': {'Tigrinya': 'ቅብሊት ኣካፍል', 'Amharic': 'ደረሰኝ ያጋሩ'},
    'Status': {'Tigrinya': 'ኩነታት', 'Amharic': 'ሁኔታ'},
    'This booking was cancelled': {'Tigrinya': 'እዚ ቡኪንግ ተሰሪዙ', 'Amharic': 'ይህ ቦታ ማስያዣ ተሰርዟል'},
    'WHERE WILL YOU PAY FROM?': {'Tigrinya': 'ካበይ ኢኹም ትኸፍሉ?', 'Amharic': 'ከየት ይከፍላሉ?'},
    'Waiting for Habesha Hub to confirm': {'Tigrinya': 'Habesha Hub ክጸድቖ ንጽበ ኣለና', 'Amharic': 'Habesha Hub እስኪያረጋግጥ በመጠበቅ ላይ'},
    'Waiting for confirmation': {'Tigrinya': 'ምጽዳቕ ይጽበ', 'Amharic': 'ማረጋገጫ በመጠበቅ ላይ'},
    'Write this in the payment message': {'Tigrinya': 'እዚ ኣብ መልእኽቲ ክፍሊት ጽሓፉ', 'Amharic': 'ይህንን በክፍያ መልዕክቱ ላይ ይጻፉ'},
    'You get a receipt in the app.': {'Tigrinya': 'ቅብሊት ኣብ ኣፕ ክትረኽቡ ኢኹም።', 'Amharic': 'ደረሰኝ በመተግበሪያው ውስጥ ያገኛሉ።'},
    'Your booking is confirmed!': {'Tigrinya': 'ቡኪንግኩም ጸዲቑ!', 'Amharic': 'ቦታ ማስያዣዎ ጸድቋል!'},
    'ADDRESS': {'Tigrinya': 'ኣድራሻ', 'Amharic': 'አድራሻ'},
    'About': {'Tigrinya': 'ብዛዕባ', 'Amharic': 'ስለ'},
    'Accommodation': {'Tigrinya': 'መንበሪ', 'Amharic': 'ማረፊያ'},
    'Account deleted': {'Tigrinya': 'ሕሳብ ተሰሪዙ', 'Amharic': 'መለያ ተሰርዟል'},
    'Add an image for your business.': {'Tigrinya': 'ንትካልኩም ስእሊ ወስኹ።', 'Amharic': 'ለድርጅትዎ ምስል ያክሉ።'},
    'Add video': {'Tigrinya': 'ቪድዮ ወስኽ', 'Amharic': 'ቪዲዮ ያክሉ'},
    'Africa': {'Tigrinya': 'ኣፍሪቃ', 'Amharic': 'አፍሪካ'},
    'After you submit, the Habesha Hub team will review your business. This usually takes 1–2 business days. You will receive an email when it is approved.': {'Tigrinya': 'ድሕሪ ምልኣኽኩም ጉጅለ Habesha Hub ትካልኩም ክምርምሮ እዩ። እዚ ብልሙድ 1–2 ናይ ስራሕ መዓልትታት ይወስድ። ምስ ተቐበለ ኢመይል ክመጸኩም እዩ።', 'Amharic': 'ካስገቡ በኋላ የHabesha Hub ቡድን ድርጅትዎን ይገመግማል። ይህ አብዛኛውን ጊዜ 1–2 የሥራ ቀናት ይወስዳል። ሲጸድቅ ኢሜይል ይደርስዎታል።'},
    'Album': {'Tigrinya': 'ኣልበም', 'Amharic': 'አልበም'},
    'Already have an account? Log in': {'Tigrinya': 'ሕሳብ ኣለኩም ድዩ? እቶ', 'Amharic': 'መለያ አለዎት? ይግቡ'},
    'Americas': {'Tigrinya': 'ኣሜሪካታት', 'Amharic': 'አሜሪካዎች'},
    'Angola': {'Tigrinya': 'ኣንጎላ', 'Amharic': 'አንጎላ'},
    'Any special requests?': {'Tigrinya': 'ፍሉይ ሕቶ ኣለኩም ድዩ?', 'Amharic': 'ልዩ ጥያቄ አለዎት?'},
    'Apple sign-in failed. Please try again.': {'Tigrinya': 'ብ Apple ምእታው ኣይሰለጠን። በጃኹም እንደገና ፈትኑ።', 'Amharic': 'በApple መግባት አልተሳካም። እባክዎ እንደገና ይሞክሩ።'},
    'Approval process': {'Tigrinya': 'መስርሕ ምጽዳቕ', 'Amharic': 'የማጽደቅ ሂደት'},
    'Are you sure you want to delete': {'Tigrinya': 'ብርግጽ ክትድምስሱ ትደልዩ ዲኹም', 'Amharic': 'በእርግጥ መሰረዝ ይፈልጋሉ'},
    'Are you sure you want to log out?': {'Tigrinya': 'ብርግጽ ክትወጹ ትደልዩ ዲኹም?', 'Amharic': 'በእርግጥ መውጣት ይፈልጋሉ?'},
    'At least 6 characters': {'Tigrinya': 'እንተወሓደ 6 ፊደላት', 'Amharic': 'ቢያንስ 6 ቁምፊዎች'},
    'BUSINESS NAME': {'Tigrinya': 'ስም ትካል', 'Amharic': 'የድርጅት ስም'},
    'Back': {'Tigrinya': 'ተመለስ', 'Amharic': 'ተመለስ'},
    'Barber': {'Tigrinya': 'ጸጉሪ ቤት', 'Amharic': 'ፀጉር ቤት'},
    'Belgium': {'Tigrinya': 'ቤልጅዩም', 'Amharic': 'ቤልጂየም'},
    'Book Now': {'Tigrinya': 'ሕጂ ሓዝ', 'Amharic': 'አሁን ያስይዙ'},
    'Book Service': {'Tigrinya': 'ኣገልግሎት ሓዝ', 'Amharic': 'አገልግሎት ያስይዙ'},
    'Book a time': {'Tigrinya': 'ግዜ ሓዝ', 'Amharic': 'ቀጠሮ ያስይዙ'},
    'Book appointment': {'Tigrinya': 'ቆጸራ ሓዝ', 'Amharic': 'ቀጠሮ ያስይዙ'},
    'Bookings': {'Tigrinya': 'ቡኪንግታት', 'Amharic': 'ቦታ ማስያዣዎች'},
    'Books': {'Tigrinya': 'መጻሕፍቲ', 'Amharic': 'መጻሕፍት'},
    'Browse products': {'Tigrinya': 'ፍርያት ርአ', 'Amharic': 'ምርቶችን ይመልከቱ'},
    'Business Statistics': {'Tigrinya': 'ስታቲስቲክስ ትካል', 'Amharic': 'የድርጅት ስታቲስቲክስ'},
    'Business name': {'Tigrinya': 'ስም ትካል', 'Amharic': 'የድርጅት ስም'},
    'Business sent for approval!': {'Tigrinya': 'ትካል ንምጽዳቕ ተላኢኹ!', 'Amharic': 'ድርጅቱ ለማጽደቅ ተልኳል!'},
    'CATEGORY': {'Tigrinya': 'ዓይነት', 'Amharic': 'ምድብ'},
    'COUNTRY': {'Tigrinya': 'ሃገር', 'Amharic': 'ሀገር'},
    'Cafe': {'Tigrinya': 'ካፈ', 'Amharic': 'ካፌ'},
    'Canada': {'Tigrinya': 'ካናዳ', 'Amharic': 'ካናዳ'},
    'Cancel': {'Tigrinya': 'ሰርዝ', 'Amharic': 'ሰርዝ'},
    'Check out Habesha Hub!\n\nFind Ethiopian & Eritrean businesses near you.\n\nDownload now: https://habesha-hub.no/download.html': {'Tigrinya': 'Habesha Hub ርአዩ!\n\nኣብ ጥቓኹም ዘለዉ ኢትዮጵያውን ኤርትራውን ትካላት ርኸቡ።\n\nሕጂ ኣውርዱ: https://habesha-hub.no/download.html', 'Amharic': 'Habesha Hub ይመልከቱ!\n\nበአቅራቢያዎ ያሉ የኢትዮጵያ እና የኤርትራ ድርጅቶችን ያግኙ።\n\nአሁን ያውርዱ: https://habesha-hub.no/download.html'},
    'Check-out must be after check-in': {'Tigrinya': 'ዕለት ምውጻእ ድሕሪ ዕለት ምእታው ክኸውን ኣለዎ', 'Amharic': 'የመውጫ ቀን ከመግቢያ ቀን በኋላ መሆን አለበት'},
    'Clinic': {'Tigrinya': 'ክሊኒክ', 'Amharic': 'ክሊኒክ'},
    'Closed': {'Tigrinya': 'ዕጹው', 'Amharic': 'ዝግ'},
    // ── Redesign (Oct 2026) ──
    'Map': {'Tigrinya': 'ካርታ', 'Amharic': 'ካርታ'},
    'places': {'Tigrinya': 'ቦታታት', 'Amharic': 'ቦታዎች'},
    'Is this your business?': {'Tigrinya': 'እዚ ትካልካ ድዩ?', 'Amharic': 'ይህ የእርስዎ ድርጅት ነው?'},
    'Claim it for free — add photos, opening hours and your menu': {'Tigrinya': 'ብነጻ ውሰዶ — ስእልታት፡ ናይ ስራሕ ሰዓታትን ሜኑን ወስኽ', 'Amharic': 'በነጻ ይውሰዱት — ፎቶዎች፣ የስራ ሰዓት እና ሜኑ ያክሉ'},
    'Claim this business': {'Tigrinya': 'ነዚ ትካል ውሰዶ', 'Amharic': 'ይህን ድርጅት ይውሰዱ'},
    'We check every claim before you get access. This usually takes 1–2 days.': {'Tigrinya': 'ቅድሚ ምፍቃድ ነፍሲ ወከፍ ሕቶ ንምርምር። መብዛሕትኡ ግዜ 1–2 መዓልቲ ይወስድ።', 'Amharic': 'ፈቃድ ከመስጠታችን በፊት እያንዳንዱን ጥያቄ እንመረምራለን። ብዙውን ጊዜ 1–2 ቀን ይወስዳል።'},
    'Your name': {'Tigrinya': 'ሽምካ', 'Amharic': 'ስምዎ'},
    'Phone number': {'Tigrinya': 'ቁጽሪ ተሌፎን', 'Amharic': 'ስልክ ቁጥር'},
    'Your role': {'Tigrinya': 'ተራኻ', 'Amharic': 'ሚናዎ'},
    'Owner, manager …': {'Tigrinya': 'ዋና፡ ኣመሓዳሪ …', 'Amharic': 'ባለቤት፣ ሥራ አስኪያጅ …'},
    'Message (optional)': {'Tigrinya': 'መልእኽቲ (ኣማራጺ)', 'Amharic': 'መልዕክት (አማራጭ)'},
    'Send claim': {'Tigrinya': 'ሕቶ ስደድ', 'Amharic': 'ጥያቄ ላክ'},
    'Please add your name and phone number': {'Tigrinya': 'በጃኻ ሽምካን ቁጽሪ ተሌፎንካን ወስኽ', 'Amharic': 'እባክዎ ስምዎን እና ስልክ ቁጥርዎን ያስገቡ'},
    'Thank you! We will contact you soon': {'Tigrinya': 'የቐንየልና! ቀልጢፍና ክንረኽበካ ኢና', 'Amharic': 'እናመሰግናለን! በቅርቡ እናገኝዎታለን'},
    'You already sent a claim for this business — we will contact you': {'Tigrinya': 'ንዚ ትካል ድሮ ሕቶ ልኢኽካ ኢኻ — ክንረኽበካ ኢና', 'Amharic': 'ለዚህ ድርጅት አስቀድመው ጥያቄ ልከዋል — እናገኝዎታለን'},
    'Report wrong info': {'Tigrinya': 'ጌጋ ሓበሬታ ሓብር', 'Amharic': 'የተሳሳተ መረጃ ያሳውቁ'},
    'What is wrong?': {'Tigrinya': 'እንታይ ጌጋ ኣሎ?', 'Amharic': 'ምን ተሳስቷል?'},
    'Permanently closed': {'Tigrinya': 'ንሓዋሩ ተዓጽዩ', 'Amharic': 'ለዘለቄታው ተዘግቷል'},
    'Wrong address or location': {'Tigrinya': 'ጌጋ ኣድራሻ ወይ ቦታ', 'Amharic': 'የተሳሳተ አድራሻ ወይም ቦታ'},
    'Wrong phone or opening hours': {'Tigrinya': 'ጌጋ ተሌፎን ወይ ሰዓታት', 'Amharic': 'የተሳሳተ ስልክ ወይም የስራ ሰዓት'},
    'Not a Habesha business': {'Tigrinya': 'ትካል ሓበሻ ኣይኮነን', 'Amharic': 'የሐበሻ ድርጅት አይደለም'},
    'Details (optional)': {'Tigrinya': 'ዝርዝር (ኣማራጺ)', 'Amharic': 'ዝርዝር (አማራጭ)'},
    'Send': {'Tigrinya': 'ስደድ', 'Amharic': 'ላክ'},
    'Thank you for helping us keep Habesha Hub correct': {'Tigrinya': 'ሓበሻ ሃብ ቅኑዕ ንምግባር ስለ ዝሓገዝካና የቐንየልና', 'Amharic': 'ሐበሻ ሃብን ትክክል ለማድረግ ስለረዱን እናመሰግናለን'},
    'Suggest a business': {'Tigrinya': 'ትካል ኣመሓይሽ', 'Amharic': 'ድርጅት ይጠቁሙ'},
    'Know a Habesha place that is missing? Tell us and we will add it.': {'Tigrinya': 'ዘይተረኽበ ቦታ ሓበሻ ትፈልጥ ዶ? ንገረና ክንውስኾ ኢና።', 'Amharic': 'የጎደለ የሐበሻ ቦታ ያውቃሉ? ይንገሩን እና እንጨምረዋለን።'},
    'Category': {'Tigrinya': 'ዓይነት', 'Amharic': 'ምድብ'},
    'Street and number': {'Tigrinya': 'ጎደና ከምኡ ቁጽሪ', 'Amharic': 'መንገድ እና ቁጥር'},
    'City': {'Tigrinya': 'ከተማ', 'Amharic': 'ከተማ'},
    'Country': {'Tigrinya': 'ሃገር', 'Amharic': 'ሀገር'},
    'Phone (optional)': {'Tigrinya': 'ተሌፎን (ኣማራጺ)', 'Amharic': 'ስልክ (አማራጭ)'},
    'Website or Instagram (optional)': {'Tigrinya': 'መርበብ ወይ Instagram (ኣማራጺ)', 'Amharic': 'ድረ-ገጽ ወይም Instagram (አማራጭ)'},
    'Anything else? (optional)': {'Tigrinya': 'ካልእ ነገር? (ኣማራጺ)', 'Amharic': 'ሌላ ነገር? (አማራጭ)'},
    'Send suggestion': {'Tigrinya': 'ርእይቶ ስደድ', 'Amharic': 'ጥቆማ ላክ'},
    'Please fill in name, address, city and country': {'Tigrinya': 'በጃኻ ሽም፡ ኣድራሻ፡ ከተማን ሃገርን ምላእ', 'Amharic': 'እባክዎ ስም፣ አድራሻ፣ ከተማ እና ሀገር ይሙሉ'},
    'Thank you! We will check it and add it soon': {'Tigrinya': 'የቐንየልና! ርኢና ቀልጢፍና ክንውስኾ ኢና', 'Amharic': 'እናመሰግናለን! አይተን በቅርቡ እንጨምረዋለን'},
    'Open now': {'Tigrinya': 'ሕጂ ክፉት', 'Amharic': 'አሁን ክፍት'},
    'Directions': {'Tigrinya': 'መንገዲ', 'Amharic': 'አቅጣጫ'},
    'Address copied': {'Tigrinya': 'ኣድራሻ ተቐዲሑ', 'Amharic': 'አድራሻ ተቀድቷል'},
    'New on Habesha Hub': {'Tigrinya': 'ሓድሽ ኣብ ሓበሻ ሃብ', 'Amharic': 'በሐበሻ ሃብ አዲስ'},
    'Book Room': {'Tigrinya': 'ክፍሊ ሓዝ', 'Amharic': 'ክፍል ያዝ'},
    'Near me': {'Tigrinya': 'ኣብ ጥቓይ', 'Amharic': 'በአቅራቢያዬ'},
    'Allow location': {'Tigrinya': 'ቦታ ፍቐድ', 'Amharic': 'አካባቢን ፍቀድ'},
    'Allow location to see Habesha businesses near you': {'Tigrinya': 'ኣብ ጥቓኻ ዘለዉ ትካላት ሓበሻ ንምርኣይ ቦታኻ ፍቐድ', 'Amharic': 'በአቅራቢያዎ ያሉ የሐበሻ ድርጅቶችን ለማየት አካባቢዎን ይፍቀዱ'},
    'No Habesha businesses within 50 km yet': {'Tigrinya': 'ኣብ 50 ኪ.ሜ ውሽጢ ገና ትካል ሓበሻ የለን', 'Amharic': 'በ50 ኪ.ሜ ውስጥ እስካሁን የሐበሻ ድርጅት የለም'},
    'Browse by country in Explore': {'Tigrinya': 'ኣብ ዳህስስ ብሃገር ርአ', 'Amharic': 'በአስስ ውስጥ በሀገር ይመልከቱ'},
    'Nearby': {'Tigrinya': 'ኣብ ጥቓኻ', 'Amharic': 'በአቅራቢያ'},
    'Save': {'Tigrinya': 'ዓቅብ', 'Amharic': 'አስቀምጥ'},
    'Saved': {'Tigrinya': 'ተዓቂቡ', 'Amharic': 'ተቀምጧል'},
    'Nothing here yet': {'Tigrinya': 'ገና ዋላ ሓደ የለን', 'Amharic': 'እስካሁን ምንም የለም'},
    'Try another category or city': {'Tigrinya': 'ካልእ ዓይነት ወይ ከተማ ፈትን', 'Amharic': 'ሌላ ምድብ ወይም ከተማ ይሞክሩ'},
    'Closes': {'Tigrinya': 'ይዕጾ', 'Amharic': 'ይዘጋል'},
    'Clothes': {'Tigrinya': 'ክዳውንቲ', 'Amharic': 'ልብሶች'},
    'Clothing': {'Tigrinya': 'ክዳውንቲ', 'Amharic': 'አልባሳት'},
    'Club': {'Tigrinya': 'ክለብ', 'Amharic': 'ክለብ'},
    'Coming soon!': {'Tigrinya': 'ቀልጢፉ ይመጽእ!', 'Amharic': 'በቅርቡ ይመጣል!'},
    'Confirm your email': {'Tigrinya': 'ኢመይልኩም ኣረጋግጹ', 'Amharic': 'ኢሜይልዎን ያረጋግጡ'},
    'Contact information': {'Tigrinya': 'ሓበሬታ ርክብ', 'Amharic': 'የመገናኛ መረጃ'},
    'Contact us': {'Tigrinya': 'ተወከሱና', 'Amharic': 'ያግኙን'},
    'Continue with Apple': {'Tigrinya': 'ብ Apple ቀጽል', 'Amharic': 'በApple ይቀጥሉ'},
    'Continue with Google': {'Tigrinya': 'ብ Google ቀጽል', 'Amharic': 'በGoogle ይቀጥሉ'},
    'Coordinates': {'Tigrinya': 'መወሰኒ ቦታ', 'Amharic': 'መጋጠሚያዎች'},
    'Could not load video': {'Tigrinya': 'ቪድዮ ክጽዓን ኣይከኣለን', 'Amharic': 'ቪዲዮውን መጫን አልተቻለም'},
    'Create account': {'Tigrinya': 'ሕሳብ ፍጠር', 'Amharic': 'መለያ ይፍጠሩ'},
    'DESCRIPTION': {'Tigrinya': 'መግለጺ', 'Amharic': 'መግለጫ'},
    'Decoration': {'Tigrinya': 'ምስላም', 'Amharic': 'ማስዋቢያ'},
    'Decoration & Events': {'Tigrinya': 'ምስላምን ኣጋጣሚታትን', 'Amharic': 'ማስዋቢያ እና ዝግጅቶች'},
    'Delete': {'Tigrinya': 'ደምስስ', 'Amharic': 'ሰርዝ'},
    'Delete business': {'Tigrinya': 'ትካል ደምስስ', 'Amharic': 'ድርጅቱን ሰርዝ'},
    'Denmark': {'Tigrinya': 'ደንማርክ', 'Amharic': 'ዴንማርክ'},
    'Describe your business...': {'Tigrinya': 'ትካልኩም ግለጹ...', 'Amharic': 'ድርጅትዎን ይግለጹ...'},
    'Description...': {'Tigrinya': 'መግለጺ...', 'Amharic': 'መግለጫ...'},
    'Digital Heritage.': {'Tigrinya': 'ዲጂታላዊ ውርሻ።', 'Amharic': 'ዲጂታል ቅርስ።'},
    'Don\'t have an account? Sign up': {'Tigrinya': 'ሕሳብ የብልኩምን? ተመዝገቡ', 'Amharic': 'መለያ የለዎትም? ይመዝገቡ'},
    'EMAIL': {'Tigrinya': 'ኢመይል', 'Amharic': 'ኢሜይል'},
    'Edit business': {'Tigrinya': 'ትካል ኣመሓይሽ', 'Amharic': 'ድርጅቱን ያርትዑ'},
    'Egypt': {'Tigrinya': 'ግብጺ', 'Amharic': 'ግብፅ'},
    'Electronics': {'Tigrinya': 'ኤሌክትሮኒክስ', 'Amharic': 'ኤሌክትሮኒክስ'},
    'Enter the full address incl. postcode and city for the correct map location.': {'Tigrinya': 'ንቑዕ ቦታ ኣብ ካርታ ምሉእ ኣድራሻ ምስ ፖስታ ቁጽርን ከተማን ጽሓፉ።', 'Amharic': 'ለትክክለኛ የካርታ ቦታ ሙሉ አድራሻ ከፖስታ ቁጥርና ከተማ ጋር ያስገቡ።'},
    'Enter your email address and we will send you a link to reset your password.': {'Tigrinya': 'ኢመይልኩም ኣእትዉ፡ ፓስዋርድ ንምሕዳስ መላግቦ ክንሰደልኩም ኢና።', 'Amharic': 'ኢሜይልዎን ያስገቡ፣ የይለፍ ቃል ለመቀየር ሊንክ እንልክልዎታለን።'},
    'Enter your name': {'Tigrinya': 'ስምኩም ኣእትዉ', 'Amharic': 'ስምዎን ያስገቡ'},
    'Eritrea': {'Tigrinya': 'ኤርትራ', 'Amharic': 'ኤርትራ'},
    'Error': {'Tigrinya': 'ጌጋ', 'Amharic': 'ስህተት'},
    'Error: check the email address': {'Tigrinya': 'ጌጋ፡ ኢመይል ኣረጋግጹ', 'Amharic': 'ስህተት፡ ኢሜይሉን ያረጋግጡ'},
    'Error: please log in again and try again.': {'Tigrinya': 'ጌጋ፡ በጃኹም ደጊምኩም እቶን ፈትኑን።', 'Amharic': 'ስህተት፡ እባክዎ እንደገና ይግቡና ይሞክሩ።'},
    'Establish Your\n': {'Tigrinya': 'ኣንጽፉ\n', 'Amharic': 'ያቋቁሙ\n'},
    'Ethiopia': {'Tigrinya': 'ኢትዮጵያ', 'Amharic': 'ኢትዮጵያ'},
    'Europe': {'Tigrinya': 'ኤውሮጳ', 'Amharic': 'አውሮፓ'},
    'Find Nearby': {'Tigrinya': 'ኣብ ጥቓኻ ርኸብ', 'Amharic': 'በአቅራቢያ ይፈልጉ'},
    'Finding coordinates...': {'Tigrinya': 'ቦታ ይድለ ኣሎ...', 'Amharic': 'ቦታ በመፈለግ ላይ...'},
    'Flight & Visa': {'Tigrinya': 'በረራን ቪዛን', 'Amharic': 'በረራ እና ቪዛ'},
    'Food': {'Tigrinya': 'መግቢ', 'Amharic': 'ምግብ'},
    'Forgot password?': {'Tigrinya': 'ፓስዋርድ ረሲዕኩም?', 'Amharic': 'የይለፍ ቃል ረሱ?'},
    'France': {'Tigrinya': 'ፈረንሳ', 'Amharic': 'ፈረንሳይ'},
    'Free for everyone. Premium available for business owners.': {'Tigrinya': 'ንኹሉ ብነጻ። ፕሪሚየም ንዋናታት ትካላት ኣሎ።', 'Amharic': 'ለሁሉም ነፃ። ፕሪሚየም ለድርጅት ባለቤቶች ይገኛል።'},
    'Full name': {'Tigrinya': 'ምሉእ ስም', 'Amharic': 'ሙሉ ስም'},
    'Furniture': {'Tigrinya': 'ኣቑሑ ገዛ', 'Amharic': 'የቤት ዕቃዎች'},
    'Gallery': {'Tigrinya': 'ጋለሪ', 'Amharic': 'ጋለሪ'},
    'Germany': {'Tigrinya': 'ጀርመን', 'Amharic': 'ጀርመን'},
    'Get directions': {'Tigrinya': 'መንገዲ ርኸብ', 'Amharic': 'አቅጣጫ ያግኙ'},
    'Go to a business and start a chat!': {'Tigrinya': 'ናብ ትካል ኪድ ዕላል ጀምር!', 'Amharic': 'ወደ ድርጅት ይሂዱና ውይይት ይጀምሩ!'},
    'Go to a business and tap the chat tab.': {'Tigrinya': 'ናብ ትካል ኪድ ናይ ዕላል ክፍሊ ጠውቕ።', 'Amharic': 'ወደ ድርጅት ይሂዱና የውይይት ትሩን ይጫኑ።'},
    'Google sign-in failed. Please try again.': {'Tigrinya': 'ብ Google ምእታው ኣይሰለጠን። በጃኹም እንደገና ፈትኑ።', 'Amharic': 'በGoogle መግባት አልተሳካም። እባክዎ እንደገና ይሞክሩ።'},
    'Guest': {'Tigrinya': 'ጋሻ', 'Amharic': 'እንግዳ'},
    'Habesha Hub takes privacy seriously. We collect minimal data.': {'Tigrinya': 'Habesha Hub ብሕታውነት ኣኽቢሩ ይርእዮ። ዝተወሰነ ሓበሬታ ጥራይ ንእክብ።', 'Amharic': 'Habesha Hub ግላዊነትን በቁም ነገር ይመለከታል። አነስተኛ መረጃ ብቻ እንሰበስባለን።'},
    'Send money home': {'Tigrinya': 'ገንዘብ ናብ ዓዲ ስደዱ', 'Amharic': 'ገንዘብ ወደ አገር ቤት ይላኩ'},
    'Hotel': {'Tigrinya': 'ሆቴል', 'Amharic': 'ሆቴል'},
    'IMAGE': {'Tigrinya': 'ስእሊ', 'Amharic': 'ምስል'},
    'IMAGE URL': {'Tigrinya': 'መላግቦ ስእሊ', 'Amharic': 'የምስል URL'},
    'Image': {'Tigrinya': 'ስእሊ', 'Amharic': 'ምስል'},
    'Image added!': {'Tigrinya': 'ስእሊ ተወሲኹ!', 'Amharic': 'ምስል ታክሏል!'},
    'Invalid email address.': {'Tigrinya': 'ዘይቅቡል ኢመይል።', 'Amharic': 'ልክ ያልሆነ ኢሜይል።'},
    'Italy': {'Tigrinya': 'ጣልያን', 'Amharic': 'ጣሊያን'},
    'Join Now': {'Tigrinya': 'እቶ', 'Amharic': 'አሁን ይቀላቀሉ'},
    'Kenya': {'Tigrinya': 'ኬንያ', 'Amharic': 'ኬንያ'},
    'LOG IN': {'Tigrinya': 'እቶ', 'Amharic': 'ግባ'},
    'Language': {'Tigrinya': 'ቋንቋ', 'Amharic': 'ቋንቋ'},
    'Location': {'Tigrinya': 'ቦታ', 'Amharic': 'ቦታ'},
    'Location found': {'Tigrinya': 'ቦታ ተረኺቡ', 'Amharic': 'ቦታ ተገኝቷል'},
    'Log in': {'Tigrinya': 'እቶ', 'Amharic': 'ይግቡ'},
    'Log in for full access': {'Tigrinya': 'ምሉእ ተበጻሕነት ንምርካብ እቶ', 'Amharic': 'ሙሉ መዳረሻ ለማግኘት ይግቡ'},
    'Log in to manage your business.': {'Tigrinya': 'ትካልኩም ንምምሕዳር እቶ።', 'Amharic': 'ድርጅትዎን ለማስተዳደር ይግቡ።'},
    'Log in to write a review': {'Tigrinya': 'ርእይቶ ንምጽሓፍ እቶ', 'Amharic': 'አስተያየት ለመጻፍ ይግቡ'},
    'Log out': {'Tigrinya': 'ውጻእ', 'Amharic': 'ውጣ'},
    'MESSAGE': {'Tigrinya': 'መልእኽቲ', 'Amharic': 'መልዕክት'},
    'Max 5 images!': {'Tigrinya': 'ዝለዓለ 5 ስእልታት!', 'Amharic': 'ቢበዛ 5 ምስሎች!'},
    'Menu not available yet': {'Tigrinya': 'ሜኑ ገና የለን', 'Amharic': 'ሜኑ ገና የለም'},
    'Message sent!': {'Tigrinya': 'መልእኽቲ ተላኢኹ!', 'Amharic': 'መልዕክት ተልኳል!'},
    'Mon - Fri': {'Tigrinya': 'ሰኑይ - ዓርቢ', 'Amharic': 'ሰኞ - ዓርብ'},
    'More info': {'Tigrinya': 'ተወሳኺ ሓበሬታ', 'Amharic': 'ተጨማሪ መረጃ'},
    'More videos': {'Tigrinya': 'ተወሳኺ ቪድዮታት', 'Amharic': 'ተጨማሪ ቪዲዮዎች'},
    'Music': {'Tigrinya': 'ሙዚቃ', 'Amharic': 'ሙዚቃ'},
    'My favorites': {'Tigrinya': 'ዝፈትዎም', 'Amharic': 'የምወዳቸው'},
    'NAME': {'Tigrinya': 'ስም', 'Amharic': 'ስም'},
    'Netherlands': {'Tigrinya': 'ሆላንድ', 'Amharic': 'ኔዘርላንድ'},
    'New user? ': {'Tigrinya': 'ሓድሽ ተጠቃሚ? ', 'Amharic': 'አዲስ ተጠቃሚ? '},
    'Next': {'Tigrinya': 'ቀጻሊ', 'Amharic': 'ቀጣይ'},
    'No messages yet': {'Tigrinya': 'ገና መልእኽቲ የለን', 'Amharic': 'እስካሁን መልዕክት የለም'},
    'No providers yet': {'Tigrinya': 'ገና ኣቕረብቲ የለዉን', 'Amharic': 'እስካሁን አቅራቢዎች የሉም'},
    'No reviews yet. Be the first!': {'Tigrinya': 'ገና ርእይቶ የለን። ቀዳማይ ኹን!', 'Amharic': 'እስካሁን አስተያየት የለም። የመጀመሪያው ይሁኑ!'},
    'No user with this email.': {'Tigrinya': 'በዚ ኢመይል ተጠቃሚ የለን።', 'Amharic': 'በዚህ ኢሜይል ተጠቃሚ የለም።'},
    'Norway': {'Tigrinya': 'ኖርወይ', 'Amharic': 'ኖርዌይ'},
    'OK, got it': {'Tigrinya': 'ሕራይ፡ ተረዲኡኒ', 'Amharic': 'እሺ፣ ገባኝ'},
    'OPENING HOURS': {'Tigrinya': 'ሰዓታት ስራሕ', 'Amharic': 'የሥራ ሰዓታት'},
    'Opens': {'Tigrinya': 'ይኽፈት', 'Amharic': 'ይከፈታል'},
    'Other': {'Tigrinya': 'ካልእ', 'Amharic': 'ሌላ'},
    'PASSWORD': {'Tigrinya': 'ፓስዋርድ', 'Amharic': 'የይለፍ ቃል'},
    'PHONE': {'Tigrinya': 'ስልኪ', 'Amharic': 'ስልክ'},
    'Password is too weak (min. 6 characters).': {'Tigrinya': 'ፓስዋርድ ድኹም እዩ (እንተወሓደ 6 ፊደላት)።', 'Amharic': 'የይለፍ ቃሉ ደካማ ነው (ቢያንስ 6 ቁምፊዎች)።'},
    'Photographer': {'Tigrinya': 'ፎቶግራፈር', 'Amharic': 'ፎቶግራፈር'},
    'Please confirm your email.': {'Tigrinya': 'በጃኹም ኢመይልኩም ኣረጋግጹ።', 'Amharic': 'እባክዎ ኢሜይልዎን ያረጋግጡ።'},
    'Please enter email and password.': {'Tigrinya': 'በጃኹም ኢመይልን ፓስዋርድን ኣእትዉ።', 'Amharic': 'እባክዎ ኢሜይል እና የይለፍ ቃል ያስገቡ።'},
    'Post Review': {'Tigrinya': 'ርእይቶ ልኣኽ', 'Amharic': 'አስተያየት ይለጥፉ'},
    'Press Enter to save': {'Tigrinya': 'ንምዕቃብ Enter ጠውቕ', 'Amharic': 'ለማስቀመጥ Enter ይጫኑ'},
    'Privacy': {'Tigrinya': 'ብሕታውነት', 'Amharic': 'ግላዊነት'},
    'Privacy policy': {'Tigrinya': 'ፖሊሲ ብሕታውነት', 'Amharic': 'የግላዊነት ፖሊሲ'},
    'Profile picture updated!': {'Tigrinya': 'ስእሊ ፕሮፋይል ተሓዲሱ!', 'Amharic': 'የመገለጫ ምስል ተዘምኗል!'},
    'Provider videos will appear here.\nStay tuned!': {'Tigrinya': 'ቪድዮታት ኣቕረብቲ ኣብዚ ክርኣዩ እዮም።\nተጸበዩ!', 'Amharic': 'የአቅራቢዎች ቪዲዮዎች እዚህ ይታያሉ።\nይጠብቁ!'},
    'Read more': {'Tigrinya': 'ተወሳኺ ኣንብብ', 'Amharic': 'ተጨማሪ ያንብቡ'},
    'Refresh': {'Tigrinya': 'ኣሕድስ', 'Amharic': 'አድስ'},
    'Register business': {'Tigrinya': 'ትካል ኣመዝግብ', 'Amharic': 'ድርጅት ይመዝገቡ'},
    'Register your business in the Habesha Hub network.': {'Tigrinya': 'ትካልኩም ኣብ መርበብ Habesha Hub ኣመዝግቡ።', 'Amharic': 'ድርጅትዎን በHabesha Hub ኔትወርክ ውስጥ ያስመዝግቡ።'},
    'Required': {'Tigrinya': 'ግድን', 'Amharic': 'ያስፈልጋል'},
    'Reset link sent to': {'Tigrinya': 'መሕደሲ መላግቦ ተላኢኹ ናብ', 'Amharic': 'የመቀየሪያ ሊንክ ተልኳል ወደ'},
    'Reset password': {'Tigrinya': 'ፓስዋርድ ኣሕድስ', 'Amharic': 'የይለፍ ቃል ይቀይሩ'},
    'Restaurant': {'Tigrinya': 'ቤት መግቢ', 'Amharic': 'ምግብ ቤት'},
    'Reviews': {'Tigrinya': 'ርእይቶታት', 'Amharic': 'አስተያየቶች'},
    'Reviews & Comments': {'Tigrinya': 'ርእይቶታትን ሓሳባትን', 'Amharic': 'አስተያየቶች እና ሐሳቦች'},
    'Rwanda': {'Tigrinya': 'ርዋንዳ', 'Amharic': 'ሩዋንዳ'},
    'SIGN UP': {'Tigrinya': 'ተመዝገብ', 'Amharic': 'ይመዝገቡ'},
    'Saturday': {'Tigrinya': 'ቀዳም', 'Amharic': 'ቅዳሜ'},
    'Save changes': {'Tigrinya': 'ለውጢ ዓቅብ', 'Amharic': 'ለውጦችን ያስቀምጡ'},
    'Searching...': {'Tigrinya': 'ይደሊ ኣሎ...', 'Amharic': 'በመፈለግ ላይ...'},
    'See menu': {'Tigrinya': 'ሜኑ ርአ', 'Amharic': 'ሜኑ ይመልከቱ'},
    'See more': {'Tigrinya': 'ተወሳኺ ርአ', 'Amharic': 'ተጨማሪ ይመልከቱ'},
    'Select a country to find services': {'Tigrinya': 'ኣገልግሎት ንምርካብ ሃገር ምረጹ', 'Amharic': 'አገልግሎቶችን ለማግኘት ሀገር ይምረጡ'},
    'Select country': {'Tigrinya': 'ሃገር ምረጹ', 'Amharic': 'ሀገር ይምረጡ'},
    'Send for approval': {'Tigrinya': 'ንምጽዳቕ ልኣኽ', 'Amharic': 'ለማጽደቅ ይላኩ'},
    'Send link': {'Tigrinya': 'መላግቦ ልኣኽ', 'Amharic': 'ሊንክ ይላኩ'},
    'Send message': {'Tigrinya': 'መልእኽቲ ልኣኽ', 'Amharic': 'መልዕክት ይላኩ'},
    'Services': {'Tigrinya': 'ኣገልግሎታት', 'Amharic': 'አገልግሎቶች'},
    'Share Habesha Hub': {'Tigrinya': 'Habesha Hub ኣካፍል', 'Amharic': 'Habesha Hub ያጋሩ'},
    'Share your experience...': {'Tigrinya': 'ተሞክሮኹም ኣካፍሉ...', 'Amharic': 'ተሞክሮዎን ያጋሩ...'},
    'Shop': {'Tigrinya': 'ድኳን', 'Amharic': 'ሱቅ'},
    'Show less': {'Tigrinya': 'ውሑድ ኣርኢ', 'Amharic': 'ያነሰ አሳይ'},
    'Something went wrong. Please try again.': {'Tigrinya': 'ገለ ጌጋ ተፈጢሩ። በጃኹም እንደገና ፈትኑ።', 'Amharic': 'የሆነ ስህተት ተፈጥሯል። እባክዎ እንደገና ይሞክሩ።'},
    'South Sudan': {'Tigrinya': 'ደቡብ ሱዳን', 'Amharic': 'ደቡብ ሱዳን'},
    'Start a chat with a business': {'Tigrinya': 'ምስ ትካል ዕላል ጀምር', 'Amharic': 'ከድርጅት ጋር ውይይት ይጀምሩ'},
    'Step': {'Tigrinya': 'ስጉምቲ', 'Amharic': 'ደረጃ'},
    'Street address, postcode, city': {'Tigrinya': 'ኣድራሻ ጎደና፡ ቁጽሪ ፖስታ፡ ከተማ', 'Amharic': 'የመንገድ አድራሻ፣ የፖስታ ቁጥር፣ ከተማ'},
    'Sunday': {'Tigrinya': 'ሰንበት', 'Amharic': 'እሑድ'},
    'Sweden': {'Tigrinya': 'ሽወደን', 'Amharic': 'ስዊድን'},
    'Swipe': {'Tigrinya': 'ኣንሸራትት', 'Amharic': 'ያንሸራትቱ'},
    'Switzerland': {'Tigrinya': 'ስዊዘርላንድ', 'Amharic': 'ስዊዘርላንድ'},
    'Tap the circle above to find nearby Habesha businesses': {'Tigrinya': 'ኣብ ጥቓኹም ዘለዉ ናይ ሓበሻ ትካላት ንምርካብ ነቲ ኣብ ላዕሊ ዘሎ ክቢ ጠውቑ', 'Amharic': 'በአቅራቢያ ያሉ የሃበሻ ድርጅቶችን ለማግኘት ከላይ ያለውን ክብ ይጫኑ'},
    'Tap the heart icon on a business to save it': {'Tigrinya': 'ትካል ንምዕቃብ ነቲ ልቢ ምልክት ጠውቑ', 'Amharic': 'ድርጅትን ለማስቀመጥ የልብ ምልክቱን ይጫኑ'},
    'Tap to search nearby': {'Tigrinya': 'ኣብ ጥቓኻ ንምድላይ ጠውቕ', 'Amharic': 'በአቅራቢያ ለመፈለግ ይጫኑ'},
    'Tap to upload an image': {'Tigrinya': 'ስእሊ ንምጽዓን ጠውቕ', 'Amharic': 'ምስል ለመጫን ይጫኑ'},
    'Tap to view providers': {'Tigrinya': 'ኣቕረብቲ ንምርኣይ ጠውቕ', 'Amharic': 'አቅራቢዎችን ለማየት ይጫኑ'},
    'Taxi': {'Tigrinya': 'ታክሲ', 'Amharic': 'ታክሲ'},
    'The app is free to use. Login is only required to register a business.': {'Tigrinya': 'እዚ ኣፕ ብነጻ እዩ። ምእታው ዘድሊ ትካል ንምምዝጋብ ጥራይ እዩ።', 'Amharic': 'መተግበሪያው ነፃ ነው። መግባት የሚያስፈልገው ድርጅት ለመመዝገብ ብቻ ነው።'},
    'This cannot be undone.': {'Tigrinya': 'እዚ ክምለስ ኣይክእልን እዩ።', 'Amharic': 'ይህ ሊቀለበስ አይችልም።'},
    'This email is already in use.': {'Tigrinya': 'እዚ ኢመይል ኣቐዲሙ ኣብ ጥቕሚ ውዒሉ ኣሎ።', 'Amharic': 'ይህ ኢሜይል አስቀድሞ ጥቅም ላይ ውሏል።'},
    'Too many attempts. Please wait a moment.': {'Tigrinya': 'ብዙሕ ፈተነታት። በጃኹም ቁሩብ ተጸበዩ።', 'Amharic': 'በጣም ብዙ ሙከራዎች። እባክዎ ትንሽ ይጠብቁ።'},
    'Transport': {'Tigrinya': 'መጓዓዝያ', 'Amharic': 'ትራንስፖርት'},
    'UK': {'Tigrinya': 'ዓባይ ብሪጣንያ', 'Amharic': 'ዩናይትድ ኪንግደም'},
    'URL of the business\'s website': {'Tigrinya': 'መላግቦ መርበብ ሓበሬታ ትካል', 'Amharic': 'የድርጅቱ ድረ-ገጽ URL'},
    'USA': {'Tigrinya': 'ኣሜሪካ', 'Amharic': 'አሜሪካ'},
    'Uganda': {'Tigrinya': 'ኡጋንዳ', 'Amharic': 'ኡጋንዳ'},
    'United Kingdom': {'Tigrinya': 'ዓባይ ብሪጣንያ', 'Amharic': 'ዩናይትድ ኪንግደም'},
    'United States': {'Tigrinya': 'ኣሜሪካ', 'Amharic': 'አሜሪካ'},
    'Update profile picture': {'Tigrinya': 'ስእሊ ፕሮፋይል ኣሕድስ', 'Amharic': 'የመገለጫ ምስል ይቀይሩ'},
    'User': {'Tigrinya': 'ተጠቃሚ', 'Amharic': 'ተጠቃሚ'},
    'Video': {'Tigrinya': 'ቪድዮ', 'Amharic': 'ቪዲዮ'},
    'Video not available': {'Tigrinya': 'ቪድዮ የለን', 'Amharic': 'ቪዲዮ አይገኝም'},
    'Video uploaded!': {'Tigrinya': 'ቪድዮ ተጸዒኑ!', 'Amharic': 'ቪዲዮ ተጭኗል!'},
    'View Profile': {'Tigrinya': 'ፕሮፋይል ርአ', 'Amharic': 'መገለጫ ይመልከቱ'},
    'Views': {'Tigrinya': 'ዝረኣዩ', 'Amharic': 'እይታዎች'},
    'WEBSITE (optional)': {'Tigrinya': 'መርበብ ሓበሬታ (ኣማራጺ)', 'Amharic': 'ድረ-ገጽ (አማራጭ)'},
    'We have sent a confirmation link to': {'Tigrinya': 'መረጋገጺ መላግቦ ሰዲድናልኩም ኣለና ናብ', 'Amharic': 'የማረጋገጫ ሊንክ ልከናል ወደ'},
    'We will reply as soon as possible.': {'Tigrinya': 'ብዝቐልጠፈ ክንምልሰልኩም ኢና።', 'Amharic': 'በተቻለ ፍጥነት እንመልስልዎታለን።'},
    'Welcome back': {'Tigrinya': 'እንቋዕ ብደሓን ተመለስኩም', 'Amharic': 'እንኳን ደህና መጡ'},
    'What we collect': {'Tigrinya': 'እንእክቦ ሓበሬታ', 'Amharic': 'የምንሰበስበው'},
    'Write a review': {'Tigrinya': 'ርእይቶ ጽሓፍ', 'Amharic': 'አስተያየት ይጻፉ'},
    'Write your message here...': {'Tigrinya': 'መልእኽትኹም ኣብዚ ጽሓፉ...', 'Amharic': 'መልዕክትዎን እዚህ ይጻፉ...'},
    'Wrong password. Please try again.': {'Tigrinya': 'ጌጋ ፓስዋርድ። በጃኹም እንደገና ፈትኑ።', 'Amharic': 'የተሳሳተ የይለፍ ቃል። እባክዎ እንደገና ይሞክሩ።'},
    'Yes, delete': {'Tigrinya': 'እወ፡ ደምስስ', 'Amharic': 'አዎ፣ ሰርዝ'},
    'You are logged out': {'Tigrinya': 'ወጺእኩም ኣለኹም', 'Amharic': 'ወጥተዋል'},
    'You must log in to rate': {'Tigrinya': 'ደረጃ ንምሃብ ክትኣትዉ ኣለኩም', 'Amharic': 'ደረጃ ለመስጠት መግባት አለብዎት'},
    'You must log in to register a business': {'Tigrinya': 'ትካል ንምምዝጋብ ክትኣትዉ ኣለኩም', 'Amharic': 'ድርጅት ለመመዝገብ መግባት አለብዎት'},
    'Your Habesha community in your pocket': {'Tigrinya': 'ናይ ሓበሻ ማሕበረሰብኩም ኣብ ኢድኩም', 'Amharic': 'የሃበሻ ማህበረሰብዎ በእጅዎ'},
    'Your business is being reviewed by Habesha Hub. We will email you when it is approved and published. Usually 1–2 business days.': {'Tigrinya': 'ትካልኩም ብ Habesha Hub ይምርመር ኣሎ። ምስ ጸደቐን ተሓትመን ኢመይል ክንሰደልኩም ኢና። ብልሙድ 1–2 ናይ ስራሕ መዓልትታት።', 'Amharic': 'ድርጅትዎ በHabesha Hub እየተገመገመ ነው። ሲጸድቅና ሲታተም ኢሜይል እንልክልዎታለን። አብዛኛውን ጊዜ 1–2 የሥራ ቀናት።'},
    'Your name...': {'Tigrinya': 'ስምኩም...', 'Amharic': 'ስምዎ...'},
    'businesses': {'Tigrinya': 'ትካላት', 'Amharic': 'ድርጅቶች'},
    'businesses found': {'Tigrinya': 'ትካላት ተረኺቦም', 'Amharic': 'ድርጅቶች ተገኝተዋል'},
    'e.g. Addis Fine Dining': {'Tigrinya': 'ንኣብነት Addis Fine Dining', 'Amharic': 'ለምሳሌ Addis Fine Dining'},
    'guest': {'Tigrinya': 'ጋሻ', 'Amharic': 'እንግዳ'},
    'guests': {'Tigrinya': 'ጋሻታት', 'Amharic': 'እንግዶች'},
    'or': {'Tigrinya': 'ወይ', 'Amharic': 'ወይም'},
    'password': {'Tigrinya': 'ፓስዋርድ', 'Amharic': 'የይለፍ ቃል'},
    'photos': {'Tigrinya': 'ስእልታት', 'Amharic': 'ፎቶዎች'},
    'videos': {'Tigrinya': 'ቪድዮታት', 'Amharic': 'ቪዲዮዎች'},
    'was deleted': {'Tigrinya': 'ተደምሲሱ', 'Amharic': 'ተሰርዟል'},
    '• Email and password\n• Nickname\n• Chat messages\n• GPS (only when searching)\n• Favorite businesses (stored locally)': {'Tigrinya': '• ኢመይልን ፓስዋርድን\n• ሳጓ\n• መልእኽቲ ዕላል\n• GPS (ኣብ ግዜ ምድላይ ጥራይ)\n• ዝፈትዉዎም ትካላት (ኣብ ስልኪ)', 'Amharic': '• ኢሜይል እና የይለፍ ቃል\n• ቅጽል ስም\n• የውይይት መልዕክቶች\n• GPS (ሲፈልጉ ብቻ)\n• የሚወዷቸው ድርጅቶች (በስልክ ላይ)'},
    '⚠ Address not found': {'Tigrinya': '⚠ ኣድራሻ ኣይተረኽበን', 'Amharic': '⚠ አድራሻ አልተገኘም'},
    '⚠ Address not found. Check and try again.': {'Tigrinya': '⚠ ኣድራሻ ኣይተረኽበን። ኣረጋጊጽኩም ደጊምኩም ፈትኑ።', 'Amharic': '⚠ አድራሻ አልተገኘም። ያረጋግጡና እንደገና ይሞክሩ።'},
    '⚠ Could not find location': {'Tigrinya': '⚠ ቦታ ክርከብ ኣይከኣለን', 'Amharic': '⚠ ቦታ ማግኘት አልተቻለም'},
    '⚠ Could not find location. Check the address.': {'Tigrinya': '⚠ ቦታ ክርከብ ኣይከኣለን። ኣድራሻ ኣረጋግጹ።', 'Amharic': '⚠ ቦታ ማግኘት አልተቻለም። አድራሻውን ያረጋግጡ።'},
    '✓ Business updated!': {'Tigrinya': '✓ ትካል ተሓዲሱ!', 'Amharic': '✓ ድርጅቱ ተዘምኗል!'},
  };

  static String get(String key) {
    return _translations[key]?[_language] ??
        _translations[key]?['English'] ??
        key;
  }

  static final Map<String, Map<String, String>> _translations = {
    'switch_to_light': {
      'English': 'Light mode',
      'Tigrinya': 'ብሩህ ሕብሪ',
      'Amharic': 'ብሩህ ገጽታ',
    },
    'switch_to_dark': {
      'English': 'Dark mode',
      'Tigrinya': 'ጸሊም ሕብሪ',
      'Amharic': 'ጨለማ ገጽታ',
    },
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
    'services': {
      'Norsk': 'Tjenester',
      'Tigrinya': 'ኣገልግሎት',
      'English': 'Services',
      'Amharic': 'አገልግሎት'
    },
    'market_items': {
      'Norsk': 'annonser',
      'Tigrinya': 'ኣቑሑ',
      'English': 'items',
      'Amharic': 'እቃዎች'
    },
    'market_see_all': {
      'Norsk': 'Se alle',
      'Tigrinya': 'ኩሉ ርአ',
      'English': 'See all',
      'Amharic': 'ሁሉንም ይመልከቱ'
    },
    'tok': {
      'Norsk': 'Hab Tok',
      'Tigrinya': 'ሃብ ቶክ',
      'English': 'Hab Tok',
      'Amharic': 'ሀብ ቶክ'
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
    'cat_wedding': {
      'Norsk': 'Bryllup',
      'Tigrinya': 'መርዓ',
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
    'flights_title': {
      'Norsk': 'Finn billige fly',
      'Tigrinya': 'ሕሱር ነፈርቲ ርኸብ',
      'English': 'Find Cheap Flights',
      'Amharic': 'ርካሽ በረራዎችን ፈልግ'
    },
    'flights_subtitle': {
      'Norsk': 'Søk fly over hele verden — beste priser garantert',
      'Tigrinya': 'ኣብ ምሉእ ዓለም ነፈርቲ ድለ — እቲ ዝበለጸ ዋጋ ዋሕሲ',
      'English': 'Search flights worldwide — best prices guaranteed',
      'Amharic': 'በዓለም ሁሉ በረራዎችን ፈልጉ — ምርጥ ዋጋዎች ዋስትና ተሰጥቷል'
    },
    'flights_popular': {
      'Norsk': 'Populære ruter',
      'Tigrinya': 'ልሙዳት መስመራት',
      'English': 'Popular Routes',
      'Amharic': 'ታዋቂ መስመሮች'
    },
    'flights_search': {
      'Norsk': 'Søk fly nå',
      'Tigrinya': 'ሕጂ ነፈርቲ ድለ',
      'English': 'Search Flights Now',
      'Amharic': 'አሁን በረራዎችን ፈልግ'
    },
    'flights_tips': {
      'Norsk': 'Tips',
      'Tigrinya': 'ምኽርታት',
      'English': 'Tips',
      'Amharic': 'ምክሮች'
    },
    'flights_tip1': {
      'Norsk': '✅ Book 2-3 måneder i forveien for beste priser',
      'Tigrinya': '✅ ቅድሚ 2-3 ወርሒ ሕዝ ንዝበለጸ ዋጋ',
      'English': '✅ Book 2-3 months in advance for best prices',
      'Amharic': '✅ ለምርጥ ዋጋ 2-3 ወር አስቀድሞ ቦታ ያዙ'
    },
    'flights_tip2': {
      'Norsk': '✅ Tirsdag og onsdag er billigste dager å fly',
      'Tigrinya': '✅ ሰሉስን ረቡዕን ብዝሒ ዝለዓለ ዋጋ ዘለዎ መዓልታት',
      'English': '✅ Tuesday & Wednesday are cheapest days to fly',
      'Amharic': '✅ ማክሰኞ እና ረቡዕ ርካሽ ቀናት ናቸው'
    },
    'flights_tip3': {
      'Norsk': '✅ Sammenlign priser med fleksible datoer',
      'Tigrinya': '✅ ዋጋታት ምስ ተለዋዋጢ ዕለታት ኣወዳድር',
      'English': '✅ Compare prices with flexible dates',
      'Amharic': '✅ ተለዋዋጭ ቀናት ጋር ዋጋዎችን ያወዳድሩ'
    },
    'travel_help_title': {
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
      'Tigrinya': 'እንታይ ሓገዝ ትደሊ?',
      'English': 'What do you need help with?',
      'Amharic': 'ምን እርዳታ ይፈልጋሉ?'
    },
    'travel_flight_title': {
      'Norsk': 'Flybestilling',
      'Tigrinya': 'ቡኪንግ ነፈርቲ',
      'English': 'Flight Booking',
      'Amharic': 'የበረራ ቦታ ማስያዝ'
    },
    'travel_flight_desc': {
      'Norsk': 'Vi bestiller flyet for deg + 300 NOK serviceavgift',
      'Tigrinya': 'ነፈርቲ ክእዘዘልካ + 300 NOK ክፍሊት',
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
      'Tigrinya': 'ምሉእ ጥቅሊ — ዝሓሰ ዋጋ',
      'English': 'Complete travel package — best value',
      'Amharic': 'ሙሉ የጉዞ ጥቅል — ምርጥ ዋጋ'
    },
    'travel_hotel_title': {
      'Norsk': 'Overnatting',
      'Tigrinya': 'መሕደሪ',
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
      'Tigrinya': 'ሕቶ ስደድ',
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
    'route_oslo_addis': {
      'Norsk': '🇳🇴 Oslo → 🇪🇹 Addis Abeba',
      'Tigrinya': '🇳🇴 ኦስሎ → 🇪🇹 ኣዲስ ኣበባ',
      'English': '🇳🇴 Oslo → 🇪🇹 Addis Abeba',
      'Amharic': '🇳🇴 ኦስሎ → 🇪🇹 አዲስ አበባ'
    },
    'route_oslo_asmara': {
      'Norsk': '🇳🇴 Oslo → 🇪🇷 Asmara',
      'Tigrinya': '🇳🇴 ኦስሎ → 🇪🇷 ኣስመራ',
      'English': '🇳🇴 Oslo → 🇪🇷 Asmara',
      'Amharic': '🇳🇴 ኦስሎ → 🇪🇷 አስመራ'
    },
    'route_stockholm_addis': {
      'Norsk': '🇸🇪 Stockholm → 🇪🇹 Addis Abeba',
      'Tigrinya': '🇸🇪 ስቶክሆልም → 🇪🇹 ኣዲስ ኣበባ',
      'English': '🇸🇪 Stockholm → 🇪🇹 Addis Abeba',
      'Amharic': '🇸🇪 ስቶክሆልም → 🇪🇹 አዲስ አበባ'
    },
    'route_london_addis': {
      'Norsk': '🇬🇧 London → 🇪🇹 Addis Abeba',
      'Tigrinya': '🇬🇧 ለንደን → 🇪🇹 ኣዲስ ኣበባ',
      'English': '🇬🇧 London → 🇪🇹 Addis Abeba',
      'Amharic': '🇬🇧 ለንደን → 🇪🇹 አዲስ አበባ'
    },
    'route_kampala_addis': {
      'Norsk': '🇺🇬 Kampala → 🇪🇹 Addis Abeba',
      'Tigrinya': '🇺🇬 ካምፓላ → 🇪🇹 ኣዲስ ኣበባ',
      'English': '🇺🇬 Kampala → 🇪🇹 Addis Abeba',
      'Amharic': '🇺🇬 ካምፓላ → 🇪🇹 አዲስ አበባ'
    },
    'route_world_africa': {
      'Norsk': '🌍 Hele verden → Afrika',
      'Tigrinya': '🌍 ምሉእ ዓለም → ኣፍሪቃ',
      'English': '🌍 Worldwide → Africa',
      'Amharic': '🌍 ዓለም ሁሉ → አፍሪካ'
    },
    'flights_tip4': {
      'Norsk': '✅ Ethiopian Airlines har ofte beste priser til Afrika',
      'Tigrinya': '✅ ኢትዮጵያን ኤርላይንስ ናብ ኣፍሪቃ ዝበለጸ ዋጋ ኣለዎ',
      'English': '✅ Ethiopian Airlines often has best Africa prices',
      'Amharic': '✅ ኢትዮጵያ አየር መንገድ ለአፍሪካ ምርጥ ዋጋ አለው'
    },
    'favorites_title': {
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
    'connect_education': {
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
    'marketplace_title': {
      'Norsk': 'Marked',
      'Tigrinya': 'ዕዳጋ',
      'English': 'Marketplace',
      'Amharic': 'ገበያ'
    },
    'marketplace_subtitle': {
      'Norsk': 'Kjøp og selg brukte ting',
      'Tigrinya': 'ዝተጠቕሙ ኣቓሑ ሸጡ ወይ ግዝኡ',
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
      'Tigrinya': 'ሽጥ',
      'English': 'Sell',
      'Amharic': 'ሸጥ'
    },
    'marketplace_search_name': {
      'Norsk': 'Søk etter produkt...',
      'Tigrinya': 'ብ ሽም ንብረት ድለ',
      'English': 'Search for product...',
      'Amharic': 'ምርት ፈልግ...'
    },
    'marketplace_search_city': {
      'Norsk': 'Søk etter by...',
      'Tigrinya': 'ከተማ ድለ...',
      'English': 'Search by city...',
      'Amharic': 'በከተማ ፈልግ...'
    },
    'marketplace_edit': {
      'Norsk': 'Rediger annonse',
      'Tigrinya': 'ኣዊጅ ኣርም',
      'English': 'Edit Listing',
      'Amharic': 'ማስታወቂያ አርም'
    },
    'marketplace_add': {
      'Norsk': 'Legg ut annonse',
      'Tigrinya': 'ዝርዝር ወስኽ',
      'English': 'Add Listing',
      'Amharic': 'ማስታወቂያ ጨምር'
    },
    'marketplace_empty': {
      'Norsk': 'Ingen annonser ennå',
      'Tigrinya': 'ዝርዝር የለን',
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
    'marketplace_city': {
      'Norsk': 'BY / STED',
      'Tigrinya': 'ከተማ / ቦታ',
      'English': 'CITY / LOCATION',
      'Amharic': 'ከተማ / ቦታ'
    },
    'market_other': {
      'Norsk': 'Annet',
      'Tigrinya': 'ካልእ',
      'English': 'Other',
      'Amharic': 'ሌላ'
    },
    'connect_messages': {
      'Norsk': 'Meldinger',
      'Tigrinya': 'መልእኽትታት',
      'English': 'Connect Messages',
      'Amharic': 'መልዕክቶች'
    },
    'connect_no_messages': {
      'Norsk': 'Ingen meldinger ennå',
      'Tigrinya': 'ገና መልእኽቲ የለን',
      'English': 'No messages yet',
      'Amharic': 'እስካሁን መልዕክት የለም'
    },
    'connect_it': {
      'Norsk': 'IT',
      'Tigrinya': 'ቴክኖሎጂ',
      'English': 'IT',
      'Amharic': 'ቴክኖሎጂ'
    },
    'connect_health': {
      'Norsk': 'Helse',
      'Tigrinya': 'ጥዕና',
      'English': 'Health',
      'Amharic': 'ጤና'
    },
    'connect_save': {
      'Norsk': 'Lagre profil',
      'Tigrinya': 'ፕሮፋይል ሓዝ',
      'English': 'Save Profile',
      'Amharic': 'መገለጫ አስቀምጥ'
    },
    'connect': {
      'Norsk': 'Koble til',
      'Tigrinya': 'ተራኸብ',
      'English': 'Connect',
      'Amharic': 'ተገናኝ'
    },
    'connect_title': {
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
    'cat_hotel': {
      'Norsk': 'Hotell/Hostel',
      'Tigrinya': 'ሆቴል/ሆስቴል',
      'English': 'Hotel/Hostel',
      'Amharic': 'ሆቴል/ሆስቴል'
    },
    'flights_title': {
      'Norsk': 'Finn billige fly',
      'Tigrinya': 'ሕሱር ነፈርቲ ርኸብ',
      'English': 'Find Cheap Flights',
      'Amharic': 'ርካሽ በረራዎችን ፈልግ'
    },
    'flights_subtitle': {
      'Norsk': 'Søk fly over hele verden — beste priser garantert',
      'Tigrinya': 'ኣብ ምሉእ ዓለም ነፈርቲ ድለ — እቲ ዝበለጸ ዋጋ ዋሕሲ',
      'English': 'Search flights worldwide — best prices guaranteed',
      'Amharic': 'በዓለም ሁሉ በረራዎችን ፈልጉ — ምርጥ ዋጋዎች ዋስትና ተሰጥቷል'
    },
    'flights_popular': {
      'Norsk': 'Populære ruter',
      'Tigrinya': 'ልሙዳት መስመራት',
      'English': 'Popular Routes',
      'Amharic': 'ታዋቂ መስመሮች'
    },
    'flights_search': {
      'Norsk': 'Søk fly nå',
      'Tigrinya': 'ሕጂ ነፈርቲ ድለ',
      'English': 'Search Flights Now',
      'Amharic': 'አሁን በረራዎችን ፈልግ'
    },
    'flights_tips': {
      'Norsk': 'Tips',
      'Tigrinya': 'ምኽርታት',
      'English': 'Tips',
      'Amharic': 'ምክሮች'
    },
    'flights_tip1': {
      'Norsk': '✅ Book 2-3 måneder i forveien for beste priser',
      'Tigrinya': '✅ ቅድሚ 2-3 ወርሒ ሕዝ ንዝበለጸ ዋጋ',
      'English': '✅ Book 2-3 months in advance for best prices',
      'Amharic': '✅ ለምርጥ ዋጋ 2-3 ወር አስቀድሞ ቦታ ያዙ'
    },
    'flights_tip2': {
      'Norsk': '✅ Tirsdag og onsdag er billigste dager å fly',
      'Tigrinya': '✅ ሰሉስን ረቡዕን ብዝሒ ዝለዓለ ዋጋ ዘለዎ መዓልታት',
      'English': '✅ Tuesday & Wednesday are cheapest days to fly',
      'Amharic': '✅ ማክሰኞ እና ረቡዕ ርካሽ ቀናት ናቸው'
    },
    'flights_tip3': {
      'Norsk': '✅ Sammenlign priser med fleksible datoer',
      'Tigrinya': '✅ ዋጋታት ምስ ተለዋዋጢ ዕለታት ኣወዳድር',
      'English': '✅ Compare prices with flexible dates',
      'Amharic': '✅ ተለዋዋጭ ቀናት ጋር ዋጋዎችን ያወዳድሩ'
    },
    'travel_help_title': {
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
      'Tigrinya': 'እንታይ ሓገዝ ትደሊ?',
      'English': 'What do you need help with?',
      'Amharic': 'ምን እርዳታ ይፈልጋሉ?'
    },
    'travel_flight_title': {
      'Norsk': 'Flybestilling',
      'Tigrinya': 'ቡኪንግ ነፈርቲ',
      'English': 'Flight Booking',
      'Amharic': 'የበረራ ቦታ ማስያዝ'
    },
    'travel_flight_desc': {
      'Norsk': 'Vi bestiller flyet for deg + 300 NOK serviceavgift',
      'Tigrinya': 'ነፈርቲ ክእዘዘልካ + 300 NOK ክፍሊት',
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
      'Tigrinya': 'ምሉእ ጥቅሊ — ዝሓሰ ዋጋ',
      'English': 'Complete travel package — best value',
      'Amharic': 'ሙሉ የጉዞ ጥቅል — ምርጥ ዋጋ'
    },
    'travel_hotel_title': {
      'Norsk': 'Overnatting',
      'Tigrinya': 'መሕደሪ',
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
      'Tigrinya': 'ሕቶ ስደድ',
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
    'route_oslo_addis': {
      'Norsk': '🇳🇴 Oslo → 🇪🇹 Addis Abeba',
      'Tigrinya': '🇳🇴 ኦስሎ → 🇪🇹 ኣዲስ ኣበባ',
      'English': '🇳🇴 Oslo → 🇪🇹 Addis Abeba',
      'Amharic': '🇳🇴 ኦስሎ → 🇪🇹 አዲስ አበባ'
    },
    'route_oslo_asmara': {
      'Norsk': '🇳🇴 Oslo → 🇪🇷 Asmara',
      'Tigrinya': '🇳🇴 ኦስሎ → 🇪🇷 ኣስመራ',
      'English': '🇳🇴 Oslo → 🇪🇷 Asmara',
      'Amharic': '🇳🇴 ኦስሎ → 🇪🇷 አስመራ'
    },
    'route_stockholm_addis': {
      'Norsk': '🇸🇪 Stockholm → 🇪🇹 Addis Abeba',
      'Tigrinya': '🇸🇪 ስቶክሆልም → 🇪🇹 ኣዲስ ኣበባ',
      'English': '🇸🇪 Stockholm → 🇪🇹 Addis Abeba',
      'Amharic': '🇸🇪 ስቶክሆልም → 🇪🇹 አዲስ አበባ'
    },
    'route_london_addis': {
      'Norsk': '🇬🇧 London → 🇪🇹 Addis Abeba',
      'Tigrinya': '🇬🇧 ለንደን → 🇪🇹 ኣዲስ ኣበባ',
      'English': '🇬🇧 London → 🇪🇹 Addis Abeba',
      'Amharic': '🇬🇧 ለንደን → 🇪🇹 አዲስ አበባ'
    },
    'route_kampala_addis': {
      'Norsk': '🇺🇬 Kampala → 🇪🇹 Addis Abeba',
      'Tigrinya': '🇺🇬 ካምፓላ → 🇪🇹 ኣዲስ ኣበባ',
      'English': '🇺🇬 Kampala → 🇪🇹 Addis Abeba',
      'Amharic': '🇺🇬 ካምፓላ → 🇪🇹 አዲስ አበባ'
    },
    'route_world_africa': {
      'Norsk': '🌍 Hele verden → Afrika',
      'Tigrinya': '🌍 ምሉእ ዓለም → ኣፍሪቃ',
      'English': '🌍 Worldwide → Africa',
      'Amharic': '🌍 ዓለም ሁሉ → አፍሪካ'
    },
    'flights_tip4': {
      'Norsk': '✅ Ethiopian Airlines har ofte beste priser til Afrika',
      'Tigrinya': '✅ ኢትዮጵያን ኤርላይንስ ናብ ኣፍሪቃ ዝበለጸ ዋጋ ኣለዎ',
      'English': '✅ Ethiopian Airlines often has best Africa prices',
      'Amharic': '✅ ኢትዮጵያ አየር መንገድ ለአፍሪካ ምርጥ ዋጋ አለው'
    },
    'favorites_title': {
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
    'connect_education': {
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
    'marketplace_title': {
      'Norsk': 'Marked',
      'Tigrinya': 'ዕዳጋ',
      'English': 'Marketplace',
      'Amharic': 'ገበያ'
    },
    'marketplace_subtitle': {
      'Norsk': 'Kjøp og selg brukte ting',
      'Tigrinya': 'ዝተጠቕሙ ኣቓሑ ሸጡ ወይ ግዝኡ',
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
      'Tigrinya': 'ሽጥ',
      'English': 'Sell',
      'Amharic': 'ሸጥ'
    },
    'marketplace_search_name': {
      'Norsk': 'Søk etter produkt...',
      'Tigrinya': 'ብ ሽም ንብረት ድለ',
      'English': 'Search for product...',
      'Amharic': 'ምርት ፈልግ...'
    },
    'marketplace_search_city': {
      'Norsk': 'Søk etter by...',
      'Tigrinya': 'ከተማ ድለ...',
      'English': 'Search by city...',
      'Amharic': 'በከተማ ፈልግ...'
    },
    'marketplace_edit': {
      'Norsk': 'Rediger annonse',
      'Tigrinya': 'ኣዊጅ ኣርም',
      'English': 'Edit Listing',
      'Amharic': 'ማስታወቂያ አርም'
    },
    'marketplace_add': {
      'Norsk': 'Legg ut annonse',
      'Tigrinya': 'ዝርዝር ወስኽ',
      'English': 'Add Listing',
      'Amharic': 'ማስታወቂያ ጨምር'
    },
    'marketplace_empty': {
      'Norsk': 'Ingen annonser ennå',
      'Tigrinya': 'ዝርዝር የለን',
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
    'marketplace_city': {
      'Norsk': 'BY / STED',
      'Tigrinya': 'ከተማ / ቦታ',
      'English': 'CITY / LOCATION',
      'Amharic': 'ከተማ / ቦታ'
    },
    'market_other': {
      'Norsk': 'Annet',
      'Tigrinya': 'ካልእ',
      'English': 'Other',
      'Amharic': 'ሌላ'
    },
    'connect_messages': {
      'Norsk': 'Meldinger',
      'Tigrinya': 'መልእኽትታት',
      'English': 'Connect Messages',
      'Amharic': 'መልዕክቶች'
    },
    'connect_no_messages': {
      'Norsk': 'Ingen meldinger ennå',
      'Tigrinya': 'ገና መልእኽቲ የለን',
      'English': 'No messages yet',
      'Amharic': 'እስካሁን መልዕክት የለም'
    },
    'connect_it': {
      'Norsk': 'IT',
      'Tigrinya': 'ቴክኖሎጂ',
      'English': 'IT',
      'Amharic': 'ቴክኖሎጂ'
    },
    'connect_health': {
      'Norsk': 'Helse',
      'Tigrinya': 'ጥዕና',
      'English': 'Health',
      'Amharic': 'ጤና'
    },
    'connect_save': {
      'Norsk': 'Lagre profil',
      'Tigrinya': 'ፕሮፋይል ሓዝ',
      'English': 'Save Profile',
      'Amharic': 'መገለጫ አስቀምጥ'
    },
    'connect': {
      'Norsk': 'Koble til',
      'Tigrinya': 'ተራኸብ',
      'English': 'Connect',
      'Amharic': 'ተገናኝ'
    },
    'connect_title': {
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
    'cat_hotel': {
      'Norsk': 'Hotell/Hostel',
      'Tigrinya': 'ሆቴል/ሆስቴል',
      'English': 'Hotel/Hostel',
      'Amharic': 'ሆቴል/ሆስቴል'
    },
    'cat_photographer': {
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
    'faq_what_q': {
      'Norsk': 'What is Habesha Hub?',
      'Tigrinya': 'እንታይ እያ Habesha Hub?',
      'English': 'What is Habesha Hub?',
      'Amharic': 'Habesha Hub ምንድን ነው?'
    },
    'faq_what_a': {
      'Norsk': 'Habesha Hub is a free platform for finding Ethiopian and Eritrean businesses nearby and around the world.',
      'Tigrinya': 'Habesha Hub ናጻ መድረኽ ኮይኑ ንኤርትራውያንን ኢትዮጵያውያንን ትካላት ኣብ ጥቓኻን ኣብ ምሉእ ዓለምን ንምርካብ ይሕግዝ።',
      'English': 'Habesha Hub is a free platform for finding Ethiopian and Eritrean businesses nearby and around the world.',
      'Amharic': 'Habesha Hub በአቅራቢያዎ እና በመላው ዓለም የኢትዮጵያ እና የኤርትራ ንግዶችን ለማግኘት ነፃ መድረክ ነው።'
    },
    'faq_account_q': {
      'Norsk': 'Do I need an account?',
      'Tigrinya': 'ሕሳብ የድልየኒ ድዩ?',
      'English': 'Do I need an account?',
      'Amharic': 'መለያ ያስፈልገኛል?'
    },
    'faq_account_a': {
      'Norsk': 'No! You can browse businesses, search, and chat as a guest.',
      'Tigrinya': 'ኣይኮነን! ከም ጋሻ ኮንካ ትካላት ክትርእን ክትደልን ክትዘራረብን ትኽእል ኢኻ።',
      'English': 'No! You can browse businesses, search, and chat as a guest.',
      'Amharic': 'አያስፈልግም! እንደ እንግዳ ንግዶችን ማሰስ፣ መፈለግ እና ማውራት ይችላሉ።'
    },
    'faq_register_q': {
      'Norsk': 'How do I register a business?',
      'Tigrinya': 'ከመይ ጌረ ትካል ይምዝገብ?',
      'English': 'How do I register a business?',
      'Amharic': 'ንግድ እንዴት እመዘግባለሁ?'
    },
    'faq_register_a': {
      'Norsk': 'Go to Profile → Register Your Business. Your business will be approved within 1-2 business days.',
      'Tigrinya': 'ናብ መግለጺ → ትካልካ መዝግብ ኪድ። ትካልካ ኣብ ውሽጢ 1-2 ናይ ስራሕ መዓልታት ክጸድቕ እዩ።',
      'English': 'Go to Profile → Register Your Business. Your business will be approved within 1-2 business days.',
      'Amharic': 'ወደ መገለጫ → ንግድዎን ይመዝግቡ ይሂዱ። ንግድዎ በ1-2 የስራ ቀናት ውስጥ ይፀድቃል።'
    },
    'contact_us': {
      'Norsk': 'Contact us',
      'Tigrinya': 'ርኸቡና',
      'English': 'Contact us',
      'Amharic': 'ያግኙን'
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

/// Short global helper: tr('Book Now') → text in the selected language.
String tr(String text) => AppTranslations.tr(text);
