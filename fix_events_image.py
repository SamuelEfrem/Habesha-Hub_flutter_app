with open('lib/screens/events_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports
old_imports = "import 'package:flutter/material.dart';\nimport 'package:cloud_firestore/cloud_firestore.dart';\nimport 'package:firebase_auth/firebase_auth.dart';\nimport 'package:intl/intl.dart';\nimport '../theme/app_theme.dart';\nimport '../utils/language_notifier.dart';"

new_imports = """import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';"""

if old_imports in content:
    content = content.replace(old_imports, new_imports)
    print("✅ Imports added")
else:
    print("❌ Imports not found")

# 2. Add File? pickedImage after imageCtrl
old_ctrl = "    final imageCtrl = TextEditingController();\n    String selectedCat"
new_ctrl = "    final imageCtrl = TextEditingController();\n    File? pickedImage;\n    String selectedCat"

if old_ctrl in content:
    content = content.replace(old_ctrl, new_ctrl)
    print("✅ pickedImage variable added")
else:
    print("❌ imageCtrl not found")

# 3. Replace URL text field with image picker
old_image_field = """              Text(t('event_image_url'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(
                  controller: imageCtrl,
                  style: tsBodyLg(color: kOnSurface),
                  decoration: const InputDecoration(hintText: 'https://...')),"""

new_image_field = """              Text('Event Image', style: tsLabel()),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (ctx2, setImg) => GestureDetector(
                  onTap: () async {
                    final p = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (p != null) { pickedImage = File(p.path); setModalState(() {}); }
                  },
                  child: Container(
                    height: 140, width: double.infinity,
                    decoration: BoxDecoration(color: kSurfaceContainerHigh, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.3))),
                    child: pickedImage != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(pickedImage!, fit: BoxFit.cover, width: double.infinity, height: 140))
                      : const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_photo_alternate_rounded, color: kSecondary, size: 36), SizedBox(height: 8), Text('Tap to add image', style: TextStyle(color: kSecondary))])),
                  ),
                ),
              ),"""

if old_image_field in content:
    content = content.replace(old_image_field, new_image_field)
    print("✅ Image picker added")
else:
    print("❌ Image field not found")

# 4. Replace imageUrl: imageCtrl.text.trim() with upload logic
old_save = """                    await _db.collection('events').add({
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'category': selectedCat,
                      'location': locationCtrl.text.trim(),
                      'date': Timestamp.fromDate(selectedDate),
                      'imageUrl': imageCtrl.text.trim(),
                      'interestedCount': 0,
                      'createdAt': FieldValue.serverTimestamp(),
                    });"""

new_save = """                    String imageUrl = '';
                    if (pickedImage != null) {
                      final ref = FirebaseStorage.instance.ref().child('events/\${DateTime.now().millisecondsSinceEpoch}.jpg');
                      await ref.putFile(pickedImage!);
                      imageUrl = await ref.getDownloadURL();
                    }
                    await _db.collection('events').add({
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'category': selectedCat,
                      'location': locationCtrl.text.trim(),
                      'date': Timestamp.fromDate(selectedDate),
                      'imageUrl': imageUrl,
                      'interestedCount': 0,
                      'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
                      'createdAt': FieldValue.serverTimestamp(),
                    });"""

if old_save in content:
    content = content.replace(old_save, new_save)
    print("✅ Upload logic added")
else:
    print("❌ Save block not found")

with open('lib/screens/events_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("\nDone!")
