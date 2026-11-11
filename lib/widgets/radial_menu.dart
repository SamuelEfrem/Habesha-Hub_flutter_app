import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/translations.dart';

/// One shortcut on the home screen.
class RadialItem {
  final IconData icon;
  final String label;
  final Color tint, ink;
  final VoidCallback onTap;
  const RadialItem(this.icon, this.label, this.tint, this.ink, this.onTap);
}

/// The shortcuts in one row: they pop in one after the other when the screen opens,
/// and shrink a little and spring back when tapped.
class ShortcutRow extends StatefulWidget {
  final List<RadialItem> items;
  const ShortcutRow({super.key, required this.items});
  @override
  State<ShortcutRow> createState() => _ShortcutRowState();
}

class _ShortcutRowState extends State<ShortcutRow> with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    return Row(children: [
      for (var i = 0; i < n; i++)
        Expanded(child: AnimatedBuilder(
          animation: _in,
          builder: (_, child) {
            final start = i * 0.1, p = Interval(start, (start + 0.55).clamp(0.0, 1.0), curve: Curves.easeOutBack).transform(_in.value);
            return Opacity(opacity: p.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, 14 * (1 - p)), child: child));
          },
          child: _Shortcut(item: widget.items[i]),
        )),
    ]);
  }
}

class _Shortcut extends StatefulWidget {
  final RadialItem item;
  const _Shortcut({required this.item});
  @override
  State<_Shortcut> createState() => _ShortcutState();
}

class _ShortcutState extends State<_Shortcut> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () { HapticFeedback.selectionClick(); it.onTap(); },
      child: AnimatedScale(
        scale: _down ? 0.88 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // a soft light-to-tint gradient in the same colour, so the circles look a bit "lifted"
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color.lerp(it.tint, Colors.white, 0.35)!, it.tint]),
              boxShadow: [BoxShadow(color: it.ink.withValues(alpha: 0.14), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(it.icon, color: it.ink, size: 21),
          ),
          const SizedBox(height: 6),
          Text(it.label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: TextStyle(fontFamily: kFontBody, fontSize: 10, height: 1.15, fontWeight: FontWeight.w600, color: kText)),
        ]),
      ),
    );
  }
}

/// "Swipe up to see all places" with a gently bouncing arrow; hidden as soon as the user scrolls.
class ScrollHint extends StatefulWidget {
  final bool visible;
  const ScrollHint({super.key, required this.visible});
  @override
  State<ScrollHint> createState() => _ScrollHintState();
}

class _ScrollHintState extends State<ScrollHint> with SingleTickerProviderStateMixin {
  late final AnimationController _b = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: !widget.visible ? const SizedBox(width: double.infinity) : Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 10),
        child: AnimatedBuilder(
          animation: _b,
          builder: (_, __) {
            final y = math.sin(_b.value * math.pi * 2) * 4;
            return Column(children: [
              Text(tr('Swipe up to see all places'), style: TextStyle(fontFamily: kFontBody, fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextSub)),
              Transform.translate(offset: Offset(0, y + 2), child: Icon(Icons.keyboard_double_arrow_up_rounded, color: kSecondary, size: 22)),
            ]);
          },
        ),
      ),
    );
  }
}
