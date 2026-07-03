with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove _incrementViewCount() calls from wrong classes
# Find all occurrences and only keep the one in _BusinessDetailScreenState
lines = content.split('\n')
new_lines = []
skip_next = False

for i, line in enumerate(lines):
    if '_incrementViewCount();' in line:
        # Check context - find which class this belongs to
        # Look back to find the nearest class definition
        context = '\n'.join(lines[max(0,i-100):i])
        if '_VideoPlayerWidgetState' in context.split('class ')[-1] or '_FullscreenVideoPageState' in context.split('class ')[-1]:
            print(f"❌ Removed from wrong class at line {i+1}")
            continue
    new_lines.append(line)

content = '\n'.join(new_lines)
with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("✅ Fixed!")
print("Done!")
