with open('lib/screens/marketplace_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """            if (user != null)
                GestureDetector(
                  onTap: () => _showAddListing(context, user, t),"""

new = """            if (user != null) ...[
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MarketInboxScreen(userId: user.uid))),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: kSurfaceContainer, shape: BoxShape.circle, border: Border.all(color: kSecondary.withOpacity(0.3))),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: kSecondary, size: 18),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAddListing(context, user, t),"""

if old in content:
    content = content.replace(old, new)
    # Fix closing bracket
    content = content.replace(
        "                ),\n            ],\n          ),\n        ),\n        body: Column(children: [",
        "                ),\n              ],\n            ],\n          ),\n        ),\n        body: Column(children: ["
    )
    print("✅ Inbox button added")
else:
    print("❌ Not found")
    idx = content.find("_showAddListing(context, user, t)")
    print(repr(content[idx-100:idx+50]))

with open('lib/screens/marketplace_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
