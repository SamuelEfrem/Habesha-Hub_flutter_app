with open('lib/screens/marketplace_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "void _contactSeller(BuildContext context, Map<String, dynamic> data,\n      User? user, String Function(String) t) {"
new = "void _contactSeller(BuildContext context, Map<String, dynamic> data,\n      User? user, String Function(String) t, {String? docId}) {"

if old in content:
    content = content.replace(old, new)
    print("✅ Added docId parameter")
else:
    print("❌ Not found")

# Fix chatId to include docId
old2 = "    final sortedId = uid1.compareTo(uid2) < 0 ? uid1 + '_' + uid2 : uid2 + '_' + uid1;\n    final fakeBusiness = Business(\n      id: 'market_' + sortedId,"
new2 = "    final sortedId = uid1.compareTo(uid2) < 0 ? uid1 + '_' + uid2 : uid2 + '_' + uid1;\n    final chatId = 'market_' + sortedId + (docId != null ? '_' + docId : '');\n    final fakeBusiness = Business(\n      id: chatId,"

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ chatId includes docId")
else:
    print("❌ chatId pattern not found")
    idx = content.find("sortedId = uid1")
    print(repr(content[idx:idx+200]))

with open('lib/screens/marketplace_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
