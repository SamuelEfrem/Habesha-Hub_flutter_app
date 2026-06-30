with open('lib/screens/events_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "final ref = FirebaseStorage.instance.ref().child('events/\\${DateTime.now().millisecondsSinceEpoch}.jpg');"
new = "final ref = FirebaseStorage.instance.ref().child('events/' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg');"

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed image URL generation")
else:
    print("❌ Pattern not found, trying alternative")
    import re
    pattern = r"FirebaseStorage\.instance\.ref\(\)\.child\('events/\\?\$\{DateTime\.now\(\)\.millisecondsSinceEpoch\}\.jpg'\);"
    replacement = "FirebaseStorage.instance.ref().child('events/' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg');"
    new_content = re.sub(pattern, replacement, content)
    if new_content != content:
        content = new_content
        print("✅ Fixed with regex")
    else:
        print("❌ Still not found")

with open('lib/screens/events_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
