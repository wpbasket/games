import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../ui/theme/app_feedback.dart';
import 'ludo_models.dart';
import 'board_coordinates.dart';
import 'bot_ai.dart';

class MoveEvent {
  final Pawn pawn;
  final int fromStep;
  final int toStep;
  final bool capturedEnemy;
  final bool reachedHome;

  const MoveEvent({
    required this.pawn,
    required this.fromStep,
    required this.toStep,
    this.capturedEnemy = false,
    this.reachedHome = false,
  });
}

class LudoEngine extends ChangeNotifier {
  // System RNG reserved strictly for non-player actions (e.g. initial starting player selection)
  final Random _systemRng = Random.secure();

  // Strictly independent, isolated cryptographic random number generators per player.
  // Each player draws exclusively from their own separate CSPRNG instance.
  // Zero shared PRNG state, zero shared seed, zero shared hash between players.
  final Map<PlayerColor, Random> _playerGenerators = {
    for (final c in PlayerColor.values) c: Random.secure(),
  };

  List<Player> _players = [];
  int _currentPlayerIndex = 0;
  TurnPhase _phase = TurnPhase.waitingForRoll;
  int _diceValue = 1;
  int _consecutiveSixes = 0;
  List<Pawn> _validPawns = [];
  String _statusMessage = 'Welcome to ttcLudo!';
  bool _isDisposed = false;
  double _botSpeedMultiplier = 1.0;
  BotDifficulty _difficulty = BotDifficulty.medium;

  // Dice roll audit tracking
  final Map<PlayerColor, List<int>> _rollHistory = {
    for (final c in PlayerColor.values) c: [],
  };

  final List<PlayerColor> _winners = []; // 1st, 2nd, 3rd, 4th place
  Timer? _botTimer;

  // Callbacks for UI animations
  Function(MoveEvent event)? onPawnMoved;
  VoidCallback? onDiceRollStart;
  VoidCallback? onCapture;
  VoidCallback? onHomeReached;

  LudoEngine({bool randomizeStartingPlayer = false}) {
    initGame(
      GameModeConfig.presets.first,
      randomizeStartingPlayer: randomizeStartingPlayer,
    );
  }

  // Getters
  List<Player> get players => _players;
  Player get currentPlayer => _players[_currentPlayerIndex];
  TurnPhase get phase => _phase;
  int get diceValue => _diceValue;
  int get consecutiveSixes => _consecutiveSixes;
  List<Pawn> get validPawns => _validPawns;
  String get statusMessage => _statusMessage;
  List<PlayerColor> get winners => _winners;
  bool get isGameOver => _phase == TurnPhase.gameOver;
  double get botSpeedMultiplier => _botSpeedMultiplier;
  bool get isSpectatorMode => _players.isNotEmpty && _players.every((p) => p.type == PlayerType.bot);
  BotDifficulty get difficulty => _difficulty;
  Map<PlayerColor, List<int>> get rollHistory => _rollHistory;

  int getRollCount(PlayerColor color) => _rollHistory[color]?.length ?? 0;
  int getSixCount(PlayerColor color) => _rollHistory[color]?.where((r) => r == 6).length ?? 0;
  double getSixPercentage(PlayerColor color) {
    final total = getRollCount(color);
    if (total == 0) return 0.0;
    return (getSixCount(color) / total) * 100.0;
  }

  Map<int, int> getRollFaceDistribution(PlayerColor color) {
    final history = _rollHistory[color] ?? [];
    final map = {for (int i = 1; i <= 6; i++) i: 0};
    for (final roll in history) {
      map[roll] = (map[roll] ?? 0) + 1;
    }
    return map;
  }

  void setDifficulty(BotDifficulty diff) {
    _difficulty = diff;
    notifyListeners();
  }

  Player? getPlayer(PlayerColor color) {
    for (final p in _players) {
      if (p.color == color) return p;
    }
    return null;
  }

  bool isSeatActive(PlayerColor color) => getPlayer(color) != null;

