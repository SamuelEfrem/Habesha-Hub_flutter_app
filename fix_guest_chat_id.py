with open('lib/screens/guest_chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """    setState(() {
      _userId = uid;
      _nickname = nick;
      _chatId = '${widget.business.id}_$uid';
    });"""

new = """    // For Connect chats, use business.id directly (already contains sorted UIDs)
    final chatId = widget.business.id.startsWith('connect_')
        ? widget.business.id
        : '\${widget.business.id}_\$uid';
    setState(() {
      _userId = uid;
      _nickname = nick;
      _chatId = chatId;
    });"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed chat ID for Connect")
else:
    print("❌ Not found")

with open('lib/screens/guest_chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
