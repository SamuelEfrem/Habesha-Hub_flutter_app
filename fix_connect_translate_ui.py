with open('lib/screens/connect_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix interests list to use translation keys
old = """  final _interests = [
    {'key': 'All', 'emoji': '🌍', 'label': 'all'},
    {'key': 'IT', 'emoji': '💻', 'label': 'IT'},
    {'key': 'Business', 'emoji': '💼', 'label': 'cat_business'},
    {'key': 'Restaurant', 'emoji': '🍽️', 'label': 'restaurant'},
    {'key': 'Music', 'emoji': '🎵', 'label': 'cat_music'},
    {'key': 'Health', 'emoji': '🏥', 'label': 'clinic'},
    {'key': 'Education', 'emoji': '📚', 'label': 'connect_education'},
    {'key': 'Other', 'emoji': '✨', 'label': 'other'},
  ];"""

new = """  final _interests = [
    {'key': 'All', 'emoji': '🌍', 'label': 'all'},
    {'key': 'IT', 'emoji': '💻', 'label': 'connect_it'},
    {'key': 'Business', 'emoji': '💼', 'label': 'cat_business'},
    {'key': 'Restaurant', 'emoji': '🍽️', 'label': 'restaurant'},
    {'key': 'Music', 'emoji': '🎵', 'label': 'cat_music'},
    {'key': 'Health', 'emoji': '🏥', 'label': 'connect_health'},
    {'key': 'Education', 'emoji': '📚', 'label': 'connect_education'},
    {'key': 'Other', 'emoji': '✨', 'label': 'other'},
  ];"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed interest labels")
else:
    print("❌ Not found")

# Fix IT label in filter (remove special case)
content = content.replace(
    "final label = item['key'] == 'IT' ? 'IT' : t(item['label']!);",
    "final label = t(item['label']!);"
)
print("✅ Fixed IT special case")

# Fix ConnectInboxScreen title
content = content.replace(
    "title: Text('Connect Messages', style: tsTitleMd(color: kSecondary)),",
    "title: Text(languageNotifier.t('connect_messages'), style: tsTitleMd(color: kSecondary)),"
)
content = content.replace(
    "Text('No messages yet', style: tsTitleLg()),",
    "Text(languageNotifier.t('connect_no_messages'), style: tsTitleLg()),"
)
print("✅ Fixed inbox translations")

# Fix You badge translation
content = content.replace(
    "child: Text('You', style: tsLabel()),",
    "child: Text(t('connect_you'), style: tsLabel()),"
)
print("✅ Fixed You badge")

with open('lib/screens/connect_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
