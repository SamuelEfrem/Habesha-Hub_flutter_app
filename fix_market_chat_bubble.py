with open('lib/screens/guest_chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """                        // For connect chats: check userId. For business chats: check isAdmin
                        final isMe = widget.business.id.startsWith('connect_')
                            ? (data['userId'] ?? '') == _userId
                            : !((data['isAdmin'] as bool?) ?? false);"""

new = """                        // For connect/market chats: check userId. For business chats: check isAdmin
                        final isMe = (widget.business.id.startsWith('connect_') || widget.business.id.startsWith('market_'))
                            ? (data['userId'] ?? '') == _userId
                            : !((data['isAdmin'] as bool?) ?? false);"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed chat bubble for market")
else:
    print("❌ Not found")

with open('lib/screens/guest_chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
