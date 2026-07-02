with open('lib/screens/admin_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add FirebaseFirestore import if not there
if "final _db = FirebaseFirestore.instance;" not in content:
    pass

old = """      ]),
      const SizedBox(height: 8),"""

new = """      ]),
      const SizedBox(height: 8),
      // Premium toggle
      GestureDetector(
        onTap: () {
          FirebaseFirestore.instance.collection('businesses').doc(docId).update({'isPremium': !business.isPremium});
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: business.isPremium ? kSecondary.withOpacity(0.1) : kSurfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: business.isPremium ? kSecondary : kOutlineVariant, width: 0.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(business.isPremium ? Icons.star_rounded : Icons.star_outline_rounded, color: kSecondary, size: 16),
            const SizedBox(width: 6),
            Text(business.isPremium ? '⭐ Remove Premium' : '⭐ Set as Premium', style: tsLabel(color: kSecondary)),
          ]),
        ),
      ),
      const SizedBox(height: 8),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Premium toggle added")
else:
    print("❌ Pattern not found")

with open('lib/screens/admin_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
