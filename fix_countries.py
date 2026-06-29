with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add new African countries after Kenya
old_kenya = "        {'name': 'Kenya', 'flag': '🇰🇪', 'label': 'country_kenya', 'cities': ['Nairobi', 'Mombasa', 'Kisumu']},"
new_kenya = """        {'name': 'Kenya', 'flag': '🇰🇪', 'label': 'country_kenya', 'cities': ['Nairobi', 'Mombasa', 'Kisumu']},
        {'name': 'Ethiopia', 'flag': '🇪🇹', 'label': 'country_ethiopia', 'cities': ['Addis Ababa', 'Dire Dawa', 'Mekelle']},
        {'name': 'Eritrea', 'flag': '🇪🇷', 'label': 'country_eritrea', 'cities': ['Asmara', 'Massawa', 'Keren']},
        {'name': 'Egypt', 'flag': '🇪🇬', 'label': 'country_egypt', 'cities': ['Cairo', 'Alexandria', 'Giza']},
        {'name': 'Angola', 'flag': '🇦🇴', 'label': 'country_angola', 'cities': ['Luanda', 'Huambo', 'Benguela']},
        {'name': 'South Sudan', 'flag': '🇸🇸', 'label': 'country_south_sudan', 'cities': ['Juba', 'Wau', 'Malakal']},
        {'name': 'Rwanda', 'flag': '🇷🇼', 'label': 'country_rwanda', 'cities': ['Kigali', 'Butare', 'Gisenyi']},"""

if old_kenya in content:
    content = content.replace(old_kenya, new_kenya)
    print("✅ African countries added")
else:
    print("❌ Kenya not found")

# 2. Add Leeds to UK
old_uk = "{'name': 'UK', 'flag': '🇬🇧', 'label': 'country_uk', 'cities': ['London', 'Manchester', 'Birmingham']},"
new_uk = "{'name': 'UK', 'flag': '🇬🇧', 'label': 'country_uk', 'cities': ['London', 'Manchester', 'Birmingham', 'Leeds']},"

if old_uk in content:
    content = content.replace(old_uk, new_uk)
    print("✅ Leeds added to UK")
else:
    print("❌ UK not found")

# 3. Fix country names to English
replacements = [
    ("'name': 'Norge'", "'name': 'Norway'"),
    ("'name': 'Sverige'", "'name': 'Sweden'"),
    ("'name': 'Danmark'", "'name': 'Denmark'"),
    ("'name': 'Tyskland'", "'name': 'Germany'"),
    ("'name': 'Nederland'", "'name': 'Netherlands'"),
    ("'name': 'Frankrike'", "'name': 'France'"),
    ("'name': 'Belgia'", "'name': 'Belgium'"),
    ("'name': 'Sveits'", "'name': 'Switzerland'"),
    ("'name': 'Italia'", "'name': 'Italy'"),
    ("'name': 'Amerika'", "'name': 'Americas'"),
]
for old, new in replacements:
    if old in content:
        content = content.replace(old, new)
        print(f"✅ {old} → {new}")

# 4. Fix country label display (use name instead of label)
old_label = "Text(t(c['label'] as String), style: tsLabel(color: sel ? kSecondary : kOnSurfaceVariant.withOpacity(0.8)))"
new_label = "Text(c['name'] as String, style: tsLabel(color: sel ? kSecondary : kOnSurfaceVariant.withOpacity(0.8)))"

if old_label in content:
    content = content.replace(old_label, new_label)
    print("✅ Label display fixed")
else:
    print("❌ Label not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("\nDone!")
