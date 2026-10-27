import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../widgets/business_card.dart';
import 'business_detail_screen.dart';
import '../utils/translations.dart';
import 'provider_extras.dart';

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
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favIds = prefs.getStringList('favorites') ?? [];
    
    if (favIds.isEmpty) {
      setState(() { _favorites = []; _loading = false; });
      return;
    }

    final businesses = <Business>[];
    for (final id in favIds) {
      try {
        final doc = await _db.collection('businesses').doc(id).get();
        if (doc.exists) {
          businesses.add(Business.fromFirestore(doc.data()!, doc.id));
        }
      } catch (e) {
        debugPrint('Error loading business $id: $e');
      }
    }

    setState(() { _favorites = businesses; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final t = languageNotifier.t;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        iconTheme: const IconThemeData(color: kSecondary),
        title: AnimatedBuilder(animation: languageNotifier, builder: (_, __) => Text(languageNotifier.t('favorites_title'), style: tsTitleMd(color: kSecondary))),
        actions: [
          IconButton(
            tooltip: tr('Favorite services'),
            icon: const Icon(Icons.miscellaneous_services_rounded, color: kSecondary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const FavoriteServicesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kSecondary),
            onPressed: () {
              setState(() => _loading = true);
              _loadFavorites();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kSecondary, strokeWidth: 1.5))
          : _favorites.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('❤️', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(languageNotifier.t('favorites_title'), style: tsTitleLg()),
                  const SizedBox(height: 8),
                  Text(tr('Tap the heart icon on a business to save it'), style: tsBodySm(color: kTextSub), textAlign: TextAlign.center),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favorites.length,
                  itemBuilder: (_, i) {
                    final business = _favorites[i];
                    return BusinessCard(
                      key: ValueKey(business.id),
                      business: business,
                      userLat: 0,
                      userLng: 0,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessDetailScreen(business: business, userLat: 0, userLng: 0))),
                      onFavoriteChanged: _loadFavorites,
                    );
                  },
                ),
    );
  }
}
