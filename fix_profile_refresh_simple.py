with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove RefreshIndicator and restore original structure
old = """          body: SafeArea(child: RefreshIndicator(
            color: kSecondary,
            backgroundColor: kSurfaceContainer,
            onRefresh: () async { await _load(); },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(children: ["""

new = """          body: SafeArea(child: SingleChildScrollView(child: Column(children: ["""

if old in content:
    content = content.replace(old, new)
    print("✅ RefreshIndicator removed, back to original")
    # Also fix the extra )) at the end
    content = content.replace("  ));\n}\nclass PrivacyScreen", "  );\n}\nclass PrivacyScreen")
    print("✅ Extra bracket removed")
else:
    print("❌ Pattern not found")
    # Show what's around body:
    idx = content.find('body: SafeArea')
    print(repr(content[idx:idx+300]))

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
