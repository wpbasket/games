import 'package:flutter/material.dart';
import '../../engine/ludo_models.dart';
import '../../engine/board_coordinates.dart';
import '../../engine/ludo_engine.dart';
import '../theme/ludo_colors.dart';
import '../widgets/board_painter.dart';
import '../widgets/animated_pawn.dart';
import '../widgets/dice_3d_widget.dart';
import '../widgets/player_card.dart';
import '../widgets/victory_dialog.dart';

class GameScreen extends StatefulWidget {
  final GameModeConfig config;
  final Map<PlayerColor, String>? customNames;
  final BotDifficulty difficulty;

  const GameScreen({
    super.key,
    required this.config,
    this.customNames,
    this.difficulty = BotDifficulty.medium,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late LudoEngine _engine;
  bool _victoryDialogShown = false;

  int get _boardQuarterTurns {
    final humanPlayers = _engine.players.where((p) => p.type == PlayerType.human).toList();
    // Dynamic bottom-left perspective ONLY for 1 Human vs Any Bots
    if (humanPlayers.length == 1 && _engine.players.length >= 2) {
      final humanColor = humanPlayers.first.color;
      switch (humanColor) {
        case PlayerColor.red:
          return 0; // Red is already Bottom-Left
        case PlayerColor.blue:
          return 1; // 90° clockwise turns Bottom-Right -> Bottom-Left
        case PlayerColor.yellow:
          return 2; // 180° clockwise turns Top-Right -> Bottom-Left
        case PlayerColor.green:
          return 3; // 270° clockwise turns Top-Left -> Bottom-Left
      }
    }
    // All other configurations (2v2, 4-Player Pass & Play, Spectator) maintain canonical unrotated board
    return 0;
  }

  PlayerColor _getCornerColor({required bool isTop, required bool isLeft}) {
    final turns = _boardQuarterTurns;
    if (turns == 0) {
      if (isTop && isLeft) return PlayerColor.green;
      if (isTop && !isLeft) return PlayerColor.yellow;
      if (!isTop && !isLeft) return PlayerColor.blue;
      return PlayerColor.red;
    }

    // Clockwise canonical order: TL (Green), TR (Yellow), BR (Blue), BL (Red)
    const canonicalOrder = [
      PlayerColor.green,
      PlayerColor.yellow,
      PlayerColor.blue,
      PlayerColor.red,
    ];

    int targetIdx;
    if (isTop && isLeft) {
      targetIdx = 0; // Top-Left
    } else if (isTop && !isLeft) {
      targetIdx = 1; // Top-Right
    } else if (!isTop && !isLeft) {
      targetIdx = 2; // Bottom-Right
    } else {
      targetIdx = 3; // Bottom-Left
    }

    final sourceIdx = (targetIdx - turns + 4) % 4;
    return canonicalOrder[sourceIdx];
  }

  @override
  void initState() {
    super.initState();
    _engine = LudoEngine();
    _engine.setDifficulty(widget.difficulty);
    _engine.initGame(widget.config, customNames: widget.customNames);
    _engine.addListener(_onEngineUpdate);
  }

  void _onEngineUpdate() {
    if (!mounted) return;
    setState(() {});

    if (_engine.isGameOver && !_victoryDialogShown) {
      _victoryDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => VictoryDialog(
            players: _engine.players,
            winners: _engine.winners,
            onPlayAgain: () {
              Navigator.pop(ctx);
              setState(() {
                _victoryDialogShown = false;
                _engine.initGame(widget.config, customNames: widget.customNames);
              });
            },
            onMainMenu: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineUpdate);
    _engine.dispose();
    super.dispose();
  }

  void _restartGame() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restart Match?'),
        content: const Text('Are you sure you want to restart this match from the beginning?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _victoryDialogShown = false;
                _engine.initGame(widget.config, customNames: widget.customNames);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatWidget(PlayerColor color, Player activePlayer) {
    final player = _engine.getPlayer(color);
    if (player != null) {
      return PlayerCardWidget(
        player: player,
        isCurrentTurn: activePlayer.color == color,
        isRolling: _engine.phase == TurnPhase.rollingDice && activePlayer.color == color,
      );
    }
    // Inactive seat indicator (fixed 52px height matching PlayerCardWidget)
    return SizedBox(
      height: 52,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.black38),
            ),
            const SizedBox(width: 6),
            Text(
              'Inactive',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePlayer = _engine.currentPlayer;
    final activeColor = LudoColors.primary(activePlayer.color);

    // Group active pawns by coordinate to calculate fanning
    final allPawns = _engine.players.expand((p) => p.pawns).toList();
    final Map<BoardCoord, List<Pawn>> pawnsAtCoord = {};
    for (final pawn in allPawns) {
      final coord = BoardCoordinates.getCoordForPawn(pawn);
      pawnsAtCoord.putIfAbsent(coord, () => []).add(pawn);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.config.title,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${_engine.players.length} Players Active • ${_engine.isSpectatorMode ? "AI Spectator" : "Offline"}',
              style: const TextStyle(color: Colors.black54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          // AI Speed Multiplier button (1x, 2x, 4x)
          PopupMenuButton<double>(
            tooltip: 'Game Speed',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                '${_engine.botSpeedMultiplier.toInt()}x',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
              ),
            ),
            onSelected: (speed) => _engine.setBotSpeedMultiplier(speed),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1.0, child: Text('1x Normal Speed')),
              const PopupMenuItem(value: 2.0, child: Text('2x Fast Speed')),
              const PopupMenuItem(value: 4.0, child: Text('4x Ultra Speed')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            tooltip: 'Restart Match',
            onPressed: _restartGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD: dynamically reflects screen Top-Left and Top-Right
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSeatWidget(_getCornerColor(isTop: true, isLeft: true), activePlayer),
                    _buildSeatWidget(_getCornerColor(isTop: true, isLeft: false), activePlayer),
                  ],
                ),
              ),
            ),

            // Center Board Area (Square AspectRatio)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: RepaintBoundary(
                          key: const ValueKey('full_board_boundary'),
                          child: RotatedBox(
                            quarterTurns: _boardQuarterTurns,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double boardSize = constraints.maxWidth;
                                final double cellSize = boardSize / 15.0;

                                return Stack(
                                  children: [
                                    // Layer 1: Static Board Painter wrapped in RepaintBoundary
                                    const RepaintBoundary(
                                      child: CustomPaint(
                                        size: Size.infinite,
                                        painter: LudoBoardPainter(),
                                      ),
                                    ),

                                    // Layer 2: Interactive Animated Pawns (Active players only!)
                                    ...allPawns.map((pawn) {
                                      final coord = BoardCoordinates.getCoordForPawn(pawn);
                                      final pawnsOnSquare = pawnsAtCoord[coord] ?? [pawn];
                                      final indexInGroup = pawnsOnSquare.indexOf(pawn);
                                      final totalInGroup = pawnsOnSquare.length;

                                      final isSelectable = _engine.phase == TurnPhase.waitingForMove &&
                                          activePlayer.type == PlayerType.human &&
                                          _engine.validPawns.any(
                                            (p) => p.id == pawn.id && p.color == pawn.color,
                                          );

                                      return AnimatedPawnWidget(
                                        key: ValueKey('${pawn.color.name}_${pawn.id}'),
                                        pawn: pawn,
                                        isSelectable: isSelectable,
                                        cellSize: cellSize,
                                        indexInGroup: indexInGroup,
                                        totalInGroup: totalInGroup,
                                        boardQuarterTurns: _boardQuarterTurns,
                                        onTap: (p) => _engine.movePawn(p),
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom HUD: dynamically reflects screen Bottom-Left (Human in 1vBot) and Bottom-Right
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSeatWidget(_getCornerColor(isTop: false, isLeft: true), activePlayer),
                    _buildSeatWidget(_getCornerColor(isTop: false, isLeft: false), activePlayer),
                  ],
                ),
              ),
            ),

            // Active Controls & Dice HUD Bar (Fixed height 84px to prevent any layout jumping)
            Container(
              height: 84,
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 3D Matrix4 Animated Dice (Shown active for both Human and Bot)
                  Dice3DWidget(
                    value: _engine.diceValue,
                    isRolling: _engine.phase == TurnPhase.rollingDice,
                    canRoll: _engine.phase == TurnPhase.waitingForRoll,
                    playerColor: activePlayer.color,
                    onRoll: () => _engine.rollDice(),
                  ),
                  const SizedBox(width: 16),

                  // Status Message & Turn Guidance (Single line ellipsis to maintain vertical stability)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _engine.statusMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: activeColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _getStatusSubtext(activePlayer),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Quick Action Button slot with invariant dimensions (76x40) to prevent width/height reflows
                  SizedBox(
                    width: 76,
                    height: 40,
                    child: _buildActionButton(activePlayer, activeColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(Player activePlayer, Color activeColor) {
    if (_engine.phase == TurnPhase.waitingForRoll) {
      return ElevatedButton(
        onPressed: () => _engine.rollDice(),
        style: ElevatedButton.styleFrom(
          backgroundColor: activeColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text(
          'ROLL',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    } else if (_engine.phase == TurnPhase.rollingDice) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: activeColor.withValues(alpha: 0.7),
          foregroundColor: Colors.white,
          disabledBackgroundColor: activeColor.withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text(
          'ROLL...',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    } else if (_engine.phase == TurnPhase.waitingForMove &&
        _engine.validPawns.length == 1) {
      return ElevatedButton(
        onPressed: activePlayer.type == PlayerType.human
            ? () => _engine.movePawn(_engine.validPawns.first)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: activeColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: activeColor,
          disabledForegroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text(
          'MOVE',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _getStatusSubtext(Player activePlayer) {
    if (activePlayer.type == PlayerType.bot) {
      if (_engine.isSpectatorMode) {
        return 'Bot is playing (${_engine.botSpeedMultiplier.toInt()}x speed)...';
      }
      switch (_engine.phase) {
        case TurnPhase.waitingForRoll:
          return 'Bot is rolling the die...';
        case TurnPhase.rollingDice:
          return 'Rolling the die...';
        case TurnPhase.waitingForMove:
          return 'AI is deciding its move...';
        case TurnPhase.movingPawn:
          return 'Moving pawn...';
        case TurnPhase.turnFinished:
          return 'Turn ending...';
        case TurnPhase.gameOver:
          return 'Match finished!';
      }
    }
    switch (_engine.phase) {
      case TurnPhase.waitingForRoll:
        return 'Tap the dice or ROLL button (1-6)';
      case TurnPhase.rollingDice:
        return 'Rolling the die...';
      case TurnPhase.waitingForMove:
        return 'Tap any highlighted pawn to move';
      case TurnPhase.movingPawn:
        return 'Moving pawn...';
      case TurnPhase.turnFinished:
        return 'Turn ending...';
      case TurnPhase.gameOver:
        return 'Match finished!';
    }
  }
}
