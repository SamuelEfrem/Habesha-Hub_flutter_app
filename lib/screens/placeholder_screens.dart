import 'admin_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/business.dart';
import '../widgets/business_card.dart';
import '../utils/language_notifier.dart';
import '../theme/app_theme.dart';
import 'business_detail_screen.dart';
import 'register_business_screen.dart';
import 'auth_screen.dart';
import 'admin_screen.dart';
import 'edit_business_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _db = FirebaseFirestore.instance;
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
        {'name': 'Etiopia', 'flag': '🇪🇹', 'label': 'country_etiopia', 'cities': ['Addis Ababa', 'Dire Dawa', 'Gondar']},
        {'name': 'Eritrea', 'flag': '🇪🇷', 'label': 'country_eritrea', 'cities': ['Asmara', 'Keren', 'Massawa']},
        {'name': 'Egypt', 'flag': '🇪🇬', 'label': 'country_egypt', 'cities': ['Cairo', 'Alexandria', 'Giza']},
        {'name': 'Kenya', 'flag': '🇰🇪', 'label': 'country_kenya', 'cities': ['Nairobi', 'Mombasa', 'Kisumu']},
      ]
    },
    {
      'name': 'Europe',
      'emoji': '🌍',
      'countries': [
        {'name': 'Norge', 'flag': '🇳🇴', 'label': 'country_norge', 'cities': ['Oslo', 'Bergen', 'Stavanger', 'Trondheim']},
        {'name': 'Sverige', 'flag': '🇸🇪', 'label': 'country_sverige', 'cities': ['Stockholm', 'Göteborg', 'Malmö']},
        {'name': 'Danmark', 'flag': '🇩🇰', 'label': 'country_danmark', 'cities': ['København', 'Aarhus', 'Odense']},
        {'name': 'UK', 'flag': '🇬🇧', 'label': 'country_uk', 'cities': ['London', 'Manchester', 'Birmingham']},
        {'name': 'Tyskland', 'flag': '🇩🇪', 'label': 'country_tyskland', 'cities': ['Berlin', 'Hamburg', 'München']},
        {'name': 'Nederland', 'flag': '🇳🇱', 'label': 'country_nederland', 'cities': ['Amsterdam', 'Rotterdam', 'Den Haag']},
        {'name': 'Frankrike', 'flag': '🇫🇷', 'label': 'country_frankrike', 'cities': ['Paris', 'Lyon', 'Marseille']},
        {'name': 'Belgia', 'flag': '🇧🇪', 'label': 'country_belgia', 'cities': ['Brussel', 'Antwerpen', 'Gent']},
        {'name': 'Sveits', 'flag': '🇨🇭', 'label': 'country_sveits', 'cities': ['Zürich', 'Genève', 'Basel']},
        {'name': 'Italia', 'flag': '🇮🇹', 'label': 'country_italia', 'cities': ['Roma', 'Milano', 'Napoli']},
      ]
    },
    {
      'name': 'Amerika',
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
          backgroundColor: kSurface,
          body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(color: kSurfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  style: tsBodyLg(color: kOnSurface),
                  onChanged: (v) { setState(() => _searchQuery = v); if (_hasSearched) _filterResults(); },
                  decoration: InputDecoration(
                    hintText: t('search_hint'),
                    hintStyle: tsBodySm(color: kOnSurfaceVariant.withOpacity(0.5)),
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
                      decoration: BoxDecoration(color: sel ? kSecondary : kSurfaceContainer, borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(cont['emoji'] as String, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(cont['name'] as String, style: tsLabel(color: sel ? const Color(0xFF342800) : kOnSurfaceVariant)),
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
                          color: sel ? kPrimaryContainer.withOpacity(0.3) : kSurfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? kSecondary : Colors.transparent, width: 0.5),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(c['flag'] as String, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(t(c['label'] as String), style: tsLabel(color: sel ? kSecondary : kOnSurfaceVariant.withOpacity(0.6))),
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
                        decoration: BoxDecoration(color: sel ? kSecondary : kSurfaceContainer, borderRadius: BorderRadius.circular(100)),
                        child: Text(city, style: tsLabel(color: sel ? const Color(0xFF342800) : kOnSurfaceVariant)),
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
                  children: ['Alle', 'Restaurant', 'Kafé', 'Butikk', 'Frisør', 'Club', 'Klinikk', 'Fotograf', 'Musikk', 'Dekorasjon', 'Taxi', 'Annet'].map((cat) {
                    final sel = cat == 'Alle' ? _selectedCategory.isEmpty : _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () { setState(() => _selectedCategory = cat == 'Alle' ? '' : cat); if (_hasSearched) _filterResults(); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: sel ? kSecondary : kSurfaceContainer, borderRadius: BorderRadius.circular(100)),
                        child: Text(cat, style: tsLabel(color: sel ? const Color(0xFF342800) : kOnSurfaceVariant)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: goldButton(
                  '${t('search_in')} ${t('country_${_selectedCountry.toLowerCase()}')}${_selectedCity.isNotEmpty ? " / $_selectedCity" : ""}',
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
                          backgroundColor: kSurfaceContainer,
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
// FAVORITES SCREEN
// ═══════════════════════════════════════════════════════════
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _db = FirebaseFirestore.instance;
  List<Business> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('favorites') ?? [];
    if (ids.isEmpty) {
      setState(() { _favorites = []; _loading = false; });
      return;
    }
    final List<Business> favs = [];
    for (final id in ids) {
      final doc = await _db.collection('businesses').doc(id).get();
      if (doc.exists) favs.add(Business.fromFirestore(doc.data()!, doc.id));
    }
    setState(() { _favorites = favs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        return Scaffold(
          backgroundColor: kSurface,
          body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 16), child: Text(t('favorites_title'), style: tsHeadlineMd(color: kSecondary))),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5))
                  : RefreshIndicator(
                      color: kSecondary,
                      backgroundColor: kSurfaceContainer,
                      onRefresh: _load,
                      child: _favorites.isEmpty
                          ? ListView(children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.55,
                                child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  const Icon(Icons.favorite_border_rounded, size: 64, color: kOnSurfaceVariant),
                                  const SizedBox(height: 16),
                                  Text(t('no_favorites'), style: tsTitleLg(), textAlign: TextAlign.center),
                                  const SizedBox(height: 8),
                                  Text(t('tap_heart'), style: tsBodySm(), textAlign: TextAlign.center),
                                ])),
                              )
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _favorites.length,
                              itemBuilder: (_, i) {
                                final b = _favorites[i];
                                return BusinessCard(
                                  business: b, userLat: 0, userLng: 0,
                                  onFavoriteChanged: _load,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: b, userLat: 0, userLng: 0))));
                              }),
                    ),
            ),
          ])),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CHAT LIST SCREEN
