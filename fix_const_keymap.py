files = [
    'lib/screens/home_screen.dart',
    'lib/screens/placeholder_screens.dart',
    'lib/screens/register_business_screen.dart',
]

for filename in files:
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    # Remove const from keyMap
    content = content.replace('    const keyMap = {', '    final keyMap = {')
    # Remove duplicate Hotel
    content = content.replace(
        "    {'key': 'Hotel', 'emoji': '🏨'},\n    {'key': 'Hotel', 'emoji': '🏨'},",
        "    {'key': 'Hotel', 'emoji': '🏨'},"
    )
    # Fix Icons.hotel in const list to use string emoji instead
    content = content.replace("{'name': 'Hotel', 'icon': Icons.hotel},", "{'name': 'Hotel', 'icon': Icons.bed_rounded},")
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ Fixed {filename}")

print("Done!")
