with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find ProfileScreen appBar or where to add refresh
old = """          body: SafeArea(child: SingleChildScrollView(child: Column(children: ["""
new = """          body: SafeArea(child: RefreshIndicator(
            color: kSecondary,
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(children: ["""

if old in content:
    content = content.replace(old, new)
    print("✅ RefreshIndicator added")
    
    # Find and fix the closing - need to add one extra )
    # The original ends with: ])));  (Column) + (SingleChildScrollView) + (SafeArea)
    # New needs:              ]))))  (Column) + (SingleChildScrollView) + (RefreshIndicator) + (SafeArea)
    old2 = "          ]));\n        };\n      },\n    );\n  }\n}\nclass PrivacyScreen"
    new2 = "          ]))));\n        };\n      },\n    );\n  }\n}\nclass PrivacyScreen"
    
    if old2 in content:
        content = content.replace(old2, new2)
        print("✅ Closing brackets fixed")
    else:
        print("❌ Closing pattern not found - showing context:")
        idx = content.find('\nclass PrivacyScreen')
        print(repr(content[idx-200:idx+20]))
else:
    print("❌ Body pattern not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
