with open('lib/screens/hotel_booking_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """Text('\\$_nights \\${_nights != 1 ? t(\\'nights\\') : t(\\'night\\')}', style: tsTitleMd("""
new = """Text('$_nights ' + (_nights != 1 ? t('nights') : t('night')), style: tsTitleMd("""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed nights display")
else:
    print("❌ Not found - trying alternative")
    # Try to find and fix directly
    import re
    pattern = r"Text\('\\?\$_nights.*?nights.*?night.*?'\)"
    matches = re.findall(pattern, content)
    print("Found:", matches[:2])

with open('lib/screens/hotel_booking_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
