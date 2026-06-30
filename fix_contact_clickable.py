with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "Row(children: [const Icon(Icons.email_outlined, color: kSecondary, size: 15), const SizedBox(width: 8), Text('support@habesha-hub.no', style: tsBodySm())]),"
new = """GestureDetector(
                  onTap: () async {
                    final url = Uri.parse('mailto:support@habesha-hub.no');
                    if (await canLaunchUrl(url)) await launchUrl(url);
                  },
                  child: Row(children: [const Icon(Icons.email_outlined, color: kSecondary, size: 15), const SizedBox(width: 8), Text('support@habesha-hub.no', style: tsBodySm(color: kSecondary))]),
                ),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Made clickable")
else:
    print("❌ Pattern not found")

# Check if url_launcher is imported
if "url_launcher" not in content:
    content = content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:url_launcher/url_launcher.dart';"
    )
    print("✅ url_launcher import added")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
