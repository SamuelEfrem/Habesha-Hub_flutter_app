# 1. home_screen.dart - add Hotel to category chips
with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """    {'key': 'Other', 'emoji': '📦'},
  ];"""
new = """    {'key': 'Hotel', 'emoji': '🏨'},
    {'key': 'Other', 'emoji': '📦'},
  ];"""
content = content.replace(old, new)

# Add Hotel to keyMap
old2 = "      'Other': 'other',"
new2 = "      'Hotel': 'cat_hotel',\n      'Other': 'other',"
content = content.replace(old2, new2)
print("✅ home_screen.dart done")
with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# 2. register_business_screen.dart - add Hotel to _cats
with open('lib/screens/register_business_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    {'name': 'Other', 'icon': Icons.storefront_rounded},"
new = "    {'name': 'Hotel', 'icon': Icons.hotel_rounded},\n    {'name': 'Other', 'icon': Icons.storefront_rounded},"
content = content.replace(old, new)

# Add Hotel to _catDisplayName keyMap
old2 = "      'Other': 'other',"
new2 = "      'Hotel': 'cat_hotel',\n      'Other': 'other',"
content = content.replace(old2, new2)
print("✅ register_business_screen.dart done")
with open('lib/screens/register_business_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

# 3. placeholder_screens.dart - add Hotel to Explore categories
with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "'All', 'Restaurant', 'Cafe', 'Shop', 'Barber', 'Club', 'Clinic', 'Photographer', 'Music', 'Decoration', 'Taxi', 'Other'"
new = "'All', 'Restaurant', 'Cafe', 'Shop', 'Barber', 'Club', 'Clinic', 'Hotel', 'Photographer', 'Music', 'Decoration', 'Taxi', 'Other'"
content = content.replace(old, new)

# Add Hotel to _explorecat keyMap
old2 = "      'Other': 'other',"
new2 = "      'Hotel': 'cat_hotel',\n      'Other': 'other',"
content = content.replace(old2, new2)
print("✅ placeholder_screens.dart done")
with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("\nAll done!")
