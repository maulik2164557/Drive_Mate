import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogoWidget extends StatelessWidget {
  final bool isDarkBackground;
  final double iconSize;
  final double fontSize;
  final String? subtitle;
  final bool showSubtitle;

  const AppLogoWidget({
    super.key,
    this.isDarkBackground = true,
    this.iconSize = 36,
    this.fontSize = 18,
    this.subtitle,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Modern Sports Car Key Logo Graphic
        SizedBox(
          width: iconSize * 1.6,
          height: iconSize,
          child: CustomPaint(
            painter: ModernSportsCarKeyLogoPainter(isDarkBackground: isDarkBackground),
          ),
        ),
        const SizedBox(width: 8),
        // Styled System Name Text: "Drive" (Yellow/Orange Italic) + "Mate" (Silver/White Italic)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.montserrat(
                  fontSize: fontSize,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
                children: [
                  TextSpan(
                    text: 'Drive',
                    style: TextStyle(
                      color: Colors.amberAccent.shade400,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: 'Mate',
                    style: TextStyle(
                      color: isDarkBackground ? Colors.white : const Color(0xFF1E293B),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (showSubtitle) ...[
              const SizedBox(height: 2),
              Text(
                subtitle ?? 'GUJARAT AUTOMOTIVE',
                style: GoogleFonts.montserrat(
                  color: isDarkBackground ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                  fontSize: fontSize * 0.38,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.2,
                  height: 1.0,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class ModernSportsCarKeyLogoPainter extends CustomPainter {
  final bool isDarkBackground;

  ModernSportsCarKeyLogoPainter({this.isDarkBackground = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Flame Gradient Colors (Yellow -> Amber -> Red)
    final carGradient = LinearGradient(
      colors: const [
        Color(0xFFFACC15), // Gold Yellow
        Color(0xFFF59E0B), // Amber
        Color(0xFFEF4444), // Crimson Red
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final carPaint = Paint()
      ..shader = carGradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round;

    // 1. Sports Car Roofline & Hood (Yellow to Red Flame Gradient)
    final roofPath = Path();
    roofPath.moveTo(w * 0.04, h * 0.52);
    roofPath.cubicTo(
      w * 0.12, h * 0.38,
      w * 0.22, h * 0.32,
      w * 0.35, h * 0.26,
    );
    roofPath.cubicTo(
      w * 0.46, h * 0.10,
      w * 0.62, h * 0.10,
      w * 0.78, h * 0.24,
    );
    roofPath.cubicTo(
      w * 0.85, h * 0.28,
      w * 0.92, h * 0.32,
      w * 0.96, h * 0.36,
    );
    canvas.drawPath(roofPath, carPaint);

    // 2. Front Wheel Arch Accent (Gold Yellow)
    final frontArch = Path();
    frontArch.moveTo(w * 0.06, h * 0.54);
    frontArch.cubicTo(
      w * 0.12, h * 0.32,
      w * 0.26, h * 0.32,
      w * 0.32, h * 0.54,
    );
    canvas.drawPath(frontArch, carPaint);

    // 3. Side Body Character Lines
    final sideLine = Path();
    sideLine.moveTo(w * 0.30, h * 0.46);
    sideLine.cubicTo(
      w * 0.42, h * 0.40,
      w * 0.52, h * 0.40,
      w * 0.62, h * 0.45,
    );
    canvas.drawPath(sideLine, carPaint);

    // 4. Rear Wheel Arch / Fender Accent (Red)
    final rearArch = Path();
    rearArch.moveTo(w * 0.66, h * 0.42);
    rearArch.cubicTo(
      w * 0.74, h * 0.28,
      w * 0.86, h * 0.28,
      w * 0.92, h * 0.42,
    );
    canvas.drawPath(rearArch, carPaint);

    // 5. Silver Car Key Graphic
    final silverColor = isDarkBackground ? const Color(0xFFE2E8F0) : const Color(0xFF475569);
    final keyPaint = Paint()
      ..color = silverColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    // Key Fob Loop
    final keyFob = Path();
    keyFob.addOval(Rect.fromLTWH(w * 0.72, h * 0.36, w * 0.24, h * 0.24));
    canvas.drawPath(keyFob, keyPaint);

    // Key Blade Extending Left
    final keyBlade = Path();
    keyBlade.moveTo(w * 0.72, h * 0.48);
    keyBlade.lineTo(w * 0.52, h * 0.50);
    // Key Teeth Notch
    keyBlade.lineTo(w * 0.56, h * 0.55);
    keyBlade.lineTo(w * 0.60, h * 0.50);
    keyBlade.lineTo(w * 0.64, h * 0.55);
    keyBlade.lineTo(w * 0.68, h * 0.49);
    canvas.drawPath(keyBlade, keyPaint);

    // 6. Sweeping Baseline Underline Swoosh
    final swooshPath = Path();
    swooshPath.moveTo(w * 0.02, h * 0.62);
    swooshPath.cubicTo(
      w * 0.20, h * 0.72,
      w * 0.65, h * 0.72,
      w * 0.98, h * 0.62,
    );
    // Outer Return Loop
    swooshPath.cubicTo(
      w * 0.92, h * 0.80,
      w * 0.78, h * 0.88,
      w * 0.62, h * 0.88,
    );
    canvas.drawPath(swooshPath, carPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
