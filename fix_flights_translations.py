# Add flight translations to translations.dart
with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    'cat_hotel': {"
new = """    'flights_title': {
      'Norsk': 'Finn billige fly',
      'Tigrinya': 'ርካሽ ነፈርቲ ርኸብ',
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
    'flights_tip4': {
      'Norsk': '✅ Ethiopian Airlines har ofte beste priser til Afrika',
      'Tigrinya': '✅ ኢትዮጵያን ኤርላይንስ ናብ ኣፍሪቃ ዝበለጸ ዋጋ ኣለዎ',
      'English': '✅ Ethiopian Airlines often has best Africa prices',
      'Amharic': '✅ ኢትዮጵያ አየር መንገድ ለአፍሪካ ምርጥ ዋጋ አለው'
    },
    'cat_hotel': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Flight translations added")
else:
    print("❌ Pattern not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
