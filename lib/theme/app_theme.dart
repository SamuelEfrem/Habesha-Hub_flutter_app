import 'package:flutter/material.dart';
import '../utils/theme_notifier.dart';
import '../utils/translations.dart';

// ── Myk: white / warm grey, Habesha green as the accent ──
// The four Habesha colours (also the stripe under photos)
const kHabGreen = Color(0xFF1E7B4F);
const kHabYellow = Color(0xFFE8B12E);
const kHabRed = Color(0xFFC8341E);
const kHabBlue = Color(0xFF2A5DB0);

// Dark theme
const kSurface = Color(0xFF121212);
const kSurfaceDim = Color(0xFF0C0C0C);
const kSurfaceContainerLow = Color(0xFF1A1A1A);
const kSurfaceContainer = Color(0xFF1F1F1F);
const kSurfaceContainerHigh = Color(0xFF262626);
const kSurfaceContainerHighest = Color(0xFF2E2E2E);
const kOnSurface = Color(0xFFF3EFE8);
const kOnSurfaceVariant = Color(0xFFA8A196);
const kOutlineVariant = Color(0xFF8A847A);
const kGreen = Color(0xFF2E9A63);
const kRed = Color(0xFFD9483A);

// Light theme
const kSurfaceLight = Color(0xFFFFFFFF);
const kSurfaceContainerLowLight = Color(0xFFF8F6F2);
const kSurfaceContainerLight = Color(0xFFF4F1EC);
const kSurfaceContainerHighLight = Color(0xFFEEEAE3);
const kSurfaceContainerHighestLight = Color(0xFFE9E3D8);
const kOnSurfaceLight = Color(0xFF1B1B1B);
const kOnSurfaceVariantLight = Color(0xFF5E5A54);

// ── Colours that follow the theme ────────────────────────
Color get kBg => themeNotifier.isDark ? kSurface : kSurfaceLight;
Color get kCard => themeNotifier.isDark ? kSurfaceContainer : kSurfaceContainerLight;
Color get kCardLow => themeNotifier.isDark ? kSurfaceContainerLow : kSurfaceContainerLowLight;
Color get kCardHigh => themeNotifier.isDark ? kSurfaceContainerHigh : kSurfaceContainerHighLight;
Color get kCardHighest => themeNotifier.isDark ? kSurfaceContainerHighest : kSurfaceContainerHighestLight;
Color get kText => themeNotifier.isDark ? kOnSurface : kOnSurfaceLight;
Color get kTextSub => themeNotifier.isDark ? kOnSurfaceVariant : kOnSurfaceVariantLight;
/// Accent (icons, links, selected things)
Color get kSecondary => themeNotifier.isDark ? const Color(0xFF4FC48A) : kHabGreen;
/// Text and icons on top of kSecondary
Color get kOnAccent => themeNotifier.isDark ? const Color(0xFF121212) : Colors.white;
/// Filled buttons (white text on it)
const kPrimaryContainer = kHabGreen;
// Soft tints behind round icons
Color get kTintGreen => themeNotifier.isDark ? const Color(0xFF173628) : const Color(0xFFE3F1E9);
Color get kTintYellow => themeNotifier.isDark ? const Color(0xFF3A3014) : const Color(0xFFFBF0D4);
Color get kTintRed => themeNotifier.isDark ? const Color(0xFF3E201A) : const Color(0xFFF8E1DD);
Color get kTintBlue => themeNotifier.isDark ? const Color(0xFF1B2B47) : const Color(0xFFE0E9F7);
Color get kInkGreen => themeNotifier.isDark ? const Color(0xFF4FC48A) : kHabGreen;
Color get kInkYellow => themeNotifier.isDark ? const Color(0xFFF0BE3C) : const Color(0xFF9A6E00);
Color get kInkRed => themeNotifier.isDark ? const Color(0xFFF27A63) : kHabRed;
Color get kInkBlue => themeNotifier.isDark ? const Color(0xFF7EA6EE) : kHabBlue;

const kFontHeadline = 'Manrope';
const kFontBody = 'Manrope';

TextStyle tsDisplay({Color? color}) => TextStyle(
    fontFamily: kFontHeadline,
    fontSize: 36,
    fontWeight: FontWeight.w900,
    height: 1.1,
    color: color ?? kText);

TextStyle tsHeadlineLg({Color? color}) => TextStyle(
    fontFamily: kFontHeadline,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: color ?? kText);

TextStyle tsHeadlineMd({Color? color}) => TextStyle(
    fontFamily: kFontHeadline,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: color ?? kText);

TextStyle tsHeadlineSm({Color? color}) => TextStyle(
    fontFamily: kFontHeadline,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: color ?? kText);

TextStyle tsTitleLg({Color? color}) => TextStyle(
    fontFamily: kFontBody,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: color ?? kText);

TextStyle tsTitleMd({Color? color}) => TextStyle(
    fontFamily: kFontBody,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: color ?? kText);

