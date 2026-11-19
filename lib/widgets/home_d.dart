import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../utils/theme_notifier.dart';

// ═══════════════════════════════════════════════════════════
// HOME (design "Forside D"): greeting bar, the "Find your habesha spot"
// hero, "What do you need today?" tiles (two of them play a short muted
// video loop) and the Shop card.
// ═══════════════════════════════════════════════════════════

String _l(String en, String ti, String am) {
  final l = languageNotifier.language;
  return l == 'Tigrinya' ? ti : l == 'Amharic' ? am : en;
}

const _cGreen = Color(0xFF1E7B4F), _cGold = Color(0xFFE8B12E), _cRed = Color(0xFFC8341E);
const _cBlue = Color(0xFF2A5DB0), _cPlum = Color(0xFF7A3E5A), _cBrown = Color(0xFF4A2E1E), _cInk = Color(0xFF2E1C13);

Color get _surf => themeNotifier.isDark ? const Color(0xFF241B15) : const Color(0xFFF4F1EC);
Color get _chip => themeNotifier.isDark ? _cGold : const Color(0xFF1B1B1B);
Color get _chipText => themeNotifier.isDark ? _cInk : Colors.white;

/// "Habesha Hub / ሰላም, Samuel" with language, light/dark and notifications on the right
class HomeGreetingBar extends StatelessWidget {
  final String name;
  final VoidCallback onBell;
  const HomeGreetingBar({super.key, required this.name, required this.onBell});

  Widget _lang(String code, String short) {
    final on = languageNotifier.language == code;
    return GestureDetector(
      onTap: () => languageNotifier.setLanguage(code),
      child: Container(
        height: 34, constraints: const BoxConstraints(minWidth: 34),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? _chip : Colors.transparent, borderRadius: BorderRadius.circular(17)),
        child: Text(short, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: on ? _chipText : kText)),
      ),
    );
  }

  Widget _round(Widget icon, VoidCallback onTap, String label) => Semantics(
        button: true, label: label,
        child: Material(
          color: _surf, shape: const CircleBorder(),
          child: InkWell(customBorder: const CircleBorder(), onTap: onTap,
              child: SizedBox(width: 40, height: 40, child: Center(child: icon))),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Habesha Hub', style: TextStyle(fontSize: 13, color: kTextSub)),
          Text(name.isEmpty ? 'ሰላም!' : 'ሰላም, $name', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kText)),
        ])),
        Container(
          height: 40, padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: _surf, borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _lang('English', 'EN'), _lang('Tigrinya', 'ትግ'), _lang('Amharic', 'አማ'),
          ]),
        ),
        const SizedBox(width: 6),
        _round(Icon(themeNotifier.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 20, color: kText),
            () => themeNotifier.toggle(), themeNotifier.isDark ? 'Light mode' : 'Dark mode'),
        const SizedBox(width: 6),
        _round(Icon(Icons.notifications_none_rounded, size: 21, color: kText), onBell, 'Notifications'),
      ]),
    );
  }
}

/// Big brown card with a jebena (the Shop on the home)
class HomeHero extends StatelessWidget {
  final VoidCallback onExplore;
  final String title, sub, button;
  final List<String> photos;   // product photos: shown on the right, fading calmly every 4 s; none = the jebena
  const HomeHero({super.key, required this.onExplore, required this.title, required this.sub, required this.button,
      this.photos = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Material(
        color: const Color(0xFF3A2418),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onExplore,
          child: SizedBox(height: 196, child: Stack(children: [
            if (photos.isEmpty) Positioned.fill(child: CustomPaint(painter: _JebenaPainter()))
            else Positioned(right: 0, top: 0, bottom: 0, width: 170, child: _HeroPhotos(photos: photos)),
            Positioned(left: 18, top: 18, width: 200, child: Text(title,
                style: const TextStyle(fontSize: 24, height: 1.15, fontWeight: FontWeight.w800, color: Colors.white))),
            Positioned(left: 18, top: 94, width: 180, child: Text(sub, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFFEADFCB)))),
            Positioned(left: 18, bottom: 18, child: Container(
              height: 44, padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(color: _cGold, borderRadius: BorderRadius.circular(22)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(button, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _cInk)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18, color: _cInk),
              ]),
            )),
          ])),
        ),
      ),
    );
  }
}

