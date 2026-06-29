with open('lib/screens/events_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """final email = snap.data?.email ?? '';
                      if (email != 'samuelefriem@gmail.com') {
                        return const SizedBox.shrink();
                      }"""

new = "if (snap.data == null) return const SizedBox.shrink();"

if old in content:
    content = content.replace(old, new)
    with open('lib/screens/events_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done!")
else:
    print("Pattern not found!")
