with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """    const keyMap = {
      'Alle': 'all',
      'Restaurant': 'restaurant',
      'Butikk': 'shop',
      'Kafé': 'cafe',
      'Frisør': 'barber',
      'Club': 'club',
      'Klinikk': 'clinic',
      'Annet': 'other',
    };"""

new = """    const keyMap = {
      'All': 'all',
      'Restaurant': 'restaurant',
      'Shop': 'shop',
      'Cafe': 'cafe',
      'Barber': 'barber',
      'Club': 'club',
      'Clinic': 'clinic',
      'Other': 'other',
    };"""

if old in content:
    content = content.replace(old, new)
    print("✅ keyMap fixed to English")
else:
    print("❌ Pattern not found")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
