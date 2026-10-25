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
        _businesses = snapshot.where((b) => b.distanceTo(pos.latitude, pos.longitude) <= 50).toList();
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
          // ── Top Bar — NO hamburger, NO profile icon ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
            child: Row(children: [
              // Title sits to the left and shrinks if the buttons need the space
              const Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Habesha Hub',
                      maxLines: 1,
                      style: TextStyle(
                          fontFamily: kFontHeadline,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: kSecondary)),
                ),
              ),
              const SizedBox(width: 8),
              // Language switcher
              _buildLangSwitcher(),
              const SizedBox(width: 8),
              // Theme toggle — sol/måne
              AnimatedBuilder(
                animation: themeNotifier,
                builder: (_, __) => GestureDetector(
                  onTap: () => themeNotifier.toggle(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kCardHigh,
                      shape: BoxShape.circle,
                      border: Border.all(color: kSecondary.withOpacity(0.4)),
                    ),
                    child: Icon(
                      themeNotifier.isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: kSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // AI chat knapp
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1A1200), size: 20),
                ),
              ),
            ]),
          ),

          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Shazam circle + search field ──
                SliverToBoxAdapter(child: _buildShazamSection(t)),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Marketplace banner
                SliverToBoxAdapter(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A3A1A), Color(0xFF2E7D32)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        const Text('🛒', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t('marketplace_title'), style: tsTitleMd(color: Colors.white)),
                          Text(t('marketplace_subtitle'), style: tsBodySm(color: Colors.white70)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
                          child: Text(t('marketplace_browse'), style: tsLabel(color: Colors.white)),
                        ),
                      ]),
                    ),
                  ),
                ),

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
        color: kCard,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: kSecondary.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['ትግርኛ', 'አማ', 'EN'].map((label) {
          final code = label == 'ትግርኛ'
              ? 'Tigrinya'
              : label == 'አማ'
                  ? 'Amharic'
                  : 'English';
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
                              : kTextSub.withOpacity(0.7))
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
        ? 'ኣብዚ ተዊቕካ ኣብ ጥቃኻ ዘሎ ትካላት ርከብ'
        : lang == 'Amharic'
            ? 'በአካባቢ ይፈልጉ'
            : tr('Find Nearby');

    return Column(children: [
      const SizedBox(height: 8),

      // Search text field
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: kCardHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            style: tsBodyLg(color: kText),
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: t('search_hint'),
              hintStyle: tsBodySm(color: kTextSub.withOpacity(0.5)),
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
                : lang == 'Amharic'
                    ? 'በመፈለግ ላይ...'
                    : tr('Searching...'))
            : searchLabel,
        style: tsTitleMd(color: _isSearching ? kSecondary : kTextSub)
            .copyWith(fontSize: 13, letterSpacing: 0.5),
      ),

      const SizedBox(height: 4),
      Text(
        _hasSearched && _position != null
            ? '${_businesses.length} ${lang == "Tigrinya" ? "ትካላት ተረኺቦም" : lang == "Amharic" ? "ድርጅቶች ተገኝተዋል" : tr("businesses found")}'
            : (lang == 'Tigrinya'
                ? 'ኣብዚ ጠዊቅካ ኣብ ቀረባካ ድለ'
                : tr('Tap to search nearby')),
        style: tsBodySm(color: kTextSub.withOpacity(0.5)),
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
    final lang = languageNotifier.language;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Text(
          '${_filtered.length} ${lang == "Tigrinya" ? "ትካላት" : tr("businesses")}',
          style: tsHeadlineSm(color: kSecondary),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _searchNearby,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.refresh_rounded, color: kSecondary, size: 14),
              const SizedBox(width: 5),
              Text(
                  lang == 'Tigrinya'
                      ? 'ሓድስ'
                      : tr('Refresh'),
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
                  : languageNotifier.language == 'Amharic'
                      ? 'ከላይ ያለውን ክበብ ጫኑ የሃበሻ ድርጅቶችን ለማግኘት'
                      : tr('Tap the circle above to find nearby Habesha businesses'),
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

