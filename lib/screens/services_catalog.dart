import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import '../utils/countries.dart';
import '../utils/translations.dart';
import 'member_screens.dart';
import 'provider_extras.dart';
import 'services_screen.dart';
import 'notices_screen.dart';
import 'cross_links.dart';
import 'wekil_screens.dart';
import 'hair_beauty.dart';
import 'placeholder_screens.dart' show ExploreScreen;

// Services in every country. Main groups with sub-categories; providers in the new groups
// register themselves (free), Habesha Hub approves, and customers contact them directly.
// Older entries keep their booking through Habesha Hub (contactMode != 'direct').

final _svc = FirebaseFirestore.instance.collection('anonymous_services');
const kMaxPhotos = 5, kMaxVideos = 3;

class ServiceGroup {
  final String key, label, emoji;
  final List<(String, String)> subs;
  final bool selfRegister;
  const ServiceGroup(this.key, this.label, this.emoji, this.subs, {this.selfRegister = true});
}

const kServiceGroups = [
  ServiceGroup('weddings', 'Weddings & celebrations', '💍', [
    ('photo_video', 'Photo & video'), ('music', 'Music (DJ, band, singer)'), ('decoration', 'Decoration'),
    ('venues', 'Venues & halls'), ('catering', 'Catering, cake & injera'), ('dresses', 'Dresses & habesha clothes'),
    ('planner', 'Wedding planner'), ('other', 'Other'),
  ]),
  ServiceGroup('travel', 'Travel & tourism', '✈️', [
    ('hotels', 'Hotels & stays'), ('guides', 'Guides & tours'), ('drivers', 'Airport pickup & drivers'),
    ('car_rental', 'Car rental'), ('visa', 'Visa & paperwork help'), ('other', 'Other'),
  ]),
  ServiceGroup('music', 'Music & entertainment', '🎵', [('dj', 'DJ'), ('band', 'Band'), ('singer', 'Singer'), ('other', 'Other')]),
  ServiceGroup('money_transfer', 'Send money home', '💸', [], selfRegister: false),
];

// old single categories → group + sub-category (the migration writes these; this is the fallback)
const _legacy = {
  'photographer': ('weddings', 'photo_video'), 'decoration': ('weddings', 'decoration'), 'clothing': ('weddings', 'dresses'),
  'accommodation': ('travel', 'hotels'), 'transport': ('travel', 'drivers'), 'flight_visa': ('travel', 'visa'),
  'money_transfer': ('money_transfer', ''), 'hawala': ('money_transfer', ''), 'music': ('music', ''),
};
String serviceGroupOf(Map data) => serviceStr(data['group']).isNotEmpty ? serviceStr(data['group']) : (_legacy[serviceStr(data['category'])]?.$1 ?? 'other');
String serviceSubOf(Map data) => serviceStr(data['subcategory']).isNotEmpty ? serviceStr(data['subcategory']) : (_legacy[serviceStr(data['category'])]?.$2 ?? '');
/// Group + sub-category for the admin form, from the old category key
(String, String) groupForCategory(String category) => _legacy[category] ?? (category, '');
ServiceGroup? serviceGroup(String key) => kServiceGroups.where((g) => g.key == key).firstOrNull;
String serviceSubLabel(Map data) {
  final g = serviceGroup(serviceGroupOf(data)), sub = serviceSubOf(data);
  final s = g?.subs.where((x) => x.$1 == sub);
  return s == null || s.isEmpty ? (g == null ? '' : tr(g.label)) : tr(s.first.$2);
}
bool isDirectContact(Map data) => serviceStr(data['contactMode']) == 'direct';
String digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
String countryLabel(String code) => '${countryFlag(code)} ${tr(countryName(code))}';

// the big cities (regions) a wekil can choose from, per country
const kRegionsOf = <String, List<String>>{
  'NO': ['Oslo', 'Bergen', 'Trondheim', 'Stavanger', 'Kristiansand', 'Drammen', 'Fredrikstad', 'Tromsø'],
  'SE': ['Stockholm', 'Göteborg', 'Malmö', 'Uppsala', 'Västerås', 'Örebro', 'Linköping'],
  'DK': ['København', 'Aarhus', 'Odense', 'Aalborg'],
  'DE': ['Berlin', 'Frankfurt', 'München', 'Hamburg', 'Köln', 'Stuttgart', 'Düsseldorf', 'Nürnberg'],
  'NL': ['Amsterdam', 'Rotterdam', 'Den Haag', 'Utrecht', 'Eindhoven'],
  'CH': ['Zürich', 'Genf', 'Bern', 'Basel', 'Lausanne'],
  'IT': ['Roma', 'Milano', 'Bologna', 'Torino'],
  'GB': ['London', 'Birmingham', 'Manchester', 'Leeds', 'Glasgow', 'Bristol'],
  'FR': ['Paris', 'Lyon', 'Marseille', 'Toulouse'],
  'BE': ['Brussel', 'Antwerpen', 'Liège'],
  'US': ['Washington DC', 'Seattle', 'Los Angeles', 'Oakland', 'Dallas', 'Houston', 'Atlanta', 'Minneapolis', 'Denver', 'Las Vegas', 'New York'],
  'CA': ['Toronto', 'Calgary', 'Edmonton', 'Vancouver', 'Ottawa', 'Winnipeg', 'Kitchener', 'Montreal'],
  'ET': ['Addis Ababa', 'Mekelle', 'Bahir Dar', 'Hawassa', 'Gondar', 'Dire Dawa', 'Adigrat', 'Aksum'],
  'ER': ['Asmara', 'Keren', 'Massawa', 'Mendefera', 'Dekemhare', 'Barentu', 'Assab'],
  'UG': ['Kampala', 'Entebbe'],
  'KE': ['Nairobi', 'Mombasa'],
  'SS': ['Juba'],
  'EG': ['Cairo', 'Alexandria'],
};

