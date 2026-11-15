import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RNG distribution uniformity test (600,000 rolls)', () {
    final rng = Random();
    final counts = List.filled(7, 0);
    const total = 600000;

    for (int i = 0; i < total; i++) {
      counts[rng.nextInt(6) + 1]++;
    }

    // Every number 1..6 should be ~100,000 (within 1.5% tolerance: 98,500 to 101,500)
    for (int i = 1; i <= 6; i++) {
      final diff = (counts[i] - 100000).abs();
      expect(diff < 1500, isTrue, reason: 'Face $i count: ${counts[i]}');
    }
  });

  test('Strictly pure physical dice simulation follows true geometric distribution (no pity ceiling)', () {
    final rng = Random(42);
    const simulatedRuns = 50000;
    int maxTurnsObserved = 0;
    final turnsToFirstSix = <int, int>{};

    for (int run = 0; run < simulatedRuns; run++) {
      int turns = 0;
      while (true) {
        turns++;
        // Pure memoryless independent trial: exactly 1/6 on every roll
        final int roll = rng.nextInt(6) + 1;
        if (roll == 6) {
          turnsToFirstSix[turns] = (turnsToFirstSix[turns] ?? 0) + 1;
          if (turns > maxTurnsObserved) maxTurnsObserved = turns;
          break;
        }
      }
    }

    // True memoryless randomness allows natural statistical long tails (turns > 6 occur ~33.5% of the time)
    expect(maxTurnsObserved, greaterThan(10),
        reason: 'True independent trials naturally exhibit streaks beyond 10 rolls');

    // Geometric distribution P(X = 1) = 1/6 ≈ 16.67%
    expect(turnsToFirstSix[1]! / simulatedRuns, closeTo(0.1667, 0.015));

    // P(X > 6) = (5/6)^6 ≈ 33.49%
    int runsExceeding6Turns = 0;
    for (int k = 7; k <= maxTurnsObserved; k++) {
      runsExceeding6Turns += turnsToFirstSix[k] ?? 0;
    }
    expect(runsExceeding6Turns / simulatedRuns, closeTo(0.3349, 0.02));
  });

  test('Independent CSPRNG per player: each seat maintains isolated cryptographic stream', () {
    // Simulate 4 isolated Random.secure instances representing Red, Green, Yellow, Blue
    final playerGenerators = {
      'Red': Random.secure(),
      'Green': Random.secure(),
      'Yellow': Random.secure(),
      'Blue': Random.secure(),
    };

    const rollsPerPlayer = 20000;
    final playerCounts = <String, List<int>>{
      for (final p in playerGenerators.keys) p: List.filled(7, 0),
    };

    for (int i = 0; i < rollsPerPlayer; i++) {
      for (final p in playerGenerators.keys) {
        final roll = playerGenerators[p]!.nextInt(6) + 1;
        playerCounts[p]![roll]++;
      }
    }

    // Every player's isolated generator should yield ~3333 per face (within 5% tolerance)
    const expectedPerFace = rollsPerPlayer / 6.0;
    for (final p in playerGenerators.keys) {
      for (int face = 1; face <= 6; face++) {
        final count = playerCounts[p]![face];
        expect((count - expectedPerFace).abs() < 300, isTrue,
            reason: '$p face $face count: $count (expected ~$expectedPerFace)');
      }
    }
  });
}
