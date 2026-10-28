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
              child: const Icon(Icons.location_on_rounded, color: kSecondary, size: 34),
            ),
            title: Text(title, textAlign: TextAlign.center, style: tsHeadlineSm(color: kText)),
            content: Text(text, textAlign: TextAlign.center, style: tsBodyLg(color: kTextSub)),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: Text(tr('Not now'), style: tsTitleMd(color: kTextSub))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: kSecondary, foregroundColor: const Color(0xFF1A1200)),
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
    return Stack(children: [
      Positioned.fill(child: CustomPaint(painter: TibebPainter())),
      SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Top bar: logo, theme, AI (language lives in Profile) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
            child: Row(children: [
              const Expanded(
                child: Text('Habesha Hub',
                    maxLines: 1,
                    style: TextStyle(
                        fontFamily: kFontHeadline,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: kSecondary)),
              ),
              _roundBtn(
                themeNotifier.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                () => themeNotifier.toggle(),
              ),
              const SizedBox(width: 10),
              _aiButton(),
            ]),
          ),

          Expanded(
            child: RefreshIndicator(
              color: kSecondary,
              backgroundColor: kCard,
              onRefresh: _searchNearby,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildSearchRow(t)),
                  SliverToBoxAdapter(child: _buildMarketplaceBanner(t)),
                  SliverToBoxAdapter(child: _buildGamesBanner()),
                  if (_hasSearched) ...[
                    SliverToBoxAdapter(child: _buildCategoryChips()),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    SliverToBoxAdapter(child: _buildResultsHeader(t)),
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),
                    _buildResultsSliver(t),
                  ] else if (_isSearching)
                    _buildSkeletons()
                  else
                    SliverToBoxAdapter(child: _buildLocationPrompt()),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  // "AI" in a glowing gold circle, so people notice the assistant
  Widget _aiButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFF2D06B), kSecondary, Color(0xFFB8960C)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: kSecondary.withOpacity(0.25 + _pulseAnim.value * 0.35),
                blurRadius: 8 + _pulseAnim.value * 10,
                spreadRadius: _pulseAnim.value * 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        ),
        child: const Text('AI',
            style: TextStyle(fontFamily: kFontBody, fontSize: 16,
                fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Color(0xFF1A1200))),
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap, {bool filled = false}) {
    return Material(
      color: filled ? kSecondary : kCardHigh,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40, height: 40,
          child: Icon(icon, size: 20, color: filled ? const Color(0xFF1A1200) : kSecondary),
        ),
      ),
    );
  }

  // ── Search field + "Near me" button ──
  Widget _buildSearchRow(String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(color: kCardHighest, borderRadius: BorderRadius.circular(16)),
            child: TextField(
              controller: _searchController,
              style: tsBodyLg(color: kText),
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: t('search_hint'),
                hintStyle: tsBodyLg(color: kTextSub.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search_rounded, color: kSecondary, size: 22),
                suffixIcon: _searchQuery.isEmpty ? null : IconButton(
                  icon: Icon(Icons.close_rounded, color: kTextSub, size: 20),
                  onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; }),
                ),
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: kPrimaryContainer,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _searchNearby,
            child: SizedBox(
              width: 52, height: 52,
              child: _isSearching
                  ? const Padding(padding: EdgeInsets.all(15),
                      child: CircularProgressIndicator(color: kSecondary, strokeWidth: 2.2))
                  : const Icon(Icons.my_location_rounded, color: kSecondary, size: 24),
            ),
          ),
        ),
      ]),
    );
  }

  // Games & Life Tools (web pages opened inside the app)
  Widget _buildGamesBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Material(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesScreen())),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B0000), Color(0xFF3A0A0A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kSecondary.withOpacity(0.4)),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.25), borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: const Text('🎮', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('Games & Tools'), style: tsTitleLg(color: Colors.white)),
                const SizedBox(height: 2),
                Text(tr('Dama, racing, driving theory & test & more'),
                    style: tsBodySm(color: Colors.white70)),
              ])),
              const Icon(Icons.chevron_right_rounded, color: kSecondary),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketplaceBanner(String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Material(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kSecondary.withOpacity(0.25)),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: kSecondary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: const Text('🛍️', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('marketplace_title'), style: tsTitleLg(color: kText)),
                const SizedBox(height: 2),
                Text(t('marketplace_subtitle'), style: tsBodySm(color: kTextSub)),
              ])),
              const Icon(Icons.chevron_right_rounded, color: kSecondary),
            ]),
          ),
        ),
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kPrimaryContainer.withOpacity(0.25),
            border: Border.all(color: kSecondary.withOpacity(0.4)),
          ),
          child: const Icon(Icons.near_me_rounded, color: kSecondary, size: 36),
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
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final selected = _selectedCategory == cat['key'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? kSecondary : kCardHigh,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                    color: selected
                        ? kSecondary
                        : kOutlineVariant.withOpacity(0.1),
                    width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(cat['emoji']!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(_catLabel(cat['key']!),
                    style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            selected ? const Color(0xFF342800) : kText)),
              ]),
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
        Text(tr('Nearby'), style: tsHeadlineSm(color: kText)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: kSecondary.withOpacity(0.15), borderRadius: BorderRadius.circular(100)),
          child: Text('${_filtered.length}', style: tsTitleMd(color: kSecondary)),
        ),
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
      {'icon': Icons.home_rounded,                  'key': 'home',     'label': 'Home'},
      {'icon': Icons.explore_rounded,               'key': 'explore',  'label': 'Explore'},
      {'icon': Icons.miscellaneous_services_rounded,'key': 'services', 'label': 'Services'},
      {'icon': Icons.play_circle_filled_rounded,    'key': 'tok',      'label': 'Hab Tok'},
      {'icon': Icons.person_rounded,                'key': 'profile',  'label': 'Profile'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: kCard.withOpacity(0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
            top: BorderSide(color: kSecondary.withOpacity(0.1), width: 0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -8))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = _currentTab == i;
              return GestureDetector(
                onTap: () => setState(() => _currentTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? kPrimaryContainer.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(items[i]['icon'] as IconData,
                        color:
                            selected ? kSecondary : kText.withOpacity(0.4),
                        size: 22),
                    const SizedBox(height: 2),
                    Text(
                        () {
                          final raw = t(items[i]['key'] as String);
                          // if translation returned the key itself (not found), use fallback label
                          return (raw == items[i]['key']) ? (items[i]['label'] as String) : raw;
                        }(),
                        style: tsLabel(
                            color: selected
                                ? kSecondary
                                : kText.withOpacity(0.4))),
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

