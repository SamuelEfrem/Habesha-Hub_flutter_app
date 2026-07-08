with open('lib/screens/marketplace_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix function signature to accept docId
old1 = "void _contactSeller(BuildContext context, Map<String, dynamic> data,\n      User? user, String Function(String) t) {"
new1 = "void _contactSeller(BuildContext context, Map<String, dynamic> data,\n      User? user, String Function(String) t, {String? docId}) {"

if old1 in content:
    content = content.replace(old1, new1)
    print("✅ docId parameter added")
else:
    print("❌ Function signature not found")

# Fix chatId to use docId
old2 = "id: 'market_' + sortedId + '_' + (data['title'] ?? 'item').replaceAll(' ', '').toLowerCase(),"
new2 = "id: 'market_' + sortedId + (docId != null ? '_' + docId : '_item'),"

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ chatId uses docId")
else:
    print("❌ chatId not found")
    idx = content.find("id: 'market_'")
    print(repr(content[idx:idx+100]))

with open('lib/screens/marketplace_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
