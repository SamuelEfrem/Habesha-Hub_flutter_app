with open('lib/screens/admin_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: Remove orderBy to avoid index requirement
content = content.replace(
    "stream: db.collection('travel_requests').orderBy('createdAt', descending: true).snapshots(),",
    "stream: db.collection('travel_requests').snapshots(),"
)
print("✅ Removed orderBy from travel_requests")

# Fix 2: Make tabs shorter on 2 lines
old_tabs = """          tabs: const [
            Tab(text: 'VENTER'),
            Tab(text: 'GODKJENT'),
            Tab(text: 'AVVIST'),
            Tab(text: 'MELDINGER'),
            Tab(text: 'BOOKINGER'),
            Tab(text: 'REISER'),
            Tab(text: 'LEGG TIL'),
          ],"""

new_tabs = """          tabs: const [
            Tab(child: Text('VENTER', style: TextStyle(fontSize: 9))),
            Tab(child: Text('GODKJENT', style: TextStyle(fontSize: 9))),
            Tab(child: Text('AVVIST', style: TextStyle(fontSize: 9))),
            Tab(child: Text('MELD.', style: TextStyle(fontSize: 9))),
            Tab(child: Text('BOOK.', style: TextStyle(fontSize: 9))),
            Tab(child: Text('REISER', style: TextStyle(fontSize: 9))),
            Tab(child: Text('LEGG TIL', style: TextStyle(fontSize: 9))),
          ],"""

if old_tabs in content:
    content = content.replace(old_tabs, new_tabs)
    print("✅ Tabs made smaller")
else:
    print("❌ Tabs pattern not found")

# Fix 3: Also fix empty state message
content = content.replace(
    "if (docs.isEmpty) return const Center(child: Text('Ingen reiseforespørsler ennå'));",
    "if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.flight_rounded, size: 56, color: kOnSurfaceVariant), const SizedBox(height: 16), const Text('No travel requests yet')]));"
)

with open('lib/screens/admin_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
