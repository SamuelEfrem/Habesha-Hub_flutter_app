import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/business.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';
import 'business_detail_screen.dart';

/// All businesses of a list as pins on a map. Tap a pin → small card →
/// tap the card → business page.
class BusinessesMapScreen extends StatefulWidget {
  final List<Business> businesses;
  final String title;
  final double? userLat;
  final double? userLng;
  const BusinessesMapScreen({
    super.key,
    required this.businesses,
    this.title = '',
    this.userLat,
    this.userLng,
  });

  @override
  State<BusinessesMapScreen> createState() => _BusinessesMapScreenState();
}

class _BusinessesMapScreenState extends State<BusinessesMapScreen> {
  Business? _selected;

  static const _emoji = {
    'Restaurant': '🍽️', 'Shop': '🛍️', 'Cafe': '☕', 'Barber': '💇', 'Club': '🎵',
    'Clinic': '🏥', 'Hotel': '🏨', 'Church': '⛪', 'Association': '🤝',
  };

  List<Business> get _onMap =>
      widget.businesses.where((b) => !(b.lat == 0 && b.lng == 0)).toList();

  bool get _hasUser => widget.userLat != null && widget.userLat != 0;

  @override
  Widget build(BuildContext context) {
    final list = _onMap;
    final points = [
      for (final b in list) LatLng(b.lat, b.lng),
      if (_hasUser) LatLng(widget.userLat!, widget.userLng!),
    ];
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: kSecondary),
        title: Text(widget.title.isEmpty ? tr('Map') : widget.title, style: tsHeadlineSm(color: kText)),
      ),
      body: Stack(children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: points.isEmpty ? const LatLng(20, 10) : points.first,
            initialZoom: points.isEmpty ? 2 : 12,
            initialCameraFit: points.length > 1
                ? CameraFit.coordinates(
                    coordinates: points,
                    padding: const EdgeInsets.fromLTRB(40, 40, 40, 160),
                    maxZoom: 15)
                : null,
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'no.habesha.hub',
            ),
            MarkerLayer(markers: [
              if (_hasUser)
                Marker(
                  point: LatLng(widget.userLat!, widget.userLng!),
                  width: 22, height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 10)],
                    ),
                  ),
                ),
              for (final b in list)
                Marker(
                  point: LatLng(b.lat, b.lng),
                  width: 44, height: 44,
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = b),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: _selected?.id == b.id ? kSecondary : kPrimaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: kSecondary, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      alignment: Alignment.center,
                      child: Text(_emoji[b.category] ?? '📍', style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
            ]),
          ],
        ),
        // Required by OpenStreetMap
        Positioned(
          left: 6, bottom: 4,
          child: Text('© OpenStreetMap contributors',
              style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.6))),
        ),
        Positioned(
          top: 12, left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(100),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)]),
            child: Text('${list.length} ${tr('places')}', style: tsTitleMd(color: kText)),
          ),
        ),
        if (_selected != null)
          Positioned(left: 16, right: 16, bottom: 24, child: _card(_selected!)),
      ]),
    );
  }

  Widget _card(Business b) {
    final dist = _hasUser ? b.formattedDistance(widget.userLat!, widget.userLng!) : '';
    return Material(
      color: kCard,
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => BusinessDetailScreen(
                business: b, userLat: widget.userLat ?? 0, userLng: widget.userLng ?? 0))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: kSecondary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Text(_emoji[b.category] ?? '📍', style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: tsTitleLg(color: kText)),
              Text([tr(b.category), if (dist.isNotEmpty) dist].join('  ·  '),
                  style: tsBodySm(color: kSecondary).copyWith(fontWeight: FontWeight.w600)),
              if (b.address.isNotEmpty)
                Text(b.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: tsBodySm(color: kTextSub)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: kSecondary),
          ]),
        ),
      ),
    );
  }
}

/// Small "Map" button used above result lists
Widget mapButton(VoidCallback onTap) => Material(
      color: kSecondary.withOpacity(0.15),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.map_rounded, color: kSecondary, size: 16),
            const SizedBox(width: 6),
            Text(tr('Map'), style: tsTitleMd(color: kSecondary)),
          ]),
        ),
      ),
    );
