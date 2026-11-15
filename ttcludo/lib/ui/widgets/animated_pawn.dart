import 'package:flutter/material.dart';
import '../../engine/ludo_models.dart';
import '../../engine/board_coordinates.dart';
import '../theme/ludo_colors.dart';

class AnimatedPawnWidget extends StatefulWidget {
  final Pawn pawn;
  final bool isSelectable;
  final double cellSize;
  final int indexInGroup;
  final int totalInGroup;
  final int boardQuarterTurns;
  final ValueChanged<Pawn> onTap;

  const AnimatedPawnWidget({
    super.key,
    required this.pawn,
    required this.isSelectable,
    required this.cellSize,
    required this.indexInGroup,
    required this.totalInGroup,
    this.boardQuarterTurns = 0,
    required this.onTap,
  });

  @override
  State<AnimatedPawnWidget> createState() => _AnimatedPawnWidgetState();
}

class _AnimatedPawnWidgetState extends State<AnimatedPawnWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isSelectable) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedPawnWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelectable && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isSelectable && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coord = BoardCoordinates.getCoordForPawn(widget.pawn);
    final fanOffset = BoardCoordinates.getFanningOffset(
      widget.indexInGroup,
      widget.totalInGroup,
      widget.cellSize,
    );

    // coord.x and coord.y are the exact center coordinates in grid units
    final double centerX = (coord.x * widget.cellSize) + fanOffset.dx;
    final double centerY = (coord.y * widget.cellSize) + fanOffset.dy;
    final double pawnSize = widget.cellSize * (widget.totalInGroup > 1 ? 0.72 : 0.85);

    final color = LudoColors.primary(widget.pawn.color);
    final darkColor = LudoColors.dark(widget.pawn.color);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      left: centerX - (pawnSize / 2),
      top: centerY - (pawnSize / 2),
      width: pawnSize,
      height: pawnSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.isSelectable ? () => widget.onTap(widget.pawn) : null,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = widget.isSelectable ? _pulseScale.value : 1.0;
            final counterTurns = (4 - (widget.boardQuarterTurns % 4)) % 4;

            return Transform.scale(
              scale: scale,
              child: RotatedBox(
                quarterTurns: counterTurns,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                  // Glow effect when selectable
                  if (widget.isSelectable)
                    Container(
                      width: pawnSize * 1.15,
                      height: pawnSize * 1.15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.9),
                            blurRadius: 8,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: color.withValues(alpha: 0.8),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                  // Pawn Pin Shadow
                  Positioned(
                    bottom: 1,
                    child: Container(
                      width: pawnSize * 0.7,
                      height: pawnSize * 0.25,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(pawnSize * 0.7, pawnSize * 0.25),
                        ),
                      ),
                    ),
                  ),

                  // 3D Glassy Pawn Pin Body
                  CustomPaint(
                    size: Size(pawnSize, pawnSize),
                    painter: _PawnPainter(
                      color: color,
                      darkColor: darkColor,
                      isSelected: widget.isSelectable,
                    ),
                  ),
                ],
              ),
            ),
          );
          },
        ),
      ),
    );
  }
}

class _PawnPainter extends CustomPainter {
  final Color color;
  final Color darkColor;
  final bool isSelected;

  _PawnPainter({
    required this.color,
    required this.darkColor,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Base Rim
    final baseRect = Rect.fromCenter(
      center: Offset(center.dx, h * 0.78),
      width: w * 0.75,
      height: h * 0.35,
    );
    final baseGradient = RadialGradient(
      center: const Alignment(-0.2, -0.4),
      colors: [Colors.white.withValues(alpha: 0.9), color, darkColor],
      stops: const [0.0, 0.45, 1.0],
    );
    final basePaint = Paint()..shader = baseGradient.createShader(baseRect);
    canvas.drawOval(baseRect, basePaint);

    // Collar / Ring
    final ringRect = Rect.fromCenter(
      center: Offset(center.dx, h * 0.52),
      width: w * 0.45,
      height: h * 0.16,
    );
    final ringPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawOval(ringRect, ringPaint);

    // Head Sphere
    final headCenter = Offset(center.dx, h * 0.32);
    final headRadius = w * 0.28;
    final headRect = Rect.fromCircle(center: headCenter, radius: headRadius);
    final headGradient = RadialGradient(
      center: const Alignment(-0.35, -0.4),
      colors: [Colors.white, color, darkColor],
      stops: const [0.05, 0.5, 1.0],
    );
    final headPaint = Paint()..shader = headGradient.createShader(headRect);
    canvas.drawCircle(headCenter, headRadius, headPaint);

    // Highlights
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(headCenter.dx - headRadius * 0.3, headCenter.dy - headRadius * 0.3),
      headRadius * 0.25,
      highlightPaint,
    );

    // Thin stroke border for clarity
    final strokePaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(headCenter, headRadius, strokePaint);
    canvas.drawOval(baseRect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _PawnPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.darkColor != darkColor ||
      oldDelegate.isSelected != isSelected;
}
