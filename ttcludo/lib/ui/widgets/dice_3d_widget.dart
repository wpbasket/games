import 'dart:math';
import 'package:flutter/material.dart';
import '../../engine/ludo_models.dart';
import '../theme/ludo_colors.dart';

class Dice3DWidget extends StatefulWidget {
  final int value;
  final bool isRolling;
  final bool canRoll;
  final PlayerColor playerColor;
  final VoidCallback onRoll;

  const Dice3DWidget({
    super.key,
    required this.value,
    required this.isRolling,
    required this.canRoll,
    required this.playerColor,
    required this.onRoll,
  });

  @override
  State<Dice3DWidget> createState() => _Dice3DWidgetState();
}

class _Dice3DWidgetState extends State<Dice3DWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotX;
  late Animation<double> _rotY;
  int _displayValue = 1;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rotX = Tween<double>(begin: 0, end: 4 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _rotY = Tween<double>(begin: 0, end: 4 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.addListener(() {
      if (_controller.isAnimating) {
        // Randomize intermediate faces during spin
        setState(() {
          _displayValue = Random().nextInt(6) + 1;
        });
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _displayValue = widget.value;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant Dice3DWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _controller.forward(from: 0.0);
    } else if (!widget.isRolling) {
      _displayValue = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = LudoColors.primary(widget.playerColor);

    return GestureDetector(
      onTap: widget.canRoll ? widget.onRoll : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final isSpinning = _controller.isAnimating || widget.isRolling;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateX(isSpinning ? _rotX.value : 0.0)
              ..rotateY(isSpinning ? _rotY.value : 0.0),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.canRoll ? activeColor : Colors.grey.shade300,
                  width: widget.canRoll ? 3.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.canRoll
                        ? activeColor.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.12),
                    blurRadius: widget.canRoll ? 12 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(7.0),
                child: _buildDiceFace(_displayValue, activeColor),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiceFace(int val, Color pipColor) {
    // 3x3 layout for pips
    final Map<int, List<bool>> pipPatterns = {
      1: [
        false, false, false,
        false, true,  false,
        false, false, false,
      ],
      2: [
        true,  false, false,
        false, false, false,
        false, false, true,
      ],
      3: [
        true,  false, false,
        false, true,  false,
        false, false, true,
      ],
      4: [
        true,  false, true,
        false, false, false,
        true,  false, true,
      ],
      5: [
        true,  false, true,
        false, true,  false,
        true,  false, true,
      ],
      6: [
        true,  false, true,
        true,  false, true,
        true,  false, true,
      ],
    };

    final pattern = pipPatterns[val] ?? pipPatterns[1]!;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        if (!pattern[index]) {
          return const SizedBox.shrink();
        }
        return Container(
          decoration: BoxDecoration(
            color: (val == 6 || val == 1) ? pipColor : const Color(0xFF263238),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 1,
                offset: const Offset(0, 0.5),
              ),
            ],
          ),
        );
      },
    );
  }
}