TextStyle tsBodyLg({Color? color}) => TextStyle(
    fontFamily: kFontBody,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: color ?? kText);

TextStyle tsBodySm({Color? color}) => TextStyle(
    fontFamily: kFontBody,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: color ?? kTextSub);

TextStyle tsLabel({Color? color}) => TextStyle(
    fontFamily: kFontBody,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: color ?? kSecondary);

ThemeData habeshaTheme() => _myk(true);
ThemeData habeshaLightTheme() => _myk(false);

ThemeData _myk(bool dark) {
  final bg = dark ? kSurface : kSurfaceLight;
  final text = dark ? kOnSurface : kOnSurfaceLight;
  final sub = dark ? kOnSurfaceVariant : kOnSurfaceVariantLight;
  final surf = dark ? kSurfaceContainer : kSurfaceContainerLight;
  final accent = dark ? const Color(0xFF4FC48A) : kHabGreen;
  final base = dark ? ColorScheme.dark(surface: bg) : ColorScheme.light(surface: bg);
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bg,
    fontFamily: kFontBody,
    colorScheme: base.copyWith(
      primary: accent,
      onPrimary: dark ? kSurface : Colors.white,
      primaryContainer: kHabGreen,
      secondary: accent,
      onSurface: text,
      surfaceTint: Colors.transparent,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: text),
      titleTextStyle: TextStyle(
          fontFamily: kFontHeadline, color: text, fontSize: 20, fontWeight: FontWeight.w800),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: accent,
      labelColor: text,
      unselectedLabelColor: sub,
      dividerColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surf,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accent, width: 1.4)),
      hintStyle: TextStyle(fontFamily: kFontBody, fontSize: 14, color: sub),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surf,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: TextStyle(fontFamily: kFontBody, color: text, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: const StadiumBorder(), minimumSize: const Size(44, 48)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(), elevation: 0, minimumSize: const Size(44, 48)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(shape: const StadiumBorder(), minimumSize: const Size(44, 48)),
    ),
    cardTheme: CardThemeData(
      color: surf,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: DividerThemeData(color: dark ? const Color(0xFF2C2C2C) : const Color(0xFFE9E3D8)),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? kSurfaceContainerHighest : kOnSurfaceLight,
      contentTextStyle: TextStyle(fontFamily: kFontBody, color: dark ? kOnSurface : Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? accent : null),
    ),
  );
}

// ── Shared Widgets ────────────────────────────────────────

Widget openBadge(bool isOpen) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: isOpen ? kHabGreen : kHabRed,
          borderRadius: BorderRadius.circular(100)),
      child: Text(isOpen ? tr('Open now') : tr('Closed'),
          style: const TextStyle(
              fontFamily: kFontBody,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: Colors.white)),
    );

Widget categoryBadge(String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(100),
          ),
      child: Text(label,
          style: TextStyle(
              fontFamily: kFontBody,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: kText)),
    );

Widget primaryButton(String label, VoidCallback? onTap,
    {bool loading = false, IconData? icon}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
          color: onTap == null
              ? kPrimaryContainer.withOpacity(0.5)
              : kPrimaryContainer,
          borderRadius: BorderRadius.circular(100)),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: kOnSurface, strokeWidth: 2))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, color: kOnSurface, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label,
                    style: const TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: kOnSurface)),
              ]),
      ),
    ),
  );
}

/// Main call-to-action: a calm pill in the accent colour (no gradient)
Widget goldButton(String label, VoidCallback? onTap,
    {bool loading = false, IconData? icon}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: onTap == null ? kSecondary.withOpacity(0.5) : kSecondary,
          borderRadius: BorderRadius.circular(100)),
      child: Center(
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: kOnAccent, strokeWidth: 2))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, color: kOnAccent, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label,
                    style: TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kOnAccent)),
              ]),
      ),
    ),
  );
}

Widget actionSquare(IconData icon, String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: kCardLow,
          borderRadius: BorderRadius.circular(12),
          ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: kSecondary, size: 28),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontFamily: kFontBody,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: kSecondary)),
      ]),
    ),
  );
}

/// The old diamond background pattern. The new look is plain, so it draws nothing.
class TibebPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(_) => false;
}

/// The Habesha Hub logo (the app icon), rounded
Widget habeshaLogo({double size = 38}) => ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.26),
      child: Image.asset('assets/images/icon.png', width: size, height: size, fit: BoxFit.cover),
    );

/// The four Habesha colours as a thin stripe (under photos and headers)
Widget habeshaStripe({double height = 5}) => SizedBox(
      height: height,
      child: const Row(children: [
        Expanded(child: ColoredBox(color: kHabGreen)),
        Expanded(child: ColoredBox(color: kHabYellow)),
        Expanded(child: ColoredBox(color: kHabRed)),
        Expanded(child: ColoredBox(color: kHabBlue)),
      ]),
    );
