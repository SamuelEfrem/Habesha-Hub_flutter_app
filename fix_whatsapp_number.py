import glob

files = [
    'lib/screens/flights_screen.dart',
    'lib/screens/travel_help_screen.dart',
]

for filename in files:
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('4797374482', '4796988155')
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ Fixed {filename}")

print("Done!")