  void setBotSpeedMultiplier(double multiplier) {
    _botSpeedMultiplier = multiplier;
    notifyListeners();
  }

  int _scaledDelay(int baseMs) {
    final ms = (baseMs / _botSpeedMultiplier).round();
    return ms < 50 ? 50 : ms;
  }

  bool get isSoloHumanMatch =>
      _players.where((p) => p.type == PlayerType.human).length == 1;

  bool _isYou(Player p) => isSoloHumanMatch && p.type == PlayerType.human;

  static String _defaultPlayerName(PlayerColor color, SeatState state, int humanCount) {
    final cap = color.name[0].toUpperCase() + color.name.substring(1);
    if (state.isHuman) {
      return humanCount == 1 ? 'You' : '$cap Player';
    } else {
      return '$cap Bot';
    }
  }

  void initGame(
    GameModeConfig config, {
    Map<PlayerColor, String>? customNames,
    bool randomizeStartingPlayer = true,
    int? startingPlayerIndex,
  }) {
    _botTimer?.cancel();
    _winners.clear();
    _consecutiveSixes = 0;
    _diceValue = 1;

    for (final c in PlayerColor.values) {
      // Re-seed with fresh, isolated operating system entropy for every player
      _playerGenerators[c] = Random.secure();
      _rollHistory[c]?.clear();
    }

    // Clockwise order around the board: Red -> Green -> Yellow -> Blue
    const order = [
      PlayerColor.red,
      PlayerColor.green,
      PlayerColor.yellow,
      PlayerColor.blue,
    ];

    final int humanCount = config.seatStates.values.where((s) => s.isHuman).length;

    _players = [];
    for (final color in order) {
      final seatState = config.seatStates[color] ?? SeatState.inactive;
      if (seatState.isActive) {
        _players.add(
          Player(
            color: color,
            type: seatState.isHuman ? PlayerType.human : PlayerType.bot,
            name: customNames?[color] ?? _defaultPlayerName(color, seatState, humanCount),
          ),
        );
      }
    }

    if (_players.length < 2) {
      throw ArgumentError('At least 2 active players are required to start a match.');
    }

    // Determine starting player:
    // When randomizeStartingPlayer is true, uses cryptographic RNG to pick who rolls first,
    // completely eliminating first-mover initiative bias.
    if (startingPlayerIndex != null) {
      _currentPlayerIndex = startingPlayerIndex % _players.length;
    } else if (randomizeStartingPlayer) {
      _currentPlayerIndex = _systemRng.nextInt(_players.length);
    } else {
      _currentPlayerIndex = 0;
    }

    _phase = TurnPhase.waitingForRoll;
    _validPawns = [];
    _statusMessage = _isYou(currentPlayer)
        ? 'Your turn to roll the dice!'
        : '${currentPlayer.name}\'s turn to roll the dice!';

    notifyListeners();

    // If initial player is bot, trigger bot turn
    _checkBotTurn();
  }

