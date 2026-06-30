with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the closing of the Stack in FlexibleSpaceBar and add overlay at the end
# Look for the pattern after all the Positioned widgets
old = """          Positioned(
              bottom: 16,
              left: 16,
              right: 110,"""

new = """          // Fullscreen tap overlay - must be last in Stack
          Positioned(
            top: 0, left: 0, right: 0,
            height: 180,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
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
          Positioned(
              bottom: 16,
              left: 16,
              right: 110,"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed!")
else:
    print("❌ Pattern not found")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
