with open('lib/screens/favorites_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: business))),"
new = "onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: business, userLat: 0, userLng: 0))),"

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed")
else:
    print("❌ Not found")

with open('lib/screens/favorites_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
