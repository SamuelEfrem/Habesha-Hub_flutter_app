with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """    {'key': 'All', 'emoji': '🏠'},
    {'key': 'Restaurant', 'emoji': '🍽️'},
    {'key': 'Shop', 'emoji': '🛒'},
    {'key': 'Cafe', 'emoji': '☕'},
    {'key': 'Club', 'emoji': '🎵'},
    {'key': 'Clinic', 'emoji': '🏥'},
    {'key': 'Barber', 'emoji': '✂'},
  ];"""

new = """    {'key': 'All', 'emoji': '🏠'},
    {'key': 'Restaurant', 'emoji': '🍽️'},
    {'key': 'Shop', 'emoji': '🛒'},
    {'key': 'Cafe', 'emoji': '☕'},
    {'key': 'Club', 'emoji': '🎵'},
    {'key': 'Clinic', 'emoji': '🏥'},
    {'key': 'Barber', 'emoji': '✂'},
    {'key': 'Other', 'emoji': '📦'},
  ];"""

if old in content:
    content = content.replace(old, new)
    print("✅ Added Other category")
else:
    print("❌ Pattern not found")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
