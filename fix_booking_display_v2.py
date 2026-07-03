with open('lib/screens/booking_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the broken lines
old1 = """            Text('\${DateFormat('dd. MMM').format(date)} kl. \${data['time']}', style: tsBodySm()),"""
new1 = """            Text(DateFormat('dd. MMM').format(date) + ' kl. ' + (data['time'] ?? ''), style: tsBodySm()),"""

old2 = """            Text('\${DateFormat('dd.MM').format((data['checkIn'] as Timestamp).toDate())} → \${DateFormat('dd.MM').format((data['checkOut'] as Timestamp).toDate())}', style: tsBodySm()),"""
new2 = """            Text(DateFormat('dd.MM').format((data['checkIn'] as Timestamp).toDate()) + ' → ' + DateFormat('dd.MM').format((data['checkOut'] as Timestamp).toDate()), style: tsBodySm()),"""

if old1 in content:
    content = content.replace(old1, new1)
    print("✅ Fixed line 426")
else:
    print("❌ Line 426 not found")

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ Fixed line 432")
else:
    print("❌ Line 432 not found")

with open('lib/screens/booking_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
