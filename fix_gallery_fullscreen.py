with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "              Image.network(_localGalleryImages[i], fit: BoxFit.cover, width: 120, height: 120),"

new = """              GestureDetector(
                onTap: () => showDialog(context: context, builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: InteractiveViewer(child: Image.network(_localGalleryImages[i], fit: BoxFit.contain)),
                  ),
                )),
                child: Image.network(_localGalleryImages[i], fit: BoxFit.cover, width: 120, height: 120),
              ),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fullscreen gallery added")
else:
    print("❌ Pattern not found")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
