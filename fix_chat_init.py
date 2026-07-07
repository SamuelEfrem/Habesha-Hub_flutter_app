with open('lib/screens/guest_chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """  @override
  void initState() {
    super.initState();
    _loadUser();
  }"""

new = """  @override
  void initState() {
    super.initState();
    // For Connect chats, set chatId immediately
    if (widget.business.id.startsWith('connect_')) {
      _chatId = widget.business.id;
    }
    _loadUser();
  }"""

if old in content:
    content = content.replace(old, new)
    print("✅ ChatId set immediately for connect chats")
else:
    print("❌ Not found")

with open('lib/screens/guest_chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
