import 'admin_register_screen.dart';
import 'add_service_screen.dart';
import 'services_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/business.dart';
import 'edit_business_screen.dart';
import 'booking_screen.dart';
import 'community_screens.dart';

const List<String> _adminEmails = [
  'samuelefriem@gmail.com',
];

bool get _isAdmin {
  final email = FirebaseAuth.instance.currentUser?.email ?? '';
  return _adminEmails.contains(email);
}

class AdminButton extends StatelessWidget {
  const AdminButton({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final email = user?.email ?? '';
        final isAdm = _adminEmails.contains(email);
        if (!isAdm) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: kSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: kSecondary.withOpacity(0.3), width: 0.5),
            ),
            child: Row(children: [
              const Icon(Icons.admin_panel_settings_rounded,
                  color: kSecondary, size: 20),
              const SizedBox(width: 14),
              Text('Admin Panel', style: tsTitleMd(color: kSecondary)),
              const Spacer(),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('businesses')
                    .snapshots(),
                builder: (_, snap) {
                  final count = snap.data?.docs.where((d) {
                        final s = (d.data() as Map<String, dynamic>)['status']
                            as String?;
                        return s == null || s == 'pending';
                      }).length ??
                      0;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: kRed, borderRadius: BorderRadius.circular(100)),
                    child: Text('$count',
                        style: tsLabel(color: Colors.white)
                            .copyWith(fontSize: 11)),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: kSecondary, size: 13),
            ]),
          ),
        );
      },
    );
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _db = FirebaseFirestore.instance;

  // Tab order — the stat tiles at the top jump to these
  static const _tabs = [
    (Icons.hourglass_top_rounded, 'Pending'),
    (Icons.verified_rounded, 'Approved'),
    (Icons.block_rounded, 'Rejected'),
    (Icons.verified_user_rounded, 'Claims'),
    (Icons.flag_rounded, 'Reports'),
    (Icons.add_business_rounded, 'Suggestions'),
    (Icons.mail_rounded, 'Messages'),
    (Icons.event_note_rounded, 'Bookings'),
    (Icons.flight_rounded, 'Travel'),
    (Icons.design_services_rounded, 'Services'),
    (Icons.receipt_long_rounded, 'Orders'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);

    if (!_isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No access')),
        );
      });
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: kBg,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: kSecondary),
            title: Row(children: [
              const Icon(Icons.admin_panel_settings_rounded, color: kSecondary, size: 22),
              const SizedBox(width: 8),
              Text('Admin', style: tsHeadlineMd(color: kText)),
            ]),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kSecondary,
                    foregroundColor: const Color(0xFF1A1200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminRegisterScreen())),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add business', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(child: _StatsRow(db: _db, onTap: (i) => _tab.animateTo(i))),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarHeader(TabBar(
              controller: _tab,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: kSecondary,
                borderRadius: BorderRadius.circular(100),
              ),
              labelColor: const Color(0xFF1A1200),
              unselectedLabelColor: kTextSub,
              labelPadding: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              labelStyle: const TextStyle(fontFamily: kFontBody, fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                for (final t in _tabs)
                  Tab(height: 36, child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(t.$1, size: 16),
                    const SizedBox(width: 6),
                    Text(t.$2),
                  ])),
              ],
            )),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _BusinessList(status: 'pending', db: _db),
            _BusinessList(status: 'approved', db: _db),
            _BusinessList(status: 'rejected', db: _db),
            const ClaimsAdminTab(),
            const ReportsAdminTab(),
            const SuggestionsAdminTab(),
            _ContactMessagesList(db: _db),
            const BookingListScreen(),
            _TravelRequestsList(db: _db),
            // ─ SERVICES (anonymous providers) ─
            Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton: FloatingActionButton(
                backgroundColor: kSecondary,
                foregroundColor: const Color(0xFF1A1200),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddServiceScreen())),
                child: const Icon(Icons.add_rounded),
              ),
              body: const ManageServicesTab(),
            ),
            // ─ BOOKINGS (service_bookings) ─
            const ManageBookingsTab(),
          ],
        ),
      ),
    );
  }
}

class _TabBarHeader extends SliverPersistentHeaderDelegate {
  final TabBar bar;
  _TabBarHeader(this.bar);
  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: kBg, child: bar);
  @override
  bool shouldRebuild(covariant _TabBarHeader old) => true;
}

