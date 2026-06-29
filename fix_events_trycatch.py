with open('lib/screens/events_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """                  onPressed: () async {
                    if (titleCtrl.text.isEmpty || locationCtrl.text.isEmpty) {
                      return;
                    }
                    String imageUrl = '';
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
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },"""

new = """                  onPressed: () async {
                    if (titleCtrl.text.isEmpty || locationCtrl.text.isEmpty) {
                      return;
                    }
                    try {
                      String imageUrl = '';
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
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      print('Event error: ' + e.toString());
                    }
                  },"""

if old in content:
    content = content.replace(old, new)
    print("Done!")
else:
    print("Pattern not found!")

with open('lib/screens/events_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
