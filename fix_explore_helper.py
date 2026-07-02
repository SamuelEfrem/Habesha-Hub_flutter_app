with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """class _ExploreScreenState extends State<ExploreScreen> {
  final _db = FirebaseFirestore.instance;"""

new = """class _ExploreScreenState extends State<ExploreScreen> {
  final _db = FirebaseFirestore.instance;

  String _explorecat(String key) {
    const keyMap = {
      'All': 'all',
      'Restaurant': 'restaurant',
      'Cafe': 'cafe',
      'Shop': 'shop',
      'Barber': 'barber',
      'Club': 'club',
      'Clinic': 'clinic',
      'Photographer': 'cat_photographer',
      'Music': 'cat_music',
      'Decoration': 'cat_decoration',
      'Taxi': 'cat_taxi',
      'Other': 'other',
    };
    final tKey = keyMap[key];
    if (tKey == null) return key;
    return languageNotifier.t(tKey);
  }"""

if old in content:
    content = content.replace(old, new)
    print("✅ Helper function added")
else:
    print("❌ Pattern not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
