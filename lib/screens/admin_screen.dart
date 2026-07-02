import 'admin_register_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/business.dart';
import 'edit_business_screen.dart';
import 'booking_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 7, vsync: this);

    if (!_isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ikke tilgang')),
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
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: kSurfaceContainer,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Text('Admin Panel', style: tsTitleLg(color: kSecondary)),
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: kSecondary,
          labelColor: kSecondary,
          unselectedLabelColor: kOnSurfaceVariant,
          labelStyle: const TextStyle(
              fontFamily: kFontBody, fontWeight: FontWeight.w700, fontSize: 11),
          tabs: const [
            Tab(child: Text('VENTER', style: TextStyle(fontSize: 9))),
            Tab(child: Text('GODKJENT', style: TextStyle(fontSize: 9))),
            Tab(child: Text('AVVIST', style: TextStyle(fontSize: 9))),
            Tab(child: Text('MELD.', style: TextStyle(fontSize: 9))),
            Tab(child: Text('BOOK.', style: TextStyle(fontSize: 9))),
            Tab(child: Text('REISER', style: TextStyle(fontSize: 9))),
            Tab(child: Text('LEGG TIL', style: TextStyle(fontSize: 9))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _BusinessList(status: 'pending', db: _db),
          _BusinessList(status: 'approved', db: _db),
          _BusinessList(status: 'rejected', db: _db),
          _ContactMessagesList(db: _db),
          const BookingListScreen(),
          _TravelRequestsList(db: _db),
          const AdminRegisterScreen(),
        ],
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
        }).toList();

        docs.sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime =
              (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                status == 'pending'
                    ? Icons.hourglass_empty_rounded
                    : status == 'approved'
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined,
                color: kOnSurfaceVariant,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                status == 'pending'
                    ? 'Ingen ventende bedrifter'
                    : status == 'approved'
                        ? 'Ingen godkjente bedrifter'
                        : 'Ingen avviste bedrifter',
                style: tsBodySm(),
                textAlign: TextAlign.center,
              ),
            ]),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final business = Business.fromFirestore(data, doc.id);
            return _AdminCard(
              business: business,
              docId: doc.id,
              status: status,
              ownerEmail: data['ownerEmail'] ?? '',
              ownerName: data['ownerName'] ?? '',
              db: db,
            );
          },
        );
      },
    ),
      ),
    ]);
  }
}

class _AdminCard extends StatelessWidget {
  final Business business;
  final String docId;
  final String status;
  final String ownerEmail;
  final String ownerName;
  final FirebaseFirestore db;

  const _AdminCard({
    required this.business,
    required this.docId,
    required this.status,
    required this.ownerEmail,
    required this.ownerName,
    required this.db,
  });

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    await db.collection('businesses').doc(docId).update({
      'status': newStatus,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newStatus == 'approved'
            ? '✓ ${business.name} godkjent og publisert!'
            : '✗ ${business.name} avvist.'),
        backgroundColor: newStatus == 'approved' ? kGreen : kRed,
      ));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurfaceContainerHigh,
        title: Text('Slett bedrift', style: tsHeadlineSm()),
        content: Text('Er du sikker på at du vil slette "${business.name}"?',
            style: tsBodyLg()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Avbryt', style: tsBodySm())),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Slett', style: tsTitleMd(color: kRed))),
        ],
      ),
    );
    if (confirm == true) {
      await db.collection('businesses').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${business.name} slettet'),
          backgroundColor: kSurfaceContainerHigh,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kSurfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'pending'
              ? kSecondary.withOpacity(0.2)
              : status == 'approved'
                  ? kGreen.withOpacity(0.2)
                  : kRed.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (business.imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              business.imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 80,
                color: kSurfaceContainerHigh,
                child: const Center(
                    child: Icon(Icons.image_not_supported_rounded,
                        color: kOnSurfaceVariant)),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(business.name, style: tsHeadlineSm())),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kSecondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(business.category, style: tsLabel()),
              ),
            ]),
            const SizedBox(height: 8),
            Text(business.description,
                style: tsBodySm(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            _infoRow(Icons.location_on_rounded, business.address),
            _infoRow(Icons.phone_rounded, business.phone),
            _infoRow(Icons.person_rounded, '$ownerName  •  $ownerEmail'),
            if (business.openingHours.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: kSurfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: business.openingHours.entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(children: [
                              Expanded(child: Text(e.key, style: tsBodySm())),
                              Text(e.value,
                                  style: tsBodySm(
                                      color: e.value == 'Stengt'
                                          ? kRed
                                          : kOnSurface)),
                            ]),
                          ))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _AdminActions(
              business: business,
              docId: docId,
              status: status,
              onUpdate: (s) => _updateStatus(context, s),
              onDelete: () => _delete(context),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, color: kSecondary, size: 14),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: tsBodySm(), overflow: TextOverflow.ellipsis)),
        ]),
      );
}

