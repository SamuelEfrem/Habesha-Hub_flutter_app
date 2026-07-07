with open('lib/screens/connect_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "                    ),\n                ],\n        ),\n\n              // Interest filter"
new = "                    ),\n                  ],\n                ]),\n              ),\n\n              // Interest filter"

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed")
else:
    print("❌ Not found")
    idx = content.find('// Interest filter')
    print(repr(content[idx-200:idx+20]))

with open('lib/screens/connect_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
