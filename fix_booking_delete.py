with open('lib/screens/booking_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the closing of the booking card and add delete button
old = """        if (status == 'pending') ...[
          const SizedBox(height: 12),
          Row(children: ["""

new = """        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => db.collection('bookings').doc(docId).delete(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: kRed.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.delete_outline_rounded, color: kRed, size: 14),
              SizedBox(width: 4),
              Text('Delete', style: TextStyle(color: kRed, fontSize: 12, fontWeight: FontWeight.w600)),
            ])),
          ),
        ),
        if (status == 'pending') ...[
          const SizedBox(height: 8),
          Row(children: ["""

if old in content:
    content = content.replace(old, new)
    print("✅ Delete button added")
else:
    print("❌ Pattern not found")

with open('lib/screens/booking_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