  /// Roll the dice
  Future<void> rollDice() async {
    if (_phase != TurnPhase.waitingForRoll) return;

    _botTimer?.cancel();
    _phase = TurnPhase.rollingDice;
    notifyListeners();
    onDiceRollStart?.call();
    AppFeedback.diceRoll();

    // Simulated rolling physics delay
    await Future.delayed(Duration(milliseconds: _scaledDelay(500)));
    if (_isDisposed) return;

    // Strictly pure, isolated cryptographic roll drawn exclusively from current player's private generator
    final rng = _playerGenerators[currentPlayer.color] ?? Random.secure();
    _diceValue = rng.nextInt(6) + 1;
    _rollHistory[currentPlayer.color]?.add(_diceValue);

    if (_diceValue == 6) {
      _consecutiveSixes++;
      AppFeedback.six();
    } else {
      _consecutiveSixes = 0;
    }

    // 3 consecutive 6s rule -> Turn forfeit
    if (_consecutiveSixes >= 3) {
      _statusMessage = _isYou(currentPlayer)
          ? 'You rolled three 6s in a row! Turn forfeited.'
          : '${currentPlayer.name} rolled three 6s in a row! Turn forfeited.';
      _consecutiveSixes = 0;
      _phase = TurnPhase.turnFinished;
      notifyListeners();

      await Future.delayed(Duration(milliseconds: _scaledDelay(850)));
      if (_isDisposed) return;
      _advanceToNextPlayer();
      return;
    }

    _calculateValidMoves();

    if (_validPawns.isEmpty) {
      _statusMessage = _isYou(currentPlayer)
          ? 'You rolled a $_diceValue. No moves possible!'
          : '${currentPlayer.name} rolled a $_diceValue. No moves possible!';
      _phase = TurnPhase.turnFinished;
      notifyListeners();

      await Future.delayed(Duration(milliseconds: _scaledDelay(750)));
      if (_isDisposed) return;
      _advanceToNextPlayer();
    } else {
      _phase = TurnPhase.waitingForMove;
      _statusMessage = _isYou(currentPlayer)
          ? 'You rolled a $_diceValue! Select a pawn to move.'
          : '${currentPlayer.name} rolled a $_diceValue! Select a pawn to move.';
      notifyListeners();

      // If Bot, automatically pick the best move after thinking delay
      if (currentPlayer.type == PlayerType.bot) {
        _botTimer?.cancel();
        _botTimer = Timer(Duration(milliseconds: _scaledDelay(650)), () {
          if (_isDisposed || _phase != TurnPhase.waitingForMove) return;
          final bestPawn = BotAI.pickBestPawn(
            botPlayer: currentPlayer,
            validPawns: _validPawns,
            diceValue: _diceValue,
            allPlayers: _players,
            difficulty: _difficulty,
          );
          movePawn(bestPawn);
        });
      }
    }
  }

  void _calculateValidMoves() {
    _validPawns = [];
    final currentPawns = currentPlayer.pawns;

    for (final pawn in currentPawns) {
      if (pawn.isHome) continue;

      if (pawn.isInBase) {
        // Can only exit base if a 6 was rolled
        if (_diceValue == 6) {
          _validPawns.add(pawn);
        }
      } else {
        // On track or in home lane: must not overshoot goal (step 56)
        if (pawn.step + _diceValue <= 56) {
          _validPawns.add(pawn);
        }
      }
    }
  }