/// Product photos that fade into each other every 4 seconds (calm, no movement)
class _HeroPhotos extends StatefulWidget {
  final List<String> photos;
  const _HeroPhotos({required this.photos});
  @override
  State<_HeroPhotos> createState() => _HeroPhotosState();
}

class _HeroPhotosState extends State<_HeroPhotos> {
  int _i = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && widget.photos.length > 1) setState(() => _i = (_i + 1) % widget.photos.length);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.photos[_i % widget.photos.length];
    return Stack(fit: StackFit.expand, children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 900),
        child: Container(
          key: ValueKey(url),
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain, memCacheWidth: 500,
              errorWidget: (_, __, ___) => const SizedBox()),
        ),
      ),
      // soft edge into the brown card, so the text side stays calm
      const IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.centerLeft, end: Alignment.centerRight, stops: [0, 0.35],
          colors: [Color(0xFF3A2418), Color(0x003A2418)])))),
    ]);
  }
}

class _JebenaPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    // the design is 350 × 200; keep it on the right side
    final k = s.height / 200;
    c.save();
    c.translate(s.width - 350 * k, 0);
    c.scale(k);
    final p = Paint();
    c.drawCircle(const Offset(275, 80), 105, p..color = const Color(0xFF5A3826));
    final steam = Paint()..color = const Color(0x59F3EFE8)..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    c.drawPath(Path()..moveTo(246, 86)..cubicTo(240, 76, 252, 70, 246, 58)..cubicTo(240, 46, 252, 40, 246, 30), steam);
    c.drawOval(Rect.fromCenter(center: const Offset(270, 186), width: 168, height: 24), p..color = const Color(0xFFC79A3B));
    p.color = const Color(0xFF141414);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(264, 82, 13, 32), const Radius.circular(4)), p);
    c.drawPath(Path()..moveTo(270, 110)..cubicTo(248, 128, 236, 146, 239, 164)..cubicTo(242, 182, 298, 182, 301, 164)
        ..cubicTo(304, 146, 292, 128, 270, 110), p);
    c.drawPath(Path()..moveTo(294, 150)..lineTo(318, 128)..lineTo(322, 132)..lineTo(300, 158)..close(), p);
    final cup = Paint()..color = Colors.white;
    final wave = Paint()..color = _cGreen..style = PaintingStyle.stroke..strokeWidth = 1.6;
    for (final x in [193.0, 318.0]) {
      c.drawPath(Path()..moveTo(x, 158)..lineTo(x + 24, 158)..lineTo(x + 20, 176)..lineTo(x + 4, 176)..close(), cup);
      c.drawPath(Path()..moveTo(x + 3, 165)..cubicTo(x + 7, 162, x + 10, 168, x + 14, 165)..cubicTo(x + 18, 162, x + 21, 168, x + 23, 165), wave);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// One tile of "What do you need today?"
class NeedTile {
  final String label;
  final Color color;
  final String? video;   // asset video, played muted in a loop
  final String? image;   // asset image
  final Widget? art;     // drawn art when there is no photo
  final Color textColor;
  final VoidCallback onTap;
  const NeedTile(this.label, this.color, this.onTap, {this.video, this.image, this.art, this.textColor = Colors.white});
}

class HomeNeedGrid extends StatelessWidget {
  final List<NeedTile> tiles;
  const HomeNeedGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_l('What do you need today?', 'ሎሚ እንታይ የድልየካ?', 'ዛሬ ምን ያስፈልግዎታል?'),
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: kText)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.12, padding: EdgeInsets.zero,
          children: [for (final t in tiles) _Tile(t)],
        ),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  final NeedTile t;
  const _Tile(this.t);

  @override
  Widget build(BuildContext context) {
    final photo = t.video != null || t.image != null;
    return Material(
      color: t.color,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: t.onTap,
        child: Stack(fit: StackFit.expand, children: [
          if (t.video != null) _LoopVideo(asset: t.video!, poster: t.image)
          else if (t.image != null) Image.asset(t.image!, fit: BoxFit.cover),
          if (t.art != null) t.art!,
          if (photo) const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              stops: [0.4, 1], colors: [Color(0x00000000), Color(0xB8000000)]))),
          Positioned(left: 10, right: 6, bottom: 9, child: Text(t.label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: t.textColor))),
        ]),
      ),
    );
  }
}

