with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Check if share_plus is imported
if "share_plus" not in content:
    content = content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:share_plus/share_plus.dart';"
    )
    print("✅ share_plus import added")

# Add share button before AdminButton
old = "                const AdminButton(),"
new = """                GestureDetector(
                  onTap: () => Share.share('Check out Habesha Hub!\\n\\nFind Ethiopian & Eritrean businesses near you.\\n\\nDownload now: https://habesha-hub.no/download.html'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.2), width: 0.5)),
                    child: Row(children: [
                      const Icon(Icons.share_rounded, color: kSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text('Share Habesha Hub', style: tsTitleMd()),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: kSecondary, size: 20),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                const AdminButton(),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Share button added")
else:
    print("❌ Pattern not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
