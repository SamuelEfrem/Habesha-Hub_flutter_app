import re

with open('lib/screens/admin_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find class start and the specific end marker
start_marker = "class _BusinessList extends StatelessWidget {"
end_marker = "}).toList();"

start_idx = content.find(start_marker)
if start_idx == -1:
    print("❌ Start marker not found")
else:
    end_idx = content.find(end_marker, start_idx)
    if end_idx == -1:
        print("❌ End marker not found")
    else:
        end_idx += len(end_marker)
        old_block = content[start_idx:end_idx]
        print(f"Found block of {len(old_block)} chars")
        
        new_block = """class _BusinessList extends StatefulWidget {
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
        
        content = content[:start_idx] + new_block + content[end_idx:]
        print("✅ Replaced!")

        with open('lib/screens/admin_screen.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Done!")
