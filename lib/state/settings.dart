import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted atelier settings + campaign progress (shared_preferences).
class AtelierSettings extends ChangeNotifier {
  static const _kMusic = 'jm_music_on';
  static const _kSfx = 'jm_sfx_on';
  static const _kMusicVol = 'jm_music_vol';
  static const _kSfxVol = 'jm_sfx_vol';
  static const _kCoins = 'jm_coins';
  static const _kUnlocked = 'jm_unlocked_level';
  static const _kStars = 'jm_stars_json';
  static const _kBest = 'jm_best_json';

  bool musicOn = true;
  bool sfxOn = true;
  double musicVolume = 0.6;
  double sfxVolume = 0.8;

  /// Persistent coin purse.
  int coins = 0;

  /// Highest unlocked atelier (level).
  int unlockedLevel = 1;

  /// Max stars earned per level (level -> 0..3).
  final Map<int, int> stars = {};

  /// Best score per level.
  final Map<int, int> bestScores = {};

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    musicVolume = p.getDouble(_kMusicVol) ?? 0.6;
    sfxVolume = p.getDouble(_kSfxVol) ?? 0.8;
    coins = p.getInt(_kCoins) ?? 0;
    unlockedLevel = p.getInt(_kUnlocked) ?? 1;
    final starsRaw = p.getString(_kStars);
    if (starsRaw != null) {
      try {
        final m = jsonDecode(starsRaw) as Map<String, dynamic>;
        m.forEach((k, v) => stars[int.parse(k)] = (v as num).toInt());
      } catch (_) {}
    }
    final bestRaw = p.getString(_kBest);
    if (bestRaw != null) {
      try {
        final m = jsonDecode(bestRaw) as Map<String, dynamic>;
        m.forEach((k, v) => bestScores[int.parse(k)] = (v as num).toInt());
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kMusicVol, musicVolume);
    await p.setDouble(_kSfxVol, sfxVolume);
    await p.setInt(_kCoins, coins);
    await p.setInt(_kUnlocked, unlockedLevel);
    await p.setString(_kStars,
        jsonEncode(stars.map((k, v) => MapEntry(k.toString(), v))));
    await p.setString(_kBest,
        jsonEncode(bestScores.map((k, v) => MapEntry(k.toString(), v))));
  }

  void setMusicOn(bool v) {
    musicOn = v;
    _save();
    notifyListeners();
  }

  void setSfxOn(bool v) {
    sfxOn = v;
    _save();
    notifyListeners();
  }

  void setMusicVolume(double v) {
    musicVolume = v.clamp(0.0, 1.0);
    _save();
    notifyListeners();
  }

  void setSfxVolume(double v) {
    sfxVolume = v.clamp(0.0, 1.0);
    _save();
    notifyListeners();
  }

  /// Returns false if the purse can't cover the cost.
  Future<bool> spendCoins(int amount) async {
    if (coins < amount) return false;
    coins -= amount;
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> earnCoins(int amount) async {
    coins += amount;
    await _save();
    notifyListeners();
  }

  /// Record a level win: stars, best score, unlock the next atelier.
  Future<void> recordWin(int level, int score, int starCount) async {
    stars[level] = (stars[level] ?? 0) < starCount ? starCount : (stars[level] ?? 0);
    bestScores[level] = (bestScores[level] ?? 0) < score ? score : (bestScores[level] ?? 0);
    if (level + 1 > unlockedLevel) unlockedLevel = level + 1;
    await _save();
    notifyListeners();
  }

  Future<void> resetProgress() async {
    final p = await SharedPreferences.getInstance();
    coins = 0;
    unlockedLevel = 1;
    stars.clear();
    bestScores.clear();
    await p.remove(_kCoins);
    await p.remove(_kUnlocked);
    await p.remove(_kStars);
    await p.remove(_kBest);
    await MidGameSave.clear();
    notifyListeners();
  }

  int totalStars() => stars.values.fold(0, (a, b) => a + b);
}

/// Mid-game persistence (RULES.md §12: state persisted on every move
/// completion; a killed app resumes mid-atelier).
class MidGameSave {
  static const _kGame = 'jm_saved_game_v1';

  static Future<void> save(Map<String, dynamic> data) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kGame, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kGame);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasSave() async {
    final p = await SharedPreferences.getInstance();
    return p.containsKey(_kGame);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kGame);
  }
}
