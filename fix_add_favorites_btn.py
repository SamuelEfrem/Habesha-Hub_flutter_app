with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'favorites_screen' not in content:
    content = content.replace(
        "import 'register_business_screen.dart';",
        "import 'register_business_screen.dart';\nimport 'favorites_screen.dart';"
    )
    print("✅ Import added")

# Add favorites button after nickname section
old = """                const SizedBox(height: 24),
                Row(children: [const Icon(Icons.translate_rounded, color: kSecondary, size: 18), const SizedBox(width: 8), Text('Language', style: tsHeadlineSm())]),"""

new = """                const SizedBox(height: 16),
                // Favorites button
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.2), width: 0.5)),
                    child: Row(children: [
                      const Icon(Icons.favorite_rounded, color: kRed, size: 20),
                      const SizedBox(width: 12),
                      Text('Mine favoritter', style: tsTitleMd()),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 14),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),
                Row(children: [const Icon(Icons.translate_rounded, color: kSecondary, size: 18), const SizedBox(width: 8), Text('Language', style: tsHeadlineSm())]),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Favorites button added to ProfileScreen")
else:
    print("❌ Pattern not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
