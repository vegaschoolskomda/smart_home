import 'package:flutter/material.dart';

/// Clean minimalist smart home illustration matching the reference image.
/// Pure Flutter CustomPainter, 100% vector, zero emojis.
class SmartHomeHeroGraphic extends StatelessWidget {
  final double width;
  final double height;

  const SmartHomeHeroGraphic({
    super.key,
    this.width = 130,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SmartHomeHeroPainter(),
      ),
    );
  }
}

class _SmartHomeHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw subtle concentric orbit arcs in background
    final arcPaint = Paint()
      ..color = const Color(0xFF1F4462).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(w * 0.75, h * 0.70);
    canvas.drawCircle(center, w * 0.42, arcPaint);
    canvas.drawCircle(center, w * 0.62, arcPaint);

    // 2. Orbit satellite dots
    final dotPaint = Paint()..color = const Color(0xFF38D3D3);
    canvas.drawCircle(Offset(w * 0.95, h * 0.25), 3.5, dotPaint);
    canvas.drawCircle(Offset(w * 0.45, h * 0.78), 4.0, dotPaint);

    // 3. House body and roof shadow / back
    final houseWidth = w * 0.68;
    final houseHeight = h * 0.62;
    final houseLeft = w * 0.45;
    final houseTop = h * 0.35;

    // Roof path (cyan rounded roof)
    final roofPath = Path();
    roofPath.moveTo(houseLeft, houseTop + houseHeight * 0.35);
    roofPath.lineTo(houseLeft + houseWidth * 0.5, houseTop - houseHeight * 0.08);
    roofPath.lineTo(houseLeft + houseWidth, houseTop + houseHeight * 0.35);
    roofPath.close();

    final roofPaint = Paint()
      ..color = const Color(0xFF4EE2E2)
      ..style = PaintingStyle.fill;
    canvas.drawPath(roofPath, roofPaint);

    // House main base (clean white rounded rect)
    final houseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        houseLeft + houseWidth * 0.08,
        houseTop + houseHeight * 0.30,
        houseWidth * 0.84,
        houseHeight * 0.65,
      ),
      const Radius.circular(12),
    );

    final housePaint = Paint()..color = Colors.white;
    canvas.drawRRect(houseRect, housePaint);

    // House windows (two cyan rounded squares)
    final windowPaint = Paint()..color = const Color(0xFF0EA5A5);
    final winWidth = houseWidth * 0.16;
    final winHeight = houseHeight * 0.18;
    final winY = houseTop + houseHeight * 0.52;

    // Window 1
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(houseLeft + houseWidth * 0.22, winY, winWidth, winHeight),
        const Radius.circular(3),
      ),
      windowPaint,
    );

    // Window 2
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(houseLeft + houseWidth * 0.44, winY, winWidth, winHeight),
        const Radius.circular(3),
      ),
      windowPaint,
    );

    // Door (dark navy slim rect on right)
    final doorPaint = Paint()..color = const Color(0xFF13253A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          houseLeft + houseWidth * 0.68,
          houseTop + houseHeight * 0.55,
          houseWidth * 0.20,
          houseHeight * 0.40,
        ),
        const Radius.circular(4),
      ),
      doorPaint,
    );

    // 4. Smart badge on the right corner of house
    final badgeCenter = Offset(houseLeft + houseWidth * 0.90, houseTop + houseHeight * 0.52);
    final badgePaint = Paint()..color = const Color(0xFF4EE2E2);
    canvas.drawCircle(badgeCenter, 11, badgePaint);

    // Lightning bolt in badge
    final boltPath = Path();
    boltPath.moveTo(badgeCenter.dx + 1, badgeCenter.dy - 6);
    boltPath.lineTo(badgeCenter.dx - 3, badgeCenter.dy + 1);
    boltPath.lineTo(badgeCenter.dx, badgeCenter.dy + 1);
    boltPath.lineTo(badgeCenter.dx - 1, badgeCenter.dy + 6);
    boltPath.lineTo(badgeCenter.dx + 3, badgeCenter.dy - 1);
    boltPath.lineTo(badgeCenter.dx, badgeCenter.dy - 1);
    boltPath.close();

    final boltPaint = Paint()
      ..color = const Color(0xFF13253A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(boltPath, boltPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
