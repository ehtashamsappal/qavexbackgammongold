/// Audio: original synthesized BGM + SFX played via flame_audio.
/// All clips are generated offline (see tools/make_audio.py) — no downloads.
///
/// BGM (2): bgm_theme.wav, bgm_calm.wav
/// SFX (12): dice_roll, checker_move, hit, bearoff, double, win, button,
///           cube_decline, gammon, tick, turn, lose
library;

import 'package:flame_audio/flame_audio.dart';
import '../state/save_data.dart';

class AudioManager {
  static final AudioManager instance = AudioManager._();
  AudioManager._();

  bool _bgmStarted = false;
  bool _ready = false;
  bool _calmBgm = false;

  Future<void> init() async {
    try {
      await FlameAudio.bgm.initialize();
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> startBgm() async {
    if (!_ready || _bgmStarted) return;
    _bgmStarted = true;
    try {
      await FlameAudio.bgm.play('bgm_theme.wav',
          volume: SaveData.instance.musicVolume * 0.6);
    } catch (_) {}
  }

  /// Switch to the alternate calm background track (e.g. practice mode).
  Future<void> useCalmBgm(bool calm) async {
    if (!_ready || calm == _calmBgm) return;
    _calmBgm = calm;
    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play(calm ? 'bgm_calm.wav' : 'bgm_theme.wav',
          volume: SaveData.instance.musicVolume * 0.6);
    } catch (_) {}
  }

  Future<void> setMusicVolume(double v) async {
    if (!_ready) return;
    try {
      FlameAudio.bgm.audioPlayer.setVolume(v * 0.6);
    } catch (_) {}
  }

  Future<void> play(String file) async {
    if (!_ready) return;
    try {
      await FlameAudio.play(file,
          volume: SaveData.instance.sfxVolume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  Future<void> dice() => play('dice_roll.wav');
  Future<void> move() => play('checker_move.wav');
  Future<void> hit() => play('hit.wav');
  Future<void> win() => play('win.wav');
  Future<void> lose() => play('lose.wav');
  Future<void> button() => play('button.wav');
  Future<void> cube() => play('double.wav');
  Future<void> cubeDecline() => play('cube_decline.wav');
  Future<void> bearOff() => play('bearoff.wav');
  Future<void> gammon() => play('gammon.wav');
  Future<void> tick() => play('tick.wav');
  Future<void> turn() => play('turn.wav');
}
