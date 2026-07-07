with open('lib/screens/guest_chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar("""

new = """    return Scaffold(
      backgroundColor: kSurface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar("""

if old in content:
    content = content.replace(old, new)
    print("✅ Added resizeToAvoidBottomInset")
else:
    print("❌ Not found")

# Also fix the bottom padding
old2 = """          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 12),"""
new2 = """          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),"""

if old2 in content:
    content = content.replace(old2, new2)
    print("✅ Fixed bottom padding")
else:
    print("❌ Padding not found")

with open('lib/screens/guest_chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
