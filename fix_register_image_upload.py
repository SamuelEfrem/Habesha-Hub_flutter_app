with open('lib/screens/register_business_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports
if 'image_picker' not in content:
    content = content.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:image_picker/image_picker.dart';\nimport 'package:firebase_storage/firebase_storage.dart';\nimport 'dart:io';"
    )
    print("✅ Imports added")

# Add image file variable
old = """  String _country = '';
  bool _saving = false;"""
new = """  String _country = '';
  File? _selectedImage;
  String _uploadedImageUrl = '';
  bool _uploadingImage = false;
  bool _saving = false;"""

if old in content:
    content = content.replace(old, new)
    print("✅ Image variables added")

# Add image upload method before _submit
old2 = """  Future<void> _submit() async {"""
new2 = """  Future<void> _pickAndUploadImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;
    setState(() { _selectedImage = File(picked.path); _uploadingImage = true; });
    try {
      final ref = FirebaseStorage.instance.ref().child('businesses/' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg');
      await ref.putFile(_selectedImage!);
      _uploadedImageUrl = await ref.getDownloadURL();
      setState(() => _uploadingImage = false);
    } catch (e) {
      setState(() => _uploadingImage = false);
      print('Upload error: ' + e.toString());
    }
  }

  Future<void> _submit() async {"""

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ Upload method added")

# Update imageUrl in submit
content = content.replace(
    "'imageUrl': '',",
    "'imageUrl': _uploadedImageUrl,"
)
print("✅ imageUrl updated")

# Replace Step 3 image section
old3 = """        Text('BILDE URL', style: tsLabel()),
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
        ],"""

new3 = """        Text('BILDE', style: tsLabel()),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _uploadingImage ? null : _pickAndUploadImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: kSurfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kSecondary.withOpacity(0.3)),
            ),
            child: _uploadingImage
                ? const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 2))
                : _selectedImage != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, height: 180, width: double.infinity, fit: BoxFit.cover))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.add_photo_alternate_rounded, color: kSecondary, size: 40),
                        const SizedBox(height: 8),
                        Text('Trykk for å laste opp bilde', style: tsBodySm(color: kSecondary)),
                      ]),
          ),
        ),"""

if old3 in content:
    content = content.replace(old3, new3)
    print("✅ Image upload UI replaced")
else:
    print("❌ Image URL section not found")

with open('lib/screens/register_business_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
