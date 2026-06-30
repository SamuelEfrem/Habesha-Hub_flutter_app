with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """    'help_support': {
      'Norsk': 'Help & Support',
      'Tigrinya': 'ሓገዝን ደገፍን',
      'English': 'Help & Support',
      'Amharic': 'እርዳታ'
    },"""

new = """    'help_support': {
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
    },"""

if old in content:
    content = content.replace(old, new)
    print("✅ FAQ translations added")
else:
    print("❌ Pattern not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
