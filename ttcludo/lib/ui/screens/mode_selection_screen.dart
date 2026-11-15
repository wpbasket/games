import 'package:flutter/material.dart';
import '../../engine/ludo_models.dart';
import '../theme/ludo_colors.dart';
import 'game_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  void _startGame(
    GameModeConfig config, {
    Map<PlayerColor, String>? customNames,
    BotDifficulty difficulty = BotDifficulty.medium,
  }) {
    if (!config.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 active players are required to start a match.'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          config: config,
          customNames: customNames,
          difficulty: difficulty,
        ),
      ),
    );
  }

  void _showCustomSetupModal() {
    BotDifficulty selectedDifficulty = BotDifficulty.medium;

    final Map<PlayerColor, SeatState> seatStates = {
      PlayerColor.red: SeatState.human,
      PlayerColor.green: SeatState.bot,
      PlayerColor.yellow: SeatState.inactive,
      PlayerColor.blue: SeatState.inactive,
    };

    final Map<PlayerColor, TextEditingController> nameControllers = {
      PlayerColor.red: TextEditingController(text: 'You'),
      PlayerColor.green: TextEditingController(text: 'Green Bot'),
      PlayerColor.yellow: TextEditingController(text: 'Yellow Bot'),
      PlayerColor.blue: TextEditingController(text: 'Blue Bot'),
    };

    void syncDefaultNames() {
      final hCount = seatStates.values.where((s) => s.isHuman).length;
      for (final c in PlayerColor.values) {
        final state = seatStates[c] ?? SeatState.inactive;
        final cap = c.name[0].toUpperCase() + c.name.substring(1);
        final txt = nameControllers[c]!.text.trim();
        if (txt == 'You' || txt == '$cap Player' || txt == '$cap Bot' || txt.isEmpty) {
          if (state.isHuman) {
            nameControllers[c]!.text = hCount == 1 ? 'You' : '$cap Player';
          } else {
            nameControllers[c]!.text = '$cap Bot';
          }
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeCount = seatStates.values.where((s) => s.isActive).length;
            final humanCount = seatStates.values.where((s) => s.isHuman).length;
            final botCount = seatStates.values.where((s) => s.isBot).length;
            final isValid = activeCount >= 2;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Custom Match Setup',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isValid
                                ? const Color(0xFF1E88E5).withValues(alpha: 0.12)
                                : const Color(0xFFE53935).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$activeCount/4 Active',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isValid ? const Color(0xFF1E88E5) : const Color(0xFFE53935),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      humanCount == 0 && botCount >= 2
                          ? 'AI Spectator Mode: $botCount Bots will battle'
                          : 'Configure each seat: Off, Human, or Bot ($humanCount Humans, $botCount Bots)',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),

                    // 4 Seat cards
                    ...PlayerColor.values.map((color) {
                      final state = seatStates[color]!;
                      final pColor = LudoColors.primary(color);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: state.isActive ? Colors.white : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: state.isActive ? pColor.withValues(alpha: 0.5) : Colors.grey.shade300,
                            width: state.isActive ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: state.isActive ? pColor : Colors.grey.shade400,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  state.isHuman
                                      ? Icons.person
                                      : (state.isBot ? Icons.smart_toy : Icons.close),
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: nameControllers[color],
                                enabled: state.isActive,
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: '${color.name.toUpperCase()} Name',
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: state.isActive ? Colors.black87 : Colors.grey.shade500,
                                ),
                              ),
                            ),
                            // 3-way toggle: Off | Human | Bot
                            _buildChoiceChip(
                              label: 'Off',
                              selected: state == SeatState.inactive,
                              activeColor: Colors.grey.shade400,
                              onTap: () {
                                setModalState(() {
                                  seatStates[color] = SeatState.inactive;
                                  syncDefaultNames();
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                            _buildChoiceChip(
                              label: 'Human',
                              selected: state == SeatState.human,
                              activeColor: pColor,
                              onTap: () {
                                setModalState(() {
                                  seatStates[color] = SeatState.human;
                                  syncDefaultNames();
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                            _buildChoiceChip(
                              label: 'Bot',
                              selected: state == SeatState.bot,
                              activeColor: Colors.indigo,
                              onTap: () {
                                setModalState(() {
                                  seatStates[color] = SeatState.bot;
                                  syncDefaultNames();
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 12),
                    // Bot Difficulty Selector (if any bots are active)
                    if (botCount > 0) ...[
                      const Text('Bot AI Difficulty',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Row(
                        children: BotDifficulty.values.map((diff) {
                          final isSelected = selectedDifficulty == diff;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(diff.label, style: const TextStyle(fontSize: 11)),
                              selected: isSelected,
                              selectedColor: const Color(0xFF1E88E5).withValues(alpha: 0.2),
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() {
                                    selectedDifficulty = diff;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (!isValid) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE53935)),
                            SizedBox(width: 6),
                            Text(
                              'Please activate at least 2 seats to play a match.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFFE53935), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isValid
                            ? () {
                                Navigator.pop(ctx);
                                final config = GameModeConfig(
                                  modeType: GameModeType.custom,
                                  title: '$activeCount-Player Custom Match',
                                  subtitle: humanCount == 0
                                      ? '$botCount Bots (Spectator)'
                                      : '$humanCount Humans, $botCount Bots',
                                  icon: Icons.tune,
                                  seatStates: seatStates,
                                );
                                final customNames = {
                                  for (final c in PlayerColor.values)
                                    c: nameControllers[c]!.text.trim().isEmpty
                                        ? (seatStates[c]?.isHuman == true && humanCount == 1
                                            ? 'You'
                                            : '${c.name[0].toUpperCase()}${c.name.substring(1)} ${seatStates[c]?.isHuman == true ? "Player" : "Bot"}')
                                        : nameControllers[c]!.text.trim(),
                                };
                                _startGame(
                                  config,
                                  customNames: customNames,
                                  difficulty: selectedDifficulty,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: isValid ? 2 : 0,
                        ),
                        child: Text(
                          isValid ? 'Start $activeCount-Player Match' : 'Select at least 2 Players',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Color(0xFF1E88E5)),
            SizedBox(width: 8),
            Text('Ludo Rules & Edge Cases'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Player Counts Supported: 2, 3, or 4 players in any Human/Bot combination.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('• Roll a 6 to exit the base yard onto the starting track.',
                  style: TextStyle(fontSize: 13)),
              SizedBox(height: 6),
              Text('• Rolling a 6 earns an EXTRA ROLL (up to 2 consecutive). Rolling three 6s forfeits the turn.',
                  style: TextStyle(fontSize: 13)),
              SizedBox(height: 6),
              Text('• Safe Spots: 8 Stars on the board (4 start cells + 4 track stars). Pawns cannot be captured there.',
                  style: TextStyle(fontSize: 13)),
              SizedBox(height: 6),
              Text('• Captures: Landing on an opponent\'s pawn on an unsafe square sends it back to its yard and awards you an extra roll!',
                  style: TextStyle(fontSize: 13)),
              SizedBox(height: 6),
              Text('• Reaching Home: Move through your colored home lane to the center with an exact roll.',
                  style: TextStyle(fontSize: 13)),
              SizedBox(height: 6),
              Text('• Win Condition: In 2-player games, ends when 1 player finishes. In 3-player, ends when 2 finish. In 4-player, ends when 3 finish.',
                  style: TextStyle(fontSize: 13)),
              SizedBox(height: 6),
              Text('• AI Spectator Mode: Set all seats to Bots to watch AI simulation matches at 1x, 2x, or 4x speed.',
                  style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.black87),
            tooltip: 'Rules & Combinations',
            onPressed: _showRulesDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo / Graphic
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.casino_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'ttcLudo',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '2, 3, or 4 Players • All Human vs Bot Combinations Supported',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),

              // Custom Match Builder Button (Prominent)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: _showCustomSetupModal,
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  label: const Text(
                    'Custom Match Builder (All Combinations)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                ),
              ),

              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('QUICK PRESET MODES',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),

              // Mode Preset Cards
              ...GameModeConfig.presets.map((config) {
                return _buildModeCard(config);
              }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(GameModeConfig config) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _startGame(config),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      config.icon,
                      color: const Color(0xFF1E88E5),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              config.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${config.activePlayerCount}P',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        config.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
