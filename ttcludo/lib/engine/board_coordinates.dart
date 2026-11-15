import 'dart:math';
import 'package:flutter/material.dart';
import 'ludo_models.dart';

class BoardCoord {
  final double x;
  final double y;

  const BoardCoord(this.x, this.y);

  Offset toPixel(double cellSize) => Offset(x * cellSize, y * cellSize);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardCoord &&
          runtimeType == other.runtimeType &&
          (x - other.x).abs() < 0.001 &&
          (y - other.y).abs() < 0.001;

  @override
  int get hashCode => Object.hash((x * 10).round(), (y * 10).round());

  @override
  String toString() => 'BoardCoord(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

class BoardCoordinates {
  /// 52 outer track coordinates in clockwise order on a 15x15 board.
  /// Each coordinate represents the EXACT CENTER of that cell in grid units (col + 0.5, row + 0.5).
  static const List<BoardCoord> globalTrack = [
    // 0..4: Left Arm (top row, moving right, directly under Green Yard)
    BoardCoord(1.5, 6.5), // Index 0: Green Start
    BoardCoord(2.5, 6.5),
    BoardCoord(3.5, 6.5),
    BoardCoord(4.5, 6.5),
    BoardCoord(5.5, 6.5),

    // 5..10: Top Arm (left col, moving up)
    BoardCoord(6.5, 5.5),
    BoardCoord(6.5, 4.5),
    BoardCoord(6.5, 3.5),
    BoardCoord(6.5, 2.5), // Index 8: Safe Star 1
    BoardCoord(6.5, 1.5),
    BoardCoord(6.5, 0.5),

    // 11: Top Turn
    BoardCoord(7.5, 0.5),

    // 12..17: Top Arm (right col, moving down, directly next to Yellow Yard)
    BoardCoord(8.5, 0.5),
    BoardCoord(8.5, 1.5), // Index 13: Yellow Start
    BoardCoord(8.5, 2.5),
    BoardCoord(8.5, 3.5),
    BoardCoord(8.5, 4.5),
    BoardCoord(8.5, 5.5),

    // 18..23: Right Arm (top row, moving right)
    BoardCoord(9.5, 6.5),
    BoardCoord(10.5, 6.5),
    BoardCoord(11.5, 6.5),
    BoardCoord(12.5, 6.5), // Index 21: Safe Star 2
    BoardCoord(13.5, 6.5),
    BoardCoord(14.5, 6.5),

    // 24: Right Turn
    BoardCoord(14.5, 7.5),

    // 25..30: Right Arm (bottom row, moving left, directly above Blue Yard)
    BoardCoord(14.5, 8.5),
    BoardCoord(13.5, 8.5), // Index 26: Blue Start
    BoardCoord(12.5, 8.5),
    BoardCoord(11.5, 8.5),
    BoardCoord(10.5, 8.5),
    BoardCoord(9.5, 8.5),

    // 31..36: Bottom Arm (right col, moving down)
    BoardCoord(8.5, 9.5),
    BoardCoord(8.5, 10.5),
    BoardCoord(8.5, 11.5),
    BoardCoord(8.5, 12.5), // Index 34: Safe Star 3
    BoardCoord(8.5, 13.5),
    BoardCoord(8.5, 14.5),

    // 37: Bottom Turn
    BoardCoord(7.5, 14.5),

    // 38..43: Bottom Arm (left col, moving up, directly next to Red Yard)
    BoardCoord(6.5, 14.5),
    BoardCoord(6.5, 13.5), // Index 39: Red Start
    BoardCoord(6.5, 12.5),
    BoardCoord(6.5, 11.5),
    BoardCoord(6.5, 10.5),
    BoardCoord(6.5, 9.5),

    // 44..49: Left Arm (bottom row, moving left)
    BoardCoord(5.5, 8.5),
    BoardCoord(4.5, 8.5),
    BoardCoord(3.5, 8.5),
    BoardCoord(2.5, 8.5), // Index 47: Safe Star 4
    BoardCoord(1.5, 8.5),
    BoardCoord(0.5, 8.5),

    // 50: Left Turn
    BoardCoord(0.5, 7.5),

    // 51: Left Arm entry
    BoardCoord(0.5, 6.5),
  ];

  /// Starting track index on globalTrack for each color
  static const Map<PlayerColor, int> startIndices = {
    PlayerColor.green: 0, // (1.5, 6.5) - Left Arm, touches Green Yard
    PlayerColor.yellow: 13, // (8.5, 1.5) - Top Arm, touches Yellow Yard
    PlayerColor.blue: 26, // (13.5, 8.5) - Right Arm, touches Blue Yard
    PlayerColor.red: 39, // (6.5, 13.5) - Bottom Arm, touches Red Yard
  };

