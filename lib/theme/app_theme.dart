import 'package:flutter/material.dart';

const kSurface = Color(0xFF131313);
const kSurfaceDim = Color(0xFF0E0E0E);
const kSurfaceContainerLow = Color(0xFF1C1B1B);
const kSurfaceContainer = Color(0xFF20201F);
const kSurfaceContainerHigh = Color(0xFF2A2A2A);
const kSurfaceContainerHighest = Color(0xFF353535);
const kPrimaryContainer = Color(0xFF8B0000);
const kSecondary = Color(0xFFD4AF37);
const kOnSurface = Color(0xFFE5E2E1);
const kOnSurfaceVariant = Color(0xFFE3BEB8);
const kOutlineVariant = Color(0xFF5A403C);
const kGreen = Color(0xFF22C55E);
const kRed = Color(0xFFEF4444);

const kFontHeadline = 'NotoSerif';
const kFontBody = 'Manrope';

TextStyle tsDisplay({Color color = kOnSurface}) => TextStyle(
    fontFamily: kFontHeadline,
    fontSize: 36,
    fontWeight: FontWeight.w900,
    height: 1.1,
    color: color);

TextStyle tsHeadlineLg({Color color = kOnSurface}) => TextStyle(
    fontFamily: kFontHeadline,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: color);

TextStyle tsHeadlineMd({Color color = kOnSurface}) => TextStyle(
    fontFamily: kFontHeadline,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: color);

TextStyle tsHeadlineSm({Color color = kOnSurface}) => TextStyle(
    fontFamily: kFontHeadline,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: color);

TextStyle tsTitleLg({Color color = kOnSurface}) => TextStyle(
    fontFamily: kFontBody,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: color);

TextStyle tsTitleMd({Color color = kOnSurface}) => TextStyle(
    fontFamily: kFontBody,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: color);

TextStyle tsBodyLg({Color color = kOnSurface}) => TextStyle(
    fontFamily: kFontBody,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: color);

TextStyle tsBodySm({Color color = kOnSurfaceVariant}) => TextStyle(
    fontFamily: kFontBody,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: color);

TextStyle tsLabel({Color color = kSecondary}) => TextStyle(
    fontFamily: kFontBody,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: color);

ThemeData habeshaTheme() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: kSurface,
      fontFamily: kFontBody,
      colorScheme: const ColorScheme.dark(
        surface: kSurface,
        primary: kSecondary,
        primaryContainer: kPrimaryContainer,
        secondary: kSecondary,
        onSurface: kOnSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: kSecondary),
        titleTextStyle: TextStyle(
            fontFamily: kFontHeadline,
            color: kSecondary,
            fontSize: 18,
            fontWeight: FontWeight.w700),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: kSecondary,
        labelColor: kSecondary,
        unselectedLabelColor: kOnSurfaceVariant,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurfaceContainerHighest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kSecondary, width: 1)),
        hintStyle: TextStyle(
            fontFamily: kFontBody, fontSize: 12, color: kOnSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: kSurfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: kSurfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );

// ── Shared Widgets ────────────────────────────────────────

Widget openBadge(bool isOpen) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: isOpen
              ? kGreen.withOpacity(0.9)
              : kPrimaryContainer.withOpacity(0.9),
          borderRadius: BorderRadius.circular(100)),
      child: Text(isOpen ? 'ÅPEN NÅ' : 'STENGT',
          style: const TextStyle(
              fontFamily: kFontBody,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white)),
    );

Widget categoryBadge(String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: kSecondary.withOpacity(0.3), width: 0.5)),
      child: Text(label.toUpperCase(),
          style: const TextStyle(
              fontFamily: kFontBody,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: kSecondary)),
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
          borderRadius: BorderRadius.circular(12)),
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

Widget goldButton(String label, VoidCallback? onTap,
    {bool loading = false, IconData? icon}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            onTap == null ? kSecondary.withOpacity(0.5) : kSecondary,
            onTap == null
                ? const Color(0xFFB8960C).withOpacity(0.5)
                : const Color(0xFFB8960C),
          ]),
          borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(color: kSurface, strokeWidth: 2))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, color: kSurface, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label,
                    style: const TextStyle(
                        fontFamily: kFontBody,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: kSurface)),
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
          color: kSurfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kSecondary.withOpacity(0.1), width: 0.5)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: kSecondary, size: 28),
        const SizedBox(height: 6),
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontFamily: kFontBody,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: kSecondary)),
      ]),
    ),
  );
}

class TibebPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kSecondary.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width + 40; x += 40) {
      for (double y = 0; y < size.height + 40; y += 40) {
        final path = Path()
          ..moveTo(x, y - 20)
          ..lineTo(x + 20, y)
          ..lineTo(x, y + 20)
          ..lineTo(x - 20, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
