with open('lib/screens/register_business_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """        Text('Bilde', style: tsHeadlineSm()),
        const SizedBox(height: 6),
        Text('Legg til en bilde-URL for bedriften din.', style: tsBodySm()),
        const SizedBox(height: 24),
        Text('BILDE URL', style: tsLabel()),
        const SizedBox(height: 8),
        TextFormField(
          controller: _imgCtrl,
          keyboardType: TextInputType.url,
          style: tsBodyLg(color: kOnSurface),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'https://...',
            prefixIcon: Icon(Icons.image_outlined, color: kSecondary),
          ),
        ),
        if (_imgCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _imgCtrl.text,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: kSurfaceContainer,
                  child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: kOnSurfaceVariant, size: 40))),
            ),
          ),
        ],
        const SizedBox(height: 20),
        const SizedBox(height: 16),"""

new = """        Text('Siste steg', style: tsHeadlineSm()),
        const SizedBox(height: 6),
        Text('Du kan legge til bilder etter at bedriften er godkjent.', style: tsBodySm()),
        const SizedBox(height: 20),"""

if old in content:
    content = content.replace(old, new)
    print("✅ Image URL field removed")
else:
    print("❌ Pattern not found")

# Also remove from Firestore save
old_save = "        'imageUrl': _imgCtrl.text.trim(),\n"
new_save = "        'imageUrl': '',\n"
if old_save in content:
    content = content.replace(old_save, new_save)
    print("✅ Firestore save updated")
else:
    print("❌ Save pattern not found")

with open('lib/screens/register_business_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
