# Fix ConnectInboxScreen - add Dismissible
with open('lib/screens/connect_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """              return GestureDetector(
                onTap: () {
                  final fakeBusiness = Business(
                    id: businessId,"""

new = """              return Dismissible(
                key: ValueKey(docs[i].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: kRed.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                ),
                onDismissed: (_) => db.collection('chats').doc(docs[i].id).delete(),
                child: GestureDetector(
                onTap: () {
                  final fakeBusiness = Business(
                    id: businessId,"""

if old in content:
    content = content.replace(old, new)
    print("✅ Dismissible added to ConnectInbox")
    # Fix closing bracket
    content = content.replace(
        "                    const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 14),\n                  ]),\n                ),\n              );\n            },\n          );\n        },\n      ),\n    );\n  }\n}",
        "                    const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 14),\n                  ]),\n                ),\n                ),\n              );\n            },\n          );\n        },\n      ),\n    );\n  }\n}"
    )
else:
    print("❌ ConnectInbox pattern not found")

with open('lib/screens/connect_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# Fix MarketInboxScreen - add Dismissible
with open('lib/screens/marketplace_screen.dart', 'r', encoding='utf-8') as f:
    content2 = f.read()

old2 = """          return GestureDetector(
                onTap: () {
                  final fakeBusiness = Business(
                    id: businessId, name: businessName, category: 'Other',"""

new2 = """          return Dismissible(
                key: ValueKey(docs[i].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: kRed.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                ),
                onDismissed: (_) => db.collection('chats').doc(docs[i].id).delete(),
                child: GestureDetector(
                onTap: () {
                  final fakeBusiness = Business(
                    id: businessId, name: businessName, category: 'Other',"""

if old2 in content2:
    content2 = content2.replace(old2, new2)
    print("✅ Dismissible added to MarketInbox")
    # Fix closing
    content2 = content2.replace(
        "                    const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 14),\n                  ]),\n                ),\n              );\n            },\n          );\n        },\n      ),\n    );\n  }\n}",
        "                    const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 14),\n                  ]),\n                ),\n                ),\n              );\n            },\n          );\n        },\n      ),\n    );\n  }\n}"
    )
else:
    print("❌ MarketInbox pattern not found")

with open('lib/screens/marketplace_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content2)

print("Done!")
