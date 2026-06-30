with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "${t('search_in')} ${t('country_${_selectedCountry.toLowerCase()}')}${_selectedCity.isNotEmpty ? \" / $_selectedCity\" : \"\"}"
new = "${t('search_in')} $_selectedCountry${_selectedCity.isNotEmpty ? \" / $_selectedCity\" : \"\"}"

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed!")
else:
    print("❌ Still not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
