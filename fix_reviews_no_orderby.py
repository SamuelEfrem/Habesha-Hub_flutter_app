with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "stream: _db.collection('businesses').doc(widget.business.id).collection('reviews').orderBy('createdAt', descending: true).limit(20).snapshots(),"
new = "stream: _db.collection('businesses').doc(widget.business.id).collection('reviews').limit(20).snapshots(),"

if old in content:
    content = content.replace(old, new)
    print("✅ orderBy removed from reviews")
else:
    print("❌ Pattern not found")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
