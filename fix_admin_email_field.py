with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "'createdAt': FieldValue.serverTimestamp(), 'replied': false, 'adminEmail': 'samuelefriem@gmail.com',"
new = "'createdAt': FieldValue.serverTimestamp(), 'replied': false, 'adminEmail': 'support@habesha-hub.no',"

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed")
else:
    print("❌ Not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
