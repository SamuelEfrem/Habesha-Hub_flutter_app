with open('lib/screens/travel_help_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'notification_service' not in content:
    content = content.replace(
        "import '../utils/language_notifier.dart';",
        "import '../utils/language_notifier.dart';\nimport '../services/notification_service.dart';"
    )
    print("✅ Import added")

# Add notification after saving to Firestore
old = """    setState(() { _sending = false; _sent = true; });
  }"""

new = """    // Send push notification to admin
    await NotificationService.sendNotificationToUser(
      userId: 'W3z67R3wiXUVvcPFDS0oxgfaDlj1',
      title: 'New Travel Request! 🌍',
      body: '${_nameCtrl.text.trim()} needs help with: $_selectedService',
      data: {'type': 'travel_request'},
    );

    setState(() { _sending = false; _sent = true; });
  }"""

if old in content:
    content = content.replace(old, new)
    print("✅ Notification added")
else:
    print("❌ Pattern not found")

with open('lib/screens/travel_help_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
