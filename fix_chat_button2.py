with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add GuestChatScreen import
if 'guest_chat_screen.dart' not in content:
    content = content.replace(
        "import 'admin_chat_screen.dart';",
        "import 'admin_chat_screen.dart';\nimport 'guest_chat_screen.dart';"
    )
    print("✅ GuestChatScreen import added")

# Fix chat button - open GuestChatScreen for non-owners
old = """            actionSquare(Icons.chat_bubble_rounded, t('chat_tab'), () {
              final user = FirebaseAuth.instance.currentUser;
              final isOwner = user?.uid == widget.business.ownerId;
              if (isOwner) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatScreen(business: widget.business, chatId: widget.business.id)));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(business: widget.business)));
              }
            }),"""

new = """            actionSquare(Icons.chat_bubble_rounded, t('chat_tab'), () {
              final user = FirebaseAuth.instance.currentUser;
              final isOwner = user?.uid == widget.business.ownerId;
              if (isOwner) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatScreen(business: widget.business, chatId: widget.business.id)));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GuestChatScreen(business: widget.business)));
              }
            }),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Chat button updated to use GuestChatScreen")
else:
    print("❌ Pattern not found")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
