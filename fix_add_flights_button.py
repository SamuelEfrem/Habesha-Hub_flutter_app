with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'flights_screen' not in content:
    content = content.replace(
        "import 'ai_chat_screen.dart';",
        "import 'ai_chat_screen.dart';\nimport 'flights_screen.dart';"
    )
    print("✅ Import added")

# Add flights banner before category chips
old = "                if (_hasSearched) ...["
new = """                // Flights banner
                SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FlightsScreen())),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF004D40), Color(0xFF00897B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        const Text('✈️', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Find Cheap Flights', style: tsTitleMd(color: Colors.white)),
                          Text('Search flights worldwide', style: tsBodySm(color: Colors.white70)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
                          child: Text('Search', style: tsLabel(color: Colors.white)),
                        ),
                      ]),
                    ),
                  ),
                ),
                if (_hasSearched) ...["""

if old in content:
    content = content.replace(old, new)
    print("✅ Flights banner added")
else:
    print("❌ Pattern not found")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
