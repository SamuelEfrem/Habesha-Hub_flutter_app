# Fix hotel icon in all files
for filename in ['lib/screens/home_screen.dart', 'lib/screens/register_business_screen.dart', 'lib/screens/business_detail_screen.dart']:
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('Icons.hotel_rounded', 'Icons.hotel')
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ Fixed {filename}")

# Also fix in hotel_booking_screen if it exists
import os
if os.path.exists('lib/screens/hotel_booking_screen.dart'):
    with open('lib/screens/hotel_booking_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('Icons.hotel_rounded', 'Icons.hotel')
    with open('lib/screens/hotel_booking_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ Fixed hotel_booking_screen.dart")
else:
    print("❌ hotel_booking_screen.dart not found in lib/screens/")
print("Done!")
