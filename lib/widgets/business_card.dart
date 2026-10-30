import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/business.dart';
import '../utils/language_notifier.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';

class BusinessCard extends StatefulWidget {
  final Business business;
  final double userLat;
  final double userLng;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteChanged;

  BusinessCard({
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
    if (mounted) setState(() => _isFavorite = favs.contains(widget.business.id));
  }

  Future<void> _toggleFav() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorites') ?? [];
    if (_isFavorite) {
      favs.remove(widget.business.id);
    } else {
      favs.add(widget.business.id);
    }
    await prefs.setStringList('favorites', favs);
    setState(() => _isFavorite = !_isFavorite);
    widget.onFavoriteChanged?.call();
  }

  String _categoryEmoji() {
    switch (widget.business.category) {
      case 'Restaurant': return '\ud83c\udf7d\ufe0f';
      case 'Shop': return '\ud83d\udecd';
      case 'Cafe': return '\u2615';
      case 'Barber': return '\ud83d\udc87';
      case 'Club': return '\ud83c\udfb5';
      case 'Clinic': return '\ud83c\udfe5';
      case 'Hotel': return '\ud83c\udfe8';
      case 'Church': return '⛪';
      case 'Association': return '🤝';
      default: return '\ud83c\udfe0';
    }
  }

  void _showMenuDialog() {
    if (widget.business.pdfMenuUrl != null && widget.business.pdfMenuUrl!.isNotEmpty) {
      final url = Uri.parse(widget.business.pdfMenuUrl!);
      canLaunchUrl(url).then((ok) {
        if (ok) launchUrl(url, mode: LaunchMode.externalApplication);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          languageNotifier.language == 'Tigrinya' ? '\u1234\u1291 \u1308\u1293 \u12a3\u12ed\u1270\u1338\u12a3\u1290\u1295'
            : tr('Menu not available yet'),
          style: tsBodySm(color: kText)),
        backgroundColor: kCardHigh,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Material(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: b.imageUrl.isEmpty ? _buildCompact() : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildImage(), habeshaStripe(height: 4), _buildInfo()],
          ),
        ),
      ),
    );
  }

  bool get _hasMenu => (widget.business.pdfMenuUrl ?? '').isNotEmpty;

  String get _distance => widget.userLat == 0
      ? ''
      : widget.business.formattedDistance(widget.userLat, widget.userLng);

  // ── No photo: one tidy row instead of a big empty box ──
  Widget _buildCompact() {
    final b = widget.business;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 14, 6, 14),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: kSecondary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(_categoryEmoji(), style: TextStyle(fontSize: 26)),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: tsTitleLg(color: kText).copyWith(fontSize: 16)),
            SizedBox(height: 3),
            Text(
              [tr(b.category), if (_distance.isNotEmpty) _distance].join('  ·  '),
              style: tsBodySm(color: kSecondary).copyWith(fontWeight: FontWeight.w600),
            ),
            if (b.address.isNotEmpty) ...[
              SizedBox(height: 2),
              Text(b.address, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: tsBodySm(color: kTextSub)),
            ],
            if (b.hasKnownHours) ...[
              SizedBox(height: 6),
              _openDot(),
            ],
          ]),
        ),
        IconButton(
          onPressed: _toggleFav,
          icon: Icon(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.redAccent : kTextSub, size: 22),
        ),
      ]),
    );
  }

  Widget _openDot() {
    final open = widget.business.isOpenNow;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7,
          decoration: BoxDecoration(color: open ? kGreen : kRed, shape: BoxShape.circle)),
      SizedBox(width: 6),
      Text(open ? tr('Open now') : tr('Closed'),
          style: tsBodySm(color: open ? kGreen : kRed).copyWith(fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildImage() {
    final b = widget.business;
    return Stack(children: [
      CachedNetworkImage(
        imageUrl: b.imageUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        memCacheWidth: 1080,
        placeholder: (_, __) => Container(height: 180, color: kCardHigh),
        errorWidget: (_, __, ___) => Container(height: 180, color: kCardHigh,
            alignment: Alignment.center,
            child: Text(_categoryEmoji(), style: TextStyle(fontSize: 48))),
      ),
      if (b.hasKnownHours) Positioned(top: 12, right: 12, child: openBadge(b.isOpenNow)),
      Positioned(
        top: 12, left: 12,
        child: Row(children: [
          if (_hasMenu) ...[
            _iconBtn(Icons.menu_book_rounded, _showMenuDialog),
            SizedBox(width: 8),
          ],
          _iconBtn(_isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, _toggleFav, color: _isFavorite ? Colors.redAccent : Colors.white),
        ]),
      ),
      if (b.isPremium)
        Positioned(bottom: 10, right: 12, child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(100), ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified_rounded, color: kSecondary, size: 12), SizedBox(width: 4), Text('Premium', style: tsLabel())]),
        )),
    ]);
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle),
        child: Icon(icon, color: color ?? kSecondary, size: 18),
      ),
    );
  }

  Widget _buildInfo() {
    final b = widget.business;
    final rated = b.rating > 0 || b.ratingCount > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(b.name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: kFontHeadline, fontSize: 20, fontWeight: FontWeight.w700, color: kText, height: 1.2))),
          if (rated) ...[
            const SizedBox(width: 8),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.star_rounded, color: kSecondary, size: 18),
              const SizedBox(width: 2),
              Text(b.rating.toStringAsFixed(1), style: tsTitleMd(color: kText)),
            ]),
          ],
        ]),
        const SizedBox(height: 4),
        Text(
          [tr(b.category), if (_distance.isNotEmpty) _distance].join('  ·  '),
          style: tsBodySm(color: kSecondary).copyWith(fontWeight: FontWeight.w600),
        ),
        if (b.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(b.description, style: tsBodySm(color: kTextSub), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ]),
    );
  }
}
