with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add a Positioned GestureDetector overlay on top of the image inside the Stack
old = """          DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,"""

new = """          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                final url = _localImageUrl ?? widget.business.imageUrl;
                if (url.isNotEmpty) {
                  showDialog(context: context, builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
                    ),
                  ));
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,"""

if old in content:
    content = content.replace(old, new)
    print("✅ Image tap overlay added")
else:
    print("❌ Pattern not found")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
