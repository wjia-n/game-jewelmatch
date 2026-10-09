import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/atelier.dart';
import '../theme/jewel_themes.dart';
import '../theme/gem_styles.dart';
import '../state/settings.dart';
import '../audio/sound_engine.dart';
import '../services/iap_service.dart';
import 'widgets.dart';
import 'pro_screen.dart';

/// Atelier Themes — 13 velvet workbenches, 9 jeweler's gem cuts, 5 metal
/// accents, and a PRO custom theme creator. Everything persists.
class ThemeScreen extends StatefulWidget {
  final AtelierSettings settings;
  final SoundEngine sound;
  final StoreService store;
  const ThemeScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.store,
  });

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _pickTheme(AtelierThemeDef t) async {
    final s = widget.settings;
    if (!AtelierThemes.isFree(t.id) && !s.proUnlocked) {
      widget.sound.play(SfxKind.invalid);
      _offerPro('${t.name} is a PRO workbench');
      return;
    }
    widget.sound.play(SfxKind.select);
    await s.setThemeId(t.id);
    _refresh();
  }

  Future<void> _pickCut(GemCutDef c) async {
    final s = widget.settings;
    if (!GemCuts.freeIds.contains(c.id) && !s.proUnlocked) {
      widget.sound.play(SfxKind.invalid);
      _offerPro('${c.name} is a PRO cut');
      return;
    }
    widget.sound.play(SfxKind.select);
    await s.setGemStyleId(c.id);
    _refresh();
  }

  Future<void> _pickAccent(MetalAccent a) async {
    widget.sound.play(SfxKind.select);
    await widget.settings.setAccentId(a.id);
    _refresh();
  }

  void _offerPro(String why) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: WalnutPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PRO WORKBENCH',
                  style: Atelier.display
                      .copyWith(fontSize: 20, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(why,
                  textAlign: TextAlign.center,
                  style: Atelier.bodyItalic
                      .copyWith(color: Atelier.creamDim)),
              const SizedBox(height: 14),
              BrassButton(
                label: 'SEE PRO',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProScreen(
                          settings: widget.settings,
                          sound: widget.sound,
                          store: widget.store)));
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Maybe later',
                    style: Atelier.body
                        .copyWith(color: Atelier.creamDim)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCustomCreator() {
    final s = widget.settings;
    if (!s.proUnlocked) {
      widget.sound.play(SfxKind.invalid);
      _offerPro('The custom atelier is a PRO tool');
      return;
    }
    widget.sound.play(SfxKind.click);
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => CustomThemeScreen(
                settings: s, sound: widget.sound)))
        .then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VelvetBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                child: Row(
                  children: [
                    BrassIconButton(
                      icon: Icons.arrow_back,
                      size: 42,
                      onTap: () {
                        widget.sound.play(SfxKind.click);
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: BrassPlaque(
                        text: 'ATELIER THEMES',
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: s,
                  builder: (_, _) => SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('VELVET WORKBENCHES'),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.82,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: AtelierThemes.all.length,
                          itemBuilder: (_, i) =>
                              _themeTile(AtelierThemes.all[i], s),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: BrassButton(
                            label: s.themeId == 'custom'
                                ? 'CUSTOM ATELIER \u2713'
                                : 'CUSTOM ATELIER (PRO)',
                            primary: false,
                            fontSize: 15,
                            onTap: _openCustomCreator,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('GEM CUTS'),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: GemCuts.all.length,
                          itemBuilder: (_, i) =>
                              _cutTile(GemCuts.all[i], s),
                        ),
                        const SizedBox(height: 18),
                        _sectionTitle('METAL ACCENTS'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final a in AtelierThemes.accents)
                              _accentDot(a, s),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            AtelierThemes.accentById(s.accentId).name,
                            style: Atelier.caption,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: Atelier.display.copyWith(fontSize: 16, letterSpacing: 3));

  Widget _themeTile(AtelierThemeDef t, AtelierSettings s) {
    final selected = s.themeId == t.id;
    final locked = !AtelierThemes.isFree(t.id) && !s.proUnlocked;
    return GestureDetector(
      onTap: () => _pickTheme(t),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Atelier.brassBright
                : Atelier.walnutDark,
            width: selected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [t.velvet, t.velvetDeep],
                      ),
                    ),
                  ),
                  // mini tray preview: 3x3 cells
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: GridView.builder(
                      physics:
                          const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 3,
                              mainAxisSpacing: 3),
                      itemCount: 9,
                      itemBuilder: (_, i) => Container(
                        decoration: BoxDecoration(
                          color: t.cell,
                          borderRadius:
                              BorderRadius.circular(3),
                          border: Border.all(
                              color: t.woodDark, width: 1),
                        ),
                        child: i == 4
                            ? CustomPaint(
                                painter: _MiniGemPainter(
                                    color: Atelier.ruby))
                            : null,
                      ),
                    ),
                  ),
                  if (locked)
                    Container(
                      color:
                          Colors.black.withValues(alpha: 0.45),
                      child: Center(
                        child: Icon(Icons.lock,
                            color: Atelier.brassBright,
                            size: 22),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: t.woodDark,
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                t.name,
                textAlign: TextAlign.center,
                style: Atelier.caption
                    .copyWith(fontSize: 10, color: t.cream),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cutTile(GemCutDef c, AtelierSettings s) {
    final selected = s.gemStyleId == c.id;
    final locked =
        !GemCuts.freeIds.contains(c.id) && !s.proUnlocked;
    return GestureDetector(
      onTap: () => _pickCut(c),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(
            color: selected
                ? Atelier.brassBright
                : Atelier.walnutDark,
            width: selected ? 3 : 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GemStone(
                    type: 0,
                    size: 44,
                    styleId: c.id,
                    lifted: selected),
                const SizedBox(height: 4),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    c.name,
                    textAlign: TextAlign.center,
                    style: Atelier.caption
                        .copyWith(fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (locked)
              Positioned(
                right: 4,
                top: 4,
                child: Icon(Icons.lock,
                    color: Atelier.brassBright, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _accentDot(MetalAccent a, AtelierSettings s) {
    final selected = s.accentId == a.id;
    return GestureDetector(
      onTap: () => _pickAccent(a),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [a.bright, a.base, a.deep],
          ),
          border: Border.all(
            color: selected
                ? Atelier.lampCream
                : Colors.black.withValues(alpha: 0.5),
            width: selected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 6,
                offset: const Offset(0, 3)),
          ],
        ),
        child: selected
            ? Icon(Icons.check,
                color: Atelier.walnutDark, size: 22)
            : null,
      ),
    );
  }
}

class _MiniGemPainter extends CustomPainter {
  final Color color;
  _MiniGemPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    GemRenderer.paint(
        canvas,
        Offset(size.width / 2, size.height / 2),
        size.width / 2,
        0,
        0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// PRO custom theme creator — pick velvet, wood, metal-tinted text colors.
/// Live preview, persisted as a compact color JSON.
class CustomThemeScreen extends StatefulWidget {
  final AtelierSettings settings;
  final SoundEngine sound;
  const CustomThemeScreen(
      {super.key, required this.settings, required this.sound});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  late Map<String, Color> _colors;

  static const List<Color> palette = [
    Color(0xFF5A1F2B), Color(0xFF3A1420), Color(0xFF6E2434),
    Color(0xFF1E2A4A), Color(0xFF141D33), Color(0xFF274069),
    Color(0xFF1E4D3B), Color(0xFF123324), Color(0xFF2E4A2E),
    Color(0xFF4A3220), Color(0xFF33220F), Color(0xFF5C3A16),
    Color(0xFF2E1D12), Color(0xFF4A3220), Color(0xFF6B4A2E),
    Color(0xFF4A1F4D), Color(0xFF331537), Color(0xFF1F4A4E),
    Color(0xFF7A1E28), Color(0xFF541420), Color(0xFF2E2E34),
    Color(0xFFF2E7CF), Color(0xFFC9B894), Color(0xFFE3B341),
  ];

  static const rows = [
    ('Velvet', 'velvet'),
    ('Velvet shadow', 'velvetDeep'),
    ('Tray cells', 'cell'),
    ('Cell shadow', 'cellDeep'),
    ('Wood frame', 'woodDark'),
    ('Wood panels', 'woodMid'),
    ('Wood highlight', 'woodLight'),
    ('Text cream', 'cream'),
    ('Text dim', 'creamDim'),
    ('Coin gold', 'coin'),
  ];

  @override
  void initState() {
    super.initState();
    final base = AtelierThemes.byId(widget.settings.themeId,
        customJson: widget.settings.customThemeJson);
    _colors = base.toJsonMap().map((k, v) => MapEntry(k, Color(v)));
  }

  Future<void> _pick(String key, String label) async {
    widget.sound.play(SfxKind.click);
    final chosen = await showDialog<Color>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: WalnutPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label.toUpperCase(),
                  style: Atelier.display.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in palette)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(c),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _colors[key] == c
                                ? Atelier.brassBright
                                : Colors.black45,
                            width: _colors[key] == c ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              BrassButton(
                  label: 'DONE',
                  fontSize: 15,
                  onTap: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) {
      setState(() => _colors[key] = chosen);
      widget.sound.play(SfxKind.select);
    }
  }

  Future<void> _save() async {
    widget.sound.play(SfxKind.start);
    final json =
        jsonEncode(_colors.map((k, v) => MapEntry(k, v.toARGB32())));
    await widget.settings.setCustomThemeJson(json);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Live preview uses the edited colors directly.
    final preview = AtelierThemeDef.fromJsonMap(
        'My Atelier',
        _colors.map((k, v) => MapEntry(k, v.toARGB32())));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.4,
            colors: [preview.velvet, preview.velvetDeep],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                child: Row(
                  children: [
                    BrassIconButton(
                      icon: Icons.arrow_back,
                      size: 42,
                      onTap: () {
                        widget.sound.play(SfxKind.click);
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: BrassPlaque(
                        text: 'CUSTOM ATELIER',
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
              ),
              // Live preview tray.
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: preview.cellDeep,
                    border:
                        Border.all(color: preview.woodDark, width: 5),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < 3; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6),
                            child: GemStone(
                                type: i * 2, size: 52),
                          ),
                        const SizedBox(width: 8),
                        Text('My Atelier',
                            style: Atelier.display.copyWith(
                                fontSize: 20,
                                color: preview.cream)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final (label, key) in rows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => _pick(key, label),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black
                                    .withValues(alpha: 0.3),
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                    color: Atelier.walnutDark),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: _colors[key],
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Atelier.brass),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(label,
                                      style: Atelier.body),
                                  const Spacer(),
                                  Icon(Icons.chevron_right,
                                      color: Atelier.creamDim),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: BrassButton(
                          label: 'SET MY ATELIER',
                          onTap: _save,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
