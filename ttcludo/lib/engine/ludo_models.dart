import 'package:flutter/material.dart';

enum PlayerColor {
  green,
  yellow,
  blue,
  red,
}

enum PlayerType {
  human,
  bot,
}

enum BotDifficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case BotDifficulty.easy:
        return 'Easy (Casual)';
      case BotDifficulty.medium:
        return 'Medium (Balanced)';
      case BotDifficulty.hard:
        return 'Hard (Master)';
    }
  }
}

enum SeatState {
  inactive,
  human,
  bot;

  bool get isActive => this != SeatState.inactive;
  bool get isHuman => this == SeatState.human;
  bool get isBot => this == SeatState.bot;
}

enum TurnPhase {
  waitingForRoll,
  rollingDice,
  waitingForMove,
  movingPawn,
  turnFinished,
  gameOver,
}

class Pawn {
  final int id; // 0..3
  final PlayerColor color;
  int step; // -1 = Base Yard, 0..50 = Main Track, 51..55 = Home Lane, 56 = Home Goal

  Pawn({
    required this.id,
    required this.color,
    this.step = -1,
  });

  bool get isInBase => step == -1;
  bool get isOnTrack => step >= 0 && step <= 50;
  bool get isInHomeLane => step >= 51 && step <= 55;
  bool get isHome => step == 56;

  Pawn copyWith({int? step}) {
    return Pawn(
      id: id,
      color: color,
      step: step ?? this.step,
    );
  }

  @override
  String toString() => 'Pawn($color #$id, step: $step)';
}

class Player {
  final PlayerColor color;
  PlayerType type;
  String name;
  final List<Pawn> pawns;
  int? rank; // 1st, 2nd, 3rd, 4th place when finished

  Player({
    required this.color,
    required this.type,
    required this.name,
    List<Pawn>? pawns,
    this.rank,
  }) : pawns = pawns ?? List.generate(4, (i) => Pawn(id: i, color: color));

  bool get hasFinished => pawns.every((p) => p.isHome);
  int get finishedPawnsCount => pawns.where((p) => p.isHome).length;
  int get basePawnsCount => pawns.where((p) => p.isInBase).length;
  int get activePawnsCount => pawns.where((p) => !p.isInBase && !p.isHome).length;

  Player copyWith({
    PlayerType? type,
    String? name,
    List<Pawn>? pawns,
    int? rank,
  }) {
    return Player(
      color: color,
      type: type ?? this.type,
      name: name ?? this.name,
      pawns: pawns ?? this.pawns.map((p) => p.copyWith()).toList(),
      rank: rank ?? this.rank,
    );
  }
}

enum GameModeType {
  oneVsThreeBots,
  oneVsOneBot,
  oneVsTwoBots,
  twoVsTwoBots,
  twoHumansPassPlay,
  threeHumansPassPlay,
  fourHumansPassPlay,
  spectatorBots,
  custom,
}

class GameModeConfig {
  final GameModeType modeType;
  final String title;
  final String subtitle;
  final IconData icon;
  final Map<PlayerColor, SeatState> seatStates;

  const GameModeConfig({
    required this.modeType,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.seatStates,
  });

  int get activePlayerCount => seatStates.values.where((s) => s.isActive).length;
  int get humanCount => seatStates.values.where((s) => s.isHuman).length;
  int get botCount => seatStates.values.where((s) => s.isBot).length;
  bool get isValid => activePlayerCount >= 2;
  bool get isSpectatorMode => humanCount == 0 && botCount >= 2;

  String get summaryText {
    if (!isValid) return 'Invalid: Minimum 2 players required';
    if (humanCount == 0) return '$activePlayerCount Bots (Spectator Mode)';
    if (botCount == 0) return '$humanCount Players (Pass & Play)';
    return '$humanCount Human${humanCount > 1 ? "s" : ""} vs $botCount Bot${botCount > 1 ? "s" : ""}';
  }

