# Add marketplace banner to home screen
with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'marketplace_screen' not in content:
    content = content.replace(
        "import 'flights_screen.dart';",
        "import 'flights_screen.dart';\nimport 'marketplace_screen.dart';"
    )
    print("✅ Import added")

# Add marketplace banner after flights banner
old = """                // Flights banner
                SliverToBoxAdapter("""

new = """                // Marketplace banner
                SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A3A1A), Color(0xFF2E7D32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        const Text('🛒', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t('marketplace_title'), style: tsTitleMd(color: Colors.white)),
                          Text(t('marketplace_subtitle'), style: tsBodySm(color: Colors.white70)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
                          child: Text(t('marketplace_browse'), style: tsLabel(color: Colors.white)),
                        ),
                      ]),
                    ),
                  ),
                ),

                // Flights banner
                SliverToBoxAdapter("""

if old in content:
    content = content.replace(old, new)
    print("✅ Marketplace banner added")
else:
    print("❌ Pattern not found")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
