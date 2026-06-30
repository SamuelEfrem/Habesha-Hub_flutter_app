with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = "                '${widget.business.name} - ${widget.business.category}\\n${widget.business.address}\\n\\nFinn på Habesha Hub!');"

new = "                '${widget.business.name} - ${widget.business.category}\\n${widget.business.address}\\n\\nFind on Habesha Hub! Download: https://habesha-hub.no/download.html');"

if old in content:
    content = content.replace(old, new)
    print("Done!")
else:
    print("Pattern not found, trying alternative...")
    # Find the Share.share line
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if 'Share.share(' in line and 'Habesha Hub' in line:
            print(f"Found on line {i+1}: {line}")
            lines[i] = "                Share.share('${widget.business.name} - ${widget.business.category}\\n${widget.business.address}\\n\\nFind on Habesha Hub!\\nDownload: https://habesha-hub.no/download.html');"
            print("Fixed!")
            break
    content = '\n'.join(lines)

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
