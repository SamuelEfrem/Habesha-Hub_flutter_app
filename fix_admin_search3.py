import re

with open('lib/screens/admin_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Use regex to match more flexibly
pattern = re.compile(
    r"class _BusinessList extends StatelessWidget \{\n"
    r"  final String status;\n"
    r"  final FirebaseFirestore db;\n"
    r"  const _BusinessList\(\{required this\.status, required this\.db\}\);\n"
    r"  @override\n"
    r"  Widget build\(BuildContext context\) \{\n"
    r"    return StreamBuilder<QuerySnapshot>\(\n"
    r"      stream: db\.collection\('businesses'\)\.snapshots\(\),\n"
    r"      builder: \(context, snap\) \{\n"
    r"        if \(!snap\.hasData\) \{\n"
    r"          return const Center\(\n"
    r"              child: CircularProgressIndicator\(\n"
    r"                  color: kSecondary, strokeWidth: 1\.5\)\);\n"
    r"        \}\n"
    r"        final docs = snap\.data!\.docs\.where\(\(doc\) \{\n"
    r"          final data = doc\.data\(\) as Map<String, dynamic>;\n"
    r"          final s = data\['status'\] as String\?;\n"
    r"          if \(status == 'pending'\) return s == null \|\| s == 'pending';\n"
    r"          return s == status;\n"
    r"        \}\)\.toList\(\);"
)

match = pattern.search(content)
if match:
    print("✅ Pattern matched with regex!")
    old_text = match.group(0)
    new_text = """class _BusinessList extends StatefulWidget {
  final String status;
  final FirebaseFirestore db;
  const _BusinessList({required this.status, required this.db});
  @override
  State<_BusinessList> createState() => _BusinessListState();
}

class _BusinessListState extends State<_BusinessList> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final db = widget.db;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          style: tsBodyLg(color: kOnSurface),
          decoration: InputDecoration(
            hintText: 'Søk bedrift...',
            prefixIcon: const Icon(Icons.search_rounded, color: kSecondary),
            filled: true,
            fillColor: kSurfaceContainer,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
      stream: db.collection('businesses').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: kSecondary, strokeWidth: 1.5));
        }
        final docs = snap.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final s = data['status'] as String?;
          bool statusMatch;
          if (status == 'pending') statusMatch = s == null || s == 'pending';
          else statusMatch = s == status;
          if (!statusMatch) return false;
          if (_searchQuery.isEmpty) return true;
          final name = (data['name'] as String? ?? '').toLowerCase();
          return name.contains(_searchQuery);
        }).toList();"""
    
    content = content.replace(old_text, new_text)
    print("✅ Replaced!")
else:
    print("❌ No regex match either")
    # Print the actual content for debugging
    start = content.find("class _BusinessList")
    print("ACTUAL CONTENT:")
    print(repr(content[start:start+800]))

with open('lib/screens/admin_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
