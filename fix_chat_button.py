with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix chat button - open AdminChatScreen for owner, BookingScreen for others
old = "            actionSquare(Icons.chat_bubble_rounded, t('chat_tab'),\n                () => _tabController.animateTo(1)),"

new = """            actionSquare(Icons.chat_bubble_rounded, t('chat_tab'), () {
              final user = FirebaseAuth.instance.currentUser;
              final isOwner = user?.uid == widget.business.ownerId;
              if (isOwner) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatScreen(business: widget.business, chatId: widget.business.id)));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(business: widget.business)));
              }
            }),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Chat button fixed")
else:
    print("❌ Pattern not found, trying alternative...")
    # Try with different whitespace
    import re
    pattern = r"actionSquare\(Icons\.chat_bubble_rounded, t\('chat_tab'\),\s*\(\) => _tabController\.animateTo\(1\)\),"
    replacement = """actionSquare(Icons.chat_bubble_rounded, t('chat_tab'), () {
              final user = FirebaseAuth.instance.currentUser;
              final isOwner = user?.uid == widget.business.ownerId;
              if (isOwner) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatScreen(business: widget.business, chatId: widget.business.id)));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(business: widget.business)));
              }
            }),"""
    new_content = re.sub(pattern, replacement, content)
    if new_content != content:
        content = new_content
        print("✅ Fixed with regex")
    else:
        print("❌ Regex also failed")

# Add AdminChatScreen import if not there
if 'admin_chat_screen.dart' not in content:
    content = content.replace(
        "import '../models/business.dart';",
        "import '../models/business.dart';\nimport 'admin_chat_screen.dart';\nimport 'booking_screen.dart';"
    )
    print("✅ Imports added")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
