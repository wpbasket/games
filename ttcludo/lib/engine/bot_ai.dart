import 'dart:math';
import 'ludo_models.dart';
import 'board_coordinates.dart';

class BotAI {
  static final Random _botRng = Random();

  /// Evaluates all valid moves and returns the pawn based on difficulty level
  static Pawn pickBestPawn({
    required Player botPlayer,
    required List<Pawn> validPawns,
    required int diceValue,
    required List<Player> allPlayers,
    BotDifficulty difficulty = BotDifficulty.medium,
  }) {
    if (validPawns.isEmpty) {
      throw ArgumentError('No valid pawns to pick from');
    }
    if (validPawns.length == 1) {
      return validPawns.first;
    }

    // Easy mode: 50% chance of making a casual human move instead of optimal play
    if (difficulty == BotDifficulty.easy && _botRng.nextDouble() < 0.50) {
      return validPawns[_botRng.nextInt(validPawns.length)];
    }

    // Medium mode: 30% casual blunder/human-like move rate
    // Gives human players natural opportunities to outplay the bot
    if (difficulty == BotDifficulty.medium && _botRng.nextDouble() < 0.30) {
      return validPawns[_botRng.nextInt(validPawns.length)];
    }

    Pawn bestPawn = validPawns.first;
    double highestScore = -999999.0;

    for (final pawn in validPawns) {
      final score = evaluateMove(
        pawn: pawn,
        diceValue: diceValue,
        botPlayer: botPlayer,
        allPlayers: allPlayers,
        difficulty: difficulty,
      );

      if (score > highestScore) {
        highestScore = score;
        bestPawn = pawn;
      }
    }

    return bestPawn;
  }

  static double evaluateMove({
    required Pawn pawn,
    required int diceValue,
    required Player botPlayer,
    required List<Player> allPlayers,
    BotDifficulty difficulty = BotDifficulty.medium,
  }) {
    double score = 0.0;

    // 1. Moving out of base yard on a 6
    if (pawn.isInBase) {
      score += 450.0;
      // Bonus if base is crowded
      score += botPlayer.basePawnsCount * 25.0;
      return score;
    }

    final targetStep = pawn.step + diceValue;

    // 2. Reaching Home Goal (step 56)
    if (targetStep == 56) {
      score += 1000.0;
      return score;
    }

    // 3. Entering the safe Home Lane (steps 51..55)
    if (targetStep >= 51 && pawn.step < 51) {
      score += 350.0;
    }

    // 4. Capture opponent pawns on the track
    if (targetStep <= 50) {
      final targetTrackIdx = BoardCoordinates.getGlobalTrackIndex(botPlayer.color, targetStep);
      final isSafeCell = BoardCoordinates.isSafeStep(botPlayer.color, targetStep);

      if (!isSafeCell && targetTrackIdx != null) {
        int capturedOpponents = 0;
        for (final opponent in allPlayers) {
          if (opponent.color == botPlayer.color) continue;
          for (final oppPawn in opponent.pawns) {
            if (oppPawn.isOnTrack) {
              final oppTrackIdx = BoardCoordinates.getGlobalTrackIndex(opponent.color, oppPawn.step);
              if (oppTrackIdx == targetTrackIdx) {
                capturedOpponents++;
                // Bonus based on how far along the opponent pawn was
                score += 800.0 + (oppPawn.step * 10.0);
              }
            }
          }
        }
        if (capturedOpponents > 0) {
          return score; // Immediate strong reward
        }
      }

      // 5. Landing on a Safe Star
      if (isSafeCell) {
        score += 280.0;
      }

      // NOTE: 6-step evasion radar and ambush avoidance are DISABLED in Easy and Medium modes!
      // This prevents bots from mathematically steering clear of the player,
      // letting bot pawns naturally stop in front of the human player to create frequent capture chances.
      if (difficulty == BotDifficulty.hard) {
        // Escaping from danger (Hard/Master mode only)
        if (!BoardCoordinates.isSafeStep(botPlayer.color, pawn.step)) {
          final currentTrackIdx = BoardCoordinates.getGlobalTrackIndex(botPlayer.color, pawn.step);
          if (currentTrackIdx != null) {
            bool underThreat = false;
            for (final opponent in allPlayers) {
              if (opponent.color == botPlayer.color) continue;
              for (final oppPawn in opponent.pawns) {
                if (oppPawn.isOnTrack) {
                  final oppTrackIdx = BoardCoordinates.getGlobalTrackIndex(opponent.color, oppPawn.step);
                  if (oppTrackIdx != null) {
                    final distanceBehind = (currentTrackIdx - oppTrackIdx + 52) % 52;
                    if (distanceBehind >= 1 && distanceBehind <= 6) {
                      underThreat = true;
                      break;
                    }
                  }
                }
              }
              if (underThreat) break;
            }
            if (underThreat) {
              score += 260.0; // Escaping capture
            }
          }
        }

        // Avoid stepping directly in front of an opponent (Hard/Master mode only)
        if (!isSafeCell) {
          for (final opponent in allPlayers) {
            if (opponent.color == botPlayer.color) continue;
            for (final oppPawn in opponent.pawns) {
              if (oppPawn.isOnTrack) {
                final oppTrackIdx = BoardCoordinates.getGlobalTrackIndex(opponent.color, oppPawn.step);
                if (oppTrackIdx != null) {
                  final distanceAhead = (targetTrackIdx! - oppTrackIdx + 52) % 52;
                  if (distanceAhead >= 1 && distanceAhead <= 6) {
                    score -= 150.0; // Penalty for placing pawn in immediate striking range
                  }
                }
              }
            }
          }
        }
      }
    }

    // 8. General progress forward
    score += targetStep * 4.0;

    return score;
  }
}
