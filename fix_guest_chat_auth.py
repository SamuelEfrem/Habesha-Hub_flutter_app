with open('lib/screens/guest_chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final uid = user?.uid ?? prefs.getString('userId') ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    if (user == null) {
      await prefs.setString('userId', uid);
    }
    final nick = prefs.getString('nickname') ?? user?.displayName ?? 'Guest';"""

new = """  Future<void> _loadUser() async {
    // Wait for auth state to be ready
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      user = await FirebaseAuth.instance.authStateChanges().first;
    }
    final prefs = await SharedPreferences.getInstance();
    final uid = user?.uid ?? prefs.getString('userId') ?? 'guest_' + DateTime.now().millisecondsSinceEpoch.toString();
    if (user == null) {
      await prefs.setString('userId', uid);
    }
    final nick = user?.displayName ?? prefs.getString('nickname') ?? 'Guest';"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed auth state")
else:
    print("❌ Not found")

with open('lib/screens/guest_chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
