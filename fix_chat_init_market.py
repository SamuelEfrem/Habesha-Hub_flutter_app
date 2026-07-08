with open('lib/screens/guest_chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """    // For Connect chats, set chatId immediately
    if (widget.business.id.startsWith('connect_')) {
      _chatId = widget.business.id;
    }"""

new = """    // For Connect/Market chats, set chatId immediately
    if (widget.business.id.startsWith('connect_') || widget.business.id.startsWith('market_')) {
      _chatId = widget.business.id;
    }"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed market chatId init")
else:
    print("❌ Not found")

with open('lib/screens/guest_chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
