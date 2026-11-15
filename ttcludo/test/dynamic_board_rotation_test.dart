import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttcludo/engine/ludo_models.dart';
import 'package:ttcludo/ui/screens/game_screen.dart';

void main() {
  testWidgets('1 Human as Green vs 3 Bots rotates Green to Bottom-Left', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;

    const config = GameModeConfig(
      modeType: GameModeType.custom,
      title: 'Green Human vs 3 Bots',
      subtitle: 'Testing rotation',
      icon: Icons.games,
      seatStates: {
        PlayerColor.green: SeatState.human,
        PlayerColor.red: SeatState.bot,
        PlayerColor.yellow: SeatState.bot,
        PlayerColor.blue: SeatState.bot,
      },
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(config: config),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Find RotatedBox wrapping the board
    final rotatedBoxFinder = find.byType(RotatedBox);
    expect(rotatedBoxFinder, findsWidgets);

    // Verify the board has quarterTurns = 3 (bringing Green from Top-Left to Bottom-Left)
    final rotatedBoxes = tester.widgetList<RotatedBox>(rotatedBoxFinder).toList();
    expect(rotatedBoxes.any((r) => r.quarterTurns == 3), isTrue);
  });

  testWidgets('1 Human as Yellow vs 1 Bot rotates Yellow to Bottom-Left', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;

    const config = GameModeConfig(
      modeType: GameModeType.custom,
      title: 'Yellow Human vs Red Bot',
      subtitle: 'Testing rotation',
      icon: Icons.games,
      seatStates: {
        PlayerColor.yellow: SeatState.human,
        PlayerColor.red: SeatState.bot,
        PlayerColor.green: SeatState.inactive,
        PlayerColor.blue: SeatState.inactive,
      },
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(config: config),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final rotatedBoxFinder = find.byType(RotatedBox);
    final rotatedBoxes = tester.widgetList<RotatedBox>(rotatedBoxFinder).toList();
    // 180° (quarterTurns = 2) brings Top-Right Yellow to Bottom-Left
    expect(rotatedBoxes.any((r) => r.quarterTurns == 2), isTrue);
  });

  testWidgets('Multi-human game (2 Humans vs 2 Bots) stays unrotated (quarterTurns = 0)', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;

    final config = GameModeConfig.presets.firstWhere(
      (p) => p.modeType == GameModeType.twoVsTwoBots,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(config: config),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final rotatedBoxFinder = find.byType(RotatedBox);
    final rotatedBoxes = tester.widgetList<RotatedBox>(rotatedBoxFinder).toList();
    // All rotated boxes should have quarterTurns = 0 in multi-human matches
    for (final r in rotatedBoxes) {
      expect(r.quarterTurns, 0);
    }
  });

  testWidgets('Spectator mode (4 Bots) stays unrotated (quarterTurns = 0)', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;

    const config = GameModeConfig(
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

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(config: config),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final rotatedBoxFinder = find.byType(RotatedBox);
    final rotatedBoxes = tester.widgetList<RotatedBox>(rotatedBoxFinder).toList();
    for (final r in rotatedBoxes) {
      expect(r.quarterTurns, 0);
    }
  });
}
