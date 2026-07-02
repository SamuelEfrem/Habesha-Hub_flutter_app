with open('lib/screens/travel_help_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """    // Send push notification to admin
    await NotificationService.sendNotificationToUser(
      userId: 'W3z67R3wiXUVvcPFDS0oxgfaDlj1',
      title: 'New Travel Request! 🌍',
      body: '${_nameCtrl.text.trim()} needs help with: $_selectedService',
      data: {'type': 'travel_request'},
    );"""

new = """    // Send push notification to admin
    try {
      await NotificationService.sendNotificationToUser(
        userId: 'W3z67R3wiXUVvcPFDS0oxgfaDlj1',
        title: 'New Travel Request! 🌍',
        body: '${_nameCtrl.text.trim()} needs help with: $_selectedService',
        data: {'type': 'travel_request'},
      );
    } catch (e) {
      print('Notification error: ' + e.toString());
    }"""

if old in content:
    content = content.replace(old, new)
    print("✅ Notification wrapped in try/catch")
else:
    print("❌ Pattern not found")

with open('lib/screens/travel_help_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
