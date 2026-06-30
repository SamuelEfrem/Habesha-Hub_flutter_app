with open('lib/screens/admin_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start = content.find("class _BusinessListState")
end = content.find("class _AdminCard")
print(repr(content[start:end][-600:]))
