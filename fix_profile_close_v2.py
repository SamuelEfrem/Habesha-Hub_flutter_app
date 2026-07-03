with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    ),\n  );\n}\n\nclass PrivacyScreen"
new = "    ),\n  )));\n}\n\nclass PrivacyScreen"

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed!")
else:
    print("❌ Not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
