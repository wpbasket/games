import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/ludo_colors.dart';

class LudoBoardPainter extends CustomPainter {
  const LudoBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double step = size.width / 15.0;

    // 1. Draw base white background
    final bgPaint = Paint()..color = LudoColors.boardBackground;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Draw 4 Corner Yards (6x6 each)
    _drawYard(canvas, step, 0, 0, LudoColors.green, LudoColors.greenLight); // Green (Top-Left)
    _drawYard(canvas, step, 9, 0, LudoColors.yellow, LudoColors.yellowLight); // Yellow (Top-Right)
    _drawYard(canvas, step, 9, 9, LudoColors.blue, LudoColors.blueLight); // Blue (Bottom-Right)
    _drawYard(canvas, step, 0, 9, LudoColors.red, LudoColors.redLight); // Red (Bottom-Left)

    // 3. Draw Track Grid, Colored Home Lanes, and Start Squares
    _drawGridAndPaths(canvas, step);

    // 4. Draw Center Home Triangles
    _drawCenterHome(canvas, size, step);

    // 5. Draw 8 Safe Stars (4 on start squares + 4 on track stars)
    _drawSafeStars(canvas, step);

    // 6. Draw outer board border
    final outerBorder = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), outerBorder);
  }

  void _drawYard(Canvas canvas, double step, double col, double row, Color primary, Color light) {
    // Outer colored yard rectangle
    final yardRect = Rect.fromLTWH(col * step, row * step, 6 * step, 6 * step);
    canvas.drawRect(yardRect, Paint()..color = primary);

    // Inner White Card (4x4 cells)
    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH((col + 1) * step, (row + 1) * step, 4 * step, 4 * step),
      Radius.circular(step * 0.5),
    );
    canvas.drawRRect(innerRect, Paint()..color = Colors.white);

    // 4 Colored circular pawn holding spots (centered at +2.0 and +4.0 grid units)
    final offsets = [
      Offset((col + 2.0) * step, (row + 2.0) * step),
      Offset((col + 4.0) * step, (row + 2.0) * step),
      Offset((col + 2.0) * step, (row + 4.0) * step),
      Offset((col + 4.0) * step, (row + 4.0) * step),
    ];

    final ringPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = step * 0.16;
    final innerFillPaint = Paint()
      ..color = light
      ..style = PaintingStyle.fill;

    for (final offset in offsets) {
      canvas.drawCircle(offset, step * 0.52, innerFillPaint);
      canvas.drawCircle(offset, step * 0.52, ringPaint);
    }
  }

  void _drawGridAndPaths(Canvas canvas, double step) {
    final borderPaint = Paint()
      ..color = LudoColors.boardGridLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw all track cell borders
    for (int col = 0; col < 15; col++) {
      for (int row = 0; row < 15; row++) {
        // Skip corner yards and center 3x3
        final inYard = (col < 6 && row < 6) ||
            (col > 8 && row < 6) ||
            (col < 6 && row > 8) ||
            (col > 8 && row > 8);
        final inCenter = (col >= 6 && col <= 8 && row >= 6 && row <= 8);

        if (!inYard && !inCenter) {
          final rect = Rect.fromLTWH(col * step, row * step, step, step);
          canvas.drawRect(rect, borderPaint);
        }
      }
    }

    // 1. GREEN (Left Arm):
    // Home lane: Row 7, Cols 1..5
    final greenPaint = Paint()..color = LudoColors.green;
    for (int c = 1; c <= 5; c++) {
      final rect = Rect.fromLTWH(c * step, 7 * step, step, step);
      canvas.drawRect(rect, greenPaint);
      canvas.drawRect(rect, borderPaint);
    }
    // Green Start Square: Col 1, Row 6 (touching Green Yard)
    final greenStart = Rect.fromLTWH(1 * step, 6 * step, step, step);
    canvas.drawRect(greenStart, greenPaint);
    canvas.drawRect(greenStart, borderPaint);

    // 2. YELLOW (Top Arm):
    // Home lane: Col 7, Rows 1..5
    final yellowPaint = Paint()..color = LudoColors.yellow;
    for (int r = 1; r <= 5; r++) {
      final rect = Rect.fromLTWH(7 * step, r * step, step, step);
      canvas.drawRect(rect, yellowPaint);
      canvas.drawRect(rect, borderPaint);
    }
    // Yellow Start Square: Col 8, Row 1 (touching Yellow Yard)
    final yellowStart = Rect.fromLTWH(8 * step, 1 * step, step, step);
    canvas.drawRect(yellowStart, yellowPaint);
    canvas.drawRect(yellowStart, borderPaint);

    // 3. BLUE (Right Arm):
    // Home lane: Row 7, Cols 9..13
    final bluePaint = Paint()..color = LudoColors.blue;
    for (int c = 9; c <= 13; c++) {
      final rect = Rect.fromLTWH(c * step, 7 * step, step, step);
      canvas.drawRect(rect, bluePaint);
      canvas.drawRect(rect, borderPaint);
    }
    // Blue Start Square: Col 13, Row 8 (touching Blue Yard)
    final blueStart = Rect.fromLTWH(13 * step, 8 * step, step, step);
    canvas.drawRect(blueStart, bluePaint);
    canvas.drawRect(blueStart, borderPaint);

    // 4. RED (Bottom Arm):
    // Home lane: Col 7, Rows 9..13
    final redPaint = Paint()..color = LudoColors.red;
    for (int r = 9; r <= 13; r++) {
      final rect = Rect.fromLTWH(7 * step, r * step, step, step);
      canvas.drawRect(rect, redPaint);
      canvas.drawRect(rect, borderPaint);
    }
    // Red Start Square: Col 6, Row 13 (touching Red Yard)
    final redStart = Rect.fromLTWH(6 * step, 13 * step, step, step);
    canvas.drawRect(redStart, redPaint);
    canvas.drawRect(redStart, borderPaint);
  }

  void _drawCenterHome(Canvas canvas, Size size, double step) {
    final center = Offset(size.width / 2, size.height / 2);

    // Left Triangle: GREEN (faces Green home lane)
    final greenPath = Path()
      ..moveTo(6 * step, 6 * step)
      ..lineTo(6 * step, 9 * step)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = LudoColors.green);

    // Top Triangle: YELLOW (faces Yellow home lane)
    final yellowPath = Path()
      ..moveTo(6 * step, 6 * step)
      ..lineTo(9 * step, 6 * step)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = LudoColors.yellow);

    // Right Triangle: BLUE (faces Blue home lane)
    final bluePath = Path()
      ..moveTo(9 * step, 6 * step)
      ..lineTo(9 * step, 9 * step)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = LudoColors.blue);

    // Bottom Triangle: RED (faces Red home lane)
    final redPath = Path()
      ..moveTo(6 * step, 9 * step)
      ..lineTo(9 * step, 9 * step)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(redPath, Paint()..color = LudoColors.red);

    // Triangle dividing borders
    final borderPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(greenPath, borderPaint);
    canvas.drawPath(yellowPath, borderPaint);
    canvas.drawPath(bluePath, borderPaint);
    canvas.drawPath(redPath, borderPaint);

    // Small clean golden center circle
    canvas.drawCircle(center, step * 0.28, Paint()..color = LudoColors.accentGold);
    canvas.drawCircle(
      center,
      step * 0.28,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawSafeStars(Canvas canvas, double step) {
    // 8 Safe Star positions:
    // 4 on start squares + 4 on track stars
    final starCells = [
      // 4 Start squares:
      const Point<int>(1, 6), // Green Start
      const Point<int>(8, 1), // Yellow Start
      const Point<int>(13, 8), // Blue Start
      const Point<int>(6, 13), // Red Start
      // 4 Safe Star squares:
      const Point<int>(6, 2), // Star 1 (Top Arm)
      const Point<int>(12, 6), // Star 2 (Right Arm)
      const Point<int>(8, 12), // Star 3 (Bottom Arm)
      const Point<int>(2, 8), // Star 4 (Left Arm)
    ];

    for (final pt in starCells) {
      final center = Offset((pt.x + 0.5) * step, (pt.y + 0.5) * step);
      _drawStar(canvas, center, step * 0.36, LudoColors.starGold);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    final double innerRadius = radius * 0.45;
    const int points = 5;

    for (int i = 0; i < points * 2; i++) {
      final r = (i % 2 == 0) ? radius : innerRadius;
      final angle = (i * pi / points) - (pi / 2);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
