with open('lib/screens/guest_chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "  late String _chatId;"
new = "  String _chatId = '';\n  bool _chatReady = false;"

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed _chatId initialization")
else:
    print("❌ Not found")

with open('lib/screens/guest_chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
