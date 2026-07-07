with open('lib/screens/connect_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import for business_inbox_screen
if 'business_inbox_screen' not in content:
    content = content.replace(
        "import 'guest_chat_screen.dart';",
        "import 'guest_chat_screen.dart';\nimport 'business_inbox_screen.dart';"
    )
    print("✅ Import added")

# Add inbox button to header
old = """                  if (user != null)
                    GestureDetector(
                      onTap: () => _showCreateProfile(context, user, t),"""

new = """                  if (user != null) ...[
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConnectInboxScreen(userId: user.uid))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(100), border: Border.all(color: kSecondary.withOpacity(0.3))),
                        child: const Icon(Icons.chat_bubble_outline_rounded, color: kSecondary, size: 18),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showCreateProfile(context, user, t),"""

if old in content:
    content = content.replace(old, new)
    # Fix closing bracket
    content = content.replace(
        "        ]),\n              ),\n\n              // Interest filter",
        "        ],\n              ),\n\n              // Interest filter"
    )
    print("✅ Inbox button added")
else:
    print("❌ Pattern not found")

with open('lib/screens/connect_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
