with open('lib/screens/events_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """        final isOwner = FirebaseAuth.instance.currentUser?.uid == data['createdBy'];"""

new = """        final isOwner = FirebaseAuth.instance.currentUser?.uid == data['createdBy'];
        print('Event: \${data['title']} createdBy=\${data['createdBy']} currentUid=\${FirebaseAuth.instance.currentUser?.uid} isOwner=\$isOwner');"""

if old in content:
    content = content.replace(old, new)
    print("✅ Debug added")
else:
    print("❌ Not found")

with open('lib/screens/events_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
