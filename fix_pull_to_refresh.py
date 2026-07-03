with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the results list builder
old = """              _buildResultsSliver(t),"""
new = """              _buildResultsSliver(t),"""

# Add RefreshIndicator around the CustomScrollView
old2 = """          child: CustomScrollView(
            slivers: ["""
new2 = """          child: RefreshIndicator(
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

if old2 in content:
    content = content.replace(old2, new2)
    # Fix closing bracket
    content = content.replace(
        "          ),\n        ]),\n      ),\n    ]);",
        "          ),\n          ),\n        ]),\n      ),\n    ]);"
    )
    print("✅ Pull-to-refresh added")
else:
    print("❌ Pattern not found")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
