with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add hotel_booking_screen import
if 'hotel_booking_screen' not in content:
    content = content.replace(
        "import 'guest_chat_screen.dart';",
        "import 'guest_chat_screen.dart';\nimport 'hotel_booking_screen.dart';"
    )
    print("✅ Import added")

# Fix booking button - open HotelBookingScreen for Hotel category
old = """            actionSquare(Icons.chat_bubble_rounded, t('chat_tab'), () {
              final user = FirebaseAuth.instance.currentUser;
              final isOwner = user?.uid == widget.business.ownerId;
              if (isOwner) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessInboxScreen(business: widget.business)));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GuestChatScreen(business: widget.business)));
              }
            }),"""

new = """            actionSquare(Icons.chat_bubble_rounded, t('chat_tab'), () {
              final user = FirebaseAuth.instance.currentUser;
              final isOwner = user?.uid == widget.business.ownerId;
              if (isOwner) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessInboxScreen(business: widget.business)));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => GuestChatScreen(business: widget.business)));
              }
            }),
            if (widget.business.category == 'Hotel')
              actionSquare(Icons.hotel_rounded, 'Book Room', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => HotelBookingScreen(business: widget.business)));
              }),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Hotel booking button added")
else:
    print("❌ Pattern not found")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
