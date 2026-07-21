import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Identité visuelle Covoit229 — inspirée des applis de mobilité du Bénin :
// vert signal + bleu nuit profond, cartes blanches arrondies, ombres douces.
class CvColors {
  static const Color green = Color(0xFF00B140);
  static const Color greenBright = Color(0xFF00D24B);
  static const Color greenDark = Color(0xFF008A33);
  static const Color navy = Color(0xFF0A1B2E);
  static const Color navySoft = Color(0xFF13294B);
  static const Color amber = Color(0xFFFFB800);
  static const Color bg = Color(0xFFF2F5F3);
  static const Color card = Colors.white;
}

const LinearGradient kGreenGradient = LinearGradient(
  colors: [CvColors.greenBright, CvColors.green],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kHeroGradient = LinearGradient(
  colors: [CvColors.navy, CvColors.navySoft],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CvColors.green,
      primary: CvColors.green,
      secondary: CvColors.amber,
    ),
    scaffoldBackgroundColor: CvColors.bg,
  );
  return base.copyWith(
    textTheme: GoogleFonts.urbanistTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: CvColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.urbanist(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F6F4),
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      prefixIconColor: CvColors.greenDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CvColors.green, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CvColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CvColors.navy,
        side: const BorderSide(color: Color(0xFFD6DED9)),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

// ---- Composants réutilisables ----

// Carte blanche arrondie avec ombre douce.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

// Bouton principal en dégradé vert avec halo.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const GradientButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: kGreenGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CvColors.green.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Avatar rond avec initiales sur dégradé vert.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? photoUrl;
  const InitialsAvatar({super.key, required this.name, this.size = 40, this.photoUrl});

  Widget _initials() {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    String ini = '';
    if (parts.isNotEmpty) ini += parts.first[0];
    if (parts.length > 1) ini += parts.last[0];
    if (ini.isEmpty) ini = '?';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(gradient: kGreenGradient, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        ini.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = photoUrl ?? '';
    if (url.isEmpty) return _initials();
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initials(),
      ),
    );
  }
}

// Logo « squircle » vert avec voiture.
class CvLogo extends StatelessWidget {
  final double size;
  const CvLogo({super.key, this.size = 84});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: kGreenGradient,
        borderRadius: BorderRadius.circular(size * 0.29),
        boxShadow: [
          BoxShadow(
            color: CvColors.green.withOpacity(0.45),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(Icons.directions_car_filled_rounded,
          color: Colors.white, size: size * 0.55),
    );
  }
}
