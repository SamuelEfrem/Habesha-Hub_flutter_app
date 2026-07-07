with open('lib/screens/guest_chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """    // Wait for auth state to be ready
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      user = await FirebaseAuth.instance.authStateChanges().first;
    }"""

new = """    // Wait for auth state to be ready
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      user = await FirebaseAuth.instance.authStateChanges().first.timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    }"""

if old in content:
    content = content.replace(old, new)
    print("✅ Added timeout to auth check")
else:
    print("❌ Not found")

with open('lib/screens/guest_chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
