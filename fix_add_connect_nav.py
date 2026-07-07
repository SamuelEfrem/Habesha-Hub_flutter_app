with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'connect_screen' not in content:
    content = content.replace(
        "import 'flights_screen.dart';",
        "import 'flights_screen.dart';\nimport 'connect_screen.dart';"
    )
    print("✅ Import added")

# Add to IndexedStack
old = """            children: [
              _buildHomeTab(t),
              const ExploreScreen(),
              const EventsScreen(),
              const ForumScreen(),
              const ProfileScreen(),
            ],"""
new = """            children: [
              _buildHomeTab(t),
              const ExploreScreen(),
              const EventsScreen(),
              const ForumScreen(),
              const ConnectScreen(),
              const ProfileScreen(),
            ],"""

if old in content:
    content = content.replace(old, new)
    print("✅ ConnectScreen added to IndexedStack")

# Add to bottom nav items
old2 = """      {'icon': Icons.person_rounded, 'key': 'profile'},
    ];"""
new2 = """      {'icon': Icons.people_rounded, 'key': 'connect'},
      {'icon': Icons.person_rounded, 'key': 'profile'},
    ];"""

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ Connect nav item added")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
