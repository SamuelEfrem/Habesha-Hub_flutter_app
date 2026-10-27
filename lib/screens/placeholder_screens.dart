import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'community_screens.dart';
import 'map_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

// Country name (as stored in Firestore) → ISO code, for the flag emoji
const Map<String, String> _countryCodes = {
  'USA': 'US', 'UK': 'GB', 'Canada': 'CA', 'Ethiopia': 'ET', 'Eritrea': 'ER', 'Germany': 'DE',
  'France': 'FR', 'Netherlands': 'NL', 'Switzerland': 'CH', 'Italy': 'IT', 'Sweden': 'SE',
  'Norway': 'NO', 'Denmark': 'DK', 'Belgium': 'BE', 'Uganda': 'UG', 'Kenya': 'KE', 'Israel': 'IL',
  'Spain': 'ES', 'Australia': 'AU', 'New Zealand': 'NZ', 'South Africa': 'ZA', 'Austria': 'AT',
  'Tanzania': 'TZ', 'Poland': 'PL', 'Thailand': 'TH', 'Lebanon': 'LB', 'United Arab Emirates': 'AE',
  'Sudan': 'SD', 'South Sudan': 'SS', 'Finland': 'FI', 'Iceland': 'IS', 'Malawi': 'MW', 'Russia': 'RU',
  'Mali': 'ML', 'Luxembourg': 'LU', 'Cambodia': 'KH', 'Burkina Faso': 'BF', 'Angola': 'AO',
  'Kazakhstan': 'KZ', 'Ukraine': 'UA', 'Ivory Coast': 'CI', 'Ireland': 'IE', 'Zambia': 'ZM',
  'Somalia': 'SO', 'Palestine': 'PS', 'Djibouti': 'DJ', 'Kuwait': 'KW', 'Portugal': 'PT',
  'Brazil': 'BR', 'Vietnam': 'VN', 'China': 'CN', 'Rwanda': 'RW', 'Romania': 'RO', 'Moldova': 'MD',
  'Egypt': 'EG', 'Saudi Arabia': 'SA', 'Qatar': 'QA', 'Greece': 'GR', 'Czech Republic': 'CZ',
};

