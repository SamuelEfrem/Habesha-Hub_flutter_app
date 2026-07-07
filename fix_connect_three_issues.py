with open('lib/screens/connect_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: Remove "Logg inn" button from cards - show nothing if not logged in
old = """          if (!isMe) ...[
            GestureDetector(
              onTap: onMessage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isLoggedIn ? kSecondary : kSurfaceContainerHigh,
                  borderRadius: BorderRadius.circular(100),
                  border: isLoggedIn ? null : Border.all(color: kSecondary.withOpacity(0.3)),
                ),
                child: Text(
                  isLoggedIn ? t('connect_message') : t('login'),
                  style: tsTitleMd(color: isLoggedIn ? const Color(0xFF1A1200) : kSecondary).copyWith(fontSize: 12),
                ),
              ),
            ),
          ],"""

new = """          if (!isMe && isLoggedIn) ...[
            GestureDetector(
              onTap: onMessage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(100)),
                child: Text(t('connect_message'), style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 12)),
              ),
            ),
          ],"""

if old in content:
    content = content.replace(old, new)
    print("✅ Fixed login button in cards")
else:
    print("❌ Card button not found")

# Fix 2: Fix overflow - wrap interest filter in SingleChildScrollView with overflow hidden
old2 = """              // Interest filter
              SizedBox(
                height: 44,
                child: ListView.builder("""

new2 = """              // Interest filter
              SizedBox(
                height: 44,
                child: ClipRect(
                child: ListView.builder("""

if old2 in content:
    content = content.replace(old2, new2)
    # Close ClipRect
    content = content.replace(
        "                ),\n              ),\n              const SizedBox(height: 12),\n\n              // Profiles list",
        "                ),\n                ),\n              ),\n              const SizedBox(height: 12),\n\n              // Profiles list"
    )
    print("✅ Fixed overflow with ClipRect")
else:
    print("❌ Interest filter not found")

with open('lib/screens/connect_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
