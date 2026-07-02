with open('lib/screens/events_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    ("_selectedCategory = 'Alle';", "_selectedCategory = 'All';"),
    ("{'key': 'Alle', 'emoji': '🌍', 'label': 'all'}", "{'key': 'All', 'emoji': '🌍', 'label': 'all'}"),
    ("{'key': 'Bryllup', 'emoji': '💒', 'label': 'cat_wedding'}", "{'key': 'Wedding', 'emoji': '💒', 'label': 'cat_wedding'}"),
    ("{'key': 'Musikk', 'emoji': '🎵', 'label': 'cat_music'}", "{'key': 'Music', 'emoji': '🎵', 'label': 'cat_music'}"),
    ("{'key': 'Mat', 'emoji': '🍽️', 'label': 'cat_food'}", "{'key': 'Food', 'emoji': '🍽️', 'label': 'cat_food'}"),
    ("{'key': 'Kultur', 'emoji': '🎭', 'label': 'cat_culture'}", "{'key': 'Culture', 'emoji': '🎭', 'label': 'cat_culture'}"),
    ("{'key': 'Business', 'emoji': '💼', 'label': 'cat_business'}", "{'key': 'Business', 'emoji': '💼', 'label': 'cat_business'}"),
    ("{'key': 'Sport', 'emoji': '⚽', 'label': 'cat_sport'}", "{'key': 'Sport', 'emoji': '⚽', 'label': 'cat_sport'}"),
    ("_selectedCategory != 'Alle'", "_selectedCategory != 'All'"),
    ("cat == 'Alle'", "cat == 'All'"),
    ("String selectedCat = 'Kultur';", "String selectedCat = 'Culture';"),
]

for old, new in replacements:
    if old in content:
        content = content.replace(old, new)
        print(f"✅ {old[:40]}")
    else:
        print(f"❌ {old[:40]}")

with open('lib/screens/events_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