// ── where the user looks: saved choice, else phone position (if already allowed), else phone language region ──
class ServiceLocation {
  static Future<(String, String)> load() async {
    final p = await SharedPreferences.getInstance();
    final c = p.getString('svc_country');
    if (c != null) return (c, p.getString('svc_city') ?? '');
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getLastKnownPosition() ?? await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 6));
        final pl = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (pl.isNotEmpty && (pl.first.isoCountryCode ?? '').length == 2) return (pl.first.isoCountryCode!.toUpperCase(), pl.first.locality ?? '');
      }
    } catch (_) {}
    final region = Platform.localeName.split(RegExp('[_-]')).last.toUpperCase();
    return (kAllCountries.any((c) => c.$1 == region) ? region : 'NO', '');
  }

  static Future<void> save(String country, String city) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('svc_country', country);
    await p.setString('svc_city', city);
  }
}

/// Approved services in a country (one equality query, no extra index needed)
Stream<QuerySnapshot<Map<String, dynamic>>> servicesIn(String country) =>
    _svc.where('country', isEqualTo: country).where('available', isEqualTo: true).snapshots();

List<String> citiesOf(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
  final m = <String, String>{};
  for (final d in docs) {
    final c = serviceStr(d.data()['city']).trim();
    if (c.isNotEmpty) m.putIfAbsent(c.toLowerCase(), () => c);
  }
  return m.values.toList()..sort();
}

// ── Services home ──
class ServicesHome extends StatefulWidget {
  const ServicesHome({super.key});
  @override
  State<ServicesHome> createState() => _ServicesHomeState();
}

class _ServicesHomeState extends State<ServicesHome> {
  String? _country;
  String _city = '', _q = '';

  @override
  void initState() {
    super.initState();
    ServiceLocation.load().then((v) { if (mounted) setState(() { _country = v.$1; _city = v.$2; }); });
  }

  Future<void> _changeLocation(List<String> cities) async {
    final r = await pickServiceLocation(context, _country ?? 'NO', _city, cities);
    if (r == null || !mounted) return;
    setState(() { _country = r.$1; _city = r.$2; });
    ServiceLocation.save(r.$1, r.$2);
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: _country == null
            ? Center(child: CircularProgressIndicator(color: kHabGreen, strokeWidth: 2))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: servicesIn(_country!),
                builder: (_, snap) {
                  final all = snap.data?.docs ?? [];
                  final cities = citiesOf(all);
                  final inCity = all.where((d) => _city.isEmpty || serviceStr(d.data()['city']).toLowerCase() == _city.toLowerCase()).toList();
                  final q = _q.trim().toLowerCase();
                  final hits = q.isEmpty ? <QueryDocumentSnapshot<Map<String, dynamic>>>[] : all.where((d) {
                    final e = d.data();
                    return [serviceText(e, 'publicName'), serviceSubLabel(e), serviceStr(e['city']), serviceStr(e['area'])].any((x) => x.toLowerCase().contains(q));
                  }).toList();
                  return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
                    Row(children: [
                      if (canPop) IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back_rounded, color: kText)),
                      Expanded(child: Text(tr('Services'), style: tsHeadlineMd(color: kText))),
                      WekilOnly(child: IconButton(tooltip: tr('My services'), icon: Icon(Icons.storefront_outlined, color: kText),
                          onPressed: () => openMyServices(context))),
                      IconButton(tooltip: tr('Favorite services'), icon: const Icon(Icons.favorite_rounded, color: kRed),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteServicesScreen()))),
                    ]),
                    const SizedBox(height: 6),
                    Material(
                      color: kCard,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _changeLocation(cities),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(children: [
                            Text(countryFlag(_country!), style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 10),
                            Expanded(child: Text('${tr(countryName(_country!))} · ${_city.isEmpty ? tr('All cities') : _city}',
                                style: tsTitleMd(color: kText))),
                            Text(tr('Change location'), style: tsBodySm(color: kInkGreen).copyWith(fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setState(() => _q = v),
                      style: tsBodyLg(color: kText),
                      decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: tr('Search by name, service or city')),
                    ),
                    const SizedBox(height: 14),
                    if (q.isNotEmpty) ...[
                      if (hits.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Text(tr('No providers yet'), textAlign: TextAlign.center, style: tsBodySm(color: kTextSub))),
                      for (final d in hits) ServiceTile(doc: d),
                    ] else ...[
                      for (final g in kServiceGroups) _groupCard(g, inCity.where((d) => serviceGroupOf(d.data()) == g.key).length),
                      const SizedBox(height: 10),
                      WekilOnly(child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52)),
                        onPressed: () => openServiceForm(context),
                        icon: const Icon(Icons.add_business_outlined),
                        label: Text(tr('Add service provider'), style: const TextStyle(fontWeight: FontWeight.w800)),
                      )),
                    ],
                  ]);
                },
              ),
      ),
    );
  }

  Widget _groupCard(ServiceGroup g, int n) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: kCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceGroupScreen(group: g, country: _country!, city: _city))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: kTintGreen, shape: BoxShape.circle),
                child: Center(child: Text(g.emoji, style: const TextStyle(fontSize: 24)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(g.label), style: tsTitleMd(color: kText)),
              if (g.subs.isNotEmpty) Text(g.subs.take(4).map((s) => tr(s.$2)).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: tsBodySm(color: kTextSub)),
            ])),
            Text('$n', style: tsTitleMd(color: kTextSub)),
            Icon(Icons.chevron_right_rounded, color: kTextSub),
          ]),
        ),
      ),
    ),
  );
}

