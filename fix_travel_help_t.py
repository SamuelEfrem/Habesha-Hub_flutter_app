with open('lib/screens/travel_help_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """  Widget _buildSuccess() {
    return Center(child: Padding("""

new = """  Widget _buildSuccess() {
    final t = languageNotifier.t;
    return Center(child: Padding("""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed")
else:
    print("❌ Not found")

with open('lib/screens/travel_help_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
