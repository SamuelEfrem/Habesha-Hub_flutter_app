with open('lib/screens/events_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the broken debug line
old = """        final isOwner = FirebaseAuth.instance.currentUser?.uid == data['createdBy'];
        print('Event: \\${data['title']} createdBy=\\${data['createdBy']} currentUid=\\${FirebaseAuth.instance.currentUser?.uid} isOwner=\\$isOwner');"""

new = "        final isOwner = FirebaseAuth.instance.currentUser?.uid == data['createdBy'];"

if old in content:
    content = content.replace(old, new)
    print("✅ Removed broken debug line")
else:
    print("trying alternative match")
    # Just find and remove any line starting with print('Event:
    lines = content.split('\n')
    new_lines = [l for l in lines if "print('Event:" not in l]
    if len(new_lines) != len(lines):
        content = '\n'.join(new_lines)
        print("✅ Removed via line filter")
    else:
        print("❌ Could not find debug line")

with open('lib/screens/events_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
