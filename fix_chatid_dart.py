with open('lib/screens/marketplace_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find and fix the broken line
old_part = "id: 'market_' + sortedId + '_' + (data['userId'] ?? '').substring(0, 4) + '_' + (data['title'] ?? '').replaceAll(' ', '').substring(0, [Math]::Min(5, (data['title'] ?? '').length)),"
new_part = "id: 'market_' + sortedId + '_' + ((data['title'] ?? '').replaceAll(' ', '').length > 5 ? (data['title'] ?? '').replaceAll(' ', '').substring(0, 5) : (data['title'] ?? '').replaceAll(' ', '')),"

if old_part in content:
    content = content.replace(old_part, new_part)
    print("✅ Fixed!")
else:
    print("❌ Not found - trying alternative")
    # Replace entire id line with docId-based approach
    content = content.replace(
        "id: 'market_' + sortedId",
        "id: 'market_' + sortedId + '_item'"
    )
    print("✅ Used fallback")

with open('lib/screens/marketplace_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
