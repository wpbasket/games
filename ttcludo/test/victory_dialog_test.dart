import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ttcludo/engine/ludo_models.dart';
import 'package:ttcludo/ui/widgets/victory_dialog.dart';

void main() {
  testWidgets('VictoryDialog displays "You Won!" when human wins in 1 Human vs Bots match', (tester) async {
    final players = [
      Player(color: PlayerColor.red, type: PlayerType.human, name: 'You', rank: 1),
      Player(color: PlayerColor.green, type: PlayerType.bot, name: 'Green Bot', rank: 2),
      Player(color: PlayerColor.yellow, type: PlayerType.bot, name: 'Yellow Bot', rank: 3),
      Player(color: PlayerColor.blue, type: PlayerType.bot, name: 'Blue Bot', rank: 4),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          body: Center(
            child: RepaintBoundary(
              key: const ValueKey('victory_dialog_boundary'),
              child: VictoryDialog(
                players: players,
                winners: const [PlayerColor.red],
                onPlayAgain: () {},
                onMainMenu: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Title says "You Won!"
    expect(find.text('You Won!'), findsOneWidget);
    expect(find.text('Congratulations on finishing all 4 pawns!'), findsOneWidget);
    // Verify Red Player is not shown, "You" is shown in podium
    expect(find.text('Red Player Wins!'), findsNothing);
    expect(find.text('You'), findsOneWidget);

    final boundaryFinder = find.byKey(const ValueKey('victory_dialog_boundary'));
    final RenderRepaintBoundary targetBoundary =
        tester.renderObject(boundaryFinder) as RenderRepaintBoundary;

    await tester.runAsync(() async {
      final ui.Image image = await targetBoundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final file = File('/home/nitishraj/.gemini/antigravity/brain/73804b15-0857-4b28-9b2e-c32aa793189e/victory_dialog_screenshot.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }
    });
  });

  testWidgets('VictoryDialog displays "You Won!" even if human name was originally "Red Player"', (tester) async {
    final players = [
      Player(color: PlayerColor.red, type: PlayerType.human, name: 'Red Player', rank: 1),
      Player(color: PlayerColor.green, type: PlayerType.bot, name: 'Green Bot', rank: 2),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VictoryDialog(
            players: players,
            winners: const [PlayerColor.red],
            onPlayAgain: () {},
            onMainMenu: () {},
          ),
        ),
      ),
    );

    expect(find.text('You Won!'), findsOneWidget);
    expect(find.text('Red Player Wins!'), findsNothing);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('VictoryDialog displays "[Bot] Wins!" and "Better luck next time!" if bot wins in 1 Human vs Bots match', (tester) async {
    final players = [
      Player(color: PlayerColor.green, type: PlayerType.bot, name: 'Green Bot', rank: 1),
      Player(color: PlayerColor.red, type: PlayerType.human, name: 'You', rank: 2),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VictoryDialog(
            players: players,
            winners: const [PlayerColor.green],
            onPlayAgain: () {},
            onMainMenu: () {},
          ),
        ),
      ),
    );

    expect(find.text('Green Bot Wins!'), findsOneWidget);
    expect(find.text('Better luck next time!'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('VictoryDialog displays "Red Player Wins!" in multi-human match', (tester) async {
    final players = [
      Player(color: PlayerColor.red, type: PlayerType.human, name: 'Red Player', rank: 1),
      Player(color: PlayerColor.yellow, type: PlayerType.human, name: 'Yellow Player', rank: 2),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VictoryDialog(
            players: players,
            winners: const [PlayerColor.red],
            onPlayAgain: () {},
            onMainMenu: () {},
          ),
        ),
      ),
    );

    expect(find.text('Red Player Wins!'), findsOneWidget);
    expect(find.text('Congratulations on finishing all 4 pawns!'), findsOneWidget);
  });
}
