import 'dart:math';
import 'dart:typed_data';

/// Programmatic sound synthesis for the jeweler's atelier sound set.
/// Everything is generated as 16-bit mono WAV bytes at 22050 Hz —
/// no external audio assets. Gem clinks, sparkle chimes, soft velvet
/// thuds, brass clicks and warm plucked music beds.
class AtelierSynth {
  static const int rate = 22050;
  static final Random _r = Random(20261009);

  static Uint8List wav(List<double> samples) {
    final n = samples.length;
    final data = ByteData(44 + n * 2);
    void str(int o, String s) {
      for (int i = 0; i < s.length; i++) {
        data.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    var peak = 0.0;
    for (final s in samples) {
      final a = s.abs();
      if (a > peak) peak = a;
    }
    final gain = peak > 0 ? 0.85 / peak : 1.0;
    for (int i = 0; i < n; i++) {
      final v = (samples[i] * gain).clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  static double _env(int i, int n, double decay) => exp(-decay * i / n);

  /// A "gem tink": high inharmonic partials, very fast decay.
  static List<double> gemTink(double freq, double seconds, {double vol = 1.0}) {
    final n = (rate * seconds).round();
    final out = List<double>.filled(n, 0.0);
    const partials = [1.0, 2.76, 5.40, 8.93];
    const amps = [1.0, 0.42, 0.22, 0.10];
    for (int i = 0; i < n; i++) {
      final t = i / rate;
      var s = 0.0;
      for (int p = 0; p < partials.length; p++) {
        s += amps[p] *
            sin(2 * pi * freq * partials[p] * t) *
            _env(i, n, 6.0 + p * 4.0);
      }
      out[i] = s * 0.45 * vol;
    }
    return out;
  }

  /// Soft plucked string (lute/harpsichord-ish) for music beds and motifs.
  static List<double> pluck(double freq, double seconds, {double vol = 1.0}) {
    final n = (rate * seconds).round();
    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final t = i / rate;
      var s = sin(2 * pi * freq * t) * _env(i, n, 4.5);
      s += 0.4 * sin(2 * pi * freq * 2 * t) * _env(i, n, 6.5);
      s += 0.18 * sin(2 * pi * freq * 3 * t) * _env(i, n, 9.0);
      // tiny strike transient
      if (i < rate * 0.003) {
        s += (_r.nextDouble() * 2 - 1) * 0.25 * (1 - i / (rate * 0.003));
      }
      out[i] = s * 0.5 * vol;
    }
    return out;
  }

  /// Velvet thud: soft low body, no harsh attack. Invalid moves / landings.
  static List<double> velvetThud() {
    final n = (rate * 0.22).round();
    final out = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final t = i / rate;
      var s = sin(2 * pi * 118 * t) * _env(i, n, 8.0) * 0.8 +
          sin(2 * pi * 79 * t) * _env(i, n, 6.0) * 0.5;
      if (i < rate * 0.01) {
        s += (_r.nextDouble() * 2 - 1) * 0.12 * (1 - i / (rate * 0.01));
      }
      out[i] = s * 0.55;
    }
    return out;
  }

  /// Velvet rustle: filtered noise swell for shuffles.
  static List<double> velvetRustle() {
    final n = (rate * 0.5).round();
    final out = List<double>.filled(n, 0.0);
    double lp = 0;
    for (int i = 0; i < n; i++) {
      final u = i / n;
      final swell = sin(pi * u);
      final noise = _r.nextDouble() * 2 - 1;
      lp = lp * 0.86 + noise * 0.14;
      out[i] = lp * swell * 0.7;
    }
    return out;
  }

  /// Brass click for UI buttons: metallic short burst.
  static List<double> brassClick() {
    final n = (rate * 0.09).round();
    final out = List<double>.filled(n, 0.0);
    const partials = [523.0, 1244.0, 2093.0];
    const amps = [1.0, 0.5, 0.3];
    for (int i = 0; i < n; i++) {
      final t = i / rate;
      var s = 0.0;
      for (int p = 0; p < partials.length; p++) {
        s += amps[p] * sin(2 * pi * partials[p] * t) * _env(i, n, 14.0);
      }
      out[i] = s * 0.4;
    }
    return out;
  }

  /// Gem select tick.
  static List<double> select() => gemTink(2350, 0.07, vol: 0.7);

  /// Soft swap swish: muffled noise + low tick.
  static List<double> swap() {
    final n = (rate * 0.12).round();
    final out = List<double>.filled(n, 0.0);
    double lp = 0;
    for (int i = 0; i < n; i++) {
      final noise = _r.nextDouble() * 2 - 1;
      lp = lp * 0.78 + noise * 0.22;
      final t = i / rate;
      out[i] = lp * _env(i, n, 5.0) * 0.35 +
          sin(2 * pi * 640 * t) * _env(i, n, 12.0) * 0.2;
    }
    return out;
  }

  /// Match pop: rising clink arpeggio. [step] = cascade step (0-based).
  static List<double> matchPop(int step, int gemCount) {
    const scale = [1318.5, 1568.0, 1760.0, 2093.0, 2637.0, 3136.0];
    final notes = (2 + gemCount ~/ 2).clamp(2, 5);
    final dur = 0.09 * notes + 0.22;
    final n = (rate * dur).round();
    final out = List<double>.filled(n, 0.0);
    for (int k = 0; k < notes; k++) {
      final freq = scale[(k + step) % scale.length];
      final start = (rate * 0.075 * k).round();
      final tone = gemTink(freq, 0.28, vol: 0.8);
      for (int i = 0; i < tone.length && start + i < n; i++) {
        out[start + i] += tone[i];
      }
    }
    return out;
  }

  /// Special-gem creation: ascending sparkle glissando.
  static List<double> specialCreate() {
    final n = (rate * 0.6).round();
    final out = List<double>.filled(n, 0.0);
    for (int k = 0; k < 8; k++) {
      final freq = 1568.0 * pow(2, k / 8);
      final start = (rate * 0.05 * k).round();
      final tone = gemTink(freq, 0.25, vol: 0.55);
      for (int i = 0; i < tone.length && start + i < n; i++) {
        out[start + i] += tone[i];
      }
    }
    return out;
  }

  /// Special detonation: clink cluster + soft thud.
  static List<double> detonate() {
    final n = (rate * 0.55).round();
    final out = List<double>.filled(n, 0.0);
    for (int k = 0; k < 6; k++) {
      final freq = 880.0 + _r.nextDouble() * 1400.0;
      final start = (rate * 0.04 * k).round();
      final tone = gemTink(freq, 0.3, vol: 0.5);
      for (int i = 0; i < tone.length && start + i < n; i++) {
        out[start + i] += tone[i];
      }
    }
    final thud = velvetThud();
    for (int i = 0; i < thud.length && i < n; i++) {
      out[i] += thud[i] * 0.7;
    }
    return out;
  }

  /// Apprentice hint: soft two-note chime.
  static List<double> hint() {
    final n = (rate * 0.5).round();
    final out = List<double>.filled(n, 0.0);
    for (final entry in [(1568.0, 0.0), (2093.0, 0.16)]) {
      final start = (rate * entry.$2).round();
      final tone = pluck(entry.$1, 0.34, vol: 0.6);
      for (int i = 0; i < tone.length && start + i < n; i++) {
        out[start + i] += tone[i];
      }
    }
    return out;
  }

  /// Game start: warm opening arpeggio.
  static List<double> start() {
    const seq = [523.25, 659.25, 783.99, 1046.5];
    final n = (rate * 1.1).round();
    final out = List<double>.filled(n, 0.0);
    for (int k = 0; k < seq.length; k++) {
      final start = (rate * 0.14 * k).round();
      final tone = pluck(seq[k], 0.6, vol: 0.75);
      for (int i = 0; i < tone.length && start + i < n; i++) {
        out[start + i] += tone[i];
      }
    }
    return out;
  }

  /// Victory: bright chime fanfare.
  static List<double> win() {
    const seq = [1046.5, 1318.5, 1568.0, 2093.0, 2637.0, 3136.0];
    final n = (rate * 1.6).round();
    final out = List<double>.filled(n, 0.0);
    for (int k = 0; k < seq.length; k++) {
      final start = (rate * 0.13 * k).round();
      final tone = gemTink(seq[k], 0.55, vol: 0.7);
      for (int i = 0; i < tone.length && start + i < n; i++) {
        out[start + i] += tone[i];
      }
    }
    return out;
  }

  /// Defeat: gentle descending motif, soft and warm.
  static List<double> lose() {
    const seq = [783.99, 659.25, 523.25, 392.0];
    final n = (rate * 1.5).round();
    final out = List<double>.filled(n, 0.0);
    for (int k = 0; k < seq.length; k++) {
      final start = (rate * 0.24 * k).round();
      final tone = pluck(seq[k], 0.7, vol: 0.6);
      for (int i = 0; i < tone.length && start + i < n; i++) {
        out[start + i] += tone[i];
      }
    }
    return out;
  }

  /// Coin earned: bright two-tone ping.
  static List<double> coin() {
    final n = (rate * 0.35).round();
    final out = List<double>.filled(n, 0.0);
    for (final entry in [(2637.0, 0.0), (3136.0, 0.09)]) {
      final start = (rate * entry.$2).round();
      final tone = gemTink(entry.$1, 0.25, vol: 0.5);
      for (int i = 0; i < tone.length && start + i < n; i++) {
        out[start + i] += tone[i];
      }
    }
    return out;
  }

  /// Looping music bed: warm plucked arpeggios over a soft bass.
  /// [lively] = gameplay bed; false = calmer menu bed. Length is an
  /// exact multiple of the 4-bar loop so ReleaseMode.loop is seamless.
  static List<double> musicBed({required bool lively}) {
    const seconds = 12.0;
    final n = (rate * seconds).round();
    final out = List<double>.filled(n, 0.0);
    // Am - F - C - G progression, plucked arpeggio.
    const chords = [
      [220.0, 261.63, 329.63], // Am
      [174.61, 220.0, 261.63], // F
      [196.0, 246.94, 293.66], // G (as F walk-down color)
      [130.81, 196.0, 261.63], // C
    ];
    final step = lively ? 0.30 : 0.48;
    final chordLen = 3.0; // 4 chords in 12s
    final arpPattern = [0, 1, 2, 1, 0, 2, 1, 2];
    int note = 0;
    for (int c = 0; c < chords.length; c++) {
      final chord = chords[c];
      final base = (c * chordLen).round();
      // soft bass root
      final bass = pluck(chord[0] / 2, 2.4, vol: 0.5);
      final bStart = (rate * base).round();
      for (int i = 0; i < bass.length && bStart + i < n; i++) {
        out[bStart + i] += bass[i] * 0.7;
      }
      // arpeggio
      for (double t = 0.0; t < chordLen; t += step) {
        final freq = chord[arpPattern[note % arpPattern.length]] * 2;
        final start = (rate * (base + t)).round();
        final tone = pluck(freq, 0.9, vol: lively ? 0.5 : 0.38);
        for (int i = 0; i < tone.length && start + i < n; i++) {
          out[start + i] += tone[i];
        }
        note++;
      }
    }
    // gentle fade edges so the loop point is clean
    final fade = (rate * 0.15).round();
    for (int i = 0; i < fade; i++) {
      final f = i / fade;
      out[i] *= f;
      out[n - 1 - i] *= f;
    }
    return out.map((s) => s * 0.5).toList();
  }
}
