import 'package:flutter/material.dart';
import 'jewel_themes.dart';

/// Jewel Match — "Vintage jeweler's atelier" design tokens.
///
/// The palette is theme-dynamic: [apply] installs the active
/// [AtelierThemeDef] + [MetalAccent] (from settings) and every widget that
/// reads [Atelier.velvet], [Atelier.brass] … picks up the workbench the
/// player chose. Gem tier colors stay fixed — a Ruby is always a Ruby.
/// Visual source of truth: stitch-batch5/jewelmatch/DESIGN.md.
class Atelier {
  Atelier._();

  static AtelierThemeDef _theme = AtelierThemes.all[0];
  static MetalAccent _accent = AtelierThemes.accents[0];

  /// Install the active theme + accent (call when settings change).
  static void apply(AtelierThemeDef theme, MetalAccent accent) {
    _theme = theme;
    _accent = accent;
  }

  static AtelierThemeDef get theme => _theme;
  static MetalAccent get accent => _accent;

  // ---- Palette (theme-driven) ----
  static Color get velvet => _theme.velvet;
  static Color get velvetDeep => _theme.velvetDeep;
  static Color get velvetNavy => _theme.cell;
  static Color get velvetNavyDeep => _theme.cellDeep;
  static Color get walnutDark => _theme.woodDark;
  static Color get walnutMid => _theme.woodMid;
  static Color get walnutLight => _theme.woodLight;
  static Color get brass => _accent.base;
  static Color get brassBright => _accent.bright;
  static Color get brassDeep => _accent.deep;
  static Color get lampCream => _theme.cream;
  static Color get creamDim => _theme.creamDim;
  static Color get creamFaint =>
      Color.lerp(_theme.creamDim, Colors.black, 0.35)!;
  static Color get coinGold => _theme.coin;
  static const resetRed = Color(0xFF8E2A33); // red-velvet danger button

  // ---- Gem tiers (RULES.md §2) — fixed, theme-independent ----
  static const ruby = Color(0xFFA31621);
  static const sapphire = Color(0xFF1D4E89);
  static const emerald = Color(0xFF1E7A4F);
  static const amethyst = Color(0xFF6A4C93);
  static const topaz = Color(0xFFC98A1B);
  static const diamond = Color(0xFFDCE6EC);

  static const List<Color> gemBase = [
    ruby,
    sapphire,
    emerald,
    amethyst,
    topaz,
    diamond,
  ];

  static const List<String> gemNames = [
    'Ruby',
    'Sapphire',
    'Emerald',
    'Amethyst',
    'Topaz',
    'Diamond',
  ];

  /// Per-gem base score (RULES.md §8). Diamond is rarer, scores more.
  static const List<int> gemBaseScore = [60, 60, 60, 60, 60, 90];

  /// Darker shade for a gem's lower facet planes / shadow side.
  static Color gemDark(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withLightness((hsl.lightness * 0.42).clamp(0.0, 1.0)).toColor();
  }

  /// Lighter tone for facet highlights.
  static Color gemLight(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness + (1 - hsl.lightness) * 0.5).clamp(0.0, 1.0))
        .toColor();
  }

  // ---- Typography ----
  static const displayFamily = 'NotoSerifDisplay'; // engraved-serif stand-in
  static const bodyFamily = 'EBGaramond';

  /// Engraved brass-plaque title.
  static TextStyle get display => TextStyle(
        fontFamily: displayFamily,
        fontWeight: FontWeight.w700,
        color: lampCream,
        letterSpacing: 3.0,
      );

  /// Dark engraved text for use ON brass plaques.
  static TextStyle get displayOnBrass => TextStyle(
        fontFamily: displayFamily,
        fontWeight: FontWeight.w700,
        color: walnutDark,
        letterSpacing: 2.0,
      );

  static TextStyle get body => TextStyle(
        fontFamily: bodyFamily,
        color: lampCream,
        fontSize: 15,
        height: 1.4,
      );

  static TextStyle get bodyItalic => body.copyWith(fontStyle: FontStyle.italic);

  static TextStyle get caption => TextStyle(
        fontFamily: bodyFamily,
        color: creamDim,
        fontSize: 12,
        letterSpacing: 1.5,
      );

  /// Engraved tabular numerals for dials, tablets, counters.
  static TextStyle get numeral => TextStyle(
        fontFamily: displayFamily,
        fontWeight: FontWeight.w700,
        color: lampCream,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get numeralOnBrass => TextStyle(
        fontFamily: displayFamily,
        fontWeight: FontWeight.w700,
        color: walnutDark,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
