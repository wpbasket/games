import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

/// Centralized, 100% cross-platform audio and tactile feedback controller.
///
/// Uses [just_audio] (ExoPlayer on Android, AVPlayer on iOS/macOS, HTML5 Audio on Web).
/// Sets [handleInterruptions: false] and [androidApplyAudioAttributes: false] so audio
/// never competes for system focus, never cuts off other apps or background media,
/// and plays cleanly across all platforms with 0ms pre-warmed latency.
class AppFeedback {
  static AudioPlayer? _dicePlayer;
  static AudioPlayer? _sixPlayer;
  static final List<AudioPlayer> _stepPlayers = [];
  static int _stepIndex = 0;
  static AudioPlayer? _entryPlayer;
  static AudioPlayer? _capturePlayer;
  static AudioPlayer? _homePlayer;

  static bool _initialized = false;

  static Future<AudioPlayer?> _createPlayer(String assetPath) async {
    try {
      final player = AudioPlayer(
        handleInterruptions: false,
        androidApplyAudioAttributes: false,
        handleAudioSessionActivation: false,
      );
      await player.setAsset(assetPath);
      await player.setVolume(1.0);
      return player;
    } catch (e) {
      debugPrint('[AppFeedback] Error loading $assetPath: $e');
      return null;
    }
  }

  /// Initialize and pre-warm audio players into memory
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _dicePlayer = await _createPlayer('assets/audio/dice_roll.wav');
      _sixPlayer = await _createPlayer('assets/audio/six.wav');

      // 4 rotating players for rapid successive pawn steps
      for (int i = 0; i < 4; i++) {
        final sp = await _createPlayer('assets/audio/pawn_step.wav');
        if (sp != null) _stepPlayers.add(sp);
      }

      _entryPlayer = await _createPlayer('assets/audio/pawn_entry.wav');
      _capturePlayer = await _createPlayer('assets/audio/capture.wav');
      _homePlayer = await _createPlayer('assets/audio/home_reached.wav');
      debugPrint('[AppFeedback] Audio initialized successfully.');
    } catch (e) {
      debugPrint('[AppFeedback] Init error: $e');
    }
  }

  /// Robust, repeated playback mechanism:
  /// Always resets player to zero before playing so every subsequent turn plays cleanly.
  static void _play(AudioPlayer? player) {
    if (!_initialized) {
      init();
    }
    if (player == null) return;
    try {
      player.stop().then((_) {
        return player.seek(Duration.zero);
      }).then((_) {
        player.play();
      }).catchError((e) {
        player.seek(Duration.zero).then((_) => player.play());
      });
    } catch (_) {}
  }

  /// 1. Subtle tactile click for app UI (cards, buttons, rules, dialogs) - haptic only, silent
  static void click() {
    HapticFeedback.lightImpact();
  }

  /// 2. Soft selection haptic for chip toggles and UI transitions - silent
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// 3. Realistic wooden dice tumbling & rattle sound (for both Human & Bot)
  static void diceRoll() {
    HapticFeedback.mediumImpact();
    _play(_dicePlayer);
  }

  /// 4. Ascending celebratory chime when rolling a 6 or bonus roll
  static void six() {
    HapticFeedback.heavyImpact();
    _play(_sixPlayer);
  }

  /// 5. Authentic wooden pawn placement 'tok' sound on track step
  static void pawnStep() {
    HapticFeedback.lightImpact();
    if (_stepPlayers.isNotEmpty) {
      final player = _stepPlayers[_stepIndex];
      _stepIndex = (_stepIndex + 1) % _stepPlayers.length;
      _play(player);
    }
  }

  /// 6. Bright unlock bell chime when a pawn exits base yard to the start star
  static void pawnEntry() {
    HapticFeedback.mediumImpact();
    _play(_entryPlayer);
  }

  /// 7. Punchy, dramatic strike pop when capturing an opponent piece
  static void capture() {
    HapticFeedback.heavyImpact();
    _play(_capturePlayer);
  }

  /// 8. Triumphant harmonic bell chime when reaching home / victory
  static void homeReached() {
    HapticFeedback.heavyImpact();
    _play(_homePlayer);
  }

  /// Alias for backward compatibility
  static void heavy() => six();
}
