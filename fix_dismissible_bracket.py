with open('lib/screens/connect_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """                    ),\n                  ]),\n                ),\n              );\n            },\n          );\n        },\n      ),\n    );\n  }\n}"""
new = """                    ),\n                  ]),\n                ),\n                ),\n              );\n            },\n          );\n        },\n      ),\n    );\n  }\n}"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed bracket")
else:
    print("❌ Not found")
    # Show end of file
    print(repr(content[-300:]))

with open('lib/screens/connect_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
