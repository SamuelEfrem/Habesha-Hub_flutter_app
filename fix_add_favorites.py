with open('lib/widgets/business_card.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add flutter import
if "import 'package:flutter/material.dart';" not in content:
    content = "import 'package:flutter/material.dart';\n" + content
    print("✅ Flutter import added")

# Check if StatefulWidget exists
if 'StatefulWidget' not in content:
    print("❌ BusinessCard is not StatefulWidget - need to check file structure")
else:
    print("✅ StatefulWidget found")

# Add _isFavorite state and methods after class declaration
old = """class BusinessCard extends StatefulWidget {
  final Business business;
  final double userLat;
  final double userLng;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteChanged;
  const BusinessCard({"""

new = """class BusinessCard extends StatefulWidget {
  final Business business;
  final double userLat;
  final double userLng;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteChanged;
  const BusinessCard({"""

# Find State class and add favorite logic
old2 = """class _BusinessCardState extends State<BusinessCard> {"""
new2 = """class _BusinessCardState extends State<BusinessCard> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFav();
  }

  Future<void> _checkFav() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorites') ?? [];
    if (mounted) setState(() => _isFavorite = favs.contains(widget.business.id));
  }

  Future<void> _toggleFav() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorites') ?? [];
    if (_isFavorite) {
      favs.remove(widget.business.id);
    } else {
      favs.add(widget.business.id);
    }
    await prefs.setStringList('favorites', favs);
    setState(() => _isFavorite = !_isFavorite);
    widget.onFavoriteChanged?.call();
  }"""

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ Favorite state added")
else:
    print("❌ State class not found")
    print("Searching for state class...")
    idx = content.find('extends State<BusinessCard>')
    print(repr(content[idx-30:idx+100]))

with open('lib/widgets/business_card.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
