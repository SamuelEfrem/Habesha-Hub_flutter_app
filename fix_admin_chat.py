with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Change AdminChatScreen to show all chats for business
old = """                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatScreen(business: widget.business, chatId: widget.business.id)));"""

new = """                Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessInboxScreen(business: widget.business)));"""

if old in content:
    content = content.replace(old, new)
    print("✅ Updated to BusinessInboxScreen")
else:
    print("❌ Pattern not found")

# Add import
if 'business_inbox_screen' not in content:
    content = content.replace(
        "import 'guest_chat_screen.dart';",
        "import 'guest_chat_screen.dart';\nimport 'business_inbox_screen.dart';"
    )
    print("✅ Import added")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
