import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttcludo/engine/ludo_engine.dart';
import 'package:ttcludo/engine/ludo_models.dart';
import 'package:ttcludo/engine/board_coordinates.dart';
import 'package:ttcludo/engine/bot_ai.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Humanized AI Test: Disabling evasion radar creates frequent capture opportunities under pure random dice', () {
    int humanCaptures = 0;
    int botCaptures = 0;
    int humanWins = 0;
    int botWins = 0;

    for (int g = 0; g < 300; g++) {
      final engine = LudoEngine();
      engine.initGame(GameModeConfig.presets[1], randomizeStartingPlayer: true); // 1v1

      int turns = 0;
      int playerIdx = 0;
      while (!engine.isGameOver && turns < 1500) {
        turns++;
        final player = engine.players[playerIdx];
        playerIdx = (playerIdx + 1) % engine.players.length;

        final roll = Random.secure().nextInt(6) + 1;

        final valid = <Pawn>[];
        for (final p in player.pawns) {
          if (p.isHome) continue;
          if (p.isInBase) {
            if (roll == 6) valid.add(p);
          } else {
            if (p.step + roll <= 56) valid.add(p);
          }
        }

        if (valid.isNotEmpty) {
          final bestPawn = BotAI.pickBestPawn(
            botPlayer: player,
            validPawns: valid,
            diceValue: roll,
            allPlayers: engine.players,
            difficulty: BotDifficulty.medium,
          );

          final toStep = bestPawn.isInBase ? 0 : bestPawn.step + roll;
          bestPawn.step = toStep;

          if (toStep <= 50) {
            final isSafe = BoardCoordinates.isSafeStep(bestPawn.color, toStep);
            final trackIdx = BoardCoordinates.getGlobalTrackIndex(bestPawn.color, toStep);
            if (!isSafe && trackIdx != null) {
              for (final opp in engine.players) {
                if (opp.color == bestPawn.color) continue;
                for (final oppPawn in opp.pawns) {
                  if (oppPawn.isOnTrack) {
                    final oppTrackIdx = BoardCoordinates.getGlobalTrackIndex(opp.color, oppPawn.step);
                    if (oppTrackIdx == trackIdx) {
                      oppPawn.step = -1;
                      if (player.type == PlayerType.human) {
                        humanCaptures++;
                      } else {
                        botCaptures++;
                      }
                    }
                  }
                }
              }
            }
          }

          if (player.hasFinished) {
            if (player.type == PlayerType.human) {
              humanWins++;
            } else {
              botWins++;
            }
            break;
          }
        }
      }
    }

    // Both players should get frequent captures without bot domination
    expect(humanCaptures, greaterThan(150), reason: 'Human captures: $humanCaptures in 300 games');
    expect(botCaptures, greaterThan(150), reason: 'Bot captures: $botCaptures in 300 games');

    // Win rates should be completely balanced (close to 50%)
    final humanWinPct = (humanWins / (humanWins + botWins)) * 100;
    expect(humanWinPct, closeTo(50.0, 10.0));
  });
}
