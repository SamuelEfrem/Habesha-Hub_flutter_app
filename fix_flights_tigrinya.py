# Fix Tigrinya word in translations
with open('lib/utils/translations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("'Tigrinya': 'ርካሽ ነፈርቲ ርኸብ'", "'Tigrinya': 'ሕሱር ነፈርቲ ርኸብ'")
content = content.replace("'Tigrinya': 'ርካሽ ዋጋ ዋሕሲ'", "'Tigrinya': 'ሕሱር ዋጋ ዋሕሲ'")

# Add route translations
old = "    'flights_tip4': {"
new = """    'route_oslo_addis': {
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
    'flights_tip4': {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Route translations added")
else:
    print("❌ Pattern not found")

with open('lib/utils/translations.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
