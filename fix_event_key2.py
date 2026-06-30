with open('lib/screens/events_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "const _EventCard({required this.docId, required this.data, required this.db});"
new = "const _EventCard({super.key, required this.docId, required this.data, required this.db});"

if old in content:
    content = content.replace(old, new)
    print("✅ super.key added to constructor")
else:
    print("❌ Pattern not found")

with open('lib/screens/events_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
