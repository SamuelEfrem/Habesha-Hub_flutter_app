with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """      final businesses = snap.docs.map((d) => Business.fromFirestore(d.data(), d.id)).toList();
      setState(() { _myBusinesses = businesses; _isOwner = businesses.isNotEmpty; _loading = false; });"""

new = """      final businesses = snap.docs.map((d) => Business.fromFirestore(d.data(), d.id)).toList();
      print('ChatList: found \${businesses.length} businesses for user \${user.uid}');
      setState(() { _myBusinesses = businesses; _isOwner = businesses.isNotEmpty; _loading = false; });"""

if old in content:
    content = content.replace(old, new)
    print("Done!")
else:
    print("Pattern not found!")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
