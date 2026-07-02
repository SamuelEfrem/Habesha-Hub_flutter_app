with open('lib/widgets/business_card.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "child: openBadge(widget.business.isOpen),"
new = "child: openBadge(widget.business.isOpenNow),"

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed isOpen → isOpenNow in business card")
else:
    print("❌ Pattern not found")

with open('lib/widgets/business_card.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
