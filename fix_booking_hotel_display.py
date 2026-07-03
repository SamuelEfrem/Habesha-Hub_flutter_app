with open('lib/screens/booking_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """          if (date != null) ...[
            const Icon(Icons.calendar_today_rounded,
                color: kSecondary, size: 14),
            const SizedBox(width: 6),
            Text('${DateFormat('dd. MMM').format(date)} kl. ${data['time']}',
                style: tsBodySm()),
          ],"""

new = """          if (data['type'] == 'hotel') ...[
            const Icon(Icons.nights_stay_rounded, color: kSecondary, size: 14),
            const SizedBox(width: 6),
            Text('${data['nights'] ?? 1} nights, ${data['guests'] ?? 1} guests', style: tsBodySm()),
          ] else if (date != null) ...[
            const Icon(Icons.calendar_today_rounded, color: kSecondary, size: 14),
            const SizedBox(width: 6),
            Text('\${DateFormat(\'dd. MMM\').format(date)} kl. \${data[\'time\']}', style: tsBodySm()),
          ],
          if (data['type'] == 'hotel' && data['checkIn'] != null) ...[
            const SizedBox(width: 10),
            const Icon(Icons.calendar_today_rounded, color: kSecondary, size: 14),
            const SizedBox(width: 4),
            Text('\${DateFormat(\'dd.MM\').format((data[\'checkIn\'] as Timestamp).toDate())} → \${DateFormat(\'dd.MM\').format((data[\'checkOut\'] as Timestamp).toDate())}', style: tsBodySm()),
          ],"""

if old in content:
    content = content.replace(old, new)
    print("✅ Hotel booking display fixed")
else:
    print("❌ Pattern not found")

with open('lib/screens/booking_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
