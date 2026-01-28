import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AudioType {
  // BGM
  bgmLobby,
  bgmChase, // Fast paced game music
  // SFX
  click,
  itemGet,
  arrestSuccess,
  arrestFail,
  siren,
  abilityActive,
}

class AudioService {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  // Multiple SFX players for concurrency?
  // AudioCache is now integrated into AudioPlayer in v7.x/v8.x of audioplayers?
  // Actually, to play SFX without cutting off previous, we create new players or use 'AudioPlayer().play' each time.
  // For simplicity, we'll use a pool or just new instances for SFX.

  bool _isMuted = false;
  double _bgmVolume = 0.5;
  double _sfxVolume = 1.0;

  AudioService() {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> init() async {
    // Optional: Preload critical sounds
    // await AudioPlayer().setSource(AssetSource('audio/bgm_lobby.mp3'));
    debugPrint('[AUDIO] Service Initialized');
  }

  void setMute(bool mute) {
    _isMuted = mute;
    if (mute) {
      _bgmPlayer.setVolume(0);
    } else {
      _bgmPlayer.setVolume(_bgmVolume);
    }
  }

  Future<void> playBgm(AudioType type) async {
    if (_isMuted) return;
    String path = _getPath(type);
    if (path.isEmpty) return;

    try {
      await _bgmPlayer.stop(); // Stop current
      await _bgmPlayer.setSource(AssetSource(path));
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.resume();
      debugPrint('[AUDIO] Playing BGM: $path');
    } catch (e) {
      debugPrint('[AUDIO] BGM Error ($path): $e');
    }
  }

  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
  }

  Future<void> playSfx(AudioType type) async {
    if (_isMuted) return;
    String path = _getPath(type);
    if (path.isEmpty) return;

    try {
      // Fire and forget SFX player
      final player = AudioPlayer();
      player.setVolume(_sfxVolume);
      await player.play(AssetSource(path));
      // Auto dispose is handled by the package usually on completion if release mode match
      player.onPlayerComplete.listen((_) => player.dispose());
    } catch (e) {
      debugPrint('[AUDIO] SFX Error ($path): $e');
    }
  }

  String _getPath(AudioType type) {
    switch (type) {
      case AudioType.bgmLobby:
        return 'audio/bgm_lobby.mp3';
      case AudioType.bgmChase:
        return 'audio/bgm_chase.mp3';
      case AudioType.click:
        return 'audio/click.mp3';
      case AudioType.itemGet:
        return 'audio/item_get.mp3';
      case AudioType.arrestSuccess:
        return 'audio/arrest_success.mp3';
      case AudioType.arrestFail:
        return 'audio/arrest_fail.mp3';
      case AudioType.siren:
        return 'audio/siren.mp3';
      case AudioType.abilityActive:
        return 'audio/ability_active.mp3';
    }
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});
