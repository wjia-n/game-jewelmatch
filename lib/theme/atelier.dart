import 'package:flutter/material.dart';

/// Jewel Match — "Vintage jeweler's atelier" design tokens.
/// Visual source of truth: stitch-batch5/jewelmatch/DESIGN.md.
/// Deep velvet trays, dark walnut display-case wood, polished brass,
/// faceted gemstones. Single warm lamp from the upper left. No neon, no glow.
class Atelier {
  Atelier._();

  // ---- Palette (DESIGN.md tokens) ----
  static const velvet = Color(0xFF5A1F2B); // Velvet Burgundy
  static const velvetDeep = Color(0xFF3A1420); // Velvet Burgundy Deep
  static const velvetNavy = Color(0xFF1E2A4A); // Velvet Navy
  static const velvetNavyDeep = Color(0xFF141D33); // navy shadow/inset
  static const walnutDark = Color(0xFF2E1D12); // display-case frames
  static const walnutMid = Color(0xFF4A3220); // panel slats
  static const walnutLight = Color(0xFF6B4A2E); // wood highlight
  static const brass = Color(0xFFB98A3E); // plaques, fittings
  static const brassBright = Color(0xFFD4AF6A); // highlights, engraved edges
  static const brassDeep = Color(0xFF7C5A26); // aged brass shadow
  static const lampCream = Color(0xFFF2E7CF); // primary text
  static const creamDim = Color(0xFFC9B894); // secondary text
  static const creamFaint = Color(0xFF8A7B5E); // muted engraving
  static const coinGold = Color(0xFFE3B341); // coins, rewards
  static const resetRed = Color(0xFF8E2A33); // red-velvet danger button

  // ---- Gem tiers (RULES.md §2) ----
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
  static TextStyle get display => const TextStyle(
        fontFamily: displayFamily,
        fontWeight: FontWeight.w700,
        color: lampCream,
        letterSpacing: 3.0,
      );

  /// Dark engraved text for use ON brass plaques.
  static TextStyle get displayOnBrass => const TextStyle(
        fontFamily: displayFamily,
        fontWeight: FontWeight.w700,
        color: walnutDark,
        letterSpacing: 2.0,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: bodyFamily,
        color: lampCream,
        fontSize: 15,
        height: 1.4,
      );

  static TextStyle get bodyItalic =>
      body.copyWith(fontStyle: FontStyle.italic);

  static TextStyle get caption => const TextStyle(
        fontFamily: bodyFamily,
        color: creamDim,
        fontSize: 12,
        letterSpacing: 1.5,
      );

  /// Engraved tabular numerals for dials, tablets, counters.
  static TextStyle get numeral => const TextStyle(
        fontFamily: displayFamily,
        fontWeight: FontWeight.w700,
        color: lampCream,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  static TextStyle get numeralOnBrass => const TextStyle(
        fontFamily: displayFamily,
        fontWeight: FontWeight.w700,
        color: walnutDark,
        fontFeatures: [FontFeature.tabularFigures()],
      );
}
