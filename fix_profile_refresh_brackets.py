with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """          body: SafeArea(child: RefreshIndicator(
            color: kSecondary,
            backgroundColor: kSurfaceContainer,
            onRefresh: () async { await _load(); },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(children: ["""

new = """          body: SafeArea(child: RefreshIndicator(
            color: kSecondary,
            backgroundColor: kSurfaceContainer,
            onRefresh: () async { await _load(); },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(children: ["""

# Find where the old SingleChildScrollView ended and add extra closing
# The original was: SafeArea(child: SingleChildScrollView(child: Column(children: [
# New is: SafeArea(child: RefreshIndicator(..., child: SingleChildScrollView(..., child: Column(children: [
# So we need one extra ))) at the end

# Find the closing of the original build method
old2 = "          ])));\n        };\n      },\n    );\n  }\n}"
new2 = "          ]))));\n        };\n      },\n    );\n  }\n}"

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ Added extra closing bracket")
else:
    print("❌ Not found - searching...")
    # Try to find the end of the profile build method
    idx = content.find('class _ProfileScreenState')
    next_class = content.find('\nclass ', idx+100)
    profile_section = content[idx:next_class]
    # Count brackets
    opens = profile_section.count('(')
    closes = profile_section.count(')')
    print(f"Opens: {opens}, Closes: {closes}, Diff: {opens-closes}")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
