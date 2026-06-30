with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "Row(children: [const Icon(Icons.email_outlined, color: kSecondary, size: 15), const SizedBox(width: 8), Text('samuelefriem@gmail.com', style: tsBodySm())]),"
new = "Row(children: [const Icon(Icons.email_outlined, color: kSecondary, size: 15), const SizedBox(width: 8), Text('support@habesha-hub.no', style: tsBodySm())]),"

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed!")
else:
    print("❌ Pattern not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
