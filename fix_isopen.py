with open('lib/screens/register_business_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "        'isOpen': false,"
new = "        'isOpen': true,"

if old in content:
    content = content.replace(old, new)
    print("✅ isOpen set to true")
else:
    print("❌ Pattern not found")

with open('lib/screens/register_business_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
