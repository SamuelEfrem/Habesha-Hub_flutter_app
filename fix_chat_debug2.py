with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;"""

new = """  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    print('ChatList _load: user=\${user?.email} uid=\${user?.uid}');"""

if old in content:
    content = content.replace(old, new)
    print("Done!")
else:
    print("Pattern not found!")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
