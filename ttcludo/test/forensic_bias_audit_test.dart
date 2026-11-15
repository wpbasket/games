import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttcludo/engine/ludo_engine.dart';
import 'package:ttcludo/engine/ludo_models.dart';
import 'package:ttcludo/engine/board_coordinates.dart';
import 'package:ttcludo/engine/bot_ai.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Forensic Edge-Case Audit: 100,000 rolls per seat in 1 Human vs 3 Bots', () {
    final engine = LudoEngine();
    engine.initGame(GameModeConfig.presets[0]);

    final Map<PlayerColor, List<int>> faceCounts = {
      for (final c in PlayerColor.values) c: List.filled(7, 0),
    };

    for (int i = 0; i < 100000; i++) {
      for (final player in engine.players) {
        final roll = Random.secure().nextInt(6) + 1;
        faceCounts[player.color]![roll]++;
      }
    }

    // Verify statistical uniformity across all faces (under 2% deviation)
    for (final player in engine.players) {
      for (int face = 1; face <= 6; face++) {
        final diff = (faceCounts[player.color]![face] - 16666).abs();
        expect(diff < 800, isTrue,
            reason: '${player.name} face $face count: ${faceCounts[player.color]![face]}');
      }
    }
  });

  test('Forensic Edge-Case Audit: Simulation of 200 complete games of 1 Human vs 1 Bot', () {
    int redWins = 0;
    int yellowWins = 0;
    int redTotalRolls = 0;
    int yellowTotalRolls = 0;
    int redSixes = 0;
    int yellowSixes = 0;

    for (int g = 0; g < 200; g++) {
      final engine = LudoEngine();
      engine.initGame(GameModeConfig.presets[1], randomizeStartingPlayer: true);

      int turns = 0;
      while (!engine.isGameOver && turns < 2000) {
        turns++;
        final player = engine.currentPlayer;
        final rng = Random.secure();
        final roll = rng.nextInt(6) + 1;

        if (player.color == PlayerColor.red) {
          redTotalRolls++;
          if (roll == 6) redSixes++;
        } else {
          yellowTotalRolls++;
          if (roll == 6) yellowSixes++;
        }

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
            difficulty: BotDifficulty.hard,
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
                    }
                  }
                }
              }
            }
          }

          if (player.hasFinished) {
            if (player.color == PlayerColor.red) {
              redWins++;
            } else {
              yellowWins++;
            }
            break;
          }
        }
      }
    }

    expect(redWins + yellowWins, equals(200));
    expect((redSixes / redTotalRolls * 100), closeTo(16.67, 2.5));
    expect((yellowSixes / yellowTotalRolls * 100), closeTo(16.67, 2.5));
  });
}
