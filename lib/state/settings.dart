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
  static const _kProfile = 'jm_profile_name';
  static const _kTheme = 'jm_theme_id';
  static const _kGemStyle = 'jm_gem_style_id';
  static const _kAccent = 'jm_accent_id';
  static const _kCustomTheme = 'jm_custom_theme_json';
  static const _kEndlessBest = 'jm_endless_best';
  static const _kTimedBest = 'jm_timed_best';
  static const _kPro = 'jm_pro_unlocked';

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

  /// Player profile name (editable, persisted).
  String profileName = 'Jeweler';

  /// Atelier theme / gem cut style / metal accent ids (see jewel_themes.dart
  /// and gem_styles.dart). Persisted.
  String themeId = 'burgundy_velvet';
  String gemStyleId = 'round_brilliant';
  String accentId = 'brass';

  /// Custom atelier theme (PRO), stored as a compact JSON color map.
  String? customThemeJson;

  /// Best scores for the endless and timed benches.
  int endlessBest = 0;
  int timedBest = 0;

  /// Pro unlock, mirrored from the Play Billing purchase (restorable).
  bool proUnlocked = false;

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
    profileName = p.getString(_kProfile) ?? 'Jeweler';
    themeId = p.getString(_kTheme) ?? 'burgundy_velvet';
    gemStyleId = p.getString(_kGemStyle) ?? 'round_brilliant';
    accentId = p.getString(_kAccent) ?? 'brass';
    customThemeJson = p.getString(_kCustomTheme);
    endlessBest = p.getInt(_kEndlessBest) ?? 0;
    timedBest = p.getInt(_kTimedBest) ?? 0;
    proUnlocked = p.getBool(_kPro) ?? false;
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
    await p.setString(_kProfile, profileName);
    await p.setString(_kTheme, themeId);
    await p.setString(_kGemStyle, gemStyleId);
    await p.setString(_kAccent, accentId);
    if (customThemeJson == null) {
      await p.remove(_kCustomTheme);
    } else {
      await p.setString(_kCustomTheme, customThemeJson!);
    }
    await p.setInt(_kEndlessBest, endlessBest);
    await p.setInt(_kTimedBest, timedBest);
    await p.setBool(_kPro, proUnlocked);
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
    endlessBest = 0;
    timedBest = 0;
    await p.remove(_kCoins);
    await p.remove(_kUnlocked);
    await p.remove(_kStars);
    await p.remove(_kBest);
    await p.remove(_kEndlessBest);
    await p.remove(_kTimedBest);
    await MidGameSave.clear();
    // Cosmetic choices (theme, gem style, accent, profile name) survive —
    // only progress is reset.
    await _save();
    notifyListeners();
  }

  int totalStars() => stars.values.fold(0, (a, b) => a + b);

  // ------------------------------------------------------------ profile

  Future<void> setProfileName(String v) async {
    profileName = v.trim().isEmpty ? 'Jeweler' : v.trim();
    await _save();
    notifyListeners();
  }

  // ------------------------------------------------------------ themes

  Future<void> setThemeId(String v) async {
    themeId = v;
    await _save();
    notifyListeners();
  }

  Future<void> setGemStyleId(String v) async {
    gemStyleId = v;
    await _save();
    notifyListeners();
  }

  Future<void> setAccentId(String v) async {
    accentId = v;
    await _save();
    notifyListeners();
  }

  Future<void> setCustomThemeJson(String? v) async {
    customThemeJson = v;
    if (v != null) themeId = 'custom';
    await _save();
    notifyListeners();
  }

  // ------------------------------------------------------------ bests

  /// Returns true when the score is a new endless best.
  Future<bool> recordEndlessScore(int score) async {
    final isBest = score > endlessBest;
    if (isBest) endlessBest = score;
    await _save();
    notifyListeners();
    return isBest;
  }

  /// Returns true when the score is a new timed best.
  Future<bool> recordTimedScore(int score) async {
    final isBest = score > timedBest;
    if (isBest) timedBest = score;
    await _save();
    notifyListeners();
    return isBest;
  }

  // ------------------------------------------------------------ pro

  Future<void> setProUnlocked(bool v) async {
    proUnlocked = v;
    await _save();
    notifyListeners();
  }

  /// Free tier: first 4 themes / 3 gem styles. Everything else needs Pro.
  bool themeIsFree(String id) =>
      const ['burgundy_velvet', 'navy_noir', 'emerald_study', 'walnut_gold']
          .contains(id);
  bool gemStyleIsFree(String id) =>
      const ['round_brilliant', 'cushion', 'oval'].contains(id);
  bool get themeLocked => !proUnlocked && !themeIsFree(themeId);
  bool get gemStyleLocked => !proUnlocked && !gemStyleIsFree(gemStyleId);
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