  /// Move a selected pawn
  Future<void> movePawn(Pawn pawn) async {
    if (_phase != TurnPhase.waitingForMove) return;
    if (!_validPawns.any((p) => p.id == pawn.id && p.color == pawn.color)) return;

    _phase = TurnPhase.movingPawn;
    _validPawns = [];
    notifyListeners();

    try {
      HapticFeedback.selectionClick();
    } catch (_) {}

    final fromStep = pawn.step;
    final int toStep = pawn.isInBase ? 0 : pawn.step + _diceValue;

    // Authentic Ludo sound: pawn unlocking from yard vs stepping on track
    if (fromStep == -1) {
      AppFeedback.pawnEntry();
    } else {
      AppFeedback.pawnStep();
    }

    // Update pawn step
    pawn.step = toStep;

    bool capturedEnemy = false;
    bool reachedHome = false;
    String bonusReason = '';

    // Check Capture on track (steps 0..50)
    if (toStep <= 50) {
      final isSafeCell = BoardCoordinates.isSafeStep(pawn.color, toStep);
      final landingTrackIdx = BoardCoordinates.getGlobalTrackIndex(pawn.color, toStep);

      if (!isSafeCell && landingTrackIdx != null) {
        for (final opp in _players) {
          if (opp.color == pawn.color) continue;
          for (final oppPawn in opp.pawns) {
            if (oppPawn.isOnTrack) {
              final oppTrackIdx = BoardCoordinates.getGlobalTrackIndex(opp.color, oppPawn.step);
              if (oppTrackIdx == landingTrackIdx) {
                // Opponent pawn captured!
                oppPawn.step = -1; // Send back to base yard
                capturedEnemy = true;
                bonusReason = 'Captured ${opp.name}\'s pawn! Earns extra roll.';
                AppFeedback.capture();
                onCapture?.call();
              }
            }
          }
        }
      }
    }

    // Check Home Goal (step 56)
    if (toStep == 56) {
      reachedHome = true;
      bonusReason = 'Reached home! Earns extra roll.';
      AppFeedback.homeReached();
      onHomeReached?.call();

      // Check if this player has finished all 4 pawns
      if (currentPlayer.hasFinished && !_winners.contains(currentPlayer.color)) {
        _winners.add(currentPlayer.color);
        currentPlayer.rank = _winners.length;
      }
    }

    // Trigger movement animation callback
    onPawnMoved?.call(MoveEvent(
      pawn: pawn,
      fromStep: fromStep,
      toStep: toStep,
      capturedEnemy: capturedEnemy,
      reachedHome: reachedHome,
    ));

    notifyListeners();

    // Check Game Over condition (when remaining unfinished players <= 1)
    if (_checkGameOver()) {
      _phase = TurnPhase.gameOver;
      AppFeedback.homeReached();
      final winner = _players.firstWhere((p) => p.rank == 1, orElse: () => _players.first);
      _statusMessage = _isYou(winner)
          ? 'Game Over! You won!'
          : 'Game Over! ${winner.name} won!';
      notifyListeners();
      return;
    }

    // Delay for movement animation
    await Future.delayed(Duration(milliseconds: _scaledDelay(380)));
    if (_isDisposed) return;

    // Check if player gets a bonus turn:
    // 1. Rolled a 6
    // 2. Captured an enemy pawn
    // 3. Reached home goal
    final bool getsExtraTurn = (_diceValue == 6) || capturedEnemy || reachedHome;

    if (getsExtraTurn && !currentPlayer.hasFinished) {
      if (bonusReason.isEmpty) {
        bonusReason = 'Rolled a 6! Roll again.';
      }
      _statusMessage = _isYou(currentPlayer)
          ? 'You: $bonusReason'
          : '${currentPlayer.name}: $bonusReason';
      _phase = TurnPhase.waitingForRoll;
      notifyListeners();
      _checkBotTurn();
    } else {
      _consecutiveSixes = 0;
      _advanceToNextPlayer();
    }
  }

  void _advanceToNextPlayer() {
    int attempts = 0;
    do {
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
      attempts++;
    } while (currentPlayer.hasFinished && attempts < _players.length);

    if (attempts >= _players.length || _checkGameOver()) {
      // Game over
      _phase = TurnPhase.gameOver;
      _statusMessage = 'Game Over!';
      notifyListeners();
      return;
    }

    _consecutiveSixes = 0;
    _phase = TurnPhase.waitingForRoll;
    _validPawns = [];
    _statusMessage = _isYou(currentPlayer)
        ? 'Your turn to roll!'
        : '${currentPlayer.name}\'s turn to roll!';
    notifyListeners();

    _checkBotTurn();
  }

  void _checkBotTurn() {
    if (_isDisposed || _phase == TurnPhase.gameOver) return;

    if (currentPlayer.type == PlayerType.bot && _phase == TurnPhase.waitingForRoll) {
      _botTimer?.cancel();
      _botTimer = Timer(Duration(milliseconds: _scaledDelay(600)), () {
        if (!_isDisposed && _phase == TurnPhase.waitingForRoll) {
          rollDice();
        }
      });
    }
  }

  bool _checkGameOver() {
    final activeRunners = _players.where((p) => !p.hasFinished).toList();
    // In any game (2, 3, or 4 players), the game ends when at most 1 unfinished player remains
    return activeRunners.length <= 1;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _botTimer?.cancel();
    super.dispose();
  }
}
