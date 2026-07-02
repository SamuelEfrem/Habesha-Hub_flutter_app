with open('lib/screens/events_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find and show context around these
for search in ["!= 'Alle'", "== 'Alle'", "selectedCat = 'Kultur'"]:
    idx = content.find(search)
    if idx >= 0:
        print(f"Found '{search}' at {idx}:")
        print(repr(content[idx-20:idx+50]))
    else:
        print(f"NOT FOUND: '{search}'")

print("\n---fixing---")
content = content.replace("!= 'Alle'", "!= 'All'")
content = content.replace("== 'Alle'", "== 'All'")
content = content.replace("selectedCat = 'Kultur'", "selectedCat = 'Culture'")

with open('lib/screens/events_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
