with open('lib/screens/connect_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: Remove orderBy to avoid index requirement
content = content.replace(
    "stream: _db.collection('connect_profiles').orderBy('createdAt', descending: true).snapshots(),",
    "stream: _db.collection('connect_profiles').snapshots(),"
)
print("✅ orderBy removed")

# Fix 2: Fix overflow - make interest filter chips smaller
content = content.replace(
    "                        child: Row(mainAxisSize: MainAxisSize.min, children: [\n                          Text(item['emoji']!, style: const TextStyle(fontSize: 14)),\n                          const SizedBox(width: 6),\n                          Text(item['key']!, style: tsLabel(color: sel ? const Color(0xFF342800) : kOnSurfaceVariant)),",
    "                        child: Row(mainAxisSize: MainAxisSize.min, children: [\n                          Text(item['emoji']!, style: const TextStyle(fontSize: 12)),\n                          const SizedBox(width: 4),\n                          Text(item['key']!, style: tsLabel(color: sel ? const Color(0xFF342800) : kOnSurfaceVariant).copyWith(fontSize: 9)),"
)
print("✅ Overflow fixed")

# Fix 3: Add translations
# Add t() references
content = content.replace(
    "Text('Connect', style: tsHeadlineMd(color: kSecondary)),",
    "Text(languageNotifier.t('connect_title'), style: tsHeadlineMd(color: kSecondary)),"
)
content = content.replace(
    "Text('Find people with same interests', style: tsBodySm()),",
    "Text(languageNotifier.t('connect_subtitle'), style: tsBodySm()),"
)
content = content.replace(
    "'My Profile', style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 13)",
    "languageNotifier.t('connect_my_profile'), style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 13)"
)
content = content.replace(
    "Text('No profiles yet', style: tsTitleLg()),",
    "Text(languageNotifier.t('connect_no_profiles'), style: tsTitleLg()),"
)
content = content.replace(
    "Text('Be the first to create a profile!', style: tsBodySm()),",
    "Text(languageNotifier.t('connect_be_first'), style: tsBodySm()),"
)
content = content.replace(
    "Text('Message', style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 12))",
    "Text(languageNotifier.t('connect_message'), style: tsTitleMd(color: const Color(0xFF1A1200)).copyWith(fontSize: 12))"
)
print("✅ Translations added")

with open('lib/screens/connect_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
