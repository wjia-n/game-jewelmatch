import 'package:flutter/material.dart';
import '../theme/atelier.dart';
import '../state/settings.dart';
import '../audio/sound_engine.dart';
import 'widgets.dart';

/// Settings — Stitch screen 4: walnut panel, brass plaque title + back,
/// brass toggles (Music, SFX), brass-inlaid volume sliders, red-velvet
/// Reset Progress, velvet About card.
class SettingsScreen extends StatelessWidget {
  final AtelierSettings settings;
  final SoundEngine sound;
  const SettingsScreen(
      {super.key, required this.settings, required this.sound});

  void _apply() {
    sound.applySettings(
      musicOn: settings.musicOn,
      sfxOn: settings.sfxOn,
      musicVolume: settings.musicVolume,
      sfxVolume: settings.sfxVolume,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VelvetBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      BrassIconButton(
                        icon: Icons.arrow_back,
                        size: 42,
                        onTap: () {
                          sound.play(SfxKind.click);
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: BrassPlaque(
                            text: 'SETTINGS',
                            fontSize: 22,
                            letterSpacing: 3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  WalnutPanel(
                    child: AnimatedBuilder(
                      animation: settings,
                      builder: (_, _) => Column(
                        children: [
                          _row(
                            'Music',
                            'Warm plucked melodies',
                            BrassToggle(
                              value: settings.musicOn,
                              onChanged: (v) {
                                settings.setMusicOn(v);
                                _apply();
                                sound.play(SfxKind.click);
                              },
                            ),
                          ),
                          BrassSlider(
                            value: settings.musicVolume,
                            onChanged: (v) {
                              settings.setMusicVolume(v);
                              _apply();
                            },
                          ),
                          const EngravedDivider(),
                          _row(
                            'Sound Effects',
                            'Gem clinks & velvet thuds',
                            BrassToggle(
                              value: settings.sfxOn,
                              onChanged: (v) {
                                settings.setSfxOn(v);
                                _apply();
                                sound.play(SfxKind.click);
                              },
                            ),
                          ),
                          BrassSlider(
                            value: settings.sfxVolume,
                            onChanged: (v) {
                              settings.setSfxVolume(v);
                              _apply();
                              sound.play(SfxKind.select);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: _ResetButton(
                      onTap: () => _confirmReset(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // About card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Atelier.velvet,
                          Atelier.velvetDeep,
                        ],
                      ),
                      border: Border.all(
                          color: Atelier.brassDeep, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('ABOUT THIS ATELIER',
                            style: Atelier.display.copyWith(
                                fontSize: 15,
                                letterSpacing: 2)),
                        const SizedBox(height: 6),
                        Text(
                          'Jewel Match is a vintage jeweler\'s atelier in your pocket. '
                          'Swap faceted gemstones, forge Faceted Bars, Prismatic Diamonds and Brilliants, '
                          'and complete every atelier\'s target before your moves run out.\n\n'
                          'Tip-jar only — no pay-to-win, ever. Made with care by Wajiha.',
                          style: Atelier.body.copyWith(
                              color: Atelier.creamDim),
                        ),
                        const SizedBox(height: 8),
                        Text('v1.0',
                            style: Atelier.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String title, String sub, Widget control) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Atelier.display.copyWith(
                        fontSize: 17, letterSpacing: 1)),
                Text(sub,
                    style: Atelier.bodyItalic.copyWith(
                        fontSize: 12,
                        color: Atelier.creamDim)),
              ],
            ),
          ),
          control,
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    sound.play(SfxKind.click);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: WalnutPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('RESET PROGRESS?',
                  style: Atelier.display.copyWith(fontSize: 20)),
              const SizedBox(height: 8),
              Text(
                'This melts down your coins, stars, unlocked ateliers and saved bench. It cannot be undone.',
                textAlign: TextAlign.center,
                style: Atelier.body
                    .copyWith(color: Atelier.creamDim),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: BrassButton(
                      label: 'KEEP',
                      primary: false,
                      fontSize: 15,
                      onTap: () {
                        sound.play(SfxKind.click);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ResetButton(
                      label: 'RESET',
                      onTap: () {
                        settings.resetProgress();
                        sound.play(SfxKind.invalid);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Red-velvet danger button.
class _ResetButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  const _ResetButton(
      {required this.onTap, this.label = 'RESET PROGRESS'});

  @override
  State<_ResetButton> createState() => _ResetButtonState();
}

class _ResetButtonState extends State<_ResetButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFB03A44),
                Atelier.resetRed,
                Color(0xFF5C1A20),
              ],
            ),
            border:
                Border.all(color: Atelier.walnutDark, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: _down ? 4 : 9,
                offset: Offset(0, _down ? 2 : 4),
              ),
            ],
          ),
          child: Center(
            child: Text(widget.label,
                style: Atelier.display.copyWith(
                    fontSize: 16, letterSpacing: 2)),
          ),
        ),
      ),
    );
  }
}
