import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttcludo/engine/ludo_models.dart';
import 'package:ttcludo/engine/board_coordinates.dart';
import 'package:ttcludo/engine/ludo_engine.dart';
import 'package:ttcludo/engine/bot_ai.dart';

void main() {
  group('Board Coordinates & Geometry Tests', () {
    test('Track length is exactly 52 cells with unique coordinates', () {
      expect(BoardCoordinates.globalTrack.length, 52);
      final set = BoardCoordinates.globalTrack.toSet();
      expect(set.length, 52);
    });

    test('Each player starting index is spaced 13 steps apart', () {
      expect(BoardCoordinates.startIndices[PlayerColor.green], 0);
      expect(BoardCoordinates.startIndices[PlayerColor.yellow], 13);
      expect(BoardCoordinates.startIndices[PlayerColor.blue], 26);
      expect(BoardCoordinates.startIndices[PlayerColor.red], 39);
    });

    test('8 Safe Star indices are well defined', () {
      expect(BoardCoordinates.safeTrackIndices.length, 8);
      for (final startIdx in BoardCoordinates.startIndices.values) {
        expect(BoardCoordinates.safeTrackIndices.contains(startIdx), isTrue);
      }
    });

    test('Home lanes have 6 coordinates leading to center', () {
      for (final color in PlayerColor.values) {
        expect(BoardCoordinates.homeLanes[color]!.length, 6);
      }
    });
  });

  group('Ludo Engine & Combination Edge Cases Tests', () {
    test('Initial 4-player game state setup (deterministic)', () {
      final engine = LudoEngine();
      engine.initGame(
        GameModeConfig.presets.first,
        randomizeStartingPlayer: false,
      ); // 1 Human vs 3 Bots
      expect(engine.players.length, 4);
      expect(engine.currentPlayer.color, PlayerColor.red);
      expect(engine.currentPlayer.name, 'You');
      expect(engine.phase, TurnPhase.waitingForRoll);
      expect(engine.isGameOver, isFalse);
      engine.dispose();
    });

    test('Starting player randomization distributes across all active players', () {
      final engine = LudoEngine();
      final startingColors = <PlayerColor, int>{};

      for (int i = 0; i < 200; i++) {
        engine.initGame(
          GameModeConfig.presets.first,
          randomizeStartingPlayer: true,
        );
        final color = engine.currentPlayer.color;
        startingColors[color] = (startingColors[color] ?? 0) + 1;
      }

      // In 4-player match, every color should be selected roughly 50 times (25% each)
      // Verify all 4 players were chosen at least 20 times over 200 runs
      expect(startingColors.keys.length, 4);
      for (final color in PlayerColor.values) {
        expect(startingColors[color]!, greaterThanOrEqualTo(20),
            reason: '$color was chosen ${startingColors[color]} times');
      }
      engine.dispose();
    });

    test('2-Player Match setup (1 Human vs 1 Bot: Red & Yellow)', () {
      final engine = LudoEngine();
      final config = GameModeConfig(
        modeType: GameModeType.oneVsOneBot,
        title: 'Duel',
        subtitle: 'Red vs Yellow',
        icon: Icons.sports_kabaddi,
        seatStates: {
          PlayerColor.red: SeatState.human,
          PlayerColor.green: SeatState.inactive,
          PlayerColor.yellow: SeatState.bot,
          PlayerColor.blue: SeatState.inactive,
        },
      );

      engine.initGame(config);
      expect(engine.players.length, 2);
      expect(engine.isSeatActive(PlayerColor.red), isTrue);
      expect(engine.isSeatActive(PlayerColor.yellow), isTrue);
      expect(engine.isSeatActive(PlayerColor.green), isFalse);
      expect(engine.isSeatActive(PlayerColor.blue), isFalse);

      // Verify pawns only exist for Red and Yellow
      final pawns = engine.players.expand((p) => p.pawns).toList();
      expect(pawns.length, 8); // 4 + 4
      expect(pawns.any((p) => p.color == PlayerColor.green), isFalse);
      expect(pawns.any((p) => p.color == PlayerColor.blue), isFalse);
      engine.dispose();
    });

    test('3-Player Match setup (2 Humans vs 1 Bot)', () {
      final engine = LudoEngine();
      final config = GameModeConfig(
        modeType: GameModeType.custom,
        title: '3-Player',
        subtitle: 'Red, Green, Blue active',
        icon: Icons.groups,
        seatStates: {
          PlayerColor.red: SeatState.human,
          PlayerColor.green: SeatState.human,
          PlayerColor.yellow: SeatState.inactive,
          PlayerColor.blue: SeatState.bot,
        },
      );

      engine.initGame(config);
      expect(engine.players.length, 3);
      expect(engine.isSeatActive(PlayerColor.yellow), isFalse);
      expect(engine.isSeatActive(PlayerColor.green), isTrue);
      engine.dispose();
    });

    test('Spectator Mode (All Bots) detection', () {
      final engine = LudoEngine();
      final config = GameModeConfig(
        modeType: GameModeType.spectatorBots,
        title: 'AI Battle',
        subtitle: '4 Bots',
        icon: Icons.smart_toy,
        seatStates: {
          PlayerColor.red: SeatState.bot,
          PlayerColor.green: SeatState.bot,
          PlayerColor.yellow: SeatState.bot,
          PlayerColor.blue: SeatState.bot,
        },
      );

      engine.initGame(config);
      expect(engine.isSpectatorMode, isTrue);
      expect(engine.players.length, 4);
      engine.dispose();
    });

    test('Validation edge case: < 2 players throws ArgumentError', () {
      final engine = LudoEngine();
      final config = GameModeConfig(
        modeType: GameModeType.custom,
        title: 'Invalid Match',
        subtitle: 'Only 1 player',
        icon: Icons.error,
        seatStates: {
          PlayerColor.red: SeatState.human,
          PlayerColor.green: SeatState.inactive,
          PlayerColor.yellow: SeatState.inactive,
          PlayerColor.blue: SeatState.inactive,
        },
      );

      expect(() => engine.initGame(config), throwsArgumentError);
      engine.dispose();
    });

    test('BotAI selects capture move over basic advance', () {
      final bot = Player(color: PlayerColor.green, type: PlayerType.bot, name: 'Bot');
      final opp = Player(color: PlayerColor.red, type: PlayerType.human, name: 'Red');

      // Bot pawn 0 is at step 5
      bot.pawns[0].step = 5;
      // Bot pawn 1 is at step 10
      bot.pawns[1].step = 10;

      // Opponent pawn is at the exact track cell where bot pawn 0 would land on a roll of 4 (step 9)
      final targetTrackIdx = BoardCoordinates.getGlobalTrackIndex(PlayerColor.green, 9);
      opp.pawns[0].step = (targetTrackIdx! - BoardCoordinates.startIndices[PlayerColor.red]! + 52) % 52;

      final bestPawn = BotAI.pickBestPawn(
        botPlayer: bot,
        validPawns: [bot.pawns[0], bot.pawns[1]],
        diceValue: 4,
        allPlayers: [bot, opp],
        difficulty: BotDifficulty.hard,
      );

      // Bot should prioritize pawn 0 to capture opponent!
      expect(bestPawn.id, 0);
    });
  });
}
