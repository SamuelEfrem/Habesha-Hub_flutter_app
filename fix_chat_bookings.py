with open('lib/screens/placeholder_screens.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add bookings stream to owner view - after chats section
old = """                const Divider(color: Colors.white10),
        ]);
      },
    );
  }
  Widget _buildUserView"""

new = """                const Divider(color: Colors.white10),
          // Show bookings for this business
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('bookings').where('businessId', isEqualTo: business.id).orderBy('createdAt', descending: true).snapshots(),
            builder: (_, bSnap) {
              if (!bSnap.hasData || bSnap.data!.docs.isEmpty) return const SizedBox();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 4), child: Text('Bookinger', style: tsLabel(color: kSecondary))),
                ...bSnap.data!.docs.map((b) {
                  final bd = b.data() as Map<String, dynamic>;
                  final date = (bd['date'] as Timestamp?)?.toDate();
                  final dateStr = date != null ? '\${date.day}.\${date.month}.\${date.year}' : '';
                  return ListTile(
                    leading: const Icon(Icons.calendar_today_rounded, color: kSecondary),
                    title: Text('\${bd['nickname'] ?? 'Gjest'} — \${bd['time'] ?? ''} \$dateStr', style: tsTitleMd()),
                    subtitle: Text(bd['message'] ?? '', style: tsBodySm()),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: kSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(bd['status'] ?? 'pending', style: tsBodySm(color: kSecondary)),
                    ),
                  );
                }),
              ]);
            },
          ),
        ]);
      },
    );
  }
  Widget _buildUserView"""

if old in content:
    content = content.replace(old, new)
    print("✅ Bookings added to owner view")
else:
    print("❌ Pattern not found")

with open('lib/screens/placeholder_screens.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done!")
