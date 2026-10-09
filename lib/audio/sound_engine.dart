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
/// music beds, played through audioplayers.
///
/// Exemplar patterns (Ludo overhaul):
/// - Synthesize clips once and cache them.
/// - Serialize music play/stop through a busy guard so rapid toggles can
///   never race.
/// - A small reusable SFX player pool instead of one player per pop.
/// - pause()/resume() on app lifecycle changes; music never silently dies:
///   every entry point re-checks the player state and restarts the bed if
///   needed.
/// - Prewarm on splash so the first note plays instantly.
/// Audio is always best-effort: failures never crash the game.
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

  /// Reusable SFX players (capped pool).
  final List<AudioPlayer> _sfxPool = [];

  /// Busy guard: music play/stop ops serialize through this chain.
  Future<void> _musicChain = Future.value();
  bool _disposed = false;

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
    // Game-appropriate audio focus so interruptions behave and the bed
    // resumes afterwards instead of dying.
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );
    } catch (_) {
      // best-effort; defaults still work
    }
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

  /// Render both music beds eagerly (called from the splash screen).
  Future<void> prewarm() async {
    if (_menuMusic == null || _gameMusic == null) {
      try {
        final beds = await Future.wait([
          compute(_renderBed, false),
          compute(_renderBed, true),
        ]);
        _menuMusic ??= beds[0];
        _gameMusic ??= beds[1];
      } catch (_) {}
    }
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
    _music?.setVolume(_musicVolume).catchError((_) {});
    for (final p in _sfxPool) {
      p.setVolume(_sfxVolume).catchError((_) {});
    }
    if (musicToggled) {
      if (_musicOn) {
        _enqueueMusic(_playCurrentBed);
      } else {
        _enqueueMusic(_stopMusicNow);
      }
    }
    notifyListeners();
  }

  /// Serialize a music op behind the busy guard.
  void _enqueueMusic(Future<void> Function() op) {
    _musicChain = _musicChain.then((_) async {
      if (_disposed) return;
      try {
        await op();
      } catch (_) {}
    });
  }

  Future<void> _playBytes(Uint8List bytes, {double vol = 1.0}) async {
    if (!_ready || !_sfxOn || _disposed) return;
    try {
      // Reuse an idle pool player; cap the pool at 8 and steal the oldest.
      AudioPlayer? p;
      for (final q in _sfxPool) {
        if (q.state != PlayerState.playing) {
          p = q;
          break;
        }
      }
      if (p == null) {
        if (_sfxPool.length >= 8) {
          p = _sfxPool.removeAt(0);
          await p.stop().catchError((_) {});
        } else {
          p = AudioPlayer();
        }
        _sfxPool.add(p);
      }
      await p.setVolume((_sfxVolume * vol).clamp(0.0, 1.0));
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
    if (!_musicOn || _disposed) return;
    await _ensureBed(_inGame);
    final bytes = _inGame ? _gameMusic : _menuMusic;
    if (bytes == null) return;
    _music ??= AudioPlayer();
    await _music!.setReleaseMode(ReleaseMode.loop);
    await _music!.setVolume(_musicVolume);
    await _music!.play(BytesSource(bytes));
  }

  Future<void> _stopMusicNow() async {
    try {
      await _music?.stop();
    } catch (_) {}
  }

  /// Switch between the menu bed and the gameplay bed. If the bed somehow
  /// stopped (interruption, race), restart it — music never silently dies.
  Future<void> setInGame(bool inGame) async {
    if (_inGame == inGame) {
      if (_musicOn && _music?.state != PlayerState.playing) {
        _enqueueMusic(_playCurrentBed);
      }
      return;
    }
    _inGame = inGame;
    _enqueueMusic(() async {
      await _stopMusicNow();
      await _playCurrentBed();
    });
  }

  Future<void> startMenuMusic() => setInGame(false);
  Future<void> startGameMusic() => setInGame(true);

  Future<void> stopMusic() async {
    _enqueueMusic(_stopMusicNow);
  }

  /// App went to background: pause (not stop) so we can resume cleanly.
  Future<void> onAppBackground() async {
    try {
      if (_music?.state == PlayerState.playing) {
        await _music?.pause();
      }
    } catch (_) {}
  }

  /// App came back: resume if we were paused, else restart a dead bed.
  Future<void> onAppForeground() async {
    if (!_musicOn || _disposed) return;
    _enqueueMusic(() async {
      final st = _music?.state;
      if (st == PlayerState.paused) {
        await _music?.resume();
      } else if (st != PlayerState.playing) {
        await _playCurrentBed();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _music?.dispose();
    for (final p in _sfxPool) {
      p.dispose();
    }
    _sfxPool.clear();
    super.dispose();
  }
}