/// Country (searchable, with flags) and city (from services that exist)
Future<(String, String)?> pickServiceLocation(BuildContext context, String country, String city, List<String> cities) {
  return showModalBottomSheet<(String, String)>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _LocationSheet(country: country, city: city, cities: cities),
  );
}

class _LocationSheet extends StatefulWidget {
  final String country, city;
  final List<String> cities;
  const _LocationSheet({required this.country, required this.city, required this.cities});
  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  late String _country = widget.country;
  String _q = '';
  final _search = TextEditingController();

  @override
  void dispose() { _search.dispose(); super.dispose(); }
  List<String>? _cities;

  @override
  void initState() {
    super.initState();
    _cities = widget.cities;
    if (widget.cities.isEmpty) _loadCities(widget.country);   // the regions that have providers
  }

  Future<void> _loadCities(String c) async {
    setState(() => _cities = null);
    final s = await _svc.where('country', isEqualTo: c).where('available', isEqualTo: true).get();
    if (mounted) setState(() => _cities = citiesOf(s.docs));
  }

  @override
  Widget build(BuildContext context) {
    final list = kAllCountries.where((c) => _q.isEmpty || tr(c.$2).toLowerCase().contains(_q.toLowerCase()) || c.$2.toLowerCase().contains(_q.toLowerCase())).toList();
    return SafeArea(child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .85,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('Change location'), style: tsHeadlineSm(color: kText)),
          const SizedBox(height: 10),
          Text('${countryLabel(_country)} · ${tr('City')}', style: tsLabel()),
          const SizedBox(height: 6),
          SizedBox(height: 40, child: _cities == null
              ? const Center(child: LinearProgressIndicator())
              : ListView(scrollDirection: Axis.horizontal, children: [
                  Padding(padding: const EdgeInsets.only(right: 8), child: ActionChip(label: Text(tr('All regions')), onPressed: () => Navigator.pop(context, (_country, '')))),
                  for (final c in _cities!) Padding(padding: const EdgeInsets.only(right: 8), child: ActionChip(label: Text(c), onPressed: () => Navigator.pop(context, (_country, c)))),
                ])),
          const SizedBox(height: 14),
          TextField(controller: _search, onChanged: (v) => setState(() => _q = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: tr('Search country'))),
          const SizedBox(height: 6),
          Expanded(child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final c = list[i];
              return ListTile(
                leading: Text(countryFlag(c.$1), style: const TextStyle(fontSize: 24)),
                title: Text(tr(c.$2), style: tsBodyLg(color: kText)),
                trailing: c.$1 == _country ? Icon(Icons.check_rounded, color: kHabGreen) : null,
                onTap: () { _search.clear(); FocusScope.of(context).unfocus(); setState(() { _country = c.$1; _q = ''; }); _loadCities(c.$1); },
              );
            },
          )),
        ]),
      ),
    ));
  }
}

// ── One group: sub-category chips, city chips, list ──
class ServiceGroupScreen extends StatefulWidget {
  final ServiceGroup group;
  final String country, city, initialSub;
  const ServiceGroupScreen({super.key, required this.group, required this.country, required this.city, this.initialSub = ''});
  @override
  State<ServiceGroupScreen> createState() => _ServiceGroupScreenState();
}

