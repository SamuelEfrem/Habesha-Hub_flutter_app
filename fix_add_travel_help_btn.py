with open('lib/screens/flights_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'travel_help_screen' not in content:
    content = content.replace(
        "import 'package:url_launcher/url_launcher.dart';",
        "import 'package:url_launcher/url_launcher.dart';\nimport 'travel_help_screen.dart';"
    )
    print("✅ Import added")

# Add help button after search button
old = """                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kSurfaceContainer,"""

new = """                  const SizedBox(height: 12),

                  // Travel help button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelHelpScreen())),
                      icon: const Icon(Icons.support_agent_rounded, color: kSecondary),
                      label: Text('Need help booking? Contact us', style: tsTitleMd(color: kSecondary)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: kSecondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kSurfaceContainer,"""

if old in content:
    content = content.replace(old, new)
    print("✅ Travel help button added")
else:
    print("❌ Pattern not found")

with open('lib/screens/flights_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
