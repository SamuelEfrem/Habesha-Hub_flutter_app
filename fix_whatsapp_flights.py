with open('lib/screens/flights_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "                  // Travel help button\n                  SizedBox(\n                    width: double.infinity,\n                    child: OutlinedButton.icon(\n                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelHelpScreen())),"

new = """                  // WhatsApp button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse('https://wa.me/4796988155?text=Hello%20Habesha%20Hub%2C%20I%20need%20help%20with%20a%20flight%20booking...');
                        if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                      icon: const Text('📱', style: TextStyle(fontSize: 18)),
                      label: Text('Chat on WhatsApp', style: tsTitleMd(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Travel help button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelHelpScreen())),"""

if old in content:
    content = content.replace(old, new)
    print("✅ WhatsApp button added to FlightsScreen")
else:
    print("❌ Still not found")
    idx = content.find('Travel help button')
    print(repr(content[idx-10:idx+150]))

with open('lib/screens/flights_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