class _ServiceGroupScreenState extends State<ServiceGroupScreen> {
  late String _sub = widget.initialSub;
  late String _city = widget.city;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: Text('${countryFlag(widget.country)} ${tr(g.label)}', style: tsTitleMd(color: kText))),
      floatingActionButton: g.selfRegister ? WekilOnly(child: FloatingActionButton.extended(
        backgroundColor: kHabGreen, foregroundColor: Colors.white,
        onPressed: () => openServiceForm(context, group: g.key),
        icon: const Icon(Icons.add_rounded), label: Text(tr('Add service provider')))) : null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: servicesIn(widget.country),
        builder: (_, snap) {
          if (!snap.hasData) return Center(child: CircularProgressIndicator(color: kHabGreen, strokeWidth: 2));
          final all = snap.data!.docs;
          // Weddings > Music shows the artists of Music & entertainment (no copies)
          final musicInWeddings = g.key == 'weddings' && _sub == 'music';
          final inGroup = all.where((d) {
            final gk = serviceGroupOf(d.data());
            return musicInWeddings ? gk == 'music' || (gk == g.key && serviceSubOf(d.data()) == 'music') : gk == g.key;
          }).toList();
          final cities = citiesOf(inGroup);
          final docs = inGroup.where((d) =>
              (_sub.isEmpty || musicInWeddings || serviceSubOf(d.data()) == _sub) &&
              (_city.isEmpty || serviceStr(d.data()['city']).toLowerCase() == _city.toLowerCase())).toList();
          return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 96), children: [
            if (g.subs.isNotEmpty) SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, children: [
              _chip(tr('All'), _sub.isEmpty, () => setState(() => _sub = '')),
              // opened from a link (e.g. Market): the chosen chip first, so it is visible
              for (final s in [...g.subs.where((s) => s.$1 == widget.initialSub), ...g.subs.where((s) => s.$1 != widget.initialSub)])
                _chip(tr(s.$2), _sub == s.$1, () => setState(() => _sub = _sub == s.$1 ? '' : s.$1)),
            ])),
            if (cities.length > 1 || _city.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, children: [
                _chip(tr('All regions'), _city.isEmpty, () => setState(() => _city = '')),
                for (final c in cities) _chip(c, _city.toLowerCase() == c.toLowerCase(), () => setState(() => _city = c)),
              ])),
            ],
            const SizedBox(height: 10),
            if (g.key == 'weddings' && (_sub.isEmpty || _sub == 'other' || _sub == 'dresses')) crossLinkCard(context, emoji: '💄',
                text: tr('Makeup, braiding and henna for the wedding: see Hair & beauty'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
                    const ExploreScreen(initialCategory: kHairCategory, initialSub: 'wedding')))),
            if (g.key == 'weddings' && _sub == 'dresses') crossLinkCard(context, emoji: '👗',
                text: tr('Buying, selling or renting one dress? See habesha clothes in Market'),
                onTap: () => openMarket(context, category: 'Habesha')),
            if (g.key == 'weddings' && _sub == 'catering') crossLinkCard(context, emoji: '🏠',
                text: tr('Homemade injera, bread and food: see Home shops in Market'),
                onTap: () => openMarket(context, tab: 'shops')),
            if (docs.isEmpty) Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Column(children: [
                Text(g.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 10),
                Text(tr('No providers yet'), style: tsTitleMd(color: kText)),
                const SizedBox(height: 4),
                Text(g.selfRegister ? tr('Be the first: register your service for free') : tr('Coming soon!'), textAlign: TextAlign.center, style: tsBodySm(color: kTextSub)),
              ]),
            ),
            // all regions: sorted by region, with the region as a small heading
            if (_city.isNotEmpty) for (final d in docs) ServiceTile(doc: d)
            else for (final (i, d) in (docs..sort((a, b) => serviceStr(a.data()['city']).toLowerCase()
                .compareTo(serviceStr(b.data()['city']).toLowerCase()))).indexed) ...[
              if (i == 0 || serviceStr(docs[i - 1].data()['city']).toLowerCase() != serviceStr(d.data()['city']).toLowerCase())
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                  child: Text('📍 ${serviceStr(d.data()['city']).isEmpty ? tr('Other') : serviceStr(d.data()['city'])}',
                      style: tsTitleMd(color: kInkGreen)),
                ),
              ServiceTile(doc: d),
            ],
          ]);
        },
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback tap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(label: Text(label), selected: on, onSelected: (_) => tap(), selectedColor: kHabGreen, showCheckmark: false,
        labelStyle: TextStyle(color: on ? Colors.white : kText, fontWeight: FontWeight.w600)),
  );
}

class ServiceTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const ServiceTile({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final e = doc.data(), imgs = serviceImages(e);
    final g = serviceGroup(serviceGroupOf(e));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: kCard,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceProviderScreen(docId: doc.id, data: e))),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 86, height: 86, child: imgs.isEmpty
                    ? Container(color: kTintGreen, child: Center(child: Text(g?.emoji ?? '⭐', style: const TextStyle(fontSize: 30))))
                    : CachedNetworkImage(imageUrl: imgs.first, fit: BoxFit.cover, memCacheWidth: 300,
                        errorWidget: (_, __, ___) => Container(color: kTintGreen))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ServiceNameText(data: e, maxLines: 1, style: tsTitleMd(color: kText)),
                Text(serviceSubLabel(e), maxLines: 1, overflow: TextOverflow.ellipsis, style: tsBodySm(color: kInkGreen).copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text([serviceStr(e['city']), serviceStr(e['area'])].where((x) => x.isNotEmpty).join(' · '), style: tsBodySm(color: kTextSub)),
                if (serviceStr(e['priceRange']).isNotEmpty) Text(serviceStr(e['priceRange']), style: tsBodySm(color: kText)),
                RatingLine(data: e),
              ])),
              Icon(Icons.chevron_right_rounded, color: kTextSub),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Profile extras for providers with direct contact ──
class DirectServiceInfo extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const DirectServiceInfo({super.key, required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final links = data['links'] is Map ? Map<String, dynamic>.from(data['links']) : <String, dynamic>{};
    Widget row(IconData i, String t) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(i, size: 18, color: kTextSub), const SizedBox(width: 8), Expanded(child: Text(t, style: tsBodyLg(color: kText))),
      ]),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Text(serviceSubLabel(data), style: tsTitleMd(color: kInkGreen)),
      if (serviceStr(data['area']).isNotEmpty) row(Icons.place_outlined, '${serviceStr(data['area'])}, ${serviceStr(data['city'])} · ${countryLabel(serviceStr(data['country']))}')
      else row(Icons.place_outlined, '${serviceStr(data['city'])} · ${countryLabel(serviceStr(data['country']))}'),
      if (serviceStr(data['priceRange']).isNotEmpty) row(Icons.sell_outlined, serviceStr(data['priceRange'])),
      if (serviceStr(data['languages']).isNotEmpty) row(Icons.translate_rounded, '${tr('Languages')}: ${serviceStr(data['languages'])}'),
      if (data['travels'] == true) row(Icons.flight_takeoff_rounded, '${tr('Travels to')}: ${serviceStr(data['travelsWhere']).isEmpty ? tr('other cities and countries') : serviceStr(data['travelsWhere'])}'),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (k, label, icon) in [('tiktok', 'TikTok', Icons.music_note_rounded), ('instagram', 'Instagram', Icons.camera_alt_outlined), ('youtube', 'YouTube', Icons.play_circle_outline_rounded)])
          if (serviceStr(links[k]).startsWith('https://')) OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse(serviceStr(links[k])), mode: LaunchMode.externalApplication),
            icon: Icon(icon, size: 18), label: Text(label)),
      ]),
      TextButton.icon(
        onPressed: () => _reportService(context, docId, serviceText(data, 'publicName')),
        icon: Icon(Icons.flag_outlined, color: kTextSub, size: 18),
        label: Text(tr('Report'), style: tsBodySm(color: kTextSub))),
    ]);
  }
}

