with open('lib/screens/marketplace_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    final fakeBusiness = Business(\nid: 'market_' + sortedId,"
new = "    final chatId = 'market_' + sortedId + (docId != null ? '_' + docId : '');\n    final fakeBusiness = Business(\n      id: chatId,"

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed!")
else:
    print("❌ Not found")

with open('lib/screens/marketplace_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