// ═══════════════════════════════════════════════════════════
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _db = FirebaseFirestore.instance;
  String? _userId;
  bool _isOwner = false;
  List<Business> _myBusinesses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? prefs.getString('userId') ?? '';
    setState(() => _userId = uid);
    if (user != null && !user.isAnonymous) {
      final isAdmin = ['samuelefriem@gmail.com'].contains(user.email);
      final snap = isAdmin
          ? await _db.collection('businesses').get()
          : await _db.collection('businesses').where('ownerId', isEqualTo: user.uid).get();
      final businesses = snap.docs.map((d) => Business.fromFirestore(d.data(), d.id)).toList();
      setState(() { _myBusinesses = businesses; _isOwner = businesses.isNotEmpty; _loading = false; });
    } else {
      setState(() { _isOwner = false; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        return Scaffold(
          backgroundColor: kSurface,
          body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 16), child: Text(t('messages_title'), style: tsHeadlineMd(color: kSecondary))),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5))
                  : _isOwner ? _buildOwnerView(t) : _buildUserView(t),
            ),
          ])),
        );
      },
    );
  }

  Widget _buildOwnerView(String Function(String) t) {
    return ListView.builder(
      itemCount: _myBusinesses.length,
      itemBuilder: (_, i) {
        final business = _myBusinesses[i];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(children: [
              const Icon(Icons.storefront_rounded, color: kSecondary, size: 16),
              const SizedBox(width: 8),
              Text(business.name, style: tsTitleMd(color: kSecondary)),
            ]),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('chats').snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox();
              final chats = snap.data!.docs.where((d) => d.id.startsWith('${business.id}_')).toList();
              if (chats.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text('Ingen meldinger ennå', style: tsBodySm(color: kOnSurfaceVariant)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chats.length,
                itemBuilder: (_, j) => _OwnerChatTile(db: _db, business: business, chatId: chats[j].id),
              );
            },
          ),
          const Divider(color: Colors.white10),
        ]);
      },
    );
  }

  Widget _buildUserView(String Function(String) t) {
    if (_userId == null || _userId!.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: kOnSurfaceVariant),
        const SizedBox(height: 16),
        Text('Start en chat med en bedrift', style: tsTitleLg(), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Gå til en bedrift og trykk på chat-fanen.', style: tsBodySm(), textAlign: TextAlign.center),
      ])));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('chats').snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5));
        final userChats = snap.data!.docs.where((d) => d.id.endsWith('_$_userId')).toList();
        if (userChats.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 64, color: kOnSurfaceVariant),
            const SizedBox(height: 16),
            Text(t('no_chats'), style: tsTitleLg(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Gå til en bedrift og start en chat!', style: tsBodySm(), textAlign: TextAlign.center),
          ])));
        }
        return ListView.builder(
          itemCount: userChats.length,
          itemBuilder: (_, i) {
            final chatId = userChats[i].id;
            final businessId = chatId.replaceAll('_$_userId', '');
            return _UserChatTile(db: _db, businessId: businessId, chatId: chatId, userId: _userId!);
          },
        );
      },
    );
  }
}

