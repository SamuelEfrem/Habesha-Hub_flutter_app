import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../models/business.dart';
import '../services/business_service.dart';
import '../widgets/business_card.dart';
import '../utils/language_notifier.dart';
import '../utils/theme_notifier.dart';
import '../theme/app_theme.dart';
import 'services_screen.dart';
import 'business_detail_screen.dart';
import 'placeholder_screens.dart';
import 'marketplace_screen.dart';
import 'ai_chat_screen.dart';
import 'habesha_tok_screen.dart';
import '../utils/translations.dart';
import 'community_screens.dart';
import 'map_screen.dart';
import '../games/games_screen.dart';
import 'send_money_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final _service = BusinessService();
  final _searchController = TextEditingController();
  late AnimationController _listAnim;
  late AnimationController _pulseAnim;

  int _currentTab = 0;
  String _selectedCategory = 'All';
  Position? _position;
  String _searchQuery = '';
  bool _hasSearched = false;
  bool _isSearching = false;
  List<Business> _businesses = [];

  final _categories = [
    {'key': 'All', 'emoji': '🏠'},
    {'key': 'Restaurant', 'emoji': '🍽️'},
    {'key': 'Shop', 'emoji': '🛒'},
    {'key': 'Cafe', 'emoji': '☕'},
    {'key': 'Club', 'emoji': '🎵'},
    {'key': 'Clinic', 'emoji': '🏥'},
    {'key': 'Barber', 'emoji': '✂'},

    {'key': 'Hotel', 'emoji': '🏨'},
    {'key': 'Church', 'emoji': '⛪'},
    {'key': 'Association', 'emoji': '🤝'},
    {'key': 'Other', 'emoji': '📦'},
  ];

  // Translate category using translations.dart keys
  String _catLabel(String key) {
    // Map Norwegian category name to translation key
    final keyMap = {
      'All': 'all',
      'Restaurant': 'restaurant',
      'Shop': 'shop',
      'Cafe': 'cafe',
      'Barber': 'barber',
      'Club': 'club',
      'Clinic': 'clinic',
      'Hotel': 'cat_hotel',
      'Hotel': 'cat_hotel',
      'Other': 'other',
    };
    final tKey = keyMap[key];
    if (tKey == null) return tr(key);
    return languageNotifier.t(tKey);
  }

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _pulseAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addObserver(this);
    // Every app start: ask for location until it is on, then search
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchNearby());
  }

  bool _askedThisStart = false;   // "Not now" → don't ask again until next start
  bool _waitingForSettings = false;

  // Back from the phone's settings → try again
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForSettings) {
      _waitingForSettings = false;
      _searchNearby();
    }
  }

  /// Location service on + permission given? Otherwise ask (system dialog,
  /// or our dialog that opens the right settings page).
  Future<bool> _ensureLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (_askedThisStart) return false;
      final go = await _locationDialog(
          tr('Turn on location'),
          tr('Habesha Hub needs your location to show Habesha places near you.'));
      if (go) {
        _waitingForSettings = true;
        await Geolocator.openLocationSettings();
      } else {
        _askedThisStart = true;
      }
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      if (_askedThisStart) return false;
      final go = await _locationDialog(
          tr('Allow location'),
          tr('Location is blocked for Habesha Hub. Open settings → Permissions → Location → Allow.'));
      if (go) {
        _waitingForSettings = true;
        await Geolocator.openAppSettings();
      } else {
        _askedThisStart = true;
      }
      return false;
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  Future<bool> _locationDialog(String title, String text) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: kCardHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            icon: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kPrimaryContainer.withOpacity(0.35)),
              child: Icon(Icons.location_on_rounded, color: kSecondary, size: 34),
            ),
            title: Text(title, textAlign: TextAlign.center, style: tsHeadlineSm(color: kText)),
            content: Text(text, textAlign: TextAlign.center, style: tsBodyLg(color: kTextSub)),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: Text(tr('Not now'), style: tsTitleMd(color: kTextSub))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kSecondary, foregroundColor: kOnAccent),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('Turn on'), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listAnim.dispose();
    _pulseAnim.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchNearby() async {
    if (_isSearching) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isSearching = true;
    });
    try {
      if (!await _ensureLocation()) {
        if (mounted) setState(() => _isSearching = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _position = pos);
      final snapshot = await _service.getBusinessesNear(pos.latitude, pos.longitude);
      snapshot.sort((a, b) => a
          .distanceTo(pos.latitude, pos.longitude)
          .compareTo(b.distanceTo(pos.latitude, pos.longitude)));
      setState(() {
        _businesses = snapshot;
        _hasSearched = true;
        _isSearching = false;
      });
      _listAnim.forward(from: 0);
    } catch (e) {
      print('GPS Error: ' + e.toString());
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Location error: ' + e.toString()),
          backgroundColor: kRed,
        ));
      }
    }
  }

  List<Business> get _filtered {
    var list = _businesses;
    if (_selectedCategory != 'All') {
      list = list.where((b) => b.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((b) =>
              b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              b.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) {
        final t = languageNotifier.t;
        return Scaffold(
          backgroundColor: kBg,
          body: IndexedStack(
            index: _currentTab,
            children: [
              _buildHomeTab(t),
              const ExploreScreen(),
              const ServicesScreen(),
              // visible=false pauses the video when the user leaves the Hab Tok tab
              HabeshaTokScreen(visible: _currentTab == 3),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(t),
        );
      },
    );
  }

  Widget _buildHomeTab(String Function(String) t) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: kSecondary,
        backgroundColor: kBg,
        onRefresh: _searchNearby,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildTopBar()),
            SliverToBoxAdapter(child: _buildGreeting()),
            SliverToBoxAdapter(child: _buildSearchRow(t)),
            SliverToBoxAdapter(child: _buildShortcuts(t)),
            if (_hasSearched) ...[
              SliverToBoxAdapter(child: _buildResultsHeader(t)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildCategoryChips()),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              _buildResultsSliver(t),
            ] else if (_isSearching)
              _buildSkeletons()
            else
              SliverToBoxAdapter(child: _buildLocationPrompt()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ── Logo + name, then language and light/dark on the right ──
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        habeshaLogo(size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Text('Habesha Hub',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: kFontHeadline, fontSize: 18, fontWeight: FontWeight.w800, color: kText)),
        ),
        _languageButton(),
        const SizedBox(width: 8),
        _roundBtn(
          themeNotifier.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          () => themeNotifier.toggle(),
          tooltip: themeNotifier.isDark ? tr('Light mode') : tr('Dark mode'),
        ),
      ]),
    );
  }

  static const _langs = [
    {'code': 'English', 'short': 'EN', 'label': 'English'},
    {'code': 'Tigrinya', 'short': 'ትግ', 'label': 'ትግርኛ'},
    {'code': 'Amharic', 'short': 'አማ', 'label': 'አማርኛ'},
  ];

  Widget _languageButton() {
    final current = _langs.firstWhere((l) => l['code'] == languageNotifier.language, orElse: () => _langs.first);
    return PopupMenuButton<String>(
      tooltip: tr('Choose language'),
      position: PopupMenuPosition.under,
      color: kBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (code) => languageNotifier.setLanguage(code),
      itemBuilder: (_) => [
        for (final l in _langs)
          PopupMenuItem<String>(
            value: l['code'],
            height: 48,
            child: Row(children: [
              Expanded(child: Text(l['label']!, style: tsTitleMd(color: kText).copyWith(fontSize: 15))),
              if (l['code'] == current['code']) Icon(Icons.check_rounded, color: kSecondary, size: 20),
            ]),
          ),
      ],
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(22)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.translate_rounded, size: 18, color: kText),
          const SizedBox(width: 6),
          Text(current['short']!, style: tsTitleMd(color: kText)),
        ]),
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap, {String? tooltip}) {
    final btn = Material(
      color: kCard,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 22, color: kText)),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip, child: btn);
  }

  // ── ሰላም, name ──
  Widget _buildGreeting() {
    final name = (FirebaseAuth.instance.currentUser?.displayName ?? '').trim().split(' ').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Text(name.isEmpty ? 'ሰላም!' : 'ሰላም, $name',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: kFontHeadline, fontSize: 30, fontWeight: FontWeight.w800,
              letterSpacing: -0.5, height: 1.2, color: kText)),
    );
  }

  // ── Search field + "Near me" button ──
  Widget _buildSearchRow(String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(27)),
            child: TextField(
              controller: _searchController,
              style: tsBodyLg(color: kText).copyWith(fontSize: 15),
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: t('search_hint'),
                hintStyle: tsBodyLg(color: kTextSub).copyWith(fontSize: 15),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.search_rounded, color: kTextSub, size: 22),
                ),
                suffixIcon: _searchQuery.isEmpty ? null : IconButton(
                  icon: Icon(Icons.close_rounded, color: kTextSub, size: 20),
                  onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; }),
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: tr('Nearby'),
          child: Material(
            color: kSecondary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _searchNearby,
              child: SizedBox(
                width: 54, height: 54,
                child: _isSearching
                    ? Padding(padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(color: kOnAccent, strokeWidth: 2.2))
                    : Icon(Icons.my_location_rounded, color: kOnAccent, size: 24),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Round shortcuts to every part of the app ──
  Widget _buildShortcuts(String Function(String) t) {
    void push(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    final items = <(IconData, String, Color, Color, VoidCallback)>[
      (Icons.explore_outlined, tr('Explore'), kTintGreen, kInkGreen, () => setState(() => _currentTab = 1)),
      (Icons.work_outline_rounded, tr('Services'), kTintYellow, kInkYellow, () => setState(() => _currentTab = 2)),
      (Icons.smart_display_outlined, tr('Hab Tok'), kTintRed, kInkRed, () => setState(() => _currentTab = 3)),
      (Icons.shopping_bag_outlined, tr('Market'), kTintBlue, kInkBlue, () => push(const MarketplaceScreen())),
      (Icons.chat_bubble_outline_rounded, tr('Habesha AI'), kTintBlue, kInkBlue, () => push(const AiChatScreen())),
      (Icons.directions_car_outlined, tr('Driving'), kTintRed, kInkRed,
          () => GamesScreen.openPage(context, 'Life Tools', 'life-tools')),
      (Icons.send_outlined, tr('Send money'), kTintYellow, kInkYellow, () => push(const SendMoneyScreen())),
      (Icons.sports_esports_outlined, tr('Games'), kTintGreen, kInkGreen, () => push(const GamesScreen())),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 26),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14,
        crossAxisSpacing: 4,
        childAspectRatio: 0.9,
        children: [
          for (final it in items)
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () { HapticFeedback.selectionClick(); it.$5(); },
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 62, height: 62,
                  decoration: BoxDecoration(color: it.$3, shape: BoxShape.circle),
                  child: Icon(it.$1, color: it.$4, size: 27),
                ),
                const SizedBox(height: 7),
                Text(it.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: kFontBody, fontSize: 12, fontWeight: FontWeight.w600, color: kText)),
              ]),
            ),
        ],
      ),
    );
  }

  // Shown before the first search (location not allowed yet)
  Widget _buildLocationPrompt() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(children: [
        Container(
          width: 84, height: 84,
          decoration: BoxDecoration(shape: BoxShape.circle, color: kTintGreen),
          child: Icon(Icons.near_me_outlined, color: kInkGreen, size: 36),
        ),
        const SizedBox(height: 18),
        Text(tr('Allow location to see Habesha businesses near you'),
            textAlign: TextAlign.center, style: tsTitleLg(color: kText)),
        const SizedBox(height: 18),
        SizedBox(width: 220, child: goldButton(tr('Allow location'), _searchNearby, icon: Icons.my_location_rounded)),
      ]),
    );
  }

  // Grey placeholder cards while loading
  Widget _buildSkeletons() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((_, i) => AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) => Opacity(
          opacity: 0.45 + _pulseAnim.value * 0.35,
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: kCardLow, borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              Container(width: 56, height: 56,
                  decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(14))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 14, width: 160, color: kCardHigh),
                const SizedBox(height: 8),
                Container(height: 10, width: 100, color: kCardHigh),
                const SizedBox(height: 6),
                Container(height: 10, width: 200, color: kCardHigh),
              ])),
            ]),
          ),
        ),
      ), childCount: 5),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final selected = _selectedCategory == cat['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: selected ? kSecondary : kCard,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => setState(() => _selectedCategory = cat['key']!),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Text(_catLabel(cat['key']!),
                        style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                            color: selected ? kOnAccent : kText)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsHeader(String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Text(tr('Nearby'), style: TextStyle(fontFamily: kFontHeadline, fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
        const SizedBox(width: 8),
        Text('${_filtered.length}', style: tsTitleMd(color: kTextSub)),
        const Spacer(),
        if (_filtered.isNotEmpty)
          mapButton(() => Navigator.push(context, MaterialPageRoute(
              builder: (_) => BusinessesMapScreen(
                    businesses: _filtered,
                    title: tr('Nearby'),
                    userLat: _position?.latitude,
                    userLng: _position?.longitude,
                  )))),
      ]),
    );
  }

  SliverList _buildResultsSliver(String Function(String) t) {
    final list = _filtered;
    if (list.isEmpty) {
      return SliverList(
          delegate: SliverChildListDelegate([
        const SizedBox(height: 30),
        Icon(Icons.storefront_rounded, color: kTextSub.withOpacity(0.5), size: 44),
        const SizedBox(height: 10),
        Center(child: Text(
            _businesses.isEmpty ? tr('No Habesha businesses within 50 km yet') : tr('Nothing here yet'),
            textAlign: TextAlign.center, style: tsTitleMd(color: kText))),
        const SizedBox(height: 4),
        Center(child: Text(
            _businesses.isEmpty ? tr('Browse by country in Explore') : tr('Try another category or city'),
            style: tsBodySm(color: kTextSub))),
        const SizedBox(height: 8),
        Center(child: suggestBusinessButton(context)),
      ]));
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final b = list[i];
          final anim = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
                parent: _listAnim,
                curve: Interval(
                    (i * 0.08).clamp(0, 0.6), ((i * 0.08) + 0.4).clamp(0, 1),
                    curve: Curves.easeOutCubic)),
          );
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
                      .animate(anim),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: BusinessCard(
                  business: b,
                  userLat: _position?.latitude ?? 59.9139,
                  userLng: _position?.longitude ?? 10.7522,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BusinessDetailScreen(
                                business: b,
                                userLat: _position?.latitude ?? 59.9139,
                                userLng: _position?.longitude ?? 10.7522,
                              ))),
                ),
              ),
            ),
          );
        },
        childCount: list.length,
      ),
    );
  }

  Widget _buildBottomNav(String Function(String) t) {
    // key = translation key; label = fallback if key not found
    final items = [
      {'icon': Icons.home_outlined, 'on': Icons.home_rounded, 'key': 'home', 'label': 'Home'},
      {'icon': Icons.explore_outlined, 'on': Icons.explore_rounded, 'key': 'explore', 'label': 'Explore'},
      {'icon': Icons.work_outline_rounded, 'on': Icons.work_rounded, 'key': 'services', 'label': 'Services'},
      {'icon': Icons.smart_display_outlined, 'on': Icons.smart_display_rounded, 'key': 'tok', 'label': 'Hab Tok'},
      {'icon': Icons.person_outline_rounded, 'on': Icons.person_rounded, 'key': 'profile', 'label': 'Profile'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: themeNotifier.isDark ? const Color(0xFF181818) : Colors.white,
        border: themeNotifier.isDark ? const Border(top: BorderSide(color: Color(0xFF2C2C2C))) : null,
        boxShadow: themeNotifier.isDark
            ? null
            : [BoxShadow(color: const Color(0xFF1B1B1B).withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = _currentTab == i;
              final color = selected ? kSecondary : kTextSub;
              final raw = t(items[i]['key'] as String);
              final label = (raw == items[i]['key']) ? (items[i]['label'] as String) : raw;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _currentTab = i),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon((selected ? items[i]['on'] : items[i]['icon']) as IconData, color: color, size: 25),
                    const SizedBox(height: 4),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: kFontBody,
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: color)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
