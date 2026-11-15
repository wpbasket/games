import 'package:flutter/material.dart';
import '../../engine/ludo_models.dart';
import '../theme/ludo_colors.dart';

class PlayerCardWidget extends StatelessWidget {
  final Player player;
  final bool isCurrentTurn;
  final bool isRolling;

  const PlayerCardWidget({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    this.isRolling = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = LudoColors.primary(player.color);
    final lightColor = LudoColors.light(player.color);

    return SizedBox(
      height: 52,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: isCurrentTurn ? Colors.white : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrentTurn ? color : Colors.transparent,
            width: 2.0,
          ),
          boxShadow: [
            if (isCurrentTurn)
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Player Avatar Circle
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: player.rank != null
                    ? Text(
                        '#${player.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : Icon(
                        player.type == PlayerType.human
                            ? Icons.person
                            : Icons.smart_toy,
                        color: Colors.white,
                        size: 16,
                      ),
              ),
            ),
            const SizedBox(width: 8),

            // Player Name & Type
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            height: 1.1,
                            color: isCurrentTurn ? color : const Color(0xFF263238),
                          ),
                        ),
                      ),
                      if (player.type == PlayerType.bot) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BOT',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  // Pawn Progress Pill (Home Count)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home, size: 11, color: color),
                        const SizedBox(width: 2),
                        Text(
                          '${player.finishedPawnsCount}/4',
                          style: TextStyle(
                            fontSize: 9.5,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (isCurrentTurn) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: lightColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: SizedBox(
                              width: 42,
                              child: Text(
                                isRolling ? 'Roll...' : 'Active',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
