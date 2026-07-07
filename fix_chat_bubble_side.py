with open('lib/screens/guest_chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """                        final data = docs[i].data() as Map<String, dynamic>;
                        final isMe = !((data['isAdmin'] as bool?) ?? false);"""

new = """                        final data = docs[i].data() as Map<String, dynamic>;
                        // For connect chats: check userId. For business chats: check isAdmin
                        final isMe = widget.business.id.startsWith('connect_')
                            ? (data['userId'] ?? '') == _userId
                            : !((data['isAdmin'] as bool?) ?? false);"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed bubble side for connect chats")
else:
    print("❌ Not found")

with open('lib/screens/guest_chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
