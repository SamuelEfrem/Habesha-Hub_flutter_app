import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/business.dart';
import '../widgets/business_card.dart';
import '../utils/language_notifier.dart';
import '../utils/theme_notifier.dart';
import '../theme/app_theme.dart';
import 'business_detail_screen.dart';
import 'register_business_screen.dart';
import 'favorites_screen.dart';
import 'auth_screen.dart';
import 'admin_screen.dart';
import 'edit_business_screen.dart';
import '../utils/translations.dart';
import 'payment.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _db = FirebaseFirestore.instance;

  Future<void> _globalSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isSearching = true; _hasSearched = false; });
    try {
      final snap = await _db.collection('businesses')
          .where('status', isEqualTo: 'approved')
          .get();
      final all = snap.docs.map((d) => Business.fromFirestore(d.data(), d.id)).toList();
      final filtered = all.where((b) =>
        b.name.toLowerCase().contains(query.toLowerCase()) ||
        b.category.toLowerCase().contains(query.toLowerCase()) ||
        b.address.toLowerCase().contains(query.toLowerCase()) ||
        b.country.toLowerCase().contains(query.toLowerCase())
      ).toList();
      setState(() {
        _allResults = filtered;
        _results = filtered;
        _isSearching = false;
        _hasSearched = true;
        _selectedCountry = '';
        _selectedCity = '';
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  String _explorecat(String key) {
    final keyMap = {
      'All': 'all',
      'Restaurant': 'restaurant',
      'Cafe': 'cafe',
      'Shop': 'shop',
      'Barber': 'barber',
      'Club': 'club',
      'Clinic': 'clinic',
      'Photographer': 'cat_photographer',
      'Music': 'cat_music',
      'Decoration': 'cat_decoration',
      'Taxi': 'cat_taxi',
      'Hotel': 'cat_hotel',
      'Hotel': 'cat_hotel',
      'Other': 'other',
    };
    final tKey = keyMap[key];
    if (tKey == null) return key;
    return languageNotifier.t(tKey);
  }
  String _selectedCountry = '';
  String _selectedCity = '';
  String _searchQuery = '';
  String _selectedCategory = '';
  List<Business> _results = [];
  List<Business> _allResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _selectedContinent = '';

  final _continents = [
    {
      'name': 'Africa',
      'emoji': '🌍',
      'countries': [
        {'name': 'Uganda', 'flag': '🇺🇬', 'label': 'country_uganda', 'cities': ['Kampala', 'Entebbe', 'Jinja']},
        {'name': 'Angola', 'flag': '🇦🇴', 'label': 'country_angola', 'cities': ['Luanda', 'Huambo', 'Benguela']},
        {'name': 'South Sudan', 'flag': '🇸🇸', 'label': 'country_south_sudan', 'cities': ['Juba', 'Wau', 'Malakal']},
        {'name': 'Rwanda', 'flag': '🇷🇼', 'label': 'country_rwanda', 'cities': ['Kigali', 'Butare', 'Gisenyi']},
        {'name': 'Kenya', 'flag': '🇰🇪', 'label': 'country_kenya', 'cities': ['Nairobi', 'Mombasa', 'Kisumu']},
        {'name': 'Ethiopia', 'flag': '🇪🇹', 'label': 'country_ethiopia', 'cities': ['Addis Ababa', 'Dire Dawa', 'Mekelle']},
        {'name': 'Eritrea', 'flag': '🇪🇷', 'label': 'country_eritrea', 'cities': ['Asmara', 'Massawa', 'Keren']},
        {'name': 'Egypt', 'flag': '🇪🇬', 'label': 'country_egypt', 'cities': ['Cairo', 'Alexandria', 'Giza']},
      ]
    },
    {
      'name': 'Europe',
      'emoji': '🌍',
      'countries': [
        {'name': 'Norway', 'flag': '🇳🇴', 'label': 'country_norge', 'cities': ['Oslo', 'Bergen', 'Stavanger', 'Trondheim']},
        {'name': 'Sweden', 'flag': '🇸🇪', 'label': 'country_sverige', 'cities': ['Stockholm', 'Göteborg', 'Malmö']},
        {'name': 'Denmark', 'flag': '🇩🇰', 'label': 'country_danmark', 'cities': ['København', 'Aarhus', 'Odense']},
        {'name': 'UK', 'flag': '🇬🇧', 'label': 'country_uk', 'cities': ['London', 'Manchester', 'Birmingham', 'Leeds']},
        {'name': 'Germany', 'flag': '🇩🇪', 'label': 'country_tyskland', 'cities': ['Berlin', 'Hamburg', 'München']},
        {'name': 'Netherlands', 'flag': '🇳🇱', 'label': 'country_nederland', 'cities': ['Amsterdam', 'Rotterdam', 'Den Haag']},
        {'name': 'France', 'flag': '🇫🇷', 'label': 'country_frankrike', 'cities': ['Paris', 'Lyon', 'Marseille']},
        {'name': 'Belgium', 'flag': '🇧🇪', 'label': 'country_belgia', 'cities': ['Brussel', 'Antwerpen', 'Gent']},
        {'name': 'Switzerland', 'flag': '🇨🇭', 'label': 'country_sveits', 'cities': ['Zürich', 'Genève', 'Basel']},
        {'name': 'Italy', 'flag': '🇮🇹', 'label': 'country_italia', 'cities': ['Roma', 'Milano', 'Napoli']},
      ]
    },
    {
      'name': 'Americas',
      'emoji': '🌎',
      'countries': [
        {'name': 'USA', 'flag': '🇺🇸', 'label': 'country_usa', 'cities': ['New York', 'Washington DC', 'Los Angeles', 'Minneapolis']},
        {'name': 'Canada', 'flag': '🇨🇦', 'label': 'country_canada', 'cities': ['Toronto', 'Ottawa', 'Vancouver']},
      ]
    },
  ];

  List<Map<String, Object>> get _countries {
    if (_selectedContinent.isEmpty) return [];
    final cont = _continents.firstWhere((c) => c['name'] == _selectedContinent, orElse: () => {'countries': []});
    return List<Map<String, Object>>.from(cont['countries'] as List);
  }

  List<String> get _cities {
    final c = _countries.firstWhere((c) => c['name'] == _selectedCountry, orElse: () => {'name': '', 'flag': '', 'label': '', 'cities': <String>[]});
    final cities = c['cities'];
    if (cities == null) return [];
    return List<String>.from(cities as List);
  }

  Future<void> _search() async {
    if (_selectedCountry.isEmpty) return;
    setState(() { _isSearching = true; _hasSearched = false; });
    try {
      final snap = await _db.collection('businesses')
          .where('status', isEqualTo: 'approved')
          .where('country', isEqualTo: _selectedCountry)
          .get();
      final all = snap.docs.map((d) => Business.fromFirestore(d.data(), d.id)).toList();
      setState(() { _allResults = all; _isSearching = false; _hasSearched = true; });
      _filterResults();
    } catch (e) {
      setState(() { _isSearching = false; _hasSearched = true; });
    }
  }

  void _filterResults() {
    var filtered = List<Business>.from(_allResults);
    if (_selectedCity.isNotEmpty) {
      filtered = filtered.where((b) => b.address.toLowerCase().contains(_selectedCity.toLowerCase())).toList();
    }
    if (_selectedCategory.isNotEmpty) {
      filtered = filtered.where((b) => b.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((b) =>
        b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        b.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        b.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    setState(() => _results = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        return Scaffold(
          backgroundColor: kBg,
          body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(color: kCardHighest, borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  style: tsBodyLg(color: kText),
                  onChanged: (v) { setState(() => _searchQuery = v); if (_hasSearched) _filterResults(); },
                  onSubmitted: (v) => _globalSearch(v),
                  decoration: InputDecoration(
                    hintText: t('search_hint'),
                    hintStyle: tsBodySm(color: kTextSub.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search_rounded, color: kSecondary, size: 22),
                    filled: false, border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _continents.length,
                itemBuilder: (_, i) {
                  final cont = _continents[i];
                  final sel = _selectedContinent == cont['name'];
                  return GestureDetector(
                    onTap: () => setState(() { _selectedContinent = cont['name'] as String; _selectedCountry = ''; _selectedCity = ''; _hasSearched = false; _results = []; _allResults = []; }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: sel ? kSecondary : kCard, borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(cont['emoji'] as String, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(tr(cont['name'] as String), style: tsLabel(color: sel ? Color(0xFF342800) : kTextSub)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedContinent.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _countries.length,
                  itemBuilder: (_, i) {
                    final c = _countries[i];
                    final sel = _selectedCountry == c['name'];
                    return GestureDetector(
                      onTap: () { setState(() { _selectedCountry = c['name'] as String; _selectedCity = ''; _selectedCategory = ''; }); _search(); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? kPrimaryContainer.withOpacity(0.3) : kCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? kSecondary : Colors.transparent, width: 0.5),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(c['flag'] as String, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(tr(c['name'] as String), style: tsLabel(color: sel ? kSecondary : kTextSub.withOpacity(0.8))),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            if (_selectedCountry.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _cities.length + 1,
                  itemBuilder: (_, i) {
                    final city = i == 0 ? t('all_cities') : _cities[i - 1];
                    final sel = i == 0 ? _selectedCity.isEmpty : _selectedCity == _cities[i - 1];
                    return GestureDetector(
                      onTap: () { setState(() => _selectedCity = i == 0 ? '' : _cities[i - 1]); if (_hasSearched) _filterResults(); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: sel ? kSecondary : kCard, borderRadius: BorderRadius.circular(100)),
                        child: Text(city, style: tsLabel(color: sel ? Color(0xFF342800) : kTextSub)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['All', 'Restaurant', 'Cafe', 'Shop', 'Barber', 'Club', 'Clinic', 'Hotel', 'Photographer', 'Music', 'Decoration', 'Taxi', 'Other'].map((cat) {
                    final sel = cat == 'All' ? _selectedCategory.isEmpty : _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () { setState(() => _selectedCategory = cat == 'All' ? '' : cat); if (_hasSearched) _filterResults(); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: sel ? kSecondary : kCard, borderRadius: BorderRadius.circular(100)),
                        child: Text(_explorecat(cat), style: tsLabel(color: sel ? Color(0xFF342800) : kTextSub)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: goldButton(
                  '${t('search_in')} ${tr(_selectedCountry)}${_selectedCity.isNotEmpty ? " / $_selectedCity" : ""}',
                  _isSearching ? null : _search, loading: _isSearching),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: !_hasSearched
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('🌍', style: TextStyle(fontSize: 56)),
                      const SizedBox(height: 16),
                      Text(t('select_country'), style: tsTitleLg(), textAlign: TextAlign.center),
                    ]))
                  : _results.isEmpty
                      ? Center(child: Text(t('no_businesses_country'), style: tsBodySm()))
                      : RefreshIndicator(
                          color: kSecondary,
                          backgroundColor: kCard,
                          onRefresh: _search,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _results.length,
                            itemBuilder: (_, i) {
                              final b = _results[i];
                              return BusinessCard(
                                business: b, userLat: 0, userLng: 0,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: b, userLat: 0, userLng: 0))));
                            },
                          ),
                        ),
            ),
          ])),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PROFILE SCREEN
// ═══════════════════════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nicknameCtrl = TextEditingController();
  String _selectedLang = 'English';
  bool _saved = false;
  User? _user;
  List<Business> _myBusinesses = [];
  bool _loadingBiz = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _user = FirebaseAuth.instance.currentUser;
    setState(() {
      _nicknameCtrl.text = _user?.displayName ?? prefs.getString('nickname') ?? '';
      _selectedLang = languageNotifier.language;
    });
    if (_user != null) _loadMyBusinesses();
  }

  Future<void> _loadMyBusinesses() async {
    if (_user == null) return;
    setState(() => _loadingBiz = true);
    try {
      final snap = await FirebaseFirestore.instance.collection('businesses').where('ownerId', isEqualTo: _user!.uid).get();
      setState(() {
        _myBusinesses = snap.docs.map((d) => Business.fromFirestore(d.data(), d.id)).toList();
        _loadingBiz = false;
      });
    } catch (_) { setState(() => _loadingBiz = false); }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: kCardHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(tr('Log out'), style: tsHeadlineSm(color: kText)),
      content: Text(tr('Are you sure you want to log out?'), style: tsBodyLg()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('Cancel'), style: tsBodySm())),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('Log out'), style: tsTitleMd(color: kRed))),
      ],
    ));
    if (confirm != true) return;
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nickname');
    await prefs.remove('favorites');
    await languageNotifier.setLanguage('English');
    if (mounted) {
      setState(() { _user = null; _nicknameCtrl.text = ''; _selectedLang = 'English'; _myBusinesses = []; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('You are logged out'), style: tsBodySm(color: kText)), backgroundColor: kCardHigh));
    }
  }

  Future<void> _deleteAccount() async {
    final t = languageNotifier.t;
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: kCardHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(t('delete_account'), style: tsHeadlineSm(color: kRed)),
      content: Text(t('delete_account_confirm'), style: tsBodyLg()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('cancel'), style: tsBodySm())),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t('delete_account'), style: tsTitleMd(color: kRed))),
      ],
    ));
    if (confirm != true) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      await user.delete();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        setState(() { _user = null; _nicknameCtrl.text = ''; _myBusinesses = []; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Account deleted'), style: tsBodySm(color: kText)), backgroundColor: kCardHigh));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Error: please log in again and try again.'), style: tsBodySm(color: kText)), backgroundColor: kRed));
    }
  }

  Future<void> _login() async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AuthScreen(returnOnLogin: true)));
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        final isLoggedIn = _user != null;
        return Scaffold(
          backgroundColor: kBg,
          body: SafeArea(child: SingleChildScrollView(child: Column(children: [
            Container(
              width: double.infinity,
              color: kCardLow,
              child: Column(children: [
                const SizedBox(height: 20),
                Stack(children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kSecondary, width: 2.5), boxShadow: [BoxShadow(color: kSecondary.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)]),
                    child: ClipOval(child: Image.asset('assets/images/icon.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: kCardHigh, child: Icon(Icons.person_rounded, size: 56, color: kSecondary)))),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(_nicknameCtrl.text.isEmpty ? (isLoggedIn ? tr('User') : tr('Guest')) : _nicknameCtrl.text, style: tsHeadlineMd()),
                const SizedBox(height: 4),
                Text(isLoggedIn ? (_user?.email ?? '') : tr('Log in for full access'), style: tsBodySm(color: kTextSub.withOpacity(0.6)), textAlign: TextAlign.center),
                const SizedBox(height: 20),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Text(t('nickname').toUpperCase(), style: tsLabel()),
                const SizedBox(height: 8),
                TextField(
                  controller: _nicknameCtrl,
                  style: tsBodyLg(color: kText),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (val) async {
                    final name = val.trim();
                    if (name.isEmpty) return;
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('nickname', name);
                    await _user?.updateDisplayName(name);
                  },
                  decoration: InputDecoration(
                    hintText: t('nickname_hint'),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: kSecondary),
                    suffixIcon: const Icon(Icons.check_circle_outline_rounded, color: kSecondary, size: 16),
                    helperText: tr('Press Enter to save'),
                    helperStyle: TextStyle(fontSize: 10, color: kTextSub.withOpacity(0.4)),
                  ),
                ),
                const SizedBox(height: 16),
                // My bookings / receipts
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.2), width: 0.5)),
                    child: Row(children: [
                      const Icon(Icons.receipt_long_rounded, color: kSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(tr('My bookings'), style: tsTitleMd()),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 14),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                // Favorites button
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.2), width: 0.5)),
                    child: Row(children: [
                      const Icon(Icons.favorite_rounded, color: kRed, size: 20),
                      const SizedBox(width: 12),
                      Text(tr('My favorites'), style: tsTitleMd()),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 14),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),
                Row(children: [const Icon(Icons.translate_rounded, color: kSecondary, size: 18), const SizedBox(width: 8), Text(tr('Language'), style: tsHeadlineSm())]),
                const SizedBox(height: 14),
                ...[
                  {'code': 'English', 'label': 'English', 'flag': '🇬🇧'},
                  {'code': 'Tigrinya', 'label': 'ትግርኛ', 'flag': '🇪🇷'},
                  {'code': 'Amharic', 'label': 'አማርኛ', 'flag': '🇪🇹'},
                ].map((lang) {
                  final sel = _selectedLang == lang['code'];
                  return GestureDetector(
                    onTap: () { setState(() => _selectedLang = lang['code']!); languageNotifier.setLanguage(lang['code']!); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: sel ? kPrimaryContainer : kCardHigh, borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 14),
                        Expanded(child: Text(lang['label']!, style: tsBodyLg(color: sel ? kText : kText.withOpacity(0.7)))),
                        if (sel) const Icon(Icons.check_circle_rounded, color: kSecondary, size: 20),
                      ]),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                // ── Theme toggle ───────────────────────────────────
                AnimatedBuilder(
                  animation: themeNotifier,
                  builder: (_, __) => GestureDetector(
                    onTap: () => themeNotifier.toggle(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Icon(themeNotifier.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: kSecondary, size: 20),
                        const SizedBox(width: 14),
                        Expanded(child: Text(themeNotifier.isDark ? t('switch_to_light') : t('switch_to_dark'), style: tsBodyLg())),
                        Switch(
                          value: !themeNotifier.isDark,
                          onChanged: (_) => themeNotifier.toggle(),
                          activeColor: kSecondary,
                        ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kPrimaryContainer, kPrimaryContainer.withOpacity(0.6)]), borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t('bring_vision'), style: tsHeadlineSm()),
                    const SizedBox(height: 6),
                    Text(t('list_business_desc'), style: tsBodySm(color: kText.withOpacity(0.7))),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterBusinessScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(color: kSecondary, borderRadius: BorderRadius.circular(100)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(t('register_business'), style: tsTitleMd(color: const Color(0xFF1A1200))),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Color(0xFF1A1200), size: 18),
                        ]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                if (isLoggedIn) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [const Icon(Icons.storefront_rounded, color: kSecondary, size: 18), const SizedBox(width: 8), Text(t('my_businesses'), style: tsHeadlineSm())]),
                    GestureDetector(onTap: _loadMyBusinesses, child: const Icon(Icons.refresh_rounded, color: kSecondary, size: 18)),
                  ]),
                  const SizedBox(height: 12),
                  if (_loadingBiz)
                    const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5))
                  else if (_myBusinesses.isEmpty)
                    Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12)), child: Text(t('no_businesses_yet'), style: tsBodySm(), textAlign: TextAlign.center))
                  else
                    ..._myBusinesses.map((b) => _businessRow(b, context)),
                  const SizedBox(height: 24),
                ],
                GestureDetector(
                  onTap: () => Share.share(tr('Check out Habesha Hub!\n\nFind Ethiopian & Eritrean businesses near you.\n\nDownload now: https://habesha-hub.no/download.html')),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kSecondary.withOpacity(0.2), width: 0.5)),
                    child: Row(children: [
                      const Icon(Icons.share_rounded, color: kSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(tr('Share Habesha Hub'), style: tsTitleMd()),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: kSecondary, size: 20),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                const AdminButton(),
                const SizedBox(height: 12),
                _menuRow(Icons.help_outline_rounded, t('help_support'), () => _showHelp()),
                const SizedBox(height: 12),
                if (isLoggedIn) ...[
                  _menuRow(Icons.logout_rounded, t('logout'), _logout, color: kRed),
                  const SizedBox(height: 12),
                  _menuRow(Icons.delete_forever_rounded, t('delete_account'), _deleteAccount, color: kRed),
                ] else
                  _menuRow(Icons.login_rounded, t('login'), _login, color: kSecondary),
                const SizedBox(height: 40),
              ]),
            ),
          ]))),
        );
      },
    );
  }

  Widget _businessRow(Business b, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(10)),
          child: b.imageUrl.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(b.imageUrl, fit: BoxFit.cover)) : const Icon(Icons.storefront_rounded, color: kSecondary, size: 24),
        ),
        title: Text(b.name, style: tsTitleMd()),
        subtitle: Text(tr(b.category), style: tsBodySm()),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 13),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: b, userLat: 0, userLng: 0))),
      ),
    );
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.85, maxChildSize: 0.95,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl, padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kOutlineVariant, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [const Icon(Icons.help_rounded, color: kSecondary, size: 24), const SizedBox(width: 10), Text(languageNotifier.t('help_support'), style: tsHeadlineMd(color: kSecondary))]),
            const SizedBox(height: 20),
            _faq(languageNotifier.t('faq_what_q'), languageNotifier.t('faq_what_a')),
            _faq(languageNotifier.t('faq_account_q'), languageNotifier.t('faq_account_a')),
            _faq(languageNotifier.t('faq_register_q'), languageNotifier.t('faq_register_a')),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(languageNotifier.t('contact_us'), style: tsTitleMd(color: kSecondary)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse('mailto:support@habesha-hub.no');
                    if (await canLaunchUrl(url)) await launchUrl(url);
                  },
                  child: Row(children: [const Icon(Icons.email_outlined, color: kSecondary, size: 15), const SizedBox(width: 8), Text('support@habesha-hub.no', style: tsBodySm(color: kSecondary))]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            goldButton(tr('Send message'), () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactScreen())); }),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _faq(String q, String a) => Theme(
    data: ThemeData(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero, title: Text(q, style: tsTitleMd()),
      iconColor: kSecondary, collapsedIconColor: kTextSub,
      children: [Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(a, style: tsBodySm()))],
    ),
  );

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: kCardHigh, borderRadius: BorderRadius.circular(100)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: kSecondary, size: 12), SizedBox(width: 5), Text(label, style: tsLabel(color: kTextSub))]),
  );

  Widget _menuRow(IconData icon, String label, VoidCallback onTap, {Color? color}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: color == kText ? kSecondary : color, size: 20),
        const SizedBox(width: 14),
        Text(label, style: tsBodyLg(color: color ?? kText)),
        const Spacer(),
        Icon(Icons.arrow_forward_ios_rounded, color: (color == null || color == kText) ? kTextSub.withOpacity(0.4) : color!.withOpacity(0.6), size: 14),
      ]),
    ),
  );
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(title: Text(tr('Privacy')), backgroundColor: kCard),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('Privacy policy'), style: tsHeadlineSm(color: kSecondary)),
        const SizedBox(height: 12),
        Text(tr('Habesha Hub takes privacy seriously. We collect minimal data.'), style: tsBodyLg()),
        const SizedBox(height: 16),
        Text(tr('What we collect'), style: tsTitleMd(color: kSecondary)),
        const SizedBox(height: 8),
        Text(tr('• Email and name\n• Bookings, receipts and payment status\n• Chat messages, reviews and marketplace listings\n• AI assistant questions (answered by Google Gemini)\n• Notification token for push messages\n• GPS (only when searching, not stored)\n• Favorites and settings (only on your phone)'), style: tsBodyLg()),
        const SizedBox(height: 16),
        Text(tr('Payments'), style: tsTitleMd(color: kSecondary)),
        const SizedBox(height: 8),
        Text(tr('We never store card or bank numbers. You pay directly with Vipps, Swish, PayPal, Mobile Money or similar.'), style: tsBodyLg()),
        const SizedBox(height: 16),
        Text(tr('Your rights'), style: tsTitleMd(color: kSecondary)),
        const SizedBox(height: 8),
        Text(tr('You can see, correct or delete your data at any time. Delete your account under Profile, or contact support@habesha-hub.no.'), style: tsBodyLg()),
        const SizedBox(height: 24),
        goldButton(tr('Read the full privacy policy'), () => launchUrl(
            Uri.parse('https://habesha-hub.no/privacy.html'), mode: LaunchMode.externalApplication),
            icon: Icons.open_in_new_rounded),
      ]),
    ),
  );
}

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _sent = false, _sending = false;

  Future<void> _send() async {
    if (_nameCtrl.text.isEmpty || _msgCtrl.text.isEmpty) return;
    setState(() => _sending = true);
    await FirebaseFirestore.instance.collection('contact_messages').add({
      'name': _nameCtrl.text.trim(), 'message': _msgCtrl.text.trim(), 'email': _emailCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(), 'replied': false, 'adminEmail': 'support@habesha-hub.no',
    });
    final subject = Uri.encodeComponent('New message from ${_nameCtrl.text.trim()}');
    final body = Uri.encodeComponent('From: ${_nameCtrl.text.trim()}\nEmail: ${_emailCtrl.text.trim()}\n\nMessage:\n${_msgCtrl.text.trim()}');
    final url = Uri.parse('mailto:support@habesha-hub.no?subject=$subject&body=$body');
    if (await canLaunchUrl(url)) await launchUrl(url);
    setState(() { _sending = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(title: Text(tr('Contact us')), backgroundColor: kCard),
    body: _sent
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_rounded, color: kGreen, size: 64),
            const SizedBox(height: 16),
            Text(tr('Message sent!'), style: tsHeadlineSm()),
            const SizedBox(height: 8),
            Text(tr('We will reply as soon as possible.'), style: tsBodySm()),
          ]))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('Contact us'), style: tsHeadlineMd(color: kSecondary)),
              const SizedBox(height: 20),
              Text(tr('NAME'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: _nameCtrl, style: tsBodyLg(color: kText), decoration: InputDecoration(hintText: tr('Your name...'))),
              const SizedBox(height: 12),
              Text(tr('EMAIL'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: _emailCtrl, style: tsBodyLg(color: kText), keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: tr('your@email.com'), prefixIcon: Icon(Icons.email_outlined, color: kSecondary))),
              const SizedBox(height: 12),
              Text(tr('MESSAGE'), style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: _msgCtrl, maxLines: 5, style: tsBodyLg(color: kText), decoration: InputDecoration(hintText: tr('Write your message here...'))),
              const SizedBox(height: 24),
              goldButton(tr('Send message'), _sending ? null : _send, loading: _sending),
            ]),
          ),
  );
}
