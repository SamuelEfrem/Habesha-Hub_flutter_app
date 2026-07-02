with open('lib/screens/admin_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Update TabController length from 6 to 7
content = content.replace(
    "_tab = TabController(length: 6, vsync: this);",
    "_tab = TabController(length: 7, vsync: this);"
)
print("✅ TabController length updated to 7")

# Add new tab
old_tabs = """            Tab(text: 'LEGG TIL'),
          ],"""
new_tabs = """            Tab(text: 'REISER'),
            Tab(text: 'LEGG TIL'),
          ],"""
if old_tabs in content:
    content = content.replace(old_tabs, new_tabs)
    print("✅ REISER tab added")

# Add new tab view
old_views = """          const AdminRegisterScreen(),
        ],"""
new_views = """          _TravelRequestsList(db: _db),
          const AdminRegisterScreen(),
        ],"""
if old_views in content:
    content = content.replace(old_views, new_views)
    print("✅ TravelRequestsList view added")

# Add _TravelRequestsList class before end of file
travel_class = """
class _TravelRequestsList extends StatelessWidget {
  final FirebaseFirestore db;
  const _TravelRequestsList({required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('travel_requests').orderBy('createdAt', descending: true).snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Ingen reiseforespørsler ennå'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final service = data['service'] ?? '';
            final name = data['name'] ?? '';
            final email = data['email'] ?? '';
            final phone = data['phone'] ?? '';
            final from = data['fromCountry'] ?? '';
            final to = data['toCountry'] ?? '';
            final date = data['travelDate'] ?? '';
            final details = data['details'] ?? '';
            final status = data['status'] ?? 'pending';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            Color statusColor = status == 'pending' ? kSecondary : status == 'done' ? kGreen : kRed;
            IconData serviceIcon = service == 'flight' ? Icons.flight_rounded : service == 'visa' ? Icons.badge_rounded : service == 'package' ? Icons.luggage_rounded : Icons.hotel_rounded;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSurfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(serviceIcon, color: kSecondary, size: 20),
                  const SizedBox(width: 8),
                  Text(service.toUpperCase(), style: tsTitleMd(color: kSecondary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(100), border: Border.all(color: statusColor.withOpacity(0.5))),
                    child: Text(status, style: tsLabel(color: statusColor)),
                  ),
                ]),
                const SizedBox(height: 10),
                Text('👤 $name', style: tsTitleMd()),
                Text('📧 $email', style: tsBodySm()),
                if (phone.isNotEmpty) Text('📞 $phone', style: tsBodySm()),
                if (from.isNotEmpty) Text('✈️ $from → $to', style: tsBodySm()),
                if (date.isNotEmpty) Text('📅 $date', style: tsBodySm()),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(details, style: tsBodySm(color: kOnSurfaceVariant)),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => db.collection('travel_requests').doc(docs[i].id).update({'status': 'done'}),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Center(child: Text('✅ Mark Done', style: TextStyle(color: kGreen, fontWeight: FontWeight.w700))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => db.collection('travel_requests').doc(docs[i].id).delete(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Center(child: Text('🗑 Delete', style: TextStyle(color: kRed, fontWeight: FontWeight.w700))),
                      ),
                    ),
                  ),
                ]),
              ]),
            );
          },
        );
      },
    );
  }
}
"""

# Add before last class or end of file
if "class _ContactMessagesList" in content:
    content = content + travel_class
    print("✅ _TravelRequestsList class added")

with open('lib/screens/admin_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done!")
