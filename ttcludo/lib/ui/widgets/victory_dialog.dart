import 'package:flutter/material.dart';
import '../../engine/ludo_models.dart';
import '../theme/ludo_colors.dart';
import '../theme/app_feedback.dart';

class VictoryDialog extends StatelessWidget {
  final List<Player> players;
  final List<PlayerColor> winners;
  final VoidCallback onPlayAgain;
  final VoidCallback onMainMenu;

  const VictoryDialog({
    super.key,
    required this.players,
    required this.winners,
    required this.onPlayAgain,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    final winnerColor = winners.isNotEmpty ? winners.first : players.first.color;
    final winnerPlayer = players.firstWhere((p) => p.color == winnerColor);
    final winThemeColor = LudoColors.primary(winnerColor);

    final int humanCount = players.where((p) => p.type == PlayerType.human).length;
    final bool isSoloHumanMatch = (humanCount == 1);
    final bool isHumanWinner = isSoloHumanMatch && (winnerPlayer.type == PlayerType.human);

    // Title and Subtitle dynamically adapted for 1 Human vs Bots
    final String titleText;
    final String subtitleText;

    if (isSoloHumanMatch) {
      if (isHumanWinner) {
        titleText = 'You Won!';
        subtitleText = 'Congratulations on finishing all 4 pawns!';
      } else {
        titleText = '${winnerPlayer.name} Wins!';
        subtitleText = 'Better luck next time!';
      }
    } else {
      titleText = '${winnerPlayer.name} Wins!';
      subtitleText = 'Congratulations on finishing all 4 pawns!';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy Badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: LudoColors.accentGold.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: LudoColors.accentGold,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Winner Announcement
            Text(
              titleText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: winThemeColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitleText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // Podium / Results List
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: List.generate(players.length, (index) {
                  final sorted = [...players]..sort((a, b) {
                      final rankA = a.rank ?? 99;
                      final rankB = b.rank ?? 99;
                      return rankA.compareTo(rankB);
                    });
                  final p = sorted[index];
                  final pColor = LudoColors.primary(p.color);
                  final isYou = isSoloHumanMatch && p.type == PlayerType.human;
                  final String capColor = p.color.name[0].toUpperCase() + p.color.name.substring(1);
                  final displayName = isYou
                      ? (p.name == 'You' || p.name == '$capColor Player' ? 'You' : '${p.name} (You)')
                      : p.name;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: p.rank == 1 ? LudoColors.accentGold : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              p.rank != null ? '#${p.rank}' : '-',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: pColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: isYou ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13,
                              color: isYou ? const Color(0xFF1E88E5) : const Color(0xFF263238),
                            ),
                          ),
                        ),
                        Text(
                          '${p.finishedPawnsCount}/4 pawns',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      AppFeedback.click();
                      onMainMenu();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Menu'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      AppFeedback.click();
                      onPlayAgain();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: winThemeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: const Text('Play Again', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
