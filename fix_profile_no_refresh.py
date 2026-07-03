with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove RefreshIndicator completely
old = """          body: SafeArea(child: RefreshIndicator(
            color: kSecondary,
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(children: ["""
new = """          body: SafeArea(child: SingleChildScrollView(child: Column(children: ["""

if old in content:
    content = content.replace(old, new)
    print("✅ RefreshIndicator removed")
else:
    print("❌ Not found")

# Fix any extra brackets near PrivacyScreen
import re
content = re.sub(r'\)+;\n\}\n\nclass PrivacyScreen', ');\n}\n\nclass PrivacyScreen', content)
print("✅ Brackets normalized")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
