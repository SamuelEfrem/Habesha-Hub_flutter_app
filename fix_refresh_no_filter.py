with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "                  _filterResults();\n                }\n              },",
    "                }\n              },"
)
print("✅ Removed _filterResults call")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