/// Muted video loop from the app's assets; shows the poster until it is ready
class _LoopVideo extends StatefulWidget {
  final String asset;
  final String? poster;
  const _LoopVideo({required this.asset, this.poster});
  @override
  State<_LoopVideo> createState() => _LoopVideoState();
}

class _LoopVideoState extends State<_LoopVideo> {
  late final VideoPlayerController _c = VideoPlayerController.asset(widget.asset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));

  @override
  void initState() {
    super.initState();
    _c.setVolume(0);
    _c.setLooping(true);
    _c.initialize().then((_) { if (mounted) { setState(() {}); _c.play(); } }).catchError((_) {});
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_c.value.isInitialized) {
      return widget.poster == null ? const SizedBox() : Image.asset(widget.poster!, fit: BoxFit.cover);
    }
    return FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge,
        child: SizedBox(width: _c.value.size.width, height: _c.value.size.height, child: VideoPlayer(_c)));
  }
}

/// Drawn art for the tiles without a photo (services bag, Habesha AI bubble)
Widget serviceTileArt() => CustomPaint(painter: _BagPainter());
Widget aiTileArt() => Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _BubblePainter())),
      const Positioned(right: 12, top: 12, width: 38, child: Text('ሓ', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: _cGreen))),
    ]);

class _BagPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final x = s.width - 48, y = 18.0;
    c.drawPath(Path()..moveTo(x, y + 4)..lineTo(x + 36, y + 4)..lineTo(x + 32, y + 38)..lineTo(x + 4, y + 38)..close(), Paint()..color = Colors.white);
    c.drawPath(Path()..moveTo(x + 10, y + 4)..lineTo(x + 10, y)..arcToPoint(Offset(x + 26, y), radius: const Radius.circular(8))..lineTo(x + 26, y + 4),
        Paint()..color = _cInk..style = PaintingStyle.stroke..strokeWidth = 3);
    c.drawRect(Rect.fromLTWH(x + 2, y + 20, 32, 5), Paint()..color = _cGreen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final x = s.width - 52, y = 10.0;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 44, 34), const Radius.circular(6));
    c.drawRRect(r, Paint()..color = Colors.white);
    c.drawPath(Path()..moveTo(x + 14, y + 34)..lineTo(x + 6, y + 42)..lineTo(x + 6, y + 34)..close(), Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The small card under the tiles (now: Explore · places near you)
class HomeShopCard extends StatelessWidget {
  final VoidCallback onTap;
  final String title, sub;
  final IconData icon;
  const HomeShopCard({super.key, required this.onTap, required this.title, required this.sub, this.icon = Icons.shopping_bag_outlined});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Material(
        color: _surf,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: SizedBox(height: 72, child: Row(children: [
            const SizedBox(width: 14),
            Container(width: 46, height: 46, decoration: BoxDecoration(color: _cBlue, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kText)),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: kTextSub)),
            ])),
            for (final c in const [_cGold, _cRed, _cGreen]) Container(
                width: 34, height: 34, margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 14),
          ])),
        ),
      ),
    );
  }
}

/// The tile colours, for home_screen
const kNeedFood = _cRed, kNeedEvents = _cBlue, kNeedServices = _cGold, kNeedBeauty = _cPlum, kNeedAi = _cGreen, kNeedLearn = _cBrown, kNeedInk = _cInk;