class _OwnerChatTile extends StatelessWidget {
  final FirebaseFirestore db;
  final Business business;
  final String chatId;
  const _OwnerChatTile({required this.db, required this.business, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('chats').doc(chatId).collection('messages').orderBy('createdAt', descending: true).limit(1).snapshots(),
      builder: (_, msgSnap) {
        String lastMsg = '...', timeStr = '', senderName = 'Bruker';
        if (msgSnap.hasData && msgSnap.data!.docs.isNotEmpty) {
          final data = msgSnap.data!.docs.first.data() as Map<String, dynamic>;
          lastMsg = data['text'] ?? '...';
          senderName = data['nickname'] ?? 'Bruker';
          final ts = data['createdAt'] as Timestamp?;
          if (ts != null) timeStr = DateFormat('HH:mm').format(ts.toDate());
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(radius: 24, backgroundColor: kSurfaceContainerHigh, child: Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : '?', style: tsTitleMd(color: kSecondary))),
            title: Text(senderName, style: tsTitleMd()),
            subtitle: Text(lastMsg, style: tsBodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(timeStr, style: tsLabel(color: kOnSurfaceVariant.withOpacity(0.5)).copyWith(fontSize: 9)),
              const SizedBox(height: 4),
              const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 12),
            ]),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminChatScreen(business: business, chatId: chatId))),
          ),
        );
      },
    );
  }
}

