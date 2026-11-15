import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttcludo/main.dart';
import 'package:ttcludo/engine/ludo_models.dart';
import 'package:ttcludo/ui/screens/game_screen.dart';

void main() {
  testWidgets('DevTools opening simulation: transient 1.6px viewport renders safely without overflow',
      (WidgetTester tester) async {
    // Simulating the transient Chrome DevTools opening / docking frame where constraints collapse to near-zero (1.6px)
    tester.view.physicalSize = const Size(1.6, 1.6);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const LudoApp());
    await tester.pump(const Duration(milliseconds: 50));

    // Must not throw any RenderFlex overflow assertion
    expect(tester.takeException(), isNull);

    // Now restore to normal responsive device dimensions (e.g. Pixel / iPhone viewport)
    tester.view.physicalSize = const Size(390, 844);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(LudoApp), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Clean up
    addTearDown(() => tester.view.resetPhysicalSize());
  });

  testWidgets('Narrow mobile viewport test (320px width) in GameScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          config: GameModeConfig(
            modeType: GameModeType.oneVsThreeBots,
            title: '1 Player vs 3 Bots (Custom Combinations)',
            subtitle: 'Solo match as Red',
            icon: Icons.smart_toy_outlined,
            seatStates: {
              PlayerColor.red: SeatState.human,
              PlayerColor.green: SeatState.bot,
              PlayerColor.yellow: SeatState.bot,
              PlayerColor.blue: SeatState.bot,
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Must fit on 320px screen without any RenderFlex overflow
    expect(tester.takeException(), isNull);

    // Dispose
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
    addTearDown(() => tester.view.resetPhysicalSize());
  });
}