/// Bottom buttons for direct contact: WhatsApp + call
Widget directContactBar(BuildContext context, Map<String, dynamic> data) =>
    WekilContactBar(data: data, fallback: () => _ownContactBar(context, data));

Widget _ownContactBar(BuildContext context, Map<String, dynamic> data) {
  final wa = digitsOnly(serviceStr(data['whatsapp'])), ph = digitsOnly(serviceStr(data['phone']).isNotEmpty ? serviceStr(data['phone']) : serviceStr(data['whatsapp']));
  final msg = '${tr('Hi, I saw your service on Habesha Hub')}: ${serviceText(data, 'publicName')}';
  return SafeArea(child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: Row(children: [
      if (wa.isNotEmpty) Expanded(child: SizedBox(height: 52, child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white),
        onPressed: () => launchUrl(Uri.parse('https://wa.me/$wa?text=${Uri.encodeComponent(msg)}'), mode: LaunchMode.externalApplication),
        icon: const Icon(Icons.chat_rounded), label: Text(tr('Book on WhatsApp'), style: const TextStyle(fontWeight: FontWeight.w800))))),
      if (ph.isNotEmpty) ...[
        const SizedBox(width: 10),
        SizedBox(height: 52, child: OutlinedButton.icon(
          onPressed: () => launchUrl(Uri.parse('tel:+$ph')),
          icon: const Icon(Icons.call_rounded), label: Text(tr('Call')))),
      ],
    ]),
  ));
}

Future<void> _reportService(BuildContext context, String id, String name) async {
  final note = TextEditingController();
  final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
    backgroundColor: kCard,
    title: Text(tr('Report'), style: tsTitleMd(color: kText)),
    content: TextField(controller: note, maxLines: 3, maxLength: 500, decoration: InputDecoration(hintText: tr('What is wrong?'))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Send'))),
    ],
  ));
  if (ok != true) return;
  final u = FirebaseAuth.instance.currentUser;
  try {
    await FirebaseFirestore.instance.collection('reports').add({
      'businessId': id, 'businessName': name, 'reason': 'service', 'note': note.text.trim(),
      'userId': u == null || u.isAnonymous ? null : u.uid, 'status': 'open', 'kind': 'service', 'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {}
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Thank you, we will look at it'))));
}

// ── Register / edit your service ──
Future<void> openServiceForm(BuildContext context, {String? group, String? docId, Map<String, dynamic>? existing}) async {
  final code = await wekilCodeOrExplain(context);
  if (code == null || !context.mounted) return;
  Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceFormScreen(group: group, docId: docId, existing: existing,
      wekilCode: code == 'ADMIN' ? null : code)));
}

Future<void> openMyServices(BuildContext context) async {
  final u = FirebaseAuth.instance.currentUser;
  if (u == null || u.isAnonymous) { if (!await ensureMember(context)) return; }
  if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const MyServicesScreen()));
}

class ServiceFormScreen extends StatefulWidget {
  final String? group, docId;
  final Map<String, dynamic>? existing;
  /// set when a wekil adds / edits: the country is fixed and the provider is published at once
  final String? wekilCode;
  const ServiceFormScreen({super.key, this.group, this.docId, this.existing, this.wekilCode});
  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _name = TextEditingController(), _desc = TextEditingController(), _city = TextEditingController(), _area = TextEditingController(),
      _price = TextEditingController(), _langs = TextEditingController(), _where = TextEditingController(), _wa = TextEditingController(),
      _phone = TextEditingController(), _ig = TextEditingController(), _tt = TextEditingController(), _yt = TextEditingController();
  late String _group = widget.group ?? 'weddings';
  String _sub = '', _country = 'NO', _error = '';
  bool _travels = false, _saving = false;
  int _cityRev = 0; // rebuilds the city field when a region chip is tapped
  List<String> _photos = [], _videos = [], _citySuggest = [];
  final List<File> _newPhotos = [], _newVideos = [];

  // admin or wekil: publishes at once, only name and city are required
  bool get _staff => widget.wekilCode != null || FirebaseAuth.instance.currentUser?.email == 'samuelefriem@gmail.com';

