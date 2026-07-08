with open('lib/screens/guest_chat_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix escaped dollar signs
old = """    final chatId = widget.business.id.startsWith('connect_')
        ? widget.business.id
        : '\\${widget.business.id}_\\$uid';"""

new = """    final chatId = (widget.business.id.startsWith('connect_') || widget.business.id.startsWith('market_'))
        ? widget.business.id
        : widget.business.id + '_' + uid;"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed escaped strings")
else:
    print("❌ Not found - trying alternative")
    # Find and fix directly
    content = content.replace(
        "'\${widget.business.id}_\$uid'",
        "widget.business.id + '_' + uid"
    )
    content = content.replace(
        "'\\${widget.business.id}_\\$uid'",
        "widget.business.id + '_' + uid"
    )
    print("✅ Fixed alternative")

with open('lib/screens/guest_chat_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
