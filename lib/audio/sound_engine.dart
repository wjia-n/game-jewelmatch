import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'synth.dart';

Uint8List _renderBed(bool lively) => AtelierSynth.wav(
      AtelierSynth.musicBed(lively: lively),
    );

enum SfxKind {
  click, // brass UI click
  select, // gem select tink
  swap, // soft velvet swish
  match, // match pop arpeggio (step passed separately)
  specialCreate, // sparkle glissando
  detonate, // special detonation
  invalid, // dull velvet thud
  shuffle, // velvet rustle
  hint, // apprentice chime
  start, // game start arpeggio
  win, // victory fanfare
  lose, // defeat motif
  coin, // coin ping
}

/// Audio engine for Jewel Match: synthesized atelier SFX + looping generated
/// music beds, played through audioplayers. Music toggle, SFX toggle and
/// both volume sliders are wired to persisted settings.
class SoundEngine extends ChangeNotifier {
  AudioPlayer? _music;
  bool _musicOn = true;
  bool _sfxOn = true;
  double _musicVolume = 0.6;
  double _sfxVolume = 0.8;
  bool _inGame = false;
  bool _ready = false;

  final Map<SfxKind, Uint8List> _sfxCache = {};
  final Map<int, Uint8List> _matchCache = {};
  Uint8List? _menuMusic;
  Uint8List? _gameMusic;

  bool get musicOn => _musicOn;
  bool get sfxOn => _sfxOn;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> init({
    required bool musicOn,
    required bool sfxOn,
    required double musicVolume,
    required double sfxVolume,
  }) async {
    _musicOn = musicOn;
    _sfxOn = sfxOn;
    _musicVolume = musicVolume;
    _sfxVolume = sfxVolume;
    // Pre-render the short SFX eagerly; music beds lazily (they're long).
    _sfxCache[SfxKind.click] = AtelierSynth.wav(AtelierSynth.brassClick());
    _sfxCache[SfxKind.select] = AtelierSynth.wav(AtelierSynth.select());
    _sfxCache[SfxKind.swap] = AtelierSynth.wav(AtelierSynth.swap());
    _sfxCache[SfxKind.specialCreate] =
        AtelierSynth.wav(AtelierSynth.specialCreate());
    _sfxCache[SfxKind.detonate] = AtelierSynth.wav(AtelierSynth.detonate());
    _sfxCache[SfxKind.invalid] = AtelierSynth.wav(AtelierSynth.velvetThud());
    _sfxCache[SfxKind.shuffle] = AtelierSynth.wav(AtelierSynth.velvetRustle());
    _sfxCache[SfxKind.hint] = AtelierSynth.wav(AtelierSynth.hint());
    _sfxCache[SfxKind.start] = AtelierSynth.wav(AtelierSynth.start());
    _sfxCache[SfxKind.win] = AtelierSynth.wav(AtelierSynth.win());
    _sfxCache[SfxKind.lose] = AtelierSynth.wav(AtelierSynth.lose());
    _sfxCache[SfxKind.coin] = AtelierSynth.wav(AtelierSynth.coin());
    // Match pops rendered per cascade step / match size on demand.
    _ready = true;
  }

  void applySettings({
    required bool musicOn,
    required bool sfxOn,
    required double musicVolume,
    required double sfxVolume,
  }) {
    final musicToggled = musicOn != _musicOn;
    _musicOn = musicOn;
    _sfxOn = sfxOn;
    _musicVolume = musicVolume;
    _sfxVolume = sfxVolume;
    _music?.setVolume(_musicVolume);
    if (musicToggled) {
      if (_musicOn) {
        _playCurrentBed();
      } else {
        _music?.stop();
      }
    }
    notifyListeners();
  }

  Future<void> _playBytes(Uint8List bytes, {double vol = 1.0}) async {
    if (!_ready || !_sfxOn) return;
    try {
      final p = AudioPlayer();
      await p.setVolume((_sfxVolume * vol).clamp(0.0, 1.0));
      p.onPlayerComplete.listen((_) => p.dispose());
      await p.play(BytesSource(bytes));
    } catch (_) {
      // Audio is best-effort; never crash the game.
    }
  }

  Future<void> play(SfxKind kind, {double vol = 1.0}) async {
    final bytes = _sfxCache[kind];
    if (bytes == null) return;
    await _playBytes(bytes, vol: vol);
  }

  /// Match pop with cascade-step-aware pitch. [step] is 1-based.
  Future<void> playMatch(int step, int gemCount) async {
    final key = step * 100 + gemCount.clamp(0, 63);
    var bytes = _matchCache[key];
    bytes ??= AtelierSynth.wav(AtelierSynth.matchPop(step, gemCount));
    _matchCache[key] = bytes;
    await _playBytes(bytes);
  }

  Future<void> _ensureBed(bool inGame) async {
    if (inGame && _gameMusic == null) {
      _gameMusic = await compute(_renderBed, true);
    } else if (!inGame && _menuMusic == null) {
      _menuMusic = await compute(_renderBed, false);
    }
  }

  Future<void> _playCurrentBed() async {
    if (!_musicOn) return;
    try {
      await _ensureBed(_inGame);
      final bytes = _inGame ? _gameMusic : _menuMusic;
      if (bytes == null) return;
      _music ??= AudioPlayer();
      await _music!.setReleaseMode(ReleaseMode.loop);
      await _music!.setVolume(_musicVolume);
      await _music!.play(BytesSource(bytes));
    } catch (_) {}
  }

  /// Switch between the menu bed and the gameplay bed.
  Future<void> setInGame(bool inGame) async {
    if (_inGame == inGame) {
      if (_musicOn && _music?.state != PlayerState.playing) {
        await _playCurrentBed();
      }
      return;
    }
    _inGame = inGame;
    await _music?.stop();
    await _playCurrentBed();
  }

  Future<void> startMenuMusic() => setInGame(false);
  Future<void> startGameMusic() => setInGame(true);

  Future<void> stopMusic() async {
    try {
      await _music?.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _music?.dispose();
    super.dispose();
  }
}