  @override
  void initState() {
    super.initState();
    if (widget.wekilCode != null) _country = widget.wekilCode!;
    final e = widget.existing;
    if (e != null) {
      _name.text = serviceStr(e['publicName']); _desc.text = serviceStr(e['description']); _city.text = serviceStr(e['city']);
      _area.text = serviceStr(e['area']); _price.text = serviceStr(e['priceRange']); _langs.text = serviceStr(e['languages']);
      _where.text = serviceStr(e['travelsWhere']); _wa.text = serviceStr(e['whatsapp']); _phone.text = serviceStr(e['phone']);
      final l = e['links'] is Map ? e['links'] as Map : {};
      _ig.text = serviceStr(l['instagram']); _tt.text = serviceStr(l['tiktok']); _yt.text = serviceStr(l['youtube']);
      _group = serviceGroupOf(e); _sub = serviceSubOf(e); _country = serviceStr(e['country']).isEmpty ? 'NO' : serviceStr(e['country']);
      _travels = e['travels'] == true; _photos = serviceImages(e); _videos = serviceVideos(e);
    } else {
      ServiceLocation.load().then((v) { if (mounted) setState(() { _country = v.$1; if (_city.text.isEmpty) _city.text = v.$2; }); _loadCities(); });
    }
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final s = await _svc.where('country', isEqualTo: _country).where('available', isEqualTo: true).get();
      if (mounted) setState(() => _citySuggest = citiesOf(s.docs));
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _city, _area, _price, _langs, _where, _wa, _phone, _ig, _tt, _yt]) { c.dispose(); }
    super.dispose();
  }

  int get _photoCount => _photos.length + _newPhotos.length;
  int get _videoCount => _videos.length + _newVideos.length;

  Future<void> _addPhotos() async {
    final room = kMaxPhotos - _photoCount;
    if (room <= 0) return;
    final x = await ImagePicker().pickMultiImage(imageQuality: 80, maxWidth: 1600);
    if (x.isNotEmpty && mounted) setState(() => _newPhotos.addAll(x.take(room).map((f) => File(f.path))));
  }

  Future<void> _addVideo() async {
    if (_videoCount >= kMaxVideos) return;
    final x = await ImagePicker().pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
    if (x == null) return;
    final f = File(x.path);
    if (await f.length() > 60 * 1024 * 1024) { setState(() => _error = tr('The video is too big. Use a shorter video (max 60 seconds).')); return; }
    try {
      final c = VideoPlayerController.file(f);
      await c.initialize();
      final long = c.value.duration > const Duration(seconds: 65);
      await c.dispose();
      if (long) { setState(() => _error = tr('The video is too long. Max 60 seconds.')); return; }
    } catch (_) {}
    if (mounted) setState(() { _newVideos.add(f); _error = ''; });
  }

  String? _link(TextEditingController c) => c.text.trim().startsWith('https://') ? c.text.trim() : null;

  Future<void> _save() async {
    if (_staff) {
      if (_name.text.trim().isEmpty || _city.text.trim().isEmpty) { setState(() => _error = tr('Please write the name and the city')); return; }
    } else {
      if (_name.text.trim().isEmpty || _city.text.trim().isEmpty || digitsOnly(_wa.text).length < 8) {
        setState(() => _error = tr('Please write the name, city and WhatsApp number with country code'));
        return;
      }
      if (_sub.isEmpty && (serviceGroup(_group)?.subs.isNotEmpty ?? false)) { setState(() => _error = tr('Please choose what you offer')); return; }
    }
    for (final c in [_ig, _tt, _yt]) {
      if (c.text.trim().isNotEmpty && _link(c) == null) { setState(() => _error = tr('Links must start with https://')); return; }
    }
    final u = FirebaseAuth.instance.currentUser!;
    setState(() { _saving = true; _error = ''; });
    try {
      final st = FirebaseStorage.instance;
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final photos = [..._photos];
      for (var i = 0; i < _newPhotos.length; i++) {
        final r = st.ref('services/${u.uid}/${stamp}_p$i.jpg');
        await r.putFile(_newPhotos[i], SettableMetadata(contentType: 'image/jpeg'));
        photos.add(await r.getDownloadURL());
      }
      final videos = [..._videos];
      for (var i = 0; i < _newVideos.length; i++) {
        final r = st.ref('services/${u.uid}/${stamp}_v$i.mp4');
        await r.putFile(_newVideos[i], SettableMetadata(contentType: 'video/mp4'));
        videos.add(await r.getDownloadURL());
      }
      final city = _city.text.trim(), match = _citySuggest.where((c) => c.toLowerCase() == city.toLowerCase());
      final data = <String, dynamic>{
        'publicName': _name.text.trim(), 'description': _desc.text.trim(), 'group': _group, 'subcategory': _sub, 'category': _group,
        'country': _country, 'city': match.isNotEmpty ? match.first : city, 'area': _area.text.trim(),
        'priceRange': _price.text.trim(), 'languages': _langs.text.trim(), 'travels': _travels, 'travelsWhere': _travels ? _where.text.trim() : '',
        'whatsapp': _wa.text.trim(), 'phone': _phone.text.trim(),
        'links': {for (final (k, c) in [('instagram', _ig), ('tiktok', _tt), ('youtube', _yt)]) if (_link(c) != null) k: _link(c)},
        'sampleImages': photos.take(kMaxPhotos).toList(), 'sampleVideoUrls': videos.take(kMaxVideos).toList(),
        'ownerId': widget.wekilCode != null ? (serviceStr(widget.existing?['ownerId']).isNotEmpty ? serviceStr(widget.existing!['ownerId']) : u.uid) : u.uid,
        'contactMode': 'direct',
        // the wekil publishes at once; the admin's own edits keep the old way
        'status': _staff ? 'approved' : 'pending', 'available': _staff,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.docId == null) {
        await _svc.add({...data, 'createdAt': FieldValue.serverTimestamp()});
      } else {
        await _svc.doc(widget.docId).update(data);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_staff ? tr('Saved and published') : tr('Thank you! Habesha Hub checks your service and publishes it soon'))));
      Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = tr('Could not save. Check your internet and try again.'); });
    }
  }

  Widget _f(TextEditingController c, String label, {int lines = 1, TextInputType? type, String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(controller: c, maxLines: lines, keyboardType: type, style: tsBodyLg(color: kText), decoration: InputDecoration(labelText: label, hintText: hint)),
  );

  @override
  Widget build(BuildContext context) {
    final groups = kServiceGroups.where((g) => g.selfRegister).toList(), g = serviceGroup(_group);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: Text(widget.docId == null ? tr('Register your service (free)') : tr('Edit service'), style: tsTitleMd(color: kText))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kTintGreen, borderRadius: BorderRadius.circular(14)),
          child: Text(_staff ? tr('Only the name and the city are needed. It is shown at once, and customers book through Habesha Hub Services on WhatsApp.')
              : tr('Free now. Habesha Hub may later offer paid extras. Customers contact you directly on WhatsApp or phone.'), style: tsBodySm(color: kInkGreen)),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final x in groups) ChoiceChip(label: Text('${x.emoji} ${tr(x.label)}'), selected: _group == x.key, selectedColor: kHabGreen, showCheckmark: false,
              labelStyle: TextStyle(color: _group == x.key ? Colors.white : kText, fontWeight: FontWeight.w600),
              onSelected: (_) => setState(() { _group = x.key; _sub = ''; })),
        ]),
        if (g != null && g.subs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(tr('What do you offer?'), style: tsLabel()),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in g.subs) ChoiceChip(label: Text(tr(s.$2)), selected: _sub == s.$1, selectedColor: kHabGreen, showCheckmark: false,
                labelStyle: TextStyle(color: _sub == s.$1 ? Colors.white : kText), onSelected: (_) => setState(() => _sub = s.$1)),
          ]),
        ],
        const SizedBox(height: 14),
        _f(_name, tr('Name of your business or service')),
        _f(_desc, tr('Description'), lines: 4),
        Text('${tr('Photos')} ($_photoCount/$kMaxPhotos) · ${tr('Videos')} ($_videoCount/$kMaxVideos)', style: tsLabel()),
        const SizedBox(height: 6),
        SizedBox(height: 84, child: ListView(scrollDirection: Axis.horizontal, children: [
          for (var i = 0; i < _photos.length; i++) _thumb(CachedNetworkImage(imageUrl: _photos[i], fit: BoxFit.cover), () => setState(() => _photos.removeAt(i))),
          for (var i = 0; i < _newPhotos.length; i++) _thumb(Image.file(_newPhotos[i], fit: BoxFit.cover), () => setState(() => _newPhotos.removeAt(i))),
          for (var i = 0; i < _videos.length; i++) _thumb(Icon(Icons.videocam_rounded, color: kInkGreen), () => setState(() => _videos.removeAt(i))),
          for (var i = 0; i < _newVideos.length; i++) _thumb(Icon(Icons.videocam_rounded, color: kInkGreen), () => setState(() => _newVideos.removeAt(i))),
          if (_photoCount < kMaxPhotos) _addBox(Icons.add_photo_alternate_outlined, _addPhotos),
          if (_videoCount < kMaxVideos) _addBox(Icons.video_call_outlined, _addVideo),
        ])),
        Padding(padding: const EdgeInsets.only(top: 6, bottom: 12),
            child: Text(tr('Up to 5 photos and 3 videos (max 60 seconds). Show more on your TikTok, Instagram or YouTube.'), style: tsBodySm(color: kTextSub))),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Text(countryFlag(_country), style: const TextStyle(fontSize: 26)),
          title: Text(tr(countryName(_country)), style: tsBodyLg(color: kText)),
          trailing: widget.wekilCode != null ? null : Text(tr('Change'), style: tsBodySm(color: kInkGreen).copyWith(fontWeight: FontWeight.w700)),
          onTap: widget.wekilCode != null ? null : () async {
            final r = await pickServiceLocation(context, _country, '', const []);
            if (r != null && mounted) { setState(() => _country = r.$1); _loadCities(); }
          },
        ),
        // region: the big cities of the country as quick choices, or write another city below
        Text(tr('Region'), style: tsLabel()),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final r in {...(kRegionsOf[_country] ?? const <String>[]), ..._citySuggest})
            ChoiceChip(
              label: Text(r), showCheckmark: false, selectedColor: kHabGreen,
              selected: _city.text.trim().toLowerCase() == r.toLowerCase(),
              labelStyle: TextStyle(color: _city.text.trim().toLowerCase() == r.toLowerCase() ? Colors.white : kText, fontWeight: FontWeight.w600),
              onSelected: (_) => setState(() { _city.text = r; _cityRev++; }),
            ),
        ]),
        const SizedBox(height: 10),
        Autocomplete<String>(
          key: ValueKey(_cityRev),
          initialValue: TextEditingValue(text: _city.text),
          optionsBuilder: (v) => _citySuggest.where((c) => v.text.isNotEmpty && c.toLowerCase().startsWith(v.text.toLowerCase())),
          onSelected: (v) => _city.text = v,
          fieldViewBuilder: (_, ctrl, focus, __) {
            ctrl.addListener(() => _city.text = ctrl.text);
            return Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: ctrl, focusNode: focus, style: tsBodyLg(color: kText),
                decoration: InputDecoration(labelText: tr('Another city / region'))));
          },
        ),
        _f(_area, tr('Area (optional)')),
        _f(_price, tr('Price (optional)'), hint: tr('e.g. from 5 000 kr')),
        _f(_langs, tr('Languages you speak'), hint: 'ትግርኛ, አማርኛ, English'),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: _travels, activeThumbColor: kHabGreen,
            title: Text(tr('I travel to other cities or countries'), style: tsBodyLg(color: kText)), onChanged: (v) => setState(() => _travels = v)),
        if (_travels) _f(_where, tr('Where?')),
        _f(_wa, tr('WhatsApp number'), type: TextInputType.phone, hint: '+47 …'),
        _f(_phone, tr('Phone (optional)'), type: TextInputType.phone),
        _f(_tt, tr('TikTok link'), type: TextInputType.url, hint: 'https://'),
        _f(_ig, tr('Instagram link'), type: TextInputType.url, hint: 'https://'),
        _f(_yt, tr('YouTube link'), type: TextInputType.url, hint: 'https://'),
        if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_error, style: tsBodySm(color: kRed))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52)),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '…' : _staff ? tr('Save and publish') : tr('Send for approval')),
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 20),
      ]),
    );
  }

  Widget _thumb(Widget w, VoidCallback remove) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Stack(children: [
      ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(width: 84, height: 84, color: kTintGreen, child: Center(child: w))),
      Positioned(right: 2, top: 2, child: InkWell(onTap: remove, child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)))),
    ]),
  );

  Widget _addBox(IconData i, VoidCallback tap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: InkWell(onTap: tap, borderRadius: BorderRadius.circular(12),
        child: Container(width: 84, height: 84, decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12)), child: Icon(i, color: kTextSub))),
  );
}

