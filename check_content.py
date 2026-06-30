with open('lib/screens/admin_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start = content.find("class _BusinessList")
print(repr(content[start:start+700]))
