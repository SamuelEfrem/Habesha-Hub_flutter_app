with open('lib/screens/hotel_booking_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "  int get _nights => _checkOut.difference(_checkIn).inDays;"
new = "  int get _nights => _checkOut.difference(_checkIn).inDays + 1;"

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed nights count")
else:
    print("❌ Not found")

with open('lib/screens/hotel_booking_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