// ── My services ──
class MyServicesScreen extends StatelessWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kBg, title: Text(tr('My services'), style: tsTitleMd(color: kText))),
      floatingActionButton: FloatingActionButton.extended(backgroundColor: kHabGreen, foregroundColor: Colors.white,
          onPressed: () => openServiceForm(context), icon: const Icon(Icons.add_rounded), label: Text(tr('Register your service (free)'))),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _svc.where('ownerId', isEqualTo: u.uid).snapshots(),
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          if (snap.hasData && docs.isEmpty) return Center(child: Text(tr('You have no services yet'), style: tsBodySm(color: kTextSub)));
          return ListView(padding: const EdgeInsets.all(16), children: [
            for (final d in docs) Card(color: kCard, child: ListTile(
              title: Text(serviceText(d.data(), 'publicName'), style: tsTitleMd(color: kText)),
              subtitle: Text('${serviceSubLabel(d.data())} · ${serviceStr(d.data()['city'])}\n${_statusText(serviceStr(d.data()['status']))}', style: tsBodySm(color: kTextSub)),
              isThreeLine: true,
              trailing: Wrap(children: [
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => openServiceForm(context, docId: d.id, existing: d.data())),
                IconButton(icon: Icon(Icons.delete_outline_rounded, color: kRed), onPressed: () async {
                  final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(backgroundColor: kCard,
                    content: Text(tr('Delete this service?')),
                    actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel'))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Delete'), style: TextStyle(color: kRed)))]));
                  if (ok == true) await d.reference.delete();
                }),
              ]),
            )),
          ]);
        },
      ),
    );
  }
}

