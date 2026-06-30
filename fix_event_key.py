with open('lib/screens/events_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """                        final data = docs[i].data() as Map<String, dynamic>;
                        return _EventCard(
                            docId: docs[i].id, data: data, db: _db);"""

new = """                        final data = docs[i].data() as Map<String, dynamic>;
                        return _EventCard(
                            key: ValueKey(docs[i].id),
                            docId: docs[i].id, data: data, db: _db);"""

if old in content:
    content = content.replace(old, new)
    print("✅ Key added to EventCard")
else:
    print("❌ Pattern not found")

with open('lib/screens/events_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
