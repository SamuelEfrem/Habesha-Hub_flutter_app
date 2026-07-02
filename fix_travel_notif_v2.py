with open('lib/screens/travel_help_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "    // Notification will be added later"
new = """    // Send notification if user is logged in
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        await NotificationService.sendNotificationToUser(
          userId: 'W3z67R3wiXUVvcPFDS0oxgfaDlj1',
          title: 'New Travel Request! 🌍',
          body: _nameCtrl.text.trim() + ' needs help with: ' + _selectedService,
          data: {'type': 'travel_request'},
        );
      } catch (e) {
        print('Notification error: ' + e.toString());
      }
    }"""

if old in content:
    content = content.replace(old, new)
    print("✅ Notification added back conditionally")
else:
    print("❌ Pattern not found")

# Add import if missing
if 'notification_service' not in content:
    content = content.replace(
        "import '../utils/language_notifier.dart';",
        "import '../utils/language_notifier.dart';\nimport '../services/notification_service.dart';"
    )
    print("✅ Import added")

with open('lib/screens/travel_help_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
