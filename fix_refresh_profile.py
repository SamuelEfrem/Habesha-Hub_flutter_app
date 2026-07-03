# Remove refresh from home_screen
with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """          Expanded(
            child: RefreshIndicator(
              color: kSecondary,
              backgroundColor: kSurfaceContainer,
              onRefresh: () async {
                if (_position != null) {
                  setState(() => _isSearching = true);
                  final snapshot = await _service.getBusinessesOnce();
                  snapshot.sort((a, b) => a.distanceTo(_position!.latitude, _position!.longitude).compareTo(b.distanceTo(_position!.latitude, _position!.longitude)));
                  setState(() {
                    _businesses = snapshot.where((b) => b.distanceTo(_position!.latitude, _position!.longitude) <= 50).toList();
                    _isSearching = false;
                  });
                }
              },
              child: CustomScrollView(
              slivers: ["""

new = """          Expanded(
            child: CustomScrollView(
              slivers: ["""

if old in content:
    content = content.replace(old, new)
    # Fix extra closing bracket
    content = content.replace(
        "              ],\n            ),\n            ),\n          ),\n        ]),",
        "              ],\n            ),\n          ),\n        ]),"
    )
    print("✅ Removed refresh from HomeScreen")
else:
    print("❌ Not found in home_screen")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# Add refresh to ProfileScreen
with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content2 = f.read()

old2 = """          body: SafeArea(child: SingleChildScrollView(child: Column(children: ["""
new2 = """          body: SafeArea(child: RefreshIndicator(
            color: kSecondary,
            backgroundColor: kSurfaceContainer,
            onRefresh: () async { await _load(); },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(children: ["""

if old2 in content2:
    content2 = content2.replace(old2, new2)
    # Fix closing
    content2 = content2.replace(
        "          ])));\n        };\n      },\n    );\n  }\n}\nclass ExploreScreen",
        "          ])))),\n        };\n      },\n    );\n  }\n}\nclass ExploreScreen"
    )
    print("✅ Refresh added to ProfileScreen")
else:
    print("❌ ProfileScreen pattern not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content2)
print("Done!")
