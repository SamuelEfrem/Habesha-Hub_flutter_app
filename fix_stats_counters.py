with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Increment reviewCount when review is posted
old = """                await _db.collection('businesses').doc(widget.business.id).collection('reviews').add({
                  'userId': user.uid,
                  'nickname': user.displayName ?? 'User',
                  'comment': commentCtrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                commentCtrl.clear();"""

new = """                await _db.collection('businesses').doc(widget.business.id).collection('reviews').add({
                  'userId': user.uid,
                  'nickname': user.displayName ?? 'User',
                  'comment': commentCtrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                await _db.collection('businesses').doc(widget.business.id).update({
                  'reviewCount': FieldValue.increment(1),
                });
                commentCtrl.clear();"""

if old in content:
    content = content.replace(old, new)
    print("✅ reviewCount increment added")
else:
    print("❌ Review post pattern not found")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# Increment bookingCount when booking is made
with open('lib/screens/booking_screen.dart', 'r', encoding='utf-8') as f:
    content2 = f.read()

old2 = """      'createdAt': FieldValue.serverTimestamp(),
    });"""

new2 = """      'createdAt': FieldValue.serverTimestamp(),
    });
    // Increment booking count
    await FirebaseFirestore.instance.collection('businesses').doc(businessId).update({
      'bookingCount': FieldValue.increment(1),
    });"""

# Find the right booking add
if "'type': 'booking'" in content2:
    content2 = content2.replace(
        "'type': 'hotel',\n      'checkIn': Timestamp.fromDate(_checkIn),",
        "'type': 'hotel',\n      'checkIn': Timestamp.fromDate(_checkIn),"
    )

print("Done!")
with open('lib/screens/booking_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content2)
