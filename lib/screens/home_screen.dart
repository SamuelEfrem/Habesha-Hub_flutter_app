import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import '../models/business.dart';
import '../services/business_service.dart';
import '../widgets/business_card.dart';
import '../utils/language_notifier.dart';
import '../theme/app_theme.dart';
import 'business_detail_screen.dart';
import 'placeholder_screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _service = BusinessService();
  final _searchController = TextEditingController();
  late AnimationController _listAnim;
  late AnimationController _pulseAnim;

  int _currentTab = 0;
  String _selectedCategory = 'Alle';
  Position? _position;
  String _searchQuery = '';
  bool _hasSearched = false;
  bool _isSearching = false;
  List<Business> _businesses = [];

  final _categories = [
    {'key': 'Alle', 'emoji': '🏠'},
    {'key': 'Restaurant', 'emoji': '🍽️'},
    {'key': 'Butikk', 'emoji': '🛒'},
    {'key': 'Kafé', 'emoji': '☕'},
    {'key': 'Frisør', 'emoji': '💇'},
    {'key': 'Club', 'emoji': '🎵'},
    {'key': 'Klinikk', 'emoji': '🏥'},
  ];

  // Translate category using translations.dart keys
  String _catLabel(String key) {
    // Map Norwegian category name to translation key
    const keyMap = {
      'Alle': 'all',
      'Restaurant': 'restaurant',
      'Butikk': 'shop',
      'Kafé': 'cafe',
      'Frisør': 'barber',
      'Club': 'club',
      'Klinikk': 'clinic',
      'Annet': 'other',
    };
    final tKey = keyMap[key];
    if (tKey == null) return key;
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
  }

  @override
  void dispose() {
    _listAnim.dispose();
    _pulseAnim.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchNearby() async {
    if (_isSearching) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isSearching = true;
    });
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _isSearching = false);
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          setState(() => _isSearching = false);
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _position = pos);
      final snapshot = await _service.getBusinessesOnce();
      snapshot.sort((a, b) => a
          .distanceTo(pos.latitude, pos.longitude)
          .compareTo(b.distanceTo(pos.latitude, pos.longitude)));
      setState(() {
        _businesses = snapshot;
        _hasSearched = true;
        _isSearching = false;
      });
      _listAnim.forward(from: 0);
    } catch (_) {
      setState(() => _isSearching = false);
    }
  }

  List<Business> get _filtered {
    var list = _businesses;
    if (_selectedCategory != 'Alle') {
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
      animation: languageNotifier,
      builder: (context, _) {
        final t = languageNotifier.t;
        return Scaffold(
          backgroundColor: kSurface,
          body: IndexedStack(
            index: _currentTab,
            children: [
              _buildHomeTab(t),
              const ExploreScreen(),
              const ChatListScreen(),
              const FavoritesScreen(),
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
          // ── Top Bar — NO hamburger, NO profile icon ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(children: [
              Text('Habesha Hub',
                  style: TextStyle(
                      fontFamily: kFontHeadline,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: kSecondary)),
              const Spacer(),
              // Language switcher — works for guests too
              _buildLangSwitcher(),
            ]),
          ),

          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Shazam circle + search field ──
                SliverToBoxAdapter(child: _buildShazamSection(t)),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                if (_hasSearched) ...[
                  // Category chips
                  SliverToBoxAdapter(child: _buildCategoryChips()),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  // Results count + refresh
                  SliverToBoxAdapter(child: _buildResultsHeader(t)),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  // Results list
                  _buildResultsSliver(t),
                ] else
                  SliverFillRemaining(child: _buildEmptyHint(t)),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ]),
      ),
    ]);
  }

  // ── Language switcher (top right, no profile icon) ────────────────────
  Widget _buildLangSwitcher() {
    final lang = languageNotifier.language;
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceContainer,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: kSecondary.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Norsk', 'ትግርኛ', 'EN'].map((label) {
          final code = label == 'ትግርኛ'
              ? 'Tigrinya'
              : label == 'EN'
                  ? 'English'
                  : 'Norsk';
          final active = lang == code;
          return GestureDetector(
            onTap: () => languageNotifier.setLanguage(code),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: active ? kSecondary : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(label,
                  style: tsLabel(
                          color: active
                              ? const Color(0xFF1A1200)
                              : kOnSurfaceVariant.withOpacity(0.7))
                      .copyWith(fontSize: 10)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Shazam-style section ─────────────────────────────────────────────
  Widget _buildShazamSection(String Function(String) t) {
    final lang = languageNotifier.language;
    // "Finn her" in Tigrinya, "Find here" in English, "Finn her" in Norwegian
    final searchLabel = lang == 'Tigrinya'
        ? 'ኣብ ቀረባካ ድለ'
        : lang == 'English'
            ? 'Find Nearby'
            : 'Finn her';

    return Column(children: [
      const SizedBox(height: 8),

      // Search text field
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: kSurfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            style: tsBodyLg(color: kOnSurface),
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: t('search_hint'),
              hintStyle: tsBodySm(color: kOnSurfaceVariant.withOpacity(0.5)),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: kSecondary, size: 22),
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),

      const SizedBox(height: 28),

      // ── Shazam Circle Button ──
      GestureDetector(
        onTap: _searchNearby,
        child: Stack(alignment: Alignment.center, children: [
          // Outer pulse rings
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) {
              if (_isSearching) {
                return Stack(alignment: Alignment.center, children: [
                  Container(
                    width: 130 + (_pulseAnim.value * 30),
                    height: 130 + (_pulseAnim.value * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimaryContainer
                          .withOpacity(0.15 - (_pulseAnim.value * 0.1)),
                    ),
                  ),
                  Container(
                    width: 110 + (_pulseAnim.value * 20),
                    height: 110 + (_pulseAnim.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPrimaryContainer
                          .withOpacity(0.2 - (_pulseAnim.value * 0.1)),
                    ),
                  ),
                ]);
              }
              // Idle: subtle pulse
              return Container(
                width: 116 + (_pulseAnim.value * 8),
                height: 116 + (_pulseAnim.value * 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      kSecondary.withOpacity(0.08 - (_pulseAnim.value * 0.04)),
                ),
              );
            },
          ),

          // Inner circle button
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                kPrimaryContainer,
                kPrimaryContainer.withOpacity(0.8),
              ]),
              boxShadow: [
                BoxShadow(
                    color: kPrimaryContainer.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2),
                BoxShadow(
                    color: kSecondary.withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 5),
              ],
              border:
                  Border.all(color: kSecondary.withOpacity(0.4), width: 1.5),
            ),
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(
                        color: kSecondary, strokeWidth: 2.5))
                : const Icon(Icons.my_location_rounded,
                    color: kSecondary, size: 38),
          ),
        ]),
      ),

      const SizedBox(height: 14),

      // Label under circle
      Text(
        _isSearching
            ? (lang == 'Tigrinya'
                ? 'ይደልይ ኣሎ...'
                : lang == 'English'
                    ? 'Searching...'
                    : 'Søker...')
            : searchLabel,
        style: tsTitleMd(color: _isSearching ? kSecondary : kOnSurfaceVariant)
            .copyWith(fontSize: 13, letterSpacing: 0.5),
      ),

      const SizedBox(height: 4),
      Text(
        _hasSearched && _position != null
            ? '${_businesses.length} ${lang == "Tigrinya" ? "ትካላት ተረኺቦም" : lang == "English" ? "businesses found" : "bedrifter funnet"}'
            : (lang == 'Tigrinya'
                ? 'ኣብዚ ጠዊቅካ ኣብ ቀረባካ ድለ'
                : lang == 'English'
                    ? 'Tap to search nearby'
                    : 'Trykk for å søke i nærheten'),
        style: tsBodySm(color: kOnSurfaceVariant.withOpacity(0.5)),
      ),

      const SizedBox(height: 8),
    ]);
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
                color: selected ? kSecondary : kSurfaceContainerHigh,
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
                            selected ? const Color(0xFF342800) : kOnSurface)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsHeader(String Function(String) t) {
    final lang = languageNotifier.language;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Text(
          '${_filtered.length} ${lang == "Tigrinya" ? "ትካላት" : lang == "English" ? "businesses" : "bedrifter"}',
          style: tsHeadlineSm(color: kSecondary),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _searchNearby,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kSurfaceContainer,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.refresh_rounded, color: kSecondary, size: 14),
              const SizedBox(width: 5),
              Text(
                  lang == 'Tigrinya'
                      ? 'ሓድስ'
                      : lang == 'English'
                          ? 'Refresh'
                          : 'Oppdater',
                  style: tsLabel()),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptyHint(String Function(String) t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(height: 20),
          Text(
              languageNotifier.language == 'Tigrinya'
                  ? 'ኣብቲ ኣብ ላዕሊ ዘሎ ክቢ ብምጥዋቅ ኣብ ጥቃካ ዝሎ ናይ ሓበሻ ትካላት ርኸብ'
                  : languageNotifier.language == 'English'
                      ? 'Tap the circle above to find nearby Habesha businesses'
                      : 'Trykk på sirkelen ovenfor for å finne Habesha bedrifter i nærheten',
              style: tsBodySm(),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  SliverList _buildResultsSliver(String Function(String) t) {
    final list = _filtered;
    if (list.isEmpty) {
      return SliverList(
          delegate: SliverChildListDelegate([
        const SizedBox(height: 40),
        Center(child: Text(t('no_businesses'), style: tsBodySm())),
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
    final items = [
      {'icon': Icons.home_rounded, 'key': 'home'},
      {'icon': Icons.explore_rounded, 'key': 'explore'},
      {'icon': Icons.chat_bubble_rounded, 'key': 'chat'},
      {'icon': Icons.favorite_rounded, 'key': 'favorites'},
      {'icon': Icons.person_rounded, 'key': 'profile'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceContainer.withOpacity(0.97),
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
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? kPrimaryContainer.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(items[i]['icon'] as IconData,
                        color:
                            selected ? kSecondary : kOnSurface.withOpacity(0.4),
                        size: 22),
                    const SizedBox(height: 2),
                    Text(t(items[i]['key'] as String),
                        style: tsLabel(
                            color: selected
                                ? kSecondary
                                : kOnSurface.withOpacity(0.4))),
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
