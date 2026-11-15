import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttcludo/engine/ludo_models.dart';
import 'package:ttcludo/ui/screens/game_screen.dart';
import 'package:ttcludo/ui/widgets/dice_3d_widget.dart';

void main() {
  testWidgets('Layout stability test: Board and HUD dimensions never shift during dice roll',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          config: GameModeConfig(
            modeType: GameModeType.fourHumansPassPlay,
            title: 'Stability Test',
            subtitle: 'Testing Zero Jitter',
            icon: Icons.games,
            seatStates: {
              PlayerColor.red: SeatState.human,
              PlayerColor.green: SeatState.human,
              PlayerColor.yellow: SeatState.human,
              PlayerColor.blue: SeatState.human,
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Measure initial board and HUD sizes
    final boardFinder = find.byKey(const ValueKey('full_board_boundary'));
    expect(boardFinder, findsOneWidget);
    final initialBoardSize = tester.getSize(boardFinder);

    // 2. Tap ROLL button
    final rollButtonFinder = find.widgetWithText(ElevatedButton, 'ROLL');
    expect(rollButtonFinder, findsOneWidget);
    await tester.tap(rollButtonFinder);

    // Pump midway during rolling animation (150ms)
    await tester.pump(const Duration(milliseconds: 150));

    final rollingBoardSize = tester.getSize(boardFinder);
    expect(rollingBoardSize, equals(initialBoardSize),
        reason: 'Board resized or jumped during dice roll animation!');

    // 3. Complete rolling animation and timers
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));

    final postRollBoardSize = tester.getSize(boardFinder);
    expect(postRollBoardSize, equals(initialBoardSize),
        reason: 'Board resized or jumped after dice roll finished!');

    // Dispose cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('Bot turn: Dice and ROLL button remain visible and active just like human turn',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          config: GameModeConfig(
            modeType: GameModeType.oneVsThreeBots,
            title: 'Bot Turn Test',
            subtitle: 'Checking Bot Dice Visibility',
            icon: Icons.smart_toy,
            seatStates: {
              PlayerColor.red: SeatState.bot,
              PlayerColor.green: SeatState.bot,
              PlayerColor.yellow: SeatState.bot,
              PlayerColor.blue: SeatState.human,
            },
          ),
        ),
      ),
    );
    // Initial pump: Red bot's turn waiting to roll
    await tester.pump(const Duration(milliseconds: 100));

    // Both ROLL button and 3D dice are visible on bot turn
    expect(find.widgetWithText(ElevatedButton, 'ROLL'), findsOneWidget);
    expect(find.byType(Dice3DWidget), findsOneWidget);

    // Dispose widget tree to cleanly cancel pending bot timers
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
