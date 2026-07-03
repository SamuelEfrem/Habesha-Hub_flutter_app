with open('lib/screens/hotel_booking_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    ("'Hotel Booking'", "t('hotel_booking')"),
    ("'CHECK-IN'", "t('check_in')"),
    ("'CHECK-OUT'", "t('check_out')"),
    ("'GUESTS'", "t('guests')"),
    ("'MESSAGE (optional)'", "t('special_requests')"),
    ("'Send Booking Request'", "t('send_booking')"),
    ("'Booking request sent!'", "t('booking_sent')"),
    ("'The host will contact you soon.'", "t('host_contact')"),
    ("'Go back'", "t('go_back')"),
    ("'$_nights night${_nights != 1 ? 's' : ''}'", "'\$_nights \${_nights != 1 ? t(\\'nights\\') : t(\\'night\\')}'"),
]

for old, new in replacements:
    if old in content:
        content = content.replace(old, new)
        print(f"✅ {old[:40]}")
    else:
        print(f"❌ {old[:40]}")

# Add AnimatedBuilder and t function
if 'final t = languageNotifier.t;' not in content:
    old2 = "    final t = languageNotifier.t;\n    return Scaffold("
    if old2 not in content:
        content = content.replace(
            "    final t = languageNotifier.t;",
            "    final t = languageNotifier.t;"
        )

with open('lib/screens/hotel_booking_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# Fix favorites screen title
with open('lib/screens/favorites_screen.dart', 'r', encoding='utf-8') as f:
    content2 = f.read()

content2 = content2.replace(
    "title: Text('Mine favoritter', style: tsTitleMd(color: kSecondary)),",
    "title: AnimatedBuilder(animation: languageNotifier, builder: (_, __) => Text(languageNotifier.t('favorites_title'), style: tsTitleMd(color: kSecondary))),"
)
content2 = content2.replace(
    "Text('Ingen favoritter ennå', style: tsTitleLg()),",
    "Text(languageNotifier.t('favorites_title'), style: tsTitleLg()),"
)

with open('lib/screens/favorites_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content2)
print("✅ Favorites screen translated")
print("Done!")
