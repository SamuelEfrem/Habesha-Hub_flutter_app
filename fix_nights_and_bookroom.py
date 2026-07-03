# Fix 1: Remove +1 from nights calculation
with open('lib/screens/hotel_booking_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "int get _nights => _checkOut.difference(_checkIn).inDays + 1;",
    "int get _nights => _checkOut.difference(_checkIn).inDays;"
)
print("✅ Removed +1 from nights")

with open('lib/screens/hotel_booking_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# Fix 2: Translate "Book Room" in business_detail_screen
with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content2 = f.read()

content2 = content2.replace(
    "'Book Room'",
    "languageNotifier.language == 'Tigrinya' ? 'ቡክ መሕደሪ' : languageNotifier.language == 'Amharic' ? 'ክፍል ያዝ' : languageNotifier.language == 'Norsk' ? 'Book rom' : 'Book Room'"
)
print("✅ Book Room translated")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content2)
print("Done!")