  static const List<GameModeConfig> presets = [
    // 4 Players: 1 Human vs 3 Bots
    GameModeConfig(
      modeType: GameModeType.oneVsThreeBots,
      title: '1 Player vs 3 Bots',
      subtitle: 'Solo match as Red against 3 computer opponents',
      icon: Icons.smart_toy_outlined,
      seatStates: {
        PlayerColor.red: SeatState.human,
        PlayerColor.green: SeatState.bot,
        PlayerColor.yellow: SeatState.bot,
        PlayerColor.blue: SeatState.bot,
      },
    ),
    // 2 Players: 1 Human vs 1 Bot (Opposite corners: Red vs Yellow)
    GameModeConfig(
      modeType: GameModeType.oneVsOneBot,
      title: '1 Player vs 1 Bot (Duel)',
      subtitle: '2-Player fast duel: Red Human vs Yellow Bot',
      icon: Icons.sports_kabaddi_outlined,
      seatStates: {
        PlayerColor.red: SeatState.human,
        PlayerColor.green: SeatState.inactive,
        PlayerColor.yellow: SeatState.bot,
        PlayerColor.blue: SeatState.inactive,
      },
    ),
    // 4 Players: 2 Humans vs 2 Bots
    GameModeConfig(
      modeType: GameModeType.twoVsTwoBots,
      title: '2 Players vs 2 Bots',
      subtitle: '2 Human players and 2 Bots on opposite sides',
      icon: Icons.people_outline,
      seatStates: {
        PlayerColor.red: SeatState.human,
        PlayerColor.green: SeatState.bot,
        PlayerColor.yellow: SeatState.human,
        PlayerColor.blue: SeatState.bot,
      },
    ),
    // 3 Players: 1 Human vs 2 Bots
    GameModeConfig(
      modeType: GameModeType.oneVsTwoBots,
      title: '1 Player vs 2 Bots (Trio)',
      subtitle: '3-Player match: Red Human vs Green & Yellow Bots',
      icon: Icons.group_work_outlined,
      seatStates: {
        PlayerColor.red: SeatState.human,
        PlayerColor.green: SeatState.bot,
        PlayerColor.yellow: SeatState.bot,
        PlayerColor.blue: SeatState.inactive,
      },
    ),
    // 4 Players: 4 Humans Pass & Play
    GameModeConfig(
      modeType: GameModeType.fourHumansPassPlay,
      title: '4 Players (Pass & Play)',
      subtitle: 'Classic 4-player local multiplayer with friends',
      icon: Icons.diversity_3_outlined,
      seatStates: {
        PlayerColor.red: SeatState.human,
        PlayerColor.green: SeatState.human,
        PlayerColor.yellow: SeatState.human,
        PlayerColor.blue: SeatState.human,
      },
    ),
    // 2 Players: 2 Humans Pass & Play
    GameModeConfig(
      modeType: GameModeType.twoHumansPassPlay,
      title: '2 Players (Pass & Play)',
      subtitle: 'Head-to-head 2 friends on one device (Red & Yellow)',
      icon: Icons.person_add_outlined,
      seatStates: {
        PlayerColor.red: SeatState.human,
        PlayerColor.green: SeatState.inactive,
        PlayerColor.yellow: SeatState.human,
        PlayerColor.blue: SeatState.inactive,
      },
    ),
    // 4 Bots: AI Battle Spectator Mode
    GameModeConfig(
      modeType: GameModeType.spectatorBots,
      title: 'AI Battle (Spectator Demo)',
      subtitle: 'Watch 4 autonomous AI bots battle with speed controls',
      icon: Icons.remove_red_eye_outlined,
      seatStates: {
        PlayerColor.red: SeatState.bot,
        PlayerColor.green: SeatState.bot,
        PlayerColor.yellow: SeatState.bot,
        PlayerColor.blue: SeatState.bot,
      },
    ),
  ];
}
