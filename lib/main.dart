import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'state/settings.dart';
import 'audio/sound_engine.dart';
import 'ui/menu_screen.dart';

/// Jewel Match — vintage jeweler's atelier match-3.
/// Stitch UI rebuild per MASTER_RULES.md (stitch-batch5/jewelmatch).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);

  final settings = AtelierSettings();
  await settings.load();

  final sound = SoundEngine();
  await sound.init(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    musicVolume: settings.musicVolume,
    sfxVolume: settings.sfxVolume,
  );

  runApp(JewelMatchApp(settings: settings, sound: sound));
}

class JewelMatchApp extends StatelessWidget {
  final AtelierSettings settings;
  final SoundEngine sound;
  const JewelMatchApp(
      {super.key, required this.settings, required this.sound});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jewel Match',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF220C13),
        fontFamily: 'EBGaramond',
        useMaterial3: true,
      ),
      home: MenuScreen(settings: settings, sound: sound),
    );
  }
}
