with open('lib/screens/events_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove debug line
old_debug = """        final isOwner = FirebaseAuth.instance.currentUser?.uid == data['createdBy'];
        print('DEBUG title=' + (data['title'] ?? '') + ' createdBy=' + (data['createdBy'] ?? 'NULL') + ' uid=' + (FirebaseAuth.instance.currentUser?.uid ?? 'NULL') + ' isOwner=' + isOwner.toString());"""

new_debug = """        final isOwner = FirebaseAuth.instance.currentUser?.uid == data['createdBy'];"""

if old_debug in content:
    content = content.replace(old_debug, new_debug)
    print("✅ Debug line removed")
else:
    print("❌ Debug pattern not found")

with open('lib/screens/events_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
