import re

# Fix business_detail_screen.dart
with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "'mailto:samuelefriem@gmail.com?subject=Premium+menu+upload');"
new = "'mailto:support@habesha-hub.no?subject=Premium+menu+upload');"
if old in content:
    content = content.replace(old, new)
    print("✅ business_detail_screen.dart fixed")
else:
    print("❌ business_detail_screen.dart pattern not found")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# Fix placeholder_screens.dart
with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old2 = "final url = Uri.parse('mailto:samuelefriem@gmail.com?subject=$subject&body=$body');"
new2 = "final url = Uri.parse('mailto:support@habesha-hub.no?subject=$subject&body=$body');"
if old2 in content:
    content = content.replace(old2, new2)
    print("✅ placeholder_screens.dart mailto fixed")
else:
    print("❌ placeholder_screens.dart mailto pattern not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