String _statusText(String s) => s == 'approved' ? '✓ ${tr('Published')}' : s == 'rejected' ? tr('Not approved') : tr('Waiting for approval');

// ── Admin: services that providers registered themselves ──
class ServicesApprovalTab extends StatelessWidget {
  const ServicesApprovalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _svc.where('status', isEqualTo: 'pending').snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        if (snap.hasData && docs.isEmpty) return Center(child: Text(tr('Nothing here'), style: tsBodySm(color: kTextSub)));
        return ListView(padding: const EdgeInsets.all(12), children: [
          for (final d in docs) Card(color: kCard, child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(serviceText(d.data(), 'publicName'), style: tsTitleMd(color: kText)),
              SelectableText('${serviceSubLabel(d.data())} · ${serviceStr(d.data()['city'])} · ${countryLabel(serviceStr(d.data()['country']))}\n'
                  'WhatsApp ${serviceStr(d.data()['whatsapp'])} · ${serviceImages(d.data()).length} 📷 · ${serviceVideos(d.data()).length} 🎬',
                  style: tsBodySm(color: kTextSub)),
              Row(children: [
                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceProviderScreen(docId: d.id, data: d.data()))),
                    child: Text(tr('Open'))),
                TextButton(onPressed: () => sendNoticeDialog(context, toUid: serviceStr(d.data()['ownerId']), refName: serviceText(d.data(), 'publicName'),
                    refType: 'service', refId: d.id), child: Text(tr('Message'))),
                const Spacer(),
                TextButton(onPressed: () => d.reference.update({'status': 'rejected', 'available': false}), child: Text(tr('Reject'), style: TextStyle(color: kRed))),
                FilledButton(style: FilledButton.styleFrom(backgroundColor: kHabGreen),
                    onPressed: () => d.reference.update({'status': 'approved', 'available': true}), child: Text(tr('Approve'))),
              ]),
            ]),
          )),
        ]);
      },
    );
  }
}


/// The provider's name, or "Habesha Hub Norge" when the country has a wekil (the wekil is the contact).
class ServiceNameText extends StatelessWidget {
  final Map<String, dynamic> data;
  final TextStyle style;
  final int? maxLines;
  const ServiceNameText({super.key, required this.data, required this.style, this.maxLines});
  @override
  Widget build(BuildContext context) => Text(serviceText(data, 'publicName'),
      maxLines: maxLines, overflow: maxLines == null ? null : TextOverflow.ellipsis, style: style);
}
