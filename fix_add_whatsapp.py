WHATSAPP_NUMBER = "4797374482"
WHATSAPP_URL = f"https://wa.me/{WHATSAPP_NUMBER}?text=Hello%20Habesha%20Hub%2C%20I%20need%20help%20with..."

# 1. Add WhatsApp button to FlightsScreen
with open('lib/screens/flights_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """                  const SizedBox(height: 12),

                  // Travel help button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelHelpScreen())),
                      icon: const Icon(Icons.support_agent_rounded, color: kSecondary),
                      label: Text('Need help booking? Contact us', style: tsTitleMd(color: kSecondary)),"""

new = """                  const SizedBox(height: 12),

                  // WhatsApp button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse('https://wa.me/4797374482?text=Hello%20Habesha%20Hub%2C%20I%20need%20help%20with%20a%20flight%20booking...');
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
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelHelpScreen())),
                      icon: const Icon(Icons.support_agent_rounded, color: kSecondary),
                      label: Text('Need help booking? Contact us', style: tsTitleMd(color: kSecondary)),"""

if old in content:
    content = content.replace(old, new)
    print("✅ WhatsApp button added to FlightsScreen")
else:
    print("❌ FlightsScreen pattern not found")

with open('lib/screens/flights_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# 2. Add WhatsApp button to TravelHelpScreen success page
with open('lib/screens/travel_help_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """        Text('support@habesha-hub.no', style: tsTitleMd(color: kSecondary)),
        const SizedBox(height: 32),"""

new = """        Text('support@habesha-hub.no', style: tsTitleMd(color: kSecondary)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            final url = Uri.parse('https://wa.me/4797374482?text=Hello%20Habesha%20Hub%2C%20I%20just%20sent%20a%20travel%20request...');
            if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFF25D366), borderRadius: BorderRadius.circular(12)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('📱', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('Also chat on WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        const SizedBox(height: 32),"""

if old in content:
    content = content.replace(old, new)
    print("✅ WhatsApp button added to TravelHelpScreen")
else:
    print("❌ TravelHelpScreen pattern not found")

# Add url_launcher import if missing
if 'url_launcher' not in content:
    content = content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:url_launcher/url_launcher.dart';"
    )
    print("✅ url_launcher import added")

with open('lib/screens/travel_help_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
