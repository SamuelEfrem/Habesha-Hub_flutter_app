with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """          Image.network(
              '${_localImageUrl ?? widget.business.imageUrl}?v=${DateTime.now().millisecondsSinceEpoch}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  color: kSurfaceContainerHigh,
                  child: const Icon(Icons.storefront_rounded,
                      size: 80, color: kSecondary))),"""

new = """          GestureDetector(
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
            child: Image.network(
              '${_localImageUrl ?? widget.business.imageUrl}?v=${DateTime.now().millisecondsSinceEpoch}',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  color: kSurfaceContainerHigh,
                  child: const Icon(Icons.storefront_rounded,
                      size: 80, color: kSecondary))),
          ),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Profile image fullscreen added")
else:
    print("❌ Pattern not found")

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
