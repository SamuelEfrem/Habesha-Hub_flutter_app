with open('lib/screens/connect_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """                  ] else
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(100)),
                        child: Text(t('login'), style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 12)),
                      ),
                    ),"""

new = "                  ],"

if old in content:
    content = content.replace(old, new)
    print("✅ Login button removed from header")
else:
    print("❌ Not found")
    idx = content.find('] else')
    print(repr(content[idx:idx+300]))

with open('lib/screens/connect_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
