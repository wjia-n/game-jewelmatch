import 'dart:math';
import 'package:flutter/material.dart';

/// Gem cut styles — the silhouettes every gemstone can be cut in.
/// All stay inside the vintage jeweler's atelier world (real cuts a
/// jeweler would know); the renderer draws faceted pseudo-3D stones for
/// each outline. First 3 are free; the rest are PRO.
class GemCutDef {
  final String id;
  final String name;
  const GemCutDef({required this.id, required this.name});
}

class GemCuts {
  static const List<GemCutDef> all = [
    GemCutDef(id: 'round_brilliant', name: 'Round Brilliant'),
    GemCutDef(id: 'cushion', name: 'Cushion'),
    GemCutDef(id: 'oval', name: 'Oval'),
    GemCutDef(id: 'emerald_cut', name: 'Emerald Cut'),
    GemCutDef(id: 'pear', name: 'Pear'),
    GemCutDef(id: 'marquise', name: 'Marquise'),
    GemCutDef(id: 'princess', name: 'Princess'),
    GemCutDef(id: 'heart', name: 'Heart'),
    GemCutDef(id: 'trillion', name: 'Trillion'),
  ];

  static const List<String> freeIds = [
    'round_brilliant',
    'cushion',
    'oval',
  ];

  static GemCutDef byId(String id) =>
      all.firstWhere((d) => d.id == id, orElse: () => all[0]);

  /// Outline polygon (centered on [c], radius [rad]) for a cut style.
  /// Used by GemRenderer to draw faceted stones in every silhouette.
  static List<Offset> outline(String styleId, Offset c, double rad) {
    switch (styleId) {
      case 'cushion':
        return _poly(c, rad, 8, pi / 8);
      case 'oval':
        return _ellipse(c, rad, rad * 0.76, 14);
      case 'emerald_cut':
        return _chamferedRect(c, rad, rad * 0.78, rad * 0.28);
      case 'pear':
        return _pear(c, rad);
      case 'marquise':
        return _marquise(c, rad);
      case 'princess':
        return _poly(c, rad * 0.98, 4, pi / 4);
      case 'heart':
        return _heart(c, rad);
      case 'trillion':
        return _poly(c, rad, 3, -pi / 2, smooth: true);
      case 'round_brilliant':
      default:
        return _poly(c, rad, 14, 0);
    }
  }

  static List<Offset> _poly(
      Offset c, double rad, int n, double phase,
      {bool smooth = false}) {
    final pts = <Offset>[];
    final steps = smooth ? n * 4 : n;
    for (int i = 0; i < steps; i++) {
      final a = phase + i * 2 * pi / steps;
      // For smoothed polygons (trillion), round the corners.
      var r = rad;
      if (smooth) {
        final t = ((i % 4) / 4 - 0.5).abs() * 2; // 0 at edge mid, 1 at corner
        r = rad * (1 - 0.12 * t * t);
      }
      pts.add(Offset(c.dx + cos(a) * r, c.dy + sin(a) * r));
    }
    return pts;
  }

  static List<Offset> _ellipse(Offset c, double rx, double ry, int n) {
    return [
      for (int i = 0; i < n; i++)
        Offset(c.dx + cos(i * 2 * pi / n) * rx,
            c.dy + sin(i * 2 * pi / n) * ry),
    ];
  }

  static List<Offset> _chamferedRect(
      Offset c, double hw, double hh, double ch) {
    // Emerald cut: rectangle with cut corners (octagon).
    return [
      Offset(c.dx - hw + ch, c.dy - hh),
      Offset(c.dx + hw - ch, c.dy - hh),
      Offset(c.dx + hw, c.dy - hh + ch),
      Offset(c.dx + hw, c.dy + hh - ch),
      Offset(c.dx + hw - ch, c.dy + hh),
      Offset(c.dx - hw + ch, c.dy + hh),
      Offset(c.dx - hw, c.dy + hh - ch),
      Offset(c.dx - hw, c.dy - hh + ch),
    ];
  }

  static List<Offset> _pear(Offset c, double rad) {
    // Teardrop: pointed top, round bottom.
    final pts = <Offset>[];
    for (int i = 0; i < 16; i++) {
      final a = -pi / 2 + i * 2 * pi / 16;
      final k = 1 - 0.38 * sin(a + pi / 2) * -1;
      final rr = rad * (0.72 + 0.28 * (1 - (sin(a) + 1) / 2) * 1.15);
      pts.add(Offset(c.dx + cos(a) * rr * k, c.dy + sin(a) * rr));
    }
    return pts;
  }

  static List<Offset> _marquise(Offset c, double rad) {
    // Navette: pointed oval, long axis horizontal.
    final pts = <Offset>[];
    for (int i = 0; i < 14; i++) {
      final a = i * 2 * pi / 14;
      final pinch = pow(cos(a).abs(), 0.65).toDouble();
      pts.add(Offset(
        c.dx + cos(a) * rad,
        c.dy + sin(a) * rad * 0.58 * (0.35 + 0.65 * pinch),
      ));
    }
    return pts;
  }

  static List<Offset> _heart(Offset c, double rad) {
    final pts = <Offset>[];
    for (int i = 0; i < 20; i++) {
      final t = i * 2 * pi / 20;
      // Classic heart param curve, scaled and flipped (y down).
      final x = 16 * pow(sin(t), 3);
      final y = 13 * cos(t) -
          5 * cos(2 * t) -
          2 * cos(3 * t) -
          cos(4 * t);
      pts.add(Offset(
        c.dx + x / 16 * rad * 0.95,
        c.dy - y / 16 * rad * 0.95 + rad * 0.08,
      ));
    }
    return pts;
  }
}
