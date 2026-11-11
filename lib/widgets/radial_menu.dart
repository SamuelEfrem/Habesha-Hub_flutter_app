import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';

/// One shortcut in the round menu.
class RadialItem {
  final IconData icon;
  final String label;
  final Color tint, ink;
  final VoidCallback onTap;
  const RadialItem(this.icon, this.label, this.tint, this.ink, this.onTap);
}

/// All shortcuts gathered in one round button. A tap opens them in a half circle
/// (they spring out one after the other); a second tap folds them back.
class RadialMenu extends StatefulWidget {
  final List<RadialItem> items;
  const RadialMenu({super.key, required this.items});
  @override
  State<RadialMenu> createState() => _RadialMenuState();
}

class _RadialMenuState extends State<RadialMenu> with TickerProviderStateMixin {
  late final AnimationController _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  // a soft "breathing" ring so new users see that the button can be tapped
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  static const _center = 72.0, _item = 56.0, _radius = 118.0;

  @override
  void dispose() {
    _open.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    if (_open.status == AnimationStatus.completed || _open.status == AnimationStatus.forward) {
      _open.reverse();
    } else {
      _open.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    return AnimatedBuilder(
      animation: Listenable.merge([_open, _pulse]),
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_open.value);
        // the area grows while the menu opens
        final height = _center + 24 + (_radius + _item + 8) * t;
        return SizedBox(
          height: height,
          child: LayoutBuilder(builder: (context, box) {
            final cx = box.maxWidth / 2, cy = _center / 2 + 4;
            return Stack(clipBehavior: Clip.none, children: [
              // the shortcuts on a half circle under the button
              for (var i = 0; i < n; i++) _bubble(i, n, cx, cy),
              // the round button in the middle
              Positioned(
                left: cx - _center / 2, top: cy - _center / 2,
                child: GestureDetector(
                  onTap: _toggle,
                  child: Stack(alignment: Alignment.center, children: [
                    if (_open.value == 0) Opacity(
                      opacity: (1 - _pulse.value) * 0.45,
                      child: Container(
                        width: _center + 22 * _pulse.value, height: _center + 22 * _pulse.value,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kSecondary, width: 2)),
                      ),
                    ),
                    Container(
                      width: _center, height: _center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: kSecondary,
                        boxShadow: [BoxShadow(color: kSecondary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Transform.rotate(
                        angle: t * math.pi * 0.75,
                        child: Icon(t > 0.5 ? Icons.close_rounded : Icons.apps_rounded, color: kOnAccent, size: 32),
                      ),
                    ),
                  ]),
                ),
              ),
              // a short hint under the closed button
              if (t < 0.99) Positioned(
                left: 0, right: 0, top: cy + _center / 2 + 6,
                child: Opacity(
                  opacity: 1 - t,
                  child: Text(tr('Services, market, events and more'), textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: kFontBody, fontSize: 12, fontWeight: FontWeight.w600, color: kTextSub)),
                ),
              ),
            ]);
          }),
        );
      },
    );
  }

  Widget _bubble(int i, int n, double cx, double cy) {
    // each bubble starts a little later than the one before
    final start = i * 0.08, end = (start + 0.62).clamp(0.0, 1.0);
    final p = Interval(start, end, curve: Curves.elasticOut).transform(_open.value);
    final fade = Interval(start, (start + 0.3).clamp(0.0, 1.0)).transform(_open.value);
    // angles from left to right along the lower half circle
    final a = math.pi * (0.95 - 0.9 * (n == 1 ? 0.5 : i / (n - 1)));
    final x = cx + math.cos(a) * _radius * p - _item / 2;
    final y = cy + math.sin(a) * _radius * p * 0.92 + 18 * p - _item / 2;
    final it = widget.items[i];
    if (_open.value == 0) return const SizedBox.shrink();
    return Positioned(
      left: x - 14, top: y,
      child: Opacity(
        opacity: fade,
        child: Transform.scale(
          scale: 0.4 + 0.6 * p.clamp(0.0, 1.2),
          child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); it.onTap(); },
            child: SizedBox(width: _item + 28, child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: _item, height: _item,
                decoration: BoxDecoration(color: it.tint, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Icon(it.icon, color: it.ink, size: 25),
              ),
              const SizedBox(height: 5),
              Text(it.label, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: kFontBody, fontSize: 10.5, height: 1.15, fontWeight: FontWeight.w600, color: kText)),
            ])),
          ),
        ),
      ),
    );
  }
}
