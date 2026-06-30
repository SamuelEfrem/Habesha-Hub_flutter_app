with open('lib/screens/events_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "final isOwner = FirebaseAuth.instance.currentUser?.uid == data['createdBy'];"
new = """final isOwner = FirebaseAuth.instance.currentUser?.uid == data['createdBy'];
        print('DEBUG title=' + (data['title'] ?? '') + ' createdBy=' + (data['createdBy'] ?? 'NULL') + ' uid=' + (FirebaseAuth.instance.currentUser?.uid ?? 'NULL') + ' isOwner=' + isOwner.toString());"""

if old in content:
    content = content.replace(old, new)
    print("✅ Added")
else:
    print("❌ Not found")

with open('lib/screens/events_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
