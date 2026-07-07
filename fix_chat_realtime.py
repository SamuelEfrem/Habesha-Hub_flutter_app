with open('lib/screens/guest_chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix - add setState after sending to refresh UI
old = """    // Add message
    await _db.collection('chats').doc(_chatId).collection('messages').add({
      'text': text,
      'userId': _userId,
      'nickname': _nickname,
      'createdAt': FieldValue.serverTimestamp(),
      'isAdmin': false,
    });

    if (_scrollController.hasClients) {"""

new = """    // Add message
    await _db.collection('chats').doc(_chatId).collection('messages').add({
      'text': text,
      'userId': _userId,
      'nickname': _nickname,
      'createdAt': FieldValue.serverTimestamp(),
      'isAdmin': false,
    });
    setState(() {});

    if (_scrollController.hasClients) {"""

if old in content:
    content = content.replace(old, new)
    print("✅ Added setState after send")
else:
    print("❌ Not found")

with open('lib/screens/guest_chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
