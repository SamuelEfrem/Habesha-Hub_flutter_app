with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """        {'name': 'Egypt', 'flag': '🇪🇬', 'label': 'country_egypt', 'cities': ['Cairo', 'Alexandria', 'Giza']},
        {'name': 'Angola', 'flag': '🇦🇴', 'label': 'country_angola', 'cities': ['Luanda', 'Huambo', 'Benguela']},
        {'name': 'South Sudan', 'flag': '🇸🇸', 'label': 'country_south_sudan', 'cities': ['Juba', 'Wau', 'Malakal']},
        {'name': 'Rwanda', 'flag': '🇷🇼', 'label': 'country_rwanda', 'cities': ['Kigali', 'Butare', 'Gisenyi']},
      ]"""

new = """        {'name': 'Egypt', 'flag': '🇪🇬', 'label': 'country_egypt', 'cities': ['Cairo', 'Alexandria', 'Giza']},
      ]"""

if old in content:
    content = content.replace(old, new)
    print("✅ Duplicates removed")
else:
    print("❌ Pattern not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
