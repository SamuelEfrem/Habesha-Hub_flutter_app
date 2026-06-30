with open('lib/screens/admin_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """class _BusinessList extends StatelessWidget {
  final String status;
  final FirebaseFirestore db;

  const _BusinessList({requiredthis.status, required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
stream: db.collection('businesses').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return constCenter(
              child: CircularProgressIndicator(
                  color: kSecondary, strokeWidth: 1.5));
        }

final docs = snap.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final s = data['status'] as String?;
          if (status == 'pending') return s == null || s == 'pending';
          return s == status;
        }).toList();"""

new = """class _BusinessList extends StatefulWidget {
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

if old in content:
    content = content.replace(old, new)
    print("✅ Matched and replaced!")
else:
    print("❌ Still no match")

with open('lib/screens/admin_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
