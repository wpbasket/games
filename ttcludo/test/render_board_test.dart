import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttcludo/engine/ludo_models.dart';
import 'package:ttcludo/ui/screens/game_screen.dart';

void main() {
  testWidgets('Render and save Ludo board screenshot', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          config: GameModeConfig(
            modeType: GameModeType.fourHumansPassPlay,
            title: 'Render Test',
            subtitle: 'Checking Board Alignment',
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

    final boundaryFinder = find.byKey(const ValueKey('full_board_boundary'));
    expect(boundaryFinder, findsOneWidget);

    final RenderRepaintBoundary targetBoundary =
        tester.renderObject(boundaryFinder) as RenderRepaintBoundary;

    await tester.runAsync(() async {
      final ui.Image image = await targetBoundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final file = File('/home/nitishraj/.gemini/antigravity/brain/73804b15-0857-4b28-9b2e-c32aa793189e/board_screenshot.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }
    });
  });

  testWidgets('Render and save Green Human rotated board screenshot', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          config: GameModeConfig(
            modeType: GameModeType.custom,
            title: 'Render Rotated Test',
            subtitle: 'Green Human vs 3 Bots',
            icon: Icons.games,
            seatStates: {
              PlayerColor.green: SeatState.human,
              PlayerColor.red: SeatState.bot,
              PlayerColor.yellow: SeatState.bot,
              PlayerColor.blue: SeatState.bot,
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final boundaryFinder = find.byKey(const ValueKey('full_board_boundary'));
    expect(boundaryFinder, findsOneWidget);

    final RenderRepaintBoundary targetBoundary =
        tester.renderObject(boundaryFinder) as RenderRepaintBoundary;

    await tester.runAsync(() async {
      final ui.Image image = await targetBoundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final file = File('/home/nitishraj/.gemini/antigravity/brain/73804b15-0857-4b28-9b2e-c32aa793189e/rotated_board_screenshot.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }
    });
  });
}