class _AdminActions extends StatelessWidget {
  final Business business;
  final String docId;
  final String status;
  final Function(String) onUpdate;
  final VoidCallback onDelete;

  const _AdminActions({
    required this.business,
    required this.docId,
    required this.status,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        if (status == 'pending') ...[
          Expanded(
              child: _btn(Icons.close_rounded, 'Avvis', kRed,
                  () => onUpdate('rejected'))),
          const SizedBox(width: 8),
          Expanded(
              flex: 2,
              child: _btn(Icons.check_rounded, 'Godkjenn og publiser', kGreen,
                  () => onUpdate('approved'))),
        ] else if (status == 'approved') ...[
          Expanded(
              child: _btn(Icons.block_rounded, 'Deaktiver', kRed,
                  () => onUpdate('rejected'))),
          const SizedBox(width: 8),
          Expanded(
              child:
                  _btn(Icons.delete_outline_rounded, 'Slett', kRed, onDelete)),
        ] else ...[
          Expanded(
              child: _btn(Icons.check_rounded, 'Godkjenn', kGreen,
                  () => onUpdate('approved'))),
          const SizedBox(width: 8),
          Expanded(
              child:
                  _btn(Icons.delete_outline_rounded, 'Slett', kRed, onDelete)),
        ],
      ]),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      EditBusinessScreen(business: business, docId: docId)));
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: kSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kSecondary.withOpacity(0.3), width: 0.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.edit_rounded, color: kSecondary, size: 15),
            const SizedBox(width: 6),
            Text('Rediger bedrift',
                style: tsTitleMd(color: kSecondary).copyWith(fontSize: 13)),
          ]),
        ),
      ),
    ]);
  }

  Widget _btn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Flexible(
              child: Text(label,
                  style: tsTitleMd(color: color).copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
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
                const Icon(Icons.mail_outline_rounded,
                    color: kOnSurfaceVariant, size: 52),
                const SizedBox(height: 12),
                Text('Ingen meldinger ennå', style: tsBodySm()),
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
                color: kSurfaceContainer,
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
                        child: Text(replied ? 'BESVART' : 'NY',
                            style: tsLabel(color: replied ? kGreen : kSecondary)
                                .copyWith(fontSize: 9)),
                      ),
                      const Spacer(),
                      if (data['createdAt'] != null)
                        Text(
                          DateFormat('dd.MM HH:mm').format(
                              (data['createdAt'] as Timestamp).toDate()),
                          style:
                              tsLabel(color: kOnSurfaceVariant.withOpacity(0.5))
                                  .copyWith(fontSize: 9),
                        ),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.person_rounded,
                          color: kSecondary, size: 14),
                      const SizedBox(width: 6),
                      Text(data['name'] ?? 'Ukjent', style: tsTitleMd()),
                    ]),
                    if ((data['email'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.email_outlined,
                            color: kSecondary, size: 14),
                        const SizedBox(width: 6),
                        Text(data['email'] ?? '', style: tsBodySm()),
                      ]),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: kSurfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(data['message'] ?? '', style: tsBodyLg()),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final email = data['email'] ?? '';
                            final name = data['name'] ?? 'Bruker';
                            final message = data['message'] ?? '';
                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Ingen e-post registrert')));
                              return;
                            }
                            final subject = Uri.encodeComponent(
                                'Svar fra Habesha Hub - $name');
                            final body = Uri.encodeComponent(
                                'Hei $name,\n\nTakk for din henvendelse:\n"$message"\n\nSvar:\n\n---\nHabesha Hub\nsamuelefriem@gmail.com');
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
                                  Text('Svar i Gmail',
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
        if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.flight_rounded, size: 56, color: kOnSurfaceVariant), const SizedBox(height: 16), const Text('No travel requests yet')]));
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
