import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/business.dart';
import '../utils/language_notifier.dart';
import '../theme/app_theme.dart';
import 'edit_business_screen.dart';

class BusinessDetailScreen extends StatefulWidget {
  final Business business;
  final double userLat;
  final double userLng;
  final bool openChat;

  const BusinessDetailScreen({
    super.key,
    required this.business,
    required this.userLat,
    required this.userLng,
    this.openChat = false,
  });

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _db = FirebaseFirestore.instance;

  String? _userId;
  String? _nickname;
  bool _chatLoading = true;
  bool _uploadingMenu = false;
  double _userRating = 0;
  bool _ratingSubmitted = false;
  int _ratingCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initChat();
    _loadRatingState();
    if (widget.openChat) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _tabController.animateTo(1));
    }
  }

  Future<void> _initChat() async {
    final prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('userId');
    if (uid == null) {
      uid = const Uuid().v4();
      await prefs.setString('userId', uid);
    }
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final name = firebaseUser?.displayName ??
        prefs.getString('nickname') ??
        languageNotifier.t('guest');
    if (mounted)
      setState(() {
        _userId = uid;
        _nickname = name;
        _chatLoading = false;
      });
  }

  Future<void> _loadRatingState() async {
    final prefs = await SharedPreferences.getInstance();
    final rated = prefs.getBool('rated_${widget.business.id}') ?? false;
    final doc =
        await _db.collection('businesses').doc(widget.business.id).get();
    if (mounted && doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final count = (data['ratingCount'] ?? 0) as int;
      setState(() {
        _ratingSubmitted = rated;
        _ratingCount = count;
      });
    }
  }

  Future<void> _submitRating(double stars) async {
    if (_ratingSubmitted) return;
    final prefs = await SharedPreferences.getInstance();
    final doc =
        await _db.collection('businesses').doc(widget.business.id).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final oldRating = (data['rating'] ?? 0.0) as double;
    final count = (data['ratingCount'] ?? 0) as int;
    final newCount = count + 1;
    final newRating = ((oldRating * count) + stars) / newCount;
    await _db.collection('businesses').doc(widget.business.id).update({
      'rating': double.parse(newRating.toStringAsFixed(1)),
      'ratingCount': newCount,
    });
    await prefs.setBool('rated_${widget.business.id}', true);
    if (mounted) {
      setState(() {
        _userRating = stars;
        _ratingSubmitted = true;
        _ratingCount = newCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '${languageNotifier.t("gave_stars")} ${stars.toInt()} ${languageNotifier.t("stars")} ⭐',
            style: tsBodySm(color: kOnSurface)),
        backgroundColor: kGreen,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  bool get _isOwner {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.uid == widget.business.ownerId ||
        user.email == widget.business.ownerEmail;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _userId == null) return;
    _messageController.clear();
    await _db
        .collection('chats')
        .doc('${widget.business.id}_$_userId')
        .collection('messages')
        .add({
      'text': text,
      'userId': _userId,
      'nickname': _nickname ?? languageNotifier.t('guest'),
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _openMaps() async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${widget.business.lat},${widget.business.lng}&travelmode=driving');
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _openOsmMaps() async {
    final url = Uri.parse(
        'https://www.openstreetmap.org/?mlat=${widget.business.lat}&mlon=${widget.business.lng}&zoom=16');
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _callBusiness() async {
    final url = Uri.parse('tel:${widget.business.phone}');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _openMenuPdf() async {
    if (widget.business.pdfMenuUrl == null) return;
    final url = Uri.parse(widget.business.pdfMenuUrl!);
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _uploadMenuImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _uploadingMenu = true);
    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance.ref(
          'menus/${widget.business.id}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await _db
          .collection('businesses')
          .doc(widget.business.id)
          .update({'pdfMenuUrl': url});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(languageNotifier.t('message_sent'),
                style: tsBodySm(color: kOnSurface)),
            backgroundColor: kGreen));
        setState(() => _uploadingMenu = false);
      }
    } catch (e) {
      setState(() => _uploadingMenu = false);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (context, _) => Scaffold(
        backgroundColor: kSurface,
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [_buildSliver()],
          body: TabBarView(
              controller: _tabController,
              children: [_buildInfoTab(), _buildChatTab()]),
        ),
      ),
    );
  }

  SliverAppBar _buildSliver() {
    final t = languageNotifier.t;
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: kSurfaceContainer,
      iconTheme: const IconThemeData(color: kSecondary),
      actions: const [],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          Image.network(widget.business.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  color: kSurfaceContainerHigh,
                  child: const Icon(Icons.storefront_rounded,
                      size: 80, color: kSecondary))),
          DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                Colors.transparent,
                kSurface.withOpacity(0.95)
              ]))),
          Positioned(
              bottom: 16,
              left: 16,
              right: 110,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: kSecondary,
                            borderRadius: BorderRadius.circular(100)),
                        child: Text(widget.business.category.toUpperCase(),
                            style: tsLabel(color: const Color(0xFF342800)))),
                    const SizedBox(height: 8),
                    Text(widget.business.name,
                        style: const TextStyle(
                            fontFamily: kFontHeadline,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: kOnSurface,
                            height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      Row(
                          children: List.generate(
                              5,
                              (i) => Icon(
                                  i < widget.business.rating.floor()
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: kSecondary,
                                  size: 13))),
                      const SizedBox(width: 6),
                      Text(widget.business.rating.toStringAsFixed(1),
                          style: tsTitleMd(color: kOnSurface)),
                      const SizedBox(width: 4),
                      Text('($_ratingCount)',
                          style: tsBodySm(
                              color: kOnSurfaceVariant.withOpacity(0.6))),
                    ]),
                  ])),
          if (widget.userLat != 0)
            Positioned(
                bottom: 22,
                right: 16,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          widget.business.formattedDistance(
                              widget.userLat, widget.userLng),
                          style: const TextStyle(
                              fontFamily: kFontBody,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kSecondary)),
                      const SizedBox(height: 6),
                      GestureDetector(
                          onTap: _openMaps,
                          child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  color: kPrimaryContainer,
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.near_me_rounded,
                                  color: kSecondary, size: 22))),
                    ])),
        ]),
      ),
      bottom: TabBar(
          controller: _tabController,
          indicatorColor: kSecondary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
              fontFamily: kFontBody,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2),
          labelColor: kSecondary,
          unselectedLabelColor: kOnSurfaceVariant,
          tabs: [Tab(text: t('info_tab')), Tab(text: t('chat_tab'))]),
    );
  }

  Widget _buildInfoTab() {
    final t = languageNotifier.t;
    return ListView(padding: const EdgeInsets.all(20), children: [
      if (!_isOwner) _buildRatingWidget(),
      if (!_isOwner) const SizedBox(height: 12),
      if (_isOwner && widget.business.isPremium) _buildOwnerControls(),
      if (_isOwner && widget.business.isPremium) const SizedBox(height: 12),
      _buildHoursCard(),
      const SizedBox(height: 12),
      _buildMenuButton(),
      const SizedBox(height: 12),
      // Address card
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: kSecondary, borderRadius: BorderRadius.circular(12)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t('full_address'),
                style: tsLabel(color: const Color(0xFF342800))
                    .copyWith(fontSize: 9, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text(
                widget.business.address.isNotEmpty
                    ? widget.business.address
                    : t('no_address'),
                style: tsTitleLg(color: const Color(0xFF1A1200))),
          ])),
      const SizedBox(height: 20),
      GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2,
          children: [
            actionSquare(Icons.map_rounded, t('map'), _openMaps),
            actionSquare(Icons.chat_bubble_rounded, t('chat_tab'),
                () => _tabController.animateTo(1)),
            actionSquare(Icons.phone_rounded, t('call'), _callBusiness),
            actionSquare(Icons.language_rounded, t('web'), () async {
              final site = widget.business.website;
              if (site != null && site.isNotEmpty) {
                final url =
                    Uri.parse(site.startsWith('http') ? site : 'https://$site');
                if (await canLaunchUrl(url))
                  await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(t('no_website'),
                        style: tsBodySm(color: kOnSurface)),
                    backgroundColor: kSurfaceContainerHigh,
                    behavior: SnackBarBehavior.floating));
              }
            }),
          ]),
      const SizedBox(height: 24),
      Row(children: [
        Text('About ${widget.business.name.split(" ").first}',
            style: tsHeadlineMd()),
        const SizedBox(width: 12),
        Expanded(
            child: Container(
                height: 1,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                  kSecondary.withOpacity(0.4),
                  Colors.transparent
                ])))),
      ]),
      const SizedBox(height: 12),
      Text(
          widget.business.description.isNotEmpty
              ? widget.business.description
              : t('no_description'),
          style: tsBodyLg(color: kOnSurfaceVariant)),
      const SizedBox(height: 24),
      _buildOfflineMap(),
      const SizedBox(height: 24),
      if (widget.business.isPremium) ...[
        _buildPremiumSection(),
        const SizedBox(height: 24)
      ],
      const SizedBox(height: 40),
    ]);
  }

  Widget _buildRatingWidget() {
    final t = languageNotifier.t;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kSurfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kSecondary.withOpacity(0.1), width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_ratingSubmitted ? t('your_rating') : t('rate_business'),
            style:
                tsTitleMd(color: _ratingSubmitted ? kSecondary : kOnSurface)),
        const SizedBox(height: 10),
        Row(
            children: List.generate(5, (i) {
          return GestureDetector(
              onTap: _ratingSubmitted
                  ? null
                  : () => setState(() => _userRating = i + 1.0),
              child: Icon(
                  i < _userRating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: kSecondary,
                  size: 36));
        })),
        if (!_ratingSubmitted && _userRating > 0) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _submitRating(_userRating),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color: kSecondary, borderRadius: BorderRadius.circular(100)),
              child: Text(t('submit_rating'),
                  style: tsTitleMd(color: const Color(0xFF1A1200))
                      .copyWith(fontSize: 13)),
            ),
          ),
        ],
        if (_ratingSubmitted)
          Text('${t("gave_stars")} ${_userRating.toInt()} ${t("stars")} ⭐',
              style: tsBodySm(color: kSecondary)),
      ]),
    );
  }

  Widget _buildOwnerControls() {
    final t = languageNotifier.t;
    return Row(children: [
      Expanded(
          child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EditBusinessScreen(
                      business: widget.business, docId: widget.business.id)));
          if (result == true && mounted) Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: kSurfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: kSecondary.withOpacity(0.3), width: 0.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.edit_rounded, color: kSecondary, size: 16),
            const SizedBox(width: 6),
            Text(t('edit'),
                style: tsTitleMd(color: kSecondary).copyWith(fontSize: 13)),
          ]),
        ),
      )),
      const SizedBox(width: 10),
      Expanded(
          child: GestureDetector(
        onTap: () async {
          final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                    backgroundColor: kSurfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Text(t('delete_business'), style: tsHeadlineSm()),
                    content: Text(t('are_you_sure'), style: tsBodyLg()),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(t('cancel'), style: tsBodySm())),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child:
                              Text(t('delete'), style: tsTitleMd(color: kRed))),
                    ],
                  ));
          if (confirm == true) {
            await _db.collection('businesses').doc(widget.business.id).delete();
            if (mounted) Navigator.pop(context);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: kRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kRed.withOpacity(0.3), width: 0.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.delete_outline_rounded, color: kRed, size: 16),
            const SizedBox(width: 6),
            Text(t('delete_business'),
                style: tsTitleMd(color: kRed).copyWith(fontSize: 13)),
          ]),
        ),
      )),
    ]);
  }

  Widget _buildHoursCard() {
    final t = languageNotifier.t;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kSurfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kSecondary.withOpacity(0.05), width: 0.5)),
      child: Column(children: [
        Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            const Icon(Icons.schedule_rounded, size: 34, color: kSecondary),
            Positioned(
                top: -2,
                right: -2,
                child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: widget.business.isOpenNow ? kGreen : kRed,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: kSurfaceContainer, width: 1.5)))),
          ]),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(widget.business.isOpenNow ? t('open_now') : t('closed'),
                    style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: widget.business.isOpenNow ? kGreen : kRed)),
                if (widget.business.openingHours.isNotEmpty)
                  Text(_summaryLine(),
                      style: tsBodySm(color: kOnSurfaceVariant))
                else
                  Text(t('no_opening_hours'), style: tsBodySm()),
              ])),
        ]),
        if (widget.business.openingHours.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(height: 0.5, color: kOutlineVariant.withOpacity(0.15)),
          const SizedBox(height: 12),
          ..._sortedHours.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(children: [
                Expanded(child: Text(e.key, style: tsBodySm())),
                Text(e.value,
                    style: tsBodySm(
                            color: e.value.toLowerCase() == 'stengt'
                                ? kRed
                                : kOnSurface)
                        .copyWith(fontWeight: FontWeight.w600)),
              ]))),
        ],
      ]),
    );
  }

  // FIX: Properly detect today including range entries like "Man - Fre"
  String _summaryLine() {
    if (widget.business.openingHours.isEmpty) return '';
    final t = languageNotifier.t;
    final weekday = DateTime.now().weekday; // 1=Mon, 6=Sat, 7=Sun

    MapEntry<String, String>? todayEntry;
    for (final e in widget.business.openingHours.entries) {
      final k = e.key.toLowerCase();
      // Range: Man-Fre / Mon-Fri covers weekdays 1-5
      if ((k.contains('man') || k.contains('mon')) &&
          (k.contains('fre') || k.contains('fri')) &&
          weekday >= 1 &&
          weekday <= 5) {
        todayEntry = e;
        break;
      }
      // Range covers whole week Mon-Sun
      if ((k.contains('man') || k.contains('mon')) &&
          (k.contains('søn') || k.contains('sun'))) {
        todayEntry = e;
        break;
      }
      // Saturday
      if ((k.contains('lør') || k.contains('sat')) && weekday == 6) {
        todayEntry = e;
        break;
      }
      // Sunday
      if ((k.contains('søn') || k.contains('sun')) && weekday == 7) {
        todayEntry = e;
        break;
      }
      // Single day match by Norwegian weekday prefix
      final prefixes = ['man', 'tir', 'ons', 'tor', 'fre', 'lør', 'søn'];
      final todayPrefix = prefixes[weekday - 1];
      if (k.startsWith(todayPrefix) ||
          (k.contains(todayPrefix) && k.length < 12)) {
        todayEntry = e;
        break;
      }
    }

    if (todayEntry == null) return '';
    final val = todayEntry.value.trim();
    if (val.toLowerCase() == 'stengt' || val.toLowerCase() == 'closed') {
      return t('closed_today');
    }
    final parts = val.split(' - ');
    if (parts.length == 2) {
      return widget.business.isOpenNow
          ? '${t("closes_at")} ${parts[1].trim()} • ${todayEntry.key}'
          : '${t("opens_at")} ${parts[0].trim()} • ${todayEntry.key}';
    }
    return val;
  }

  int _dayOrder(String key) {
    final k = key.toLowerCase();
    if (k.contains('man') || k.contains('mon')) return 0;
    if (k.contains('lør') || k.contains('sat')) return 1;
    if (k.contains('søn') || k.contains('sun')) return 2;
    return 3;
  }

  Map<String, String> get _sortedHours {
    final hours = widget.business.openingHours;
    if (hours.isEmpty) return hours;
    final sorted = hours.entries.toList()
      ..sort((a, b) => _dayOrder(a.key).compareTo(_dayOrder(b.key)));
    return Map.fromEntries(sorted);
  }

  Widget _buildMenuButton() {
    final t = languageNotifier.t;
    final hasMenu = widget.business.pdfMenuUrl != null &&
        widget.business.pdfMenuUrl!.isNotEmpty;

    if (hasMenu) {
      return GestureDetector(
          onTap: _openMenuPdf,
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  color: kPrimaryContainer,
                  borderRadius: BorderRadius.circular(12)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.restaurant_menu_rounded,
                    color: kSecondary, size: 20),
                const SizedBox(width: 8),
                Text(t('view_menu'),
                    style: tsTitleMd(color: kOnSurface)
                        .copyWith(letterSpacing: 0.5)),
              ])));
    }

    if (_isOwner && widget.business.isPremium) {
      return GestureDetector(
          onTap: _uploadingMenu ? null : _uploadMenuImage,
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  color: kSecondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: kSecondary.withOpacity(0.5), width: 0.5)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_uploadingMenu)
                  const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: kSecondary, strokeWidth: 2))
                else
                  const Icon(Icons.upload_rounded, color: kSecondary, size: 20),
                const SizedBox(width: 8),
                Text(_uploadingMenu ? t('uploading') : t('upload_menu'),
                    style: tsTitleMd(color: kSecondary).copyWith(fontSize: 13)),
              ])));
    }

    if (_isOwner && !widget.business.isPremium) {
      return GestureDetector(
        onTap: () async {
          final url = Uri.parse(
              'mailto:samuelefriem@gmail.com?subject=Premium+menu+upload');
          if (await canLaunchUrl(url)) await launchUrl(url);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
              color: kSurfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: kSecondary.withOpacity(0.2), width: 0.5)),
          child: Row(children: [
            const Icon(Icons.mail_outline_rounded, color: kSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(t('want_upload_menu'),
                      style:
                          tsTitleMd(color: kSecondary).copyWith(fontSize: 13)),
                  Text(t('contact_for_premium'),
                      style:
                          tsBodySm(color: kOnSurfaceVariant.withOpacity(0.6))),
                ])),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: kSecondary, size: 12),
          ]),
        ),
      );
    }

    // Guest
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
          color: kSurfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: kOutlineVariant.withOpacity(0.15), width: 0.5)),
      child: Row(children: [
        Icon(Icons.restaurant_menu_rounded,
            color: kOnSurfaceVariant.withOpacity(0.3), size: 20),
        const SizedBox(width: 10),
        Text(t('menu_not_available'),
            style: tsBodySm(color: kOnSurfaceVariant.withOpacity(0.45))),
      ]),
    );
  }

  Widget _buildOfflineMap() {
    final t = languageNotifier.t;
    final lat = widget.business.lat;
    final lng = widget.business.lng;
    final ok = lat != 0 && lng != 0;
    return GestureDetector(
        onTap: _openOsmMaps,
        child: Container(
            height: 180,
            decoration: BoxDecoration(
                color: const Color(0xFF1A2035),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: kSecondary.withOpacity(0.1), width: 0.5)),
            clipBehavior: Clip.hardEdge,
            child: Stack(children: [
              if (ok)
                Positioned.fill(
                    child: Image.network(
                        'https://tile.openstreetmap.org/15/${_lon2tile(lng, 15)}/${_lat2tile(lat, 15)}.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _mapPlaceholder())),
              if (!ok) _mapPlaceholder(),
              Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.45)
                  ]))),
              Center(
                  child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          color: kPrimaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: kPrimaryContainer.withOpacity(0.5),
                                blurRadius: 16,
                                spreadRadius: 4)
                          ]),
                      child: const Icon(Icons.location_on_rounded,
                          color: kSecondary, size: 28))),
              Positioned(
                  bottom: 4,
                  left: 8,
                  child: Text('© OpenStreetMap',
                      style: tsLabel().copyWith(
                          fontSize: 7, color: Colors.white.withOpacity(0.4)))),
              Positioned(
                  bottom: 10,
                  right: 12,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(100)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.open_in_new_rounded,
                            color: kSecondary, size: 11),
                        const SizedBox(width: 4),
                        Text(t('open_map'),
                            style: tsLabel().copyWith(fontSize: 9)),
                      ]))),
            ])));
  }

  int _lon2tile(double lon, int z) => ((lon + 180) / 360 * (1 << z)).floor();
  int _lat2tile(double lat, int z) {
    final r = lat * 3.14159265358979 / 180;
    return ((1 - (r.abs() / 1.5707963)) * (1 << z) / 2)
        .floor()
        .clamp(0, (1 << z) - 1);
  }

  Widget _mapPlaceholder() => Container(
      color: const Color(0xFF1A2035),
      child: const Center(
          child: Icon(Icons.map_rounded, color: Color(0xFF2A3C5A), size: 60)));

  Widget _buildPremiumSection() {
    final t = languageNotifier.t;
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPrimaryContainer.withOpacity(0.35), kSurface]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kSecondary.withOpacity(0.2), width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.verified_rounded, color: kSecondary, size: 24),
            const SizedBox(width: 10),
            Text(t('premium_partner'), style: tsHeadlineSm(color: kSecondary)),
            const Spacer(),
            Opacity(
                opacity: 0.08,
                child: const Icon(Icons.verified_rounded,
                    color: kSecondary, size: 64)),
          ]),
          const SizedBox(height: 10),
          Text(t('premium_desc'), style: tsBodySm()),
          const SizedBox(height: 14),
          ...[
            t('verified_business'),
            t('priority_booking'),
            t('digital_menu')
          ].map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: kGreen, size: 16),
                const SizedBox(width: 10),
                Text(item, style: tsLabel(color: kOnSurface.withOpacity(0.7))),
              ]))),
        ]));
  }

  Widget _buildChatTab() {
    final t = languageNotifier.t;
    if (_chatLoading)
      return const Center(
          child:
              CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
    return Column(children: [
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: kSurfaceContainer,
          child: Row(children: [
            const Icon(Icons.person_outline_rounded,
                color: kSecondary, size: 14),
            const SizedBox(width: 6),
            Text('${t("chatting_as")} $_nickname', style: tsBodySm()),
          ])),
      Expanded(
          child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('chats')
                  .doc('${widget.business.id}_$_userId')
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(
                      child: CircularProgressIndicator(
                          color: kSecondary, strokeWidth: 1.5));
                final docs = snapshot.data!.docs;
                if (docs.isEmpty)
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            color: kOnSurfaceVariant, size: 52),
                        const SizedBox(height: 12),
                        Text(t('no_messages'),
                            style: tsBodySm(), textAlign: TextAlign.center),
                      ]));
                return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final isMe = data['userId'] == _userId;
                      final time = data['createdAt'] as Timestamp?;
                      return _buildBubble(
                          text: data['text'] ?? '',
                          nickname: data['nickname'] ?? t('guest'),
                          isMe: isMe,
                          time: time?.toDate());
                    });
              })),
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: kSurfaceContainer,
          child: Row(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: kSurfaceContainerHigh, shape: BoxShape.circle),
                child: const Icon(Icons.add_rounded,
                    color: kOnSurfaceVariant, size: 20)),
            const SizedBox(width: 10),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        color: kSurfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24)),
                    child: TextField(
                        controller: _messageController,
                        style: tsBodyLg(color: kOnSurface),
                        decoration: InputDecoration(
                            hintText: t('type_message'),
                            filled: false,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12)),
                        onSubmitted: (_) => _sendMessage()))),
            const SizedBox(width: 10),
            GestureDetector(
                onTap: _sendMessage,
                child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                        color: kSecondary, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded,
                        color: Color(0xFF1A1200), size: 20))),
          ])),
    ]);
  }

  Widget _buildBubble(
      {required String text,
      required String nickname,
      required bool isMe,
      DateTime? time}) {
    return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72),
          decoration: BoxDecoration(
              color: isMe ? kPrimaryContainer : kSurfaceContainerHigh,
              borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18))),
          child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(nickname,
                    style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isMe ? kOnSurface.withOpacity(0.6) : kSecondary,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(text, style: tsBodyLg()),
                if (time != null) ...[
                  const SizedBox(height: 3),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(DateFormat('HH:mm').format(time),
                        style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 10,
                            color: isMe
                                ? kOnSurface.withOpacity(0.35)
                                : kOnSurfaceVariant.withOpacity(0.4))),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      Icon(Icons.done_all_rounded,
                          size: 12, color: kSecondary.withOpacity(0.6))
                    ],
                  ]),
                ],
              ]),
        ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
