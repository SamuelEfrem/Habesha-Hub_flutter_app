with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """  Future<void> _submitRating(double stars) async {
    if (_ratingSubmitted) return;
    final prefs = await SharedPreferences.getInstance();"""

new = """  Future<void> _submitRating(double stars) async {
    if (_ratingSubmitted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Du må logge inn for å rate', style: tsBodySm(color: kOnSurface)),
        backgroundColor: kRed,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final prefs = await SharedPreferences.getInstance();"""

if old in content:
    content = content.replace(old, new)
    print("✅ Login required for rating")
else:
    print("❌ Pattern not found")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
