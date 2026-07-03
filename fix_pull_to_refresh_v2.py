with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """          Expanded(
            child: CustomScrollView(
              slivers: ["""

new = """          Expanded(
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
                  _filterResults();
                }
              },
              child: CustomScrollView(
              slivers: ["""

if old in content:
    content = content.replace(old, new)
    # Close the RefreshIndicator
    content = content.replace(
        "              ],\n            ),\n          ),\n        ]),",
        "              ],\n            ),\n            ),\n          ),\n        ]),"
    )
    print("✅ Pull-to-refresh added")
else:
    print("❌ Pattern not found")
    idx = content.find('CustomScrollView')
    print(repr(content[idx-60:idx+60]))

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
