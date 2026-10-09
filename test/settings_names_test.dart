import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jewelmatch/state/settings.dart';

/// Regression tests for the player-name persistence bug class (2026-10-09):
///
/// Batch-1 found that SharedPreferences.setStringList is backed by an
/// UNORDERED StringSet on Android, scrambling ordered name data on every
/// app restart (ludo hit this). Jewel Match's profile name was audited and
/// found NOT to use setStringList anywhere: it persists as a single
/// order-safe string ('jm_profile_name'). These tests lock that in so a
/// future refactor can never reintroduce an unordered list for the name.
void main() {
  Future<AtelierSettings> freshSettings() async {
    final s = AtelierSettings();
    await s.load();
    return s;
  }

  test('profile name defaults to Jeweler when nothing is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await freshSettings();
    expect(s.profileName, 'Jeweler');
  });

  test('profile name round-trips byte-for-byte through prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await freshSettings();
    await s.setProfileName('Wajiha');
    // Simulate an app restart: new settings object, same prefs store.
    final s2 = await freshSettings();
    expect(s2.profileName, 'Wajiha');
  });

  test('profile name is stored as a single ordered string, not a list',
      () async {
    SharedPreferences.setMockInitialValues({});
    final s = await freshSettings();
    await s.setProfileName('Gem Hunter 42');
    final p = await SharedPreferences.getInstance();
    // The raw persisted value must be the exact string — no list involved.
    expect(p.getString('jm_profile_name'), 'Gem Hunter 42');
    expect(p.get('jm_profile_name'), isA<String>());
  });

  test('unicode / emoji names survive unchanged', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await freshSettings();
    await s.setProfileName('珠宝匠💎');
    final s2 = await freshSettings();
    expect(s2.profileName, '珠宝匠💎');
  });

  test('leading/trailing whitespace is trimmed', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await freshSettings();
    await s.setProfileName('   Ruby   ');
    expect(s.profileName, 'Ruby');
    final p = await SharedPreferences.getInstance();
    expect(p.getString('jm_profile_name'), 'Ruby');
  });

  test('blank names fall back to the default', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await freshSettings();
    await s.setProfileName('    ');
    expect(s.profileName, 'Jeweler');
  });

  test('rename is immediately visible to a fresh load (no stale cache)',
      () async {
    SharedPreferences.setMockInitialValues({});
    final s = await freshSettings();
    await s.setProfileName('First');
    await s.setProfileName('Second');
    final s2 = await freshSettings();
    expect(s2.profileName, 'Second');
  });
}