// ── Overview: live counts, tap to open that tab ──
class _StatsRow extends StatelessWidget {
  final FirebaseFirestore db;
  final ValueChanged<int> onTap;
  const _StatsRow({required this.db, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('businesses').snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        int pending = 0, approved = 0, rejected = 0, imported = 0;
        for (final d in docs) {
          final m = d.data() as Map<String, dynamic>;
          final s = m['status'] as String?;
          if (s == null || s == 'pending') pending++;
          if (s == 'approved') approved++;
          if (s == 'rejected') rejected++;
          if (m['source'] == 'osm') imported++;
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(children: [
            Row(children: [
              _tile('Pending', pending, Icons.hourglass_top_rounded, kSecondary, () => onTap(0), highlight: pending > 0),
              const SizedBox(width: 10),
              _tile('Live', approved, Icons.verified_rounded, kGreen, () => onTap(1)),
              const SizedBox(width: 10),
              _tile('Rejected', rejected, Icons.block_rounded, kRed, () => onTap(2)),
            ]),
            const SizedBox(height: 8),
            Text('${docs.length} businesses in total  ·  $imported imported from OpenStreetMap',
                style: tsBodySm(color: kTextSub)),
          ]),
        );
      },
    );
  }

  Widget _tile(String label, int n, IconData icon, Color color, VoidCallback onTap, {bool highlight = false}) {
    return Expanded(
      child: Material(
        color: highlight ? color.withOpacity(0.15) : kCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text('$n', style: tsHeadlineMd(color: kText)),
              Text(label, style: tsBodySm(color: kTextSub)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _BusinessList extends StatefulWidget {
  final String status;
  final FirebaseFirestore db;
  const _BusinessList({required this.status, required this.db});
  @override
  State<_BusinessList> createState() => _BusinessListState();
}

class _BusinessListState extends State<_BusinessList> with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  String _source = 'all'; // all | owners | imported

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final status = widget.status;
    final db = widget.db;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: TextField(
          style: tsBodyLg(color: kText),
          decoration: InputDecoration(
            hintText: 'Search name, city or country…',
            prefixIcon: const Icon(Icons.search_rounded, color: kSecondary),
            filled: true,
            fillColor: kCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        ),
      ),
      SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _filterChip('All', 'all'),
            _filterChip('Registered by owners', 'owners'),
            _filterChip('Imported (OSM)', 'imported'),
          ],
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: db.collection('businesses').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
            }
            final docs = snap.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final s = data['status'] as String?;
              final statusMatch = status == 'pending' ? (s == null || s == 'pending') : s == status;
              if (!statusMatch) return false;
              final imported = data['source'] == 'osm';
              if (_source == 'owners' && imported) return false;
              if (_source == 'imported' && !imported) return false;
              if (_searchQuery.isEmpty) return true;
              final hay = '${data['name'] ?? ''} ${data['address'] ?? ''} ${data['country'] ?? ''}'.toLowerCase();
              return hay.contains(_searchQuery);
            }).toList();

            // Newest first; owner-registered before imported
            docs.sort((a, b) {
              final am = a.data() as Map<String, dynamic>, bm = b.data() as Map<String, dynamic>;
              final ai = am['source'] == 'osm' ? 1 : 0, bi = bm['source'] == 'osm' ? 1 : 0;
              if (ai != bi) return ai.compareTo(bi);
              final aTime = am['createdAt'] as Timestamp?, bTime = bm['createdAt'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

            if (docs.isEmpty) {
              return Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(status == 'pending'
                          ? Icons.task_alt_rounded
                          : status == 'approved' ? Icons.storefront_rounded : Icons.block_rounded,
                      color: kTextSub.withOpacity(0.5), size: 52),
                  const SizedBox(height: 12),
                  Text(status == 'pending' ? 'All caught up — nothing to review' : 'Nothing here',
                      style: tsTitleMd(color: kText)),
                ]),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
              itemCount: docs.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4),
                    child: Text('${docs.length} ${docs.length == 1 ? 'business' : 'businesses'}',
                        style: tsBodySm(color: kTextSub)),
                  );
                }
                final doc = docs[i - 1];
                final data = doc.data() as Map<String, dynamic>;
                return _AdminCard(
                  key: ValueKey(doc.id),
                  business: Business.fromFirestore(data, doc.id),
                  docId: doc.id,
                  status: status,
                  ownerEmail: serviceStr(data['ownerEmail']),
                  ownerName: serviceStr(data['ownerName']),
                  db: db,
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  Widget _filterChip(String label, String value) {
    final sel = _source == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => setState(() => _source = value),
        showCheckmark: false,
        selectedColor: kSecondary.withOpacity(0.2),
        backgroundColor: kCard,
        side: BorderSide(color: sel ? kSecondary : Colors.transparent),
        labelStyle: TextStyle(fontFamily: kFontBody, fontSize: 12, fontWeight: FontWeight.w600,
            color: sel ? kSecondary : kText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
    );
  }
}

// ── One business: compact row, tap to expand details + all actions ──
class _AdminCard extends StatefulWidget {
  final Business business;
  final String docId;
  final String status;
  final String ownerEmail;
  final String ownerName;
  final FirebaseFirestore db;