  /// The 8 safe star indices on the 52 globalTrack
  static const Set<int> safeTrackIndices = {0, 8, 13, 21, 26, 34, 39, 47};

  /// Colored home lanes (5 steps + 1 center goal)
  static const Map<PlayerColor, List<BoardCoord>> homeLanes = {
    PlayerColor.green: [
      BoardCoord(1.5, 7.5),
      BoardCoord(2.5, 7.5),
      BoardCoord(3.5, 7.5),
      BoardCoord(4.5, 7.5),
      BoardCoord(5.5, 7.5),
      BoardCoord(6.8, 7.5), // Green Goal inside Left Triangle
    ],
    PlayerColor.yellow: [
      BoardCoord(7.5, 1.5),
      BoardCoord(7.5, 2.5),
      BoardCoord(7.5, 3.5),
      BoardCoord(7.5, 4.5),
      BoardCoord(7.5, 5.5),
      BoardCoord(7.5, 6.8), // Yellow Goal inside Top Triangle
    ],
    PlayerColor.blue: [
      BoardCoord(13.5, 7.5),
      BoardCoord(12.5, 7.5),
      BoardCoord(11.5, 7.5),
      BoardCoord(10.5, 7.5),
      BoardCoord(9.5, 7.5),
      BoardCoord(8.2, 7.5), // Blue Goal inside Right Triangle
    ],
    PlayerColor.red: [
      BoardCoord(7.5, 13.5),
      BoardCoord(7.5, 12.5),
      BoardCoord(7.5, 11.5),
      BoardCoord(7.5, 10.5),
      BoardCoord(7.5, 9.5),
      BoardCoord(7.5, 8.2), // Red Goal inside Bottom Triangle
    ],
  };

  /// Yard base resting spots for the 4 pawns of each color.
  /// Exactly centered at (col + 2.0, row + 2.0) etc., matching the drawn circles.
  static const Map<PlayerColor, List<BoardCoord>> yardPads = {
    PlayerColor.green: [
      BoardCoord(2.0, 2.0),
      BoardCoord(4.0, 2.0),
      BoardCoord(2.0, 4.0),
      BoardCoord(4.0, 4.0),
    ],
    PlayerColor.yellow: [
      BoardCoord(11.0, 2.0),
      BoardCoord(13.0, 2.0),
      BoardCoord(11.0, 4.0),
      BoardCoord(13.0, 4.0),
    ],
    PlayerColor.blue: [
      BoardCoord(11.0, 11.0),
      BoardCoord(13.0, 11.0),
      BoardCoord(11.0, 13.0),
      BoardCoord(13.0, 13.0),
    ],
    PlayerColor.red: [
      BoardCoord(2.0, 11.0),
      BoardCoord(4.0, 11.0),
      BoardCoord(2.0, 13.0),
      BoardCoord(4.0, 13.0),
    ],
  };

  /// Returns the exact (x, y) center coordinate in grid units for a pawn
  static BoardCoord getCoordForPawn(Pawn pawn) {
    if (pawn.isInBase) {
      return yardPads[pawn.color]![pawn.id];
    }
    if (pawn.isOnTrack) {
      final startIdx = startIndices[pawn.color]!;
      final trackIdx = (startIdx + pawn.step) % 52;
      return globalTrack[trackIdx];
    }
    if (pawn.isInHomeLane || pawn.isHome) {
      final homeStep = pawn.step - 51; // 0..5
      return homeLanes[pawn.color]![homeStep];
    }
    return yardPads[pawn.color]![pawn.id];
  }

  /// Returns the global track index (0..51) if the pawn is on the outer track
  static int? getGlobalTrackIndex(PlayerColor color, int step) {
    if (step < 0 || step > 50) return null;
    final startIdx = startIndices[color]!;
    return (startIdx + step) % 52;
  }

  /// Checks if a pawn is on a safe cell where it cannot be killed
  static bool isSafeStep(PlayerColor color, int step) {
    if (step < 0) return true; // In base yard
    if (step > 50) return true; // In home lane or finished
    final trackIdx = getGlobalTrackIndex(color, step);
    if (trackIdx == null) return true;
    return safeTrackIndices.contains(trackIdx);
  }

  /// Returns a small fanning offset if multiple pawns share the same coordinate
  static Offset getFanningOffset(int indexInGroup, int totalInGroup, double cellSize) {
    if (totalInGroup <= 1) return Offset.zero;

    final radius = cellSize * 0.22;
    final angle = (2 * pi / totalInGroup) * indexInGroup;
    return Offset(cos(angle) * radius, sin(angle) * radius);
  }
}
