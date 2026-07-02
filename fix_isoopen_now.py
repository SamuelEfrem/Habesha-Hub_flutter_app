import re

# Fix business_detail_screen.dart
with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace .isOpen with .isOpenNow
old_count = content.count('.isOpen')
content = content.replace('.isOpen', '.isOpenNow')
print(f"business_detail_screen.dart: replaced {old_count} occurrences")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# Fix home_screen.dart
with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_count = content.count('.isOpen')
content = content.replace('.isOpen', '.isOpenNow')
print(f"home_screen.dart: replaced {old_count} occurrences")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# Fix placeholder_screens.dart
with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_count = content.count('.isOpen')
content = content.replace('.isOpen', '.isOpenNow')
print(f"placeholder_screens.dart: replaced {old_count} occurrences")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