  const _AdminCard({
    super.key,
    required this.business,
    required this.docId,
    required this.status,
    required this.ownerEmail,
    required this.ownerName,
    required this.db,
  });

  @override
  State<_AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<_AdminCard> {
  bool _open = false;

  Business get business => widget.business;

  Future<void> _updateStatus(String newStatus) async {
    await widget.db.collection('businesses').doc(widget.docId).update({
      'status': newStatus,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newStatus == 'approved'
            ? '✓ ${business.name} is live'
            : '✗ ${business.name} hidden'),
        backgroundColor: newStatus == 'approved' ? kGreen : kRed,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () => widget.db.collection('businesses').doc(widget.docId)
              .update({'status': widget.status == 'pending' ? 'pending' : widget.status}),
        ),
      ));
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardHigh,
        title: Text('Delete business', style: tsHeadlineSm()),
        content: Text('Delete "${business.name}" for good? This can\'t be undone.\n\nTip: "Hide" keeps it so you can bring it back.',
            style: tsBodyLg()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: tsBodySm())),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: tsTitleMd(color: kRed))),
        ],
      ),
    );
    if (confirm == true) {
      await widget.db.collection('businesses').doc(widget.docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${business.name} deleted'),
          backgroundColor: kCardHigh,
        ));
      }
    }
  }

  static const _emoji = {
    'Restaurant': '🍽️', 'Shop': '🛍️', 'Cafe': '☕', 'Barber': '💇', 'Club': '🎵',
    'Clinic': '🏥', 'Hotel': '🏨',
  };

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final imported = business.source == 'osm';
    final statusColor = status == 'pending' ? kSecondary : status == 'approved' ? kGreen : kRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52, height: 52,
                  child: business.imageUrl.isNotEmpty
                      ? Image.network(business.imageUrl, fit: BoxFit.cover, cacheWidth: 160,
                          errorBuilder: (_, __, ___) => _emojiBox())
                      : _emojiBox(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(business.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: tsTitleLg(color: kText))),
                  if (business.isPremium) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded, color: kSecondary, size: 16),
                  ],
                ]),
                const SizedBox(height: 2),
                Text([business.category, if (business.country.isNotEmpty) business.country].join('  ·  '),
                    style: tsBodySm(color: kSecondary).copyWith(fontWeight: FontWeight.w600)),
                Text(imported ? 'Imported from OpenStreetMap' : (widget.ownerEmail.isNotEmpty ? widget.ownerEmail : 'No owner'),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: tsBodySm(color: kTextSub)),
              ])),
              // Quick decision without opening the card
              if (status == 'pending') ...[
                _roundAction(Icons.close_rounded, kRed, () => _updateStatus('rejected')),
                const SizedBox(width: 6),
                _roundAction(Icons.check_rounded, kGreen, () => _updateStatus('approved')),
              ] else
                Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: kTextSub),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: !_open ? const SizedBox(width: double.infinity) : Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Divider(color: kTextSub.withOpacity(0.15), height: 1),
              const SizedBox(height: 12),
              if (business.description.isNotEmpty) ...[
                Text(business.description, style: tsBodySm(color: kText)),
                const SizedBox(height: 10),
              ],
              _infoRow(Icons.location_on_rounded, business.address),
              if (business.phone.isNotEmpty) _infoRow(Icons.phone_rounded, business.phone),
              if (!imported && (widget.ownerName.isNotEmpty || widget.ownerEmail.isNotEmpty))
                _infoRow(Icons.person_rounded, [widget.ownerName, widget.ownerEmail].where((s) => s.isNotEmpty).join('  ·  ')),
              if (business.openingHours.isNotEmpty)
                _infoRow(Icons.schedule_rounded,
                    business.openingHours.entries.map((e) => '${e.key} ${e.value}').join('   ')),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (status != 'approved')
                  _pill(Icons.check_rounded, status == 'pending' ? 'Approve' : 'Make live', kGreen, () => _updateStatus('approved')),
                if (status != 'rejected')
                  _pill(Icons.visibility_off_rounded, 'Hide', kRed, () => _updateStatus('rejected')),
                _pill(Icons.edit_rounded, 'Edit', kSecondary, () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => EditBusinessScreen(business: business, docId: widget.docId)))),
                _pill(business.isPremium ? Icons.star_rounded : Icons.star_outline_rounded,
                    business.isPremium ? 'Remove Premium' : 'Make Premium', kSecondary,
                    () => widget.db.collection('businesses').doc(widget.docId).update({'isPremium': !business.isPremium})),
                _pill(Icons.delete_outline_rounded, 'Delete', kRed, _delete),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _emojiBox() => Container(
        color: kSecondary.withOpacity(0.12),
        alignment: Alignment.center,
        child: Text(_emoji[business.category] ?? '🏠', style: const TextStyle(fontSize: 24)),
      );

  Widget _roundAction(IconData icon, Color color, VoidCallback onTap) => Material(
        color: color.withOpacity(0.15),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Icon(icon, color: color, size: 22)),
        ),
      );

  Widget _pill(IconData icon, String label, Color color, VoidCallback onTap) => Material(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: tsTitleMd(color: color).copyWith(fontSize: 12)),
            ]),
          ),
        ),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: kSecondary, size: 15),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: tsBodySm(color: kText))),
        ]),
      );
}

