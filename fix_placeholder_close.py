with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Check if file ends properly
print("Last 100 chars:", repr(content[-100:]))

# Add missing closing brackets if needed
if not content.strip().endswith('}'):
    content = content.rstrip() + '\n}\n'
    print("✅ Added closing bracket")
elif content.count('{') > content.count('}'):
    diff = content.count('{') - content.count('}')
    content = content.rstrip() + '\n' + '}\n' * diff
    print(f"✅ Added {diff} closing brackets")
else:
    print("Brackets seem balanced")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
