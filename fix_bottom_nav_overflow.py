with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Reduce padding in bottom nav items
old = """                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),"""
new = """                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Reduced nav padding")
else:
    print("❌ Padding not found")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