class _ContactMessagesList extends StatelessWidget {
  final FirebaseFirestore db;
  const _ContactMessagesList({required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('contact_messages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: kSecondary, strokeWidth: 1.5));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Icon(Icons.mail_outline_rounded,
                    color: kTextSub, size: 52),
                const SizedBox(height: 12),
                Text('No messages yet', style: tsBodySm()),
              ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final replied = data['replied'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: replied
                      ? kGreen.withOpacity(0.2)
                      : kSecondary.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: replied
                              ? kGreen.withOpacity(0.1)
                              : kSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(replied ? 'ANSWERED' : 'NEW',
                            style: tsLabel(color: replied ? kGreen : kSecondary)
                                .copyWith(fontSize: 9)),
                      ),
                      const Spacer(),
                      if (data['createdAt'] != null)
                        Text(
                          DateFormat('dd.MM HH:mm').format(
                              (data['createdAt'] as Timestamp).toDate()),
                          style:
                              tsLabel(color: kTextSub.withOpacity(0.5))
                                  .copyWith(fontSize: 9),
                        ),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.person_rounded,
                          color: kSecondary, size: 14),
                      const SizedBox(width: 6),
                      Text(data['name'] ?? 'Unknown', style: tsTitleMd()),
                    ]),
                    if (serviceStr(data['email']).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.email_outlined,
                            color: kSecondary, size: 14),
                        const SizedBox(width: 6),
                        Text(serviceStr(data['email']), style: tsBodySm()),
                      ]),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: kCardHigh,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(serviceStr(data['message']), style: tsBodyLg()),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final email = serviceStr(data['email']);
                            final name = data['name'] ?? 'Bruker';
                            final message = serviceStr(data['message']);
                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('No email registered')));
                              return;
                            }
                            final subject = Uri.encodeComponent(
                                'Reply from Habesha Hub - $name');
                            final body = Uri.encodeComponent(
                                'Hi $name,\n\nThank you for your message:\n"$message"\n\nReply:\n\n---\nHabesha Hub\nsupport@habesha-hub.no');
                            final gmailUrl = Uri.parse(
                                'https://mail.google.com/mail/?view=cm&to=$email&su=$subject&body=$body');
                            final mailtoUrl = Uri.parse(
                                'mailto:$email?subject=$subject&body=$body');
                            if (await canLaunchUrl(gmailUrl)) {
                              await launchUrl(gmailUrl,
                                  mode: LaunchMode.externalApplication);
                            } else if (await canLaunchUrl(mailtoUrl)) {
                              await launchUrl(mailtoUrl);
                            }
                            await docs[i].reference.update({'replied': true});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: kSecondary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: kSecondary.withOpacity(0.3),
                                  width: 0.5),
                            ),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.reply_rounded,
                                      color: kSecondary, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Reply in Gmail',
                                      style: tsTitleMd(color: kSecondary)
                                          .copyWith(fontSize: 12)),
                                ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => docs[i].reference.delete(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: kRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: kRed.withOpacity(0.3), width: 0.5),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: kRed, size: 18),
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

class _TravelRequestsList extends StatelessWidget {
  final FirebaseFirestore db;
  const _TravelRequestsList({required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('travel_requests').snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
        final docs = snap.data!.docs;
        if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.flight_rounded, size: 56, color: kTextSub), const SizedBox(height: 16), const Text('No travel requests yet')]));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final service = serviceStr(data['service']);
            final name = serviceStr(data['name']);
            final email = serviceStr(data['email']);
            final phone = serviceStr(data['phone']);
            final from = serviceStr(data['fromCountry']);
            final to = serviceStr(data['toCountry']);
            final date = serviceStr(data['travelDate']);
            final details = serviceStr(data['details']);
            final status = data['status'] ?? 'pending';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            Color statusColor = status == 'pending' ? kSecondary : status == 'done' ? kGreen : kRed;
            IconData serviceIcon = service == 'flight' ? Icons.flight_rounded : service == 'visa' ? Icons.badge_rounded : service == 'package' ? Icons.luggage_rounded : Icons.hotel_rounded;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCard,
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
                  Text(details, style: tsBodySm(color: kTextSub)),
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