class _UserChatTile extends StatelessWidget {
  final FirebaseFirestore db;
  final String businessId, chatId, userId;
  const _UserChatTile({required this.db, required this.businessId, required this.chatId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: db.collection('businesses').doc(businessId).get(),
      builder: (_, bSnap) {
        if (!bSnap.hasData || !bSnap.data!.exists) return const SizedBox();
        final b = Business.fromFirestore(bSnap.data!.data() as Map<String, dynamic>, bSnap.data!.id);
        return StreamBuilder<QuerySnapshot>(
          stream: db.collection('chats').doc(chatId).collection('messages').orderBy('createdAt', descending: true).limit(1).snapshots(),
          builder: (_, msgSnap) {
            String lastMsg = '...', timeStr = '';
            if (msgSnap.hasData && msgSnap.data!.docs.isNotEmpty) {
              final data = msgSnap.data!.docs.first.data() as Map<String, dynamic>;
              lastMsg = data['text'] ?? '...';
              final ts = data['createdAt'] as Timestamp?;
              if (ts != null) timeStr = DateFormat('HH:mm').format(ts.toDate());
            }
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(radius: 26, backgroundColor: kSurfaceContainerHigh, backgroundImage: b.imageUrl.isNotEmpty ? NetworkImage(b.imageUrl) : null, child: b.imageUrl.isEmpty ? const Icon(Icons.storefront_rounded, color: kSecondary) : null),
                title: Text(b.name, style: tsTitleMd()),
                subtitle: Text(lastMsg, style: tsBodySm(), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(timeStr, style: tsLabel(color: kOnSurfaceVariant.withOpacity(0.5)).copyWith(fontSize: 9)),
                  const SizedBox(height: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 12),
                ]),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: b, userLat: 0, userLng: 0, openChat: true))),
              ),
            );
          },
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
  String _selectedLang = 'Norsk';
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
      backgroundColor: kSurfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Logg ut', style: tsHeadlineSm(color: kOnSurface)),
      content: Text('Er du sikker på at du vil logge ut?', style: tsBodyLg()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Avbryt', style: tsBodySm())),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Logg ut', style: tsTitleMd(color: kRed))),
      ],
    ));
    if (confirm != true) return;
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nickname');
    await prefs.remove('favorites');
    await languageNotifier.setLanguage('Norsk');
    if (mounted) {
      setState(() { _user = null; _nicknameCtrl.text = ''; _selectedLang = 'Norsk'; _myBusinesses = []; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Du er logget ut', style: tsBodySm(color: kOnSurface)), backgroundColor: kSurfaceContainerHigh));
    }
  }

  Future<void> _deleteAccount() async {
    final t = languageNotifier.t;
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: kSurfaceContainerHigh,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Konto slettet', style: tsBodySm(color: kOnSurface)), backgroundColor: kSurfaceContainerHigh));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feil: Logg inn på nytt og prøv igjen.', style: tsBodySm(color: kOnSurface)), backgroundColor: kRed));
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
          backgroundColor: kSurface,
          body: SafeArea(child: SingleChildScrollView(child: Column(children: [
            Container(
              width: double.infinity,
              color: kSurfaceContainerLow,
              child: Column(children: [
                const SizedBox(height: 20),
                Stack(children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kSecondary, width: 2.5), boxShadow: [BoxShadow(color: kSecondary.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)]),
                    child: ClipOval(child: Image.asset('assets/images/icon.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: kSurfaceContainerHigh, child: const Icon(Icons.person_rounded, size: 56, color: kSecondary)))),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(_nicknameCtrl.text.isEmpty ? (isLoggedIn ? 'Bruker' : 'Gjest') : _nicknameCtrl.text, style: tsHeadlineMd()),
                const SizedBox(height: 4),
                Text(isLoggedIn ? (_user?.email ?? '') : 'Logg inn for å få full tilgang', style: tsBodySm(color: kOnSurfaceVariant.withOpacity(0.6)), textAlign: TextAlign.center),
                const SizedBox(height: 20),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (!isLoggedIn) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(14), border: Border.all(color: kSecondary.withOpacity(0.2), width: 0.5)),
                    child: Column(children: [
                      Row(children: [const Icon(Icons.login_rounded, color: kSecondary, size: 20), const SizedBox(width: 10), Text(t('login_register'), style: tsTitleMd(color: kSecondary))]),
                      const SizedBox(height: 8),
                      Text(t('login_for_business'), style: tsBodySm()),
                      const SizedBox(height: 14),
                      goldButton(t('login'), _login, icon: Icons.login_rounded),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(t('nickname').toUpperCase(), style: tsLabel()),
                const SizedBox(height: 8),
                TextField(
                  controller: _nicknameCtrl,
                  style: tsBodyLg(color: kOnSurface),
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
                    helperText: 'Press Enter to save',
                    helperStyle: TextStyle(fontSize: 10, color: kOnSurfaceVariant.withOpacity(0.4)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(children: [const Icon(Icons.translate_rounded, color: kSecondary, size: 18), const SizedBox(width: 8), Text('Language', style: tsHeadlineSm())]),
                const SizedBox(height: 14),
                ...[
                  {'code': 'English', 'label': 'English', 'flag': '🇬🇧'},
                  {'code': 'Tigrinya', 'label': 'ትግርኛ', 'flag': '🇪🇷'},
                  {'code': 'Amharic', 'label': 'አማርኛ', 'flag': '🇪🇹'},
                  {'code': 'Norsk', 'label': 'Norsk', 'flag': '🇳🇴'},
                ].map((lang) {
                  final sel = _selectedLang == lang['code'];
                  return GestureDetector(
                    onTap: () { setState(() => _selectedLang = lang['code']!); languageNotifier.setLanguage(lang['code']!); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: sel ? kPrimaryContainer : kSurfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 14),
                        Expanded(child: Text(lang['label']!, style: tsBodyLg(color: sel ? kOnSurface : kOnSurface.withOpacity(0.7)))),
                        if (sel) const Icon(Icons.check_circle_rounded, color: kSecondary, size: 20),
                      ]),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kPrimaryContainer, kPrimaryContainer.withOpacity(0.6)]), borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t('bring_vision'), style: tsHeadlineSm()),
                    const SizedBox(height: 6),
                    Text(t('list_business_desc'), style: tsBodySm(color: kOnSurface.withOpacity(0.7))),
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
                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12)), child: Text(t('no_businesses_yet'), style: tsBodySm(), textAlign: TextAlign.center))
                  else
                    ..._myBusinesses.map((b) => _businessRow(b, context)),
                  const SizedBox(height: 24),
                ],
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
      decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: kSurfaceContainerHigh, borderRadius: BorderRadius.circular(10)),
          child: b.imageUrl.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(b.imageUrl, fit: BoxFit.cover)) : const Icon(Icons.storefront_rounded, color: kSecondary, size: 24),
        ),
        title: Text(b.name, style: tsTitleMd()),
        subtitle: Text('${b.category}', style: tsBodySm()),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 13),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: b, userLat: 0, userLng: 0))),
      ),
    );
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.85, maxChildSize: 0.95,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl, padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: kOutlineVariant, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [const Icon(Icons.help_rounded, color: kSecondary, size: 24), const SizedBox(width: 10), Text('Help & Support', style: tsHeadlineMd(color: kSecondary))]),
            const SizedBox(height: 20),
            _faq('Hva er Habesha Hub?', 'Habesha Hub er en gratis plattform for å finne etiopiske og eritreiske bedrifter i nærheten og over hele verden.'),
            _faq('Trenger jeg konto?', 'Nei! Du kan bla gjennom bedrifter, søke og chatte som gjest.'),
            _faq('Hvordan registrerer jeg bedrift?', 'Gå til Profil → Register Your Business. Bedriften godkjennes innen 1-2 virkedager.'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kSurfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Kontakt oss', style: tsTitleMd(color: kSecondary)),
                const SizedBox(height: 10),
                Row(children: [const Icon(Icons.email_outlined, color: kSecondary, size: 15), const SizedBox(width: 8), Text('samuelefriem@gmail.com', style: tsBodySm())]),
              ]),
            ),
            const SizedBox(height: 16),
            goldButton('Send melding', () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactScreen())); }),
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
      iconColor: kSecondary, collapsedIconColor: kOnSurfaceVariant,
      children: [Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(a, style: tsBodySm()))],
    ),
  );

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: kSurfaceContainerHigh, borderRadius: BorderRadius.circular(100)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: kSecondary, size: 12), const SizedBox(width: 5), Text(label, style: tsLabel(color: kOnSurfaceVariant))]),
  );

  Widget _menuRow(IconData icon, String label, VoidCallback onTap, {Color color = kOnSurface}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: kSurfaceContainer, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: color == kOnSurface ? kSecondary : color, size: 20),
        const SizedBox(width: 14),
        Text(label, style: tsBodyLg(color: color)),
        const Spacer(),
        Icon(Icons.arrow_forward_ios_rounded, color: color == kOnSurface ? kOnSurfaceVariant.withOpacity(0.4) : color.withOpacity(0.6), size: 14),
      ]),
    ),
  );
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kSurface,
    appBar: AppBar(title: const Text('Personvern'), backgroundColor: kSurfaceContainer),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Personvernerklæring', style: tsHeadlineSm(color: kSecondary)),
        const SizedBox(height: 12),
        Text('Habesha Hub tar personvern på alvor. Vi samler minimalt med data.', style: tsBodyLg()),
        const SizedBox(height: 16),
        Text('Hva vi samler inn', style: tsTitleMd(color: kSecondary)),
        const SizedBox(height: 8),
        Text('• E-post og passord\n• Kallenavn\n• Chat-meldinger\n• GPS (kun ved søk)\n• Favoritt-bedrifter (lokalt)', style: tsBodyLg()),
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
      'createdAt': FieldValue.serverTimestamp(), 'replied': false, 'adminEmail': 'samuelefriem@gmail.com',
    });
    final subject = Uri.encodeComponent('Ny henvendelse fra ${_nameCtrl.text.trim()}');
    final body = Uri.encodeComponent('Fra: ${_nameCtrl.text.trim()}\nE-post: ${_emailCtrl.text.trim()}\n\nMelding:\n${_msgCtrl.text.trim()}');
    final url = Uri.parse('mailto:samuelefriem@gmail.com?subject=$subject&body=$body');
    if (await canLaunchUrl(url)) await launchUrl(url);
    setState(() { _sending = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kSurface,
    appBar: AppBar(title: const Text('Kontakt oss'), backgroundColor: kSurfaceContainer),
    body: _sent
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_rounded, color: kGreen, size: 64),
            const SizedBox(height: 16),
            Text('Melding sendt!', style: tsHeadlineSm()),
            const SizedBox(height: 8),
            Text('Vi svarer deg så snart som mulig.', style: tsBodySm()),
          ]))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Kontakt oss', style: tsHeadlineMd(color: kSecondary)),
              const SizedBox(height: 20),
              Text('NAVN', style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: _nameCtrl, style: tsBodyLg(color: kOnSurface), decoration: const InputDecoration(hintText: 'Ditt navn...')),
              const SizedBox(height: 12),
              Text('E-POST', style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: _emailCtrl, style: tsBodyLg(color: kOnSurface), keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'din@epost.no', prefixIcon: Icon(Icons.email_outlined, color: kSecondary))),
              const SizedBox(height: 12),
              Text('MELDING', style: tsLabel()),
              const SizedBox(height: 8),
              TextField(controller: _msgCtrl, maxLines: 5, style: tsBodyLg(color: kOnSurface), decoration: const InputDecoration(hintText: 'Skriv din melding her...')),
              const SizedBox(height: 24),
              goldButton('Send melding', _sending ? null : _send, loading: _sending),
            ]),
          ),
  );
}
