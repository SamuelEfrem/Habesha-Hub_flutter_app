with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """                if (!isLoggedIn) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(14), border: Border.all(color: kSecondary.withOpacity(0.2), width: 0.5)),
                    child: Column(children: [
                      Row(children: [const Icon(Icons.login_rounded, color: kSecondary, size: 20), const SizedBox(width: 10), Text(t('login_register'), style: tsTitleMd(color: kSecondary))]),
                      const SizedBox(height: 8),
                      Text(t('login_for_business'), style: tsBodySm()),
                      const SizedBox(height: 14),
                      goldButton(t('login'), _login, icon: Icons.login_rounded),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ],"""

new = ""

if old in content:
    content = content.replace(old, new)
    print("✅ Login box removed from profile")
else:
    print("❌ Not found - trying simpler pattern")
    # Find just the isLoggedIn block
    idx = content.find("if (!isLoggedIn) ...[")
    end = content.find("],\n                Text(t('nickname')", idx)
    if idx >= 0 and end >= 0:
        content = content[:idx] + content[end+2:]
        print("✅ Removed with alternative method")
    else:
        print("❌ Still not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
