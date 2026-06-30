with open('lib/screens/business_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """            Share.share('Check out ${widget.business.name} on Habesha Hub!\\n\\n${widget.business.category} | ${widget.business.address}\\n\\nDownload Habesha Hub: https://habesha-hub.no/download.html');"""

new = """            Share.share('${widget.business.name} - ${widget.business.category}\\n${widget.business.address}\\n\\nCheck out on Habesha Hub!\\nDownload: https://habesha-hub.no/download.html');"""

# Try to find and fix the broken line
import re
content = re.sub(
    r"Share\.share\('[^']*'\);",
    "Share.share('\\${widget.business.name} - \\${widget.business.category}\\n\\${widget.business.address}\\n\\nCheck out on Habesha Hub!\\nDownload: https://habesha-hub.no/download.html');",
    content
)

with open('lib/screens/business_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
