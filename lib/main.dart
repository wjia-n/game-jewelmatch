import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'state/settings.dart';
import 'audio/sound_engine.dart';
import 'services/iap_service.dart';
import 'theme/atelier.dart';
import 'theme/jewel_themes.dart';
import 'ui/splash_screen.dart';

/// Jewel Match — vintage jeweler's atelier match-3.
/// Stitch UI rebuild per MASTER_RULES.md (stitch-batch5/jewelmatch),
/// exemplar retrofit: engine watchdog, endless/timed modes, IAP, themes.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);

  final settings = AtelierSettings();
  await settings.load();

  // Apply the player's workbench (theme + metal accent) before first paint.
  Atelier.apply(
    AtelierThemes.byId(settings.themeId,
        customJson: settings.customThemeJson),
    AtelierThemes.accentById(settings.accentId),
  );
  // Re-apply whenever cosmetic settings change.
  settings.addListener(() {
    Atelier.apply(
      AtelierThemes.byId(settings.themeId,
          customJson: settings.customThemeJson),
      AtelierThemes.accentById(settings.accentId),
    );
  });

  final sound = SoundEngine();
  await sound.init(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    musicVolume: settings.musicVolume,
    sfxVolume: settings.sfxVolume,
  );

  final store = StoreService();
  // Store init happens on the splash screen (needs no await here).

  runApp(JewelMatchApp(
      settings: settings, sound: sound, store: store));
}

class JewelMatchApp extends StatelessWidget {
  final AtelierSettings settings;
  final SoundEngine sound;
  final StoreService store;
  const JewelMatchApp(
      {super.key,
      required this.settings,
      required this.sound,
      required this.store});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (_, _) => MaterialApp(
        title: 'Jewel Match',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: Atelier.velvetDeep,
          fontFamily: 'EBGaramond',
          useMaterial3: true,
        ),
        home: SplashScreen(
            settings: settings, sound: sound, store: store),
      ),
    );
  }
}
