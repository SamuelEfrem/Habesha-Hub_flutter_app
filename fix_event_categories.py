with open('lib/screens/events_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix category keys to English
old = """  String _selectedCategory = 'Alle';
  final _categories = [
    {'key': 'Alle', 'emoji': '🌍', 'label': 'all'},
    {'key': 'Bryllup', 'emoji': '💒', 'label': 'cat_wedding'},
    {'key': 'Musikk', 'emoji': '🎵', 'label': 'cat_music'},
    {'key': 'Mat', 'emoji': '🍽️', 'label': 'cat_food'},
    {'key': 'Kultur', 'emoji': '🎭', 'label': 'cat_culture'},
    {'key': 'Business', 'emoji': '💼', 'label': 'cat_business'},
    {'key': 'Sport', 'emoji': '⚽', 'label': 'cat_sport'},
  ];"""

new = """  String _selectedCategory = 'All';
  final _categories = [
    {'key': 'All', 'emoji': '🌍', 'label': 'all'},
    {'key': 'Wedding', 'emoji': '💒', 'label': 'cat_wedding'},
    {'key': 'Music', 'emoji': '🎵', 'label': 'cat_music'},
    {'key': 'Food', 'emoji': '🍽️', 'label': 'cat_food'},
    {'key': 'Culture', 'emoji': '🎭', 'label': 'cat_culture'},
    {'key': 'Business', 'emoji': '💼', 'label': 'cat_business'},
    {'key': 'Sport', 'emoji': '⚽', 'label': 'cat_sport'},
  ];"""

if old in content:
    content = content.replace(old, new)
    print("✅ Event categories fixed")
else:
    print("❌ Pattern not found")

# Fix filter comparison
content = content.replace("_selectedCategory != 'Alle'", "_selectedCategory != 'All'")
content = content.replace("cat == 'Alle'", "cat == 'All'")
content = content.replace("selectedCat = cat['key']!", "selectedCat = cat['key']!")

# Fix default selectedCat in create modal
content = content.replace("String selectedCat = 'Kultur';", "String selectedCat = 'Culture';")

with open('lib/screens/events_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
