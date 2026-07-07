with open('lib/screens/connect_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix - don't push AuthScreen if already logged in
old = """    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true)));
      return;
    }"""
new = """    if (user == null) {
      final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true)));
      if (result != true) return;
      // Retry after login
      final newUser = FirebaseAuth.instance.currentUser;
      if (newUser == null) return;
      _openChat(context, data, t, newUser);
      return;
    }"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed login flow")
else:
    print("❌ Not found")

with open('lib/screens/connect_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
