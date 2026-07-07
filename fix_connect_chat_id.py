with open('lib/screens/connect_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix _openChat to use sorted UIDs for consistent chatId
old = """    final fakeBusiness = Business(
      id: 'connect_' + (data['userId'] ?? ''),"""

new = """    // Sort UIDs to always get same chatId regardless of who initiates
    final uid1 = user.uid;
    final uid2 = data['userId'] ?? '';
    final sortedId = uid1.compareTo(uid2) < 0 ? uid1 + '_' + uid2 : uid2 + '_' + uid1;
    final fakeBusiness = Business(
      id: 'connect_' + sortedId,"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed chat ID to use sorted UIDs")
else:
    print("❌ Pattern not found")

with open('lib/screens/connect_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
