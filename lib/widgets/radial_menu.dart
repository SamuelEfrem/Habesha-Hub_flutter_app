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

/// When the home opens: the five circles appear gathered in the middle, spin a little,
/// then spread out to their places with a bounce (about 1.6 s); the labels fade in last.
class _ShortcutRowState extends State<ShortcutRow> with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    return LayoutBuilder(builder: (_, box) {
      final slot = box.maxWidth / n;
      return Row(children: [
        for (var i = 0; i < n; i++)
          Expanded(child: AnimatedBuilder(
            animation: _in,
            builder: (_, child) {
              final t = _in.value;
              // 1) gather: pop in at the middle, one after the other
              final gather = Interval(i * 0.04, 0.3 + i * 0.04, curve: Curves.easeOutBack).transform(t);
              // 2) spread out to the own place, with a bounce
              final spread = const Interval(0.38, 1.0, curve: Curves.elasticOut).transform(t);
              final toMiddle = (box.maxWidth / 2) - (i + 0.5) * slot;
              return Transform.translate(
                offset: Offset(toMiddle * (1 - spread), 0),
                child: Transform.rotate(
                  angle: (1 - gather) * 1.6 * (i.isEven ? 1 : -1),
                  child: Transform.scale(scale: gather.clamp(0.0, 1.2), child: child),
                ),
              );
            },
            child: _Shortcut(item: widget.items[i], labelIn: _in),
          )),
      ]);
    });
  }
}

class _Shortcut extends StatefulWidget {
  final RadialItem item;
  final Animation<double>? labelIn;   // the label fades in when the circles have spread out
  const _Shortcut({required this.item, this.labelIn});
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
          FadeTransition(
            opacity: widget.labelIn == null ? const AlwaysStoppedAnimation(1.0)
                : CurvedAnimation(parent: widget.labelIn!, curve: const Interval(0.6, 1.0)),
            child: Text(it.label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: TextStyle(fontFamily: kFontBody, fontSize: 10, height: 1.15, fontWeight: FontWeight.w600, color: kText)),
          ),
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