String countryFlag(String country) {
  final code = _countryCodes[country];
  if (code == null) return '🌍';
  return String.fromCharCodes(code.codeUnits.map((c) => 0x1F1E6 + c - 65));
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _db = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();

  List<Business> _all = [];
  bool _loading = true;
  String _country = '';
  String _city = '';
  String _category = '';
  String _query = '';

  static const _categoryOrder = ['Restaurant', 'Cafe', 'Shop', 'Barber', 'Club', 'Clinic', 'Hotel',
    'Photographer', 'Music', 'Decoration', 'Taxi', 'Other'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snap = await _db.collection('businesses').where('status', isEqualTo: 'approved').get();
      if (!mounted) return;
      setState(() {
        _all = snap.docs.map((d) => Business.fromFirestore(d.data(), d.id)).toList();
        _country = prefs.getString('explore_country') ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCountry(String c) async {
    setState(() { _country = c; _city = ''; _category = ''; });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('explore_country', c);
  }

  /// Countries with their number of businesses, biggest first
  List<MapEntry<String, int>> get _countries {
    final m = <String, int>{};
    for (final b in _all) {
      if (b.country.isNotEmpty) m[b.country] = (m[b.country] ?? 0) + 1;
    }
    return m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// City from an address like "Old Kent Road 244, SE1 5UB London" → "London"
  String _cityOf(Business b) {
    final parts = b.address.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    for (final p in parts.reversed) {
      final words = p.split(RegExp(r'\s+')).where((w) => !RegExp(r'\d').hasMatch(w)).toList();
      final city = words.join(' ').trim();
      if (city.isNotEmpty && city.toLowerCase() != b.country.toLowerCase() && city.length > 1) return city;
    }
    return '';
  }

  List<Business> get _inCountry => _all.where((b) => b.country == _country).toList();

  List<MapEntry<String, int>> get _cities {
    final m = <String, int>{};
    for (final b in _inCountry) {
      final c = _cityOf(b);
      if (c.isNotEmpty) m[c] = (m[c] ?? 0) + 1;
    }
    return m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  List<Business> get _results {
    final q = _query.toLowerCase();
    // Typing searches the whole world; otherwise show the chosen country
    var list = q.isNotEmpty && _country.isEmpty ? _all : _inCountry;
    if (_city.isNotEmpty) list = list.where((b) => _cityOf(b) == _city).toList();
    if (_category.isNotEmpty) list = list.where((b) => b.category == _category).toList();
    if (q.isNotEmpty) {
      list = list.where((b) =>
          b.name.toLowerCase().contains(q) ||
          b.address.toLowerCase().contains(q) ||
          b.description.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  String _catLabel(String key) {
    const keyMap = {
      'Restaurant': 'restaurant', 'Cafe': 'cafe', 'Shop': 'shop', 'Barber': 'barber', 'Club': 'club',
      'Clinic': 'clinic', 'Photographer': 'cat_photographer', 'Music': 'cat_music',
      'Decoration': 'cat_decoration', 'Taxi': 'cat_taxi', 'Hotel': 'cat_hotel', 'Other': 'other',
    };
    final k = keyMap[key];
    return k == null ? tr(key) : languageNotifier.t(k);
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
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
              child: Row(children: [
                Expanded(child: Text(tr('Explore'), style: tsHeadlineLg(color: kSecondary))),
                IconButton(
                  tooltip: tr('Suggest a business'),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SuggestBusinessScreen(country: _country))),
                  icon: const Icon(Icons.add_business_rounded, color: kSecondary),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Container(
                height: 52,
                decoration: BoxDecoration(color: kCardHighest, borderRadius: BorderRadius.circular(16)),
                child: TextField(
                  controller: _searchCtrl,
                  style: tsBodyLg(color: kText),
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: t('search_hint'),
                    hintStyle: tsBodyLg(color: kTextSub.withOpacity(0.7)),
                    prefixIcon: const Icon(Icons.search_rounded, color: kSecondary, size: 22),
                    suffixIcon: _query.isEmpty ? null : IconButton(
                      icon: Icon(Icons.close_rounded, color: kTextSub, size: 20),
                      onPressed: () => setState(() { _searchCtrl.clear(); _query = ''; }),
                    ),
                    filled: false, border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            if (_country.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _pickerButton('${countryFlag(_country)}  ${tr(_country)}', _showCountrySheet),
                  const SizedBox(width: 10),
                  if (_cities.isNotEmpty)
                    Flexible(child: _pickerButton(_city.isEmpty ? t('all_cities') : _city, _showCitySheet)),
                  const Spacer(),
                  if (_results.isNotEmpty)
                    mapButton(() => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => BusinessesMapScreen(
                              businesses: _results,
                              title: _city.isNotEmpty ? _city : tr(_country),
                            )))),
                ]),
              ),
              const SizedBox(height: 12),
              _buildCategoryChips(),
              const SizedBox(height: 8),
            ],
            Expanded(child: _buildBody(t)),
          ])),
        );
      },
    );
  }

  Widget _pickerButton(String label, VoidCallback onTap) {
    return Material(
      color: kCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: tsTitleMd(color: kText))),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, color: kSecondary, size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final counts = <String, int>{};
    for (final b in _inCountry.where((b) => _city.isEmpty || _cityOf(b) == _city)) {
      counts[b.category] = (counts[b.category] ?? 0) + 1;
    }
    final cats = _categoryOrder.where(counts.containsKey).toList();
    if (cats.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _chip(tr('All'), _category.isEmpty, () => setState(() => _category = '')),
          for (final c in cats)
            _chip('${_catLabel(c)}  ${counts[c]}', _category == c, () => setState(() => _category = c)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: sel ? kSecondary : kCard,
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(label, style: TextStyle(fontFamily: kFontBody, fontSize: 13,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? const Color(0xFF1A1200) : kText)),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(String Function(String) t) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 2));
    }
    // No country yet and not typing: let the user choose one
    if (_country.isEmpty && _query.isEmpty) return _countryList();
    final list = _results;
    if (list.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.storefront_rounded, color: kTextSub.withOpacity(0.5), size: 44),
        const SizedBox(height: 10),
        Text(tr('Nothing here yet'), style: tsTitleMd(color: kText)),
        const SizedBox(height: 4),
        Text(tr('Try another category or city'), style: tsBodySm(color: kTextSub)),
        const SizedBox(height: 12),
        suggestBusinessButton(context, country: _country),
      ]));
    }
    return RefreshIndicator(
      color: kSecondary,
      backgroundColor: kCard,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        itemCount: list.length + 1,
        itemBuilder: (_, i) {
          // Last row: missing a place? suggest it
          if (i == list.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(child: suggestBusinessButton(context, country: _country)),
            );
          }
          final b = list[i];
          return BusinessCard(
            key: ValueKey(b.id),
            business: b, userLat: 0, userLng: 0,
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => BusinessDetailScreen(business: b, userLat: 0, userLng: 0))));
        },
      ),
    );
  }

  Widget _countryList({void Function()? afterPick}) {
    final countries = _countries;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: countries.length,
      itemBuilder: (_, i) {
        final c = countries[i];
        final sel = c.key == _country;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: sel ? kSecondary.withOpacity(0.15) : kCard,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () { _pickCountry(c.key); afterPick?.call(); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Text(countryFlag(c.key), style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Text(tr(c.key), style: tsTitleLg(color: kText))),
                  Text('${c.value}', style: tsTitleMd(color: kSecondary)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: kTextSub, size: 20),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCountrySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: Column(children: [
          _sheetHandle(),
          Expanded(child: _countryList(afterPick: () => Navigator.pop(ctx))),
        ]),
      ),
    );
  }

  void _showCitySheet() {
    final t = languageNotifier.t;
    final cities = _cities;
    showModalBottomSheet(
      context: context,
      backgroundColor: kBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.6,
        child: Column(children: [
          _sheetHandle(),
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            children: [
              ListTile(
                title: Text(t('all_cities'), style: tsTitleLg(color: kText)),
                trailing: _city.isEmpty ? const Icon(Icons.check_rounded, color: kSecondary) : null,
                onTap: () { setState(() => _city = ''); Navigator.pop(ctx); },
              ),
              for (final c in cities)
                ListTile(
                  title: Text(c.key, style: tsTitleLg(color: kText)),
                  subtitle: Text('${c.value}', style: tsBodySm(color: kTextSub)),
                  trailing: _city == c.key ? const Icon(Icons.check_rounded, color: kSecondary) : null,
                  onTap: () { setState(() { _city = c.key; _category = ''; }); Navigator.pop(ctx); },
                ),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _sheetHandle() => Container(
        width: 40, height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: kTextSub.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
      );
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

  String get _initial {
    final src = _nicknameCtrl.text.trim().isNotEmpty ? _nicknameCtrl.text.trim() : (_user?.email ?? '?');
    return src.characters.first.toUpperCase();
  }

  Future<void> _saveNickname() async {
    final name = _nicknameCtrl.text.trim();
    if (name.isEmpty) return;
    FocusScope.of(context).unfocus();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', name);
    await _user?.updateDisplayName(name);
    if (mounted) setState(() => _saved = true);
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
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [kPrimaryContainer, Color(0xFF5A0000)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    border: Border.all(color: kSecondary, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: isLoggedIn
                      ? Text(_initial, style: const TextStyle(fontFamily: kFontHeadline,
                          fontSize: 40, fontWeight: FontWeight.w700, color: kSecondary))
                      : const Icon(Icons.person_rounded, size: 48, color: kSecondary),
                ),
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

                Text(t('nickname'), style: tsTitleMd(color: kTextSub)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nicknameCtrl,
                  style: tsBodyLg(color: kText),
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() => _saved = false),
                  onSubmitted: (_) => _saveNickname(),
                  decoration: InputDecoration(
                    hintText: t('nickname_hint'),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: kSecondary),
                    suffixIcon: TextButton(
                      onPressed: _saveNickname,
                      child: Text(_saved ? tr('Saved') : tr('Save'),
                          style: tsTitleMd(color: _saved ? kGreen : kSecondary)),
                    ),
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
                Row(children: [const Icon(Icons.translate_rounded, color: kSecondary, size: 18), const SizedBox(width: 8), Text(tr('Language'), style: tsHeadlineSm(color: kText))]),
                const SizedBox(height: 12),
                Row(children: [
                  for (final lang in const [
                    {'code': 'English', 'label': 'English', 'flag': '🇬🇧'},
                    {'code': 'Tigrinya', 'label': 'ትግርኛ', 'flag': '🇪🇷'},
                    {'code': 'Amharic', 'label': 'አማርኛ', 'flag': '🇪🇹'},
                  ]) ...[
                    if (lang['code'] != 'English') const SizedBox(width: 8),
                    Expanded(child: Material(
                      color: _selectedLang == lang['code'] ? kSecondary : kCard,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () { setState(() => _selectedLang = lang['code']!); languageNotifier.setLanguage(lang['code']!); },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(children: [
                            Text(lang['flag']!, style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text(lang['label']!, style: tsTitleMd(
                                color: _selectedLang == lang['code'] ? const Color(0xFF1A1200) : kText)),
                          ]),
                        ),
                      ),
                    )),
                  ],
                ]),
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
          child: b.imageUrl.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: b.imageUrl, fit: BoxFit.cover, memCacheWidth: 200)) : const Icon(Icons.storefront_rounded, color: kSecondary, size: 24),
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
