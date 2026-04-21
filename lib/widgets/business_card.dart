import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/business.dart';
import '../utils/language_notifier.dart';
import '../theme/app_theme.dart';

class BusinessCard extends StatefulWidget {
  final Business business;
  final double userLat;
  final double userLng;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteChanged;

  const BusinessCard({
    super.key,
    required this.business,
    required this.userLat,
    required this.userLng,
    required this.onTap,
    this.onFavoriteChanged,
  });

  @override
  State<BusinessCard> createState() => _BusinessCardState();
}

class _BusinessCardState extends State<BusinessCard> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFav();
  }

  Future<void> _checkFav() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorites') ?? [];
    if (mounted)
      setState(() => _isFavorite = favs.contains(widget.business.id));
  }

  Future<void> _toggleFav() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorites') ?? [];
    if (_isFavorite)
      favs.remove(widget.business.id);
    else
      favs.add(widget.business.id);
    await prefs.setStringList('favorites', favs);
    setState(() => _isFavorite = !_isFavorite);
    widget.onFavoriteChanged?.call();
  }

  String _ctaLabel() {
    switch (widget.business.category) {
      case 'Restaurant':
        return 'Se meny ›';
      case 'Butikk':
        return 'Utforsk utvalg ›';
      case 'Kafé':
        return 'Finn veien ›';
      case 'Frisør':
        return 'Bestill time ›';
      case 'Club':
        return 'Mer info ›';
      default:
        return 'Se mer ›';
    }
  }

  String _categoryEmoji() {
    switch (widget.business.category) {
      case 'Restaurant':
        return '🍽️';
      case 'Butikk':
        return '🛒';
      case 'Kafé':
        return '☕';
      case 'Frisør':
        return '💇';
      case 'Club':
        return '🎵';
      case 'Klinikk':
        return '🏥';
      default:
        return '🏠';
    }
  }

  void _showMenuDialog() {
    if (widget.business.pdfMenuUrl != null &&
        widget.business.pdfMenuUrl!.isNotEmpty) {
      final url = Uri.parse(widget.business.pdfMenuUrl!);
      canLaunchUrl(url).then((ok) {
        if (ok) launchUrl(url, mode: LaunchMode.externalApplication);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            languageNotifier.language == 'Tigrinya'
                ? 'ሜኑ ገና ኣይተጸዓነን'
                : languageNotifier.language == 'English'
                    ? 'Menu not available yet'
                    : 'Meny ikke tilgjengelig ennå',
            style: tsBodySm(color: kOnSurface)),
        backgroundColor: kSurfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: kSurfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            _buildImage(),
            // Info
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: CachedNetworkImage(
            imageUrl: widget.business.imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 200,
              color: kSurfaceContainerHigh,
              child: const Center(
                  child: CircularProgressIndicator(
                      color: kSecondary, strokeWidth: 1.5)),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 200,
              color: kSurfaceContainerHigh,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.storefront_rounded,
                        size: 52, color: kSecondary),
                    const SizedBox(height: 8),
                    Text(widget.business.name, style: tsLabel()),
                  ]),
            ),
          ),
        ),

        // Top right: Open/Closed badge
        Positioned(
          top: 12,
          right: 12,
          child: openBadge(widget.business.isOpen),
        ),

        // Top left: Menu + Favorite icons
        Positioned(
          top: 12,
          left: 12,
          child: Row(children: [
            _iconBtn(Icons.menu_book_rounded, _showMenuDialog),
            const SizedBox(width: 8),
            _iconBtn(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              _toggleFav,
              color: _isFavorite ? Colors.redAccent : kOnSurface,
            ),
          ]),
        ),

        // Bottom left: Category badge
        Positioned(
          bottom: 10,
          left: 12,
          child:
              categoryBadge('${_categoryEmoji()} ${widget.business.category}'),
        ),

        // Premium badge bottom right
        if (widget.business.isPremium)
          Positioned(
            bottom: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: kSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(100),
                border:
                    Border.all(color: kSecondary.withOpacity(0.4), width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.verified_rounded, color: kSecondary, size: 10),
                const SizedBox(width: 3),
                Text('PREMIUM', style: tsLabel()),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap,
      {Color color = kSecondary}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }

  Widget _buildInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + star rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(widget.business.name,
                    style: TextStyle(
                      fontFamily: kFontHeadline,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kSecondary,
                    )),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kSurfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, color: kSecondary, size: 14),
                  const SizedBox(width: 3),
                  Text(widget.business.rating.toStringAsFixed(1),
                      style: tsTitleMd(color: kOnSurface)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Description
          Text(widget.business.description,
              style: tsBodySm(color: kOnSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),

          const SizedBox(height: 14),

          // Divider
          Container(height: 0.5, color: kOutlineVariant.withOpacity(0.1)),
          const SizedBox(height: 12),

          // Distance + CTA
          Row(
            children: [
              const Icon(Icons.near_me_rounded,
                  color: kOnSurfaceVariant, size: 14),
              const SizedBox(width: 5),
              Text(
                widget.userLat == 0
                    ? widget.business.address
                    : widget.business
                        .formattedDistance(widget.userLat, widget.userLng),
                style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kOnSurfaceVariant.withOpacity(0.7)),
              ),
              const Spacer(),
              Text(_ctaLabel(),
                  style: TextStyle(
                    fontFamily: kFontBody,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kSecondary,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
