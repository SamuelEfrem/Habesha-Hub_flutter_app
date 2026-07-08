with open('lib/screens/marketplace_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix _contactSeller to include docId in chatId
old = """  void _contactSeller(BuildContext context, Map<String, dynamic> data, User? user, String Function(String) t) {
    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true)));
      return;
    }
    final uid1 = user.uid;
    final uid2 = data['userId'] ?? '';
    if (uid1 == uid2) return;
    final sortedId = uid1.compareTo(uid2) < 0 ? uid1 + '_' + uid2 : uid2 + '_' + uid1;
    final fakeBusiness = Business(
      id: 'market_' + sortedId,"""

new = """  void _contactSeller(BuildContext context, Map<String, dynamic> data, User? user, String Function(String) t, {String? docId}) {
    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true)));
      return;
    }
    final uid1 = user.uid;
    final uid2 = data['userId'] ?? '';
    if (uid1 == uid2) return;
    final sortedId = uid1.compareTo(uid2) < 0 ? uid1 + '_' + uid2 : uid2 + '_' + uid1;
    // Include listing ID so each item has its own chat
    final chatId = 'market_' + sortedId + (docId != null ? '_' + docId : '');
    final fakeBusiness = Business(
      id: chatId,"""

if old in content:
    content = content.replace(old, new)
    print("✅ Per-item chat ID added")
else:
    print("❌ Not found")

# Pass docId when calling _contactSeller
content = content.replace(
    "onContact: () => _contactSeller(context, data, user, t),",
    "onContact: () => _contactSeller(context, data, user, t, docId: docs[i].id),"
)
print("✅ docId passed to contactSeller")

with open('lib/screens/marketplace_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
