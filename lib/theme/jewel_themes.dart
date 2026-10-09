import 'dart:convert';
import 'package:flutter/material.dart';

/// Atelier theme catalog — the velvet tray, walnut case and lamplight of
/// each workbench. Every theme stays inside the vintage jeweler's atelier
/// material world (deep velvets, dark walnut, warm lamplight); the variety
/// comes from different velvets, woods and moods. First 4 are FREE, the
/// rest are PRO. A PRO custom theme can also be built from a color JSON.
class AtelierThemeDef {
  final String id;
  final String name;
  final Color velvet; // tray backdrop
  final Color velvetDeep; // tray shadow/inset
  final Color cell; // recessed board cell
  final Color cellDeep; // cell inset shadow
  final Color woodDark; // display-case frame
  final Color woodMid; // panel slats
  final Color woodLight; // wood highlight
  final Color cream; // primary text
  final Color creamDim; // secondary text
  final Color coin; // coin gold

  const AtelierThemeDef({
    required this.id,
    required this.name,
    required this.velvet,
    required this.velvetDeep,
    required this.cell,
    required this.cellDeep,
    required this.woodDark,
    required this.woodMid,
    required this.woodLight,
    required this.cream,
    required this.creamDim,
    required this.coin,
  });

  Map<String, int> toJsonMap() => {
        'velvet': velvet.toARGB32(),
        'velvetDeep': velvetDeep.toARGB32(),
        'cell': cell.toARGB32(),
        'cellDeep': cellDeep.toARGB32(),
        'woodDark': woodDark.toARGB32(),
        'woodMid': woodMid.toARGB32(),
        'woodLight': woodLight.toARGB32(),
        'cream': cream.toARGB32(),
        'creamDim': creamDim.toARGB32(),
        'coin': coin.toARGB32(),
      };

  static AtelierThemeDef fromJsonMap(String name, Map<String, dynamic> m) {
    int c(String k, int fb) => (m[k] as num?)?.toInt() ?? fb;
    Color cc(String k, int fb) => Color(c(k, fb));
    return AtelierThemeDef(
      id: 'custom',
      name: name,
      velvet: cc('velvet', 0xFF5A1F2B),
      velvetDeep: cc('velvetDeep', 0xFF3A1420),
      cell: cc('cell', 0xFF1E2A4A),
      cellDeep: cc('cellDeep', 0xFF141D33),
      woodDark: cc('woodDark', 0xFF2E1D12),
      woodMid: cc('woodMid', 0xFF4A3220),
      woodLight: cc('woodLight', 0xFF6B4A2E),
      cream: cc('cream', 0xFFF2E7CF),
      creamDim: cc('creamDim', 0xFFC9B894),
      coin: cc('coin', 0xFFE3B341),
    );
  }
}

/// Metal accents for brass-work (plaques, buttons, dials, toggles).
class MetalAccent {
  final String id;
  final String name;
  final Color base;
  final Color bright;
  final Color deep;
  const MetalAccent({
    required this.id,
    required this.name,
    required this.base,
    required this.bright,
    required this.deep,
  });
}

class AtelierThemes {
  static const List<String> freeThemeIds = [
    'burgundy_velvet',
    'navy_noir',
    'emerald_study',
    'walnut_gold',
  ];

  static const List<AtelierThemeDef> all = [
    // 1 — canonical Stitch palette (DESIGN.md)
    AtelierThemeDef(
      id: 'burgundy_velvet',
      name: 'Burgundy Velvet',
      velvet: Color(0xFF5A1F2B),
      velvetDeep: Color(0xFF3A1420),
      cell: Color(0xFF1E2A4A),
      cellDeep: Color(0xFF141D33),
      woodDark: Color(0xFF2E1D12),
      woodMid: Color(0xFF4A3220),
      woodLight: Color(0xFF6B4A2E),
      cream: Color(0xFFF2E7CF),
      creamDim: Color(0xFFC9B894),
      coin: Color(0xFFE3B341),
    ),
    // 2
    AtelierThemeDef(
      id: 'navy_noir',
      name: 'Navy Noir',
      velvet: Color(0xFF1E2A4A),
      velvetDeep: Color(0xFF141D33),
      cell: Color(0xFF3A1C2A),
      cellDeep: Color(0xFF2A1420),
      woodDark: Color(0xFF1A1410),
      woodMid: Color(0xFF33261A),
      woodLight: Color(0xFF54402A),
      cream: Color(0xFFF0E9D6),
      creamDim: Color(0xFFB9AC8E),
      coin: Color(0xFFE3B341),
    ),
    // 3
    AtelierThemeDef(
      id: 'emerald_study',
      name: 'Emerald Study',
      velvet: Color(0xFF1E4D3B),
      velvetDeep: Color(0xFF123324),
      cell: Color(0xFF2A3A4A),
      cellDeep: Color(0xFF1C2836),
      woodDark: Color(0xFF2A1E12),
      woodMid: Color(0xFF463322),
      woodLight: Color(0xFF63482E),
      cream: Color(0xFFF2EAD2),
      creamDim: Color(0xFFC2B48E),
      coin: Color(0xFFE8C547),
    ),
    // 4
    AtelierThemeDef(
      id: 'walnut_gold',
      name: 'Walnut & Gold',
      velvet: Color(0xFF4A3220),
      velvetDeep: Color(0xFF33220F),
      cell: Color(0xFF5A1F2B),
      cellDeep: Color(0xFF3F1620),
      woodDark: Color(0xFF241610),
      woodMid: Color(0xFF3E2A18),
      woodLight: Color(0xFF5C4026),
      cream: Color(0xFFF6ECD4),
      creamDim: Color(0xFFCBB98F),
      coin: Color(0xFFF0C84E),
    ),
    // 5 — PRO
    AtelierThemeDef(
      id: 'midnight_vault',
      name: 'Midnight Vault',
      velvet: Color(0xFF141D33),
      velvetDeep: Color(0xFF0C1220),
      cell: Color(0xFF232B3D),
      cellDeep: Color(0xFF161C29),
      woodDark: Color(0xFF14100C),
      woodMid: Color(0xFF2A2118),
      woodLight: Color(0xFF453824),
      cream: Color(0xFFEDE6D2),
      creamDim: Color(0xFFA89B7E),
      coin: Color(0xFFD9A83C),
    ),
    // 6 — PRO
    AtelierThemeDef(
      id: 'bordeaux_rose',
      name: 'Bordeaux Rose',
      velvet: Color(0xFF6E2434),
      velvetDeep: Color(0xFF4A1826),
      cell: Color(0xFF2E3A55),
      cellDeep: Color(0xFF1F2740),
      woodDark: Color(0xFF2E1D12),
      woodMid: Color(0xFF4E3524),
      woodLight: Color(0xFF6E4C32),
      cream: Color(0xFFF7E8D2),
      creamDim: Color(0xFFD0B992),
      coin: Color(0xFFE8BE52),
    ),
    // 7 — PRO
    AtelierThemeDef(
      id: 'sapphire_hall',
      name: 'Sapphire Hall',
      velvet: Color(0xFF274069),
      velvetDeep: Color(0xFF1A2C4A),
      cell: Color(0xFF4A2438),
      cellDeep: Color(0xFF351A29),
      woodDark: Color(0xFF201812),
      woodMid: Color(0xFF3A2C1E),
      woodLight: Color(0xFF58432C),
      cream: Color(0xFFF1EAD8),
      creamDim: Color(0xFFBCAF90),
      coin: Color(0xFFE3B341),
    ),
    // 8 — PRO
    AtelierThemeDef(
      id: 'forest_atelier',
      name: 'Forest Atelier',
      velvet: Color(0xFF2E4A2E),
      velvetDeep: Color(0xFF1E331E),
      cell: Color(0xFF3D3A24),
      cellDeep: Color(0xFF2B2918),
      woodDark: Color(0xFF241A10),
      woodMid: Color(0xFF3F2F1C),
      woodLight: Color(0xFF5B452A),
      cream: Color(0xFFF3EBD4),
      creamDim: Color(0xFFC4B48C),
      coin: Color(0xFFDDB43E),
    ),
    // 9 — PRO
    AtelierThemeDef(
      id: 'charcoal_silk',
      name: 'Charcoal Silk',
      velvet: Color(0xFF2E2E34),
      velvetDeep: Color(0xFF1E1E24),
      cell: Color(0xFF4A2438),
      cellDeep: Color(0xFF331824),
      woodDark: Color(0xFF1C1712),
      woodMid: Color(0xFF33291E),
      woodLight: Color(0xFF4E402C),
      cream: Color(0xFFEFE7D2),
      creamDim: Color(0xFFB3A586),
      coin: Color(0xFFE0B444),
    ),
    // 10 — PRO
    AtelierThemeDef(
      id: 'plum_royal',
      name: 'Plum Royal',
      velvet: Color(0xFF4A1F4D),
      velvetDeep: Color(0xFF331537),
      cell: Color(0xFF24344A),
      cellDeep: Color(0xFF182231),
      woodDark: Color(0xFF261512),
      woodMid: Color(0xFF42291E),
      woodLight: Color(0xFF5E3D2C),
      cream: Color(0xFFF4E9D6),
      creamDim: Color(0xFFC8B28E),
      coin: Color(0xFFE6BA48),
    ),
    // 11 — PRO
    AtelierThemeDef(
      id: 'teal_cabinet',
      name: 'Teal Cabinet',
      velvet: Color(0xFF1F4A4E),
      velvetDeep: Color(0xFF143136),
      cell: Color(0xFF4A2E24),
      cellDeep: Color(0xFF331F18),
      woodDark: Color(0xFF221812),
      woodMid: Color(0xFF3C2C1E),
      woodLight: Color(0xFF58412C),
      cream: Color(0xFFF2EAD4),
      creamDim: Color(0xFFC0B08A),
      coin: Color(0xFFDFB23E),
    ),
    // 12 — PRO
    AtelierThemeDef(
      id: 'crimson_court',
      name: 'Crimson Court',
      velvet: Color(0xFF7A1E28),
      velvetDeep: Color(0xFF541420),
      cell: Color(0xFF1E2A4A),
      cellDeep: Color(0xFF141D33),
      woodDark: Color(0xFF2A1812),
      woodMid: Color(0xFF482C1E),
      woodLight: Color(0xFF66402C),
      cream: Color(0xFFF8EAD2),
      creamDim: Color(0xFFD4BC92),
      coin: Color(0xFFF0C24C),
    ),
    // 13 — PRO
    AtelierThemeDef(
      id: 'amber_den',
      name: 'Amber Den',
      velvet: Color(0xFF5C3A16),
      velvetDeep: Color(0xFF3F270E),
      cell: Color(0xFF2E3A4A),
      cellDeep: Color(0xFF1F2835),
      woodDark: Color(0xFF201510),
      woodMid: Color(0xFF3A281A),
      woodLight: Color(0xFF563C26),
      cream: Color(0xFFF6ECD2),
      creamDim: Color(0xFFCBB489),
      coin: Color(0xFFF5CE55),
    ),
  ];

  static const List<MetalAccent> accents = [
    MetalAccent(
      id: 'brass',
      name: 'Polished Brass',
      base: Color(0xFFB98A3E),
      bright: Color(0xFFD4AF6A),
      deep: Color(0xFF7C5A26),
    ),
    MetalAccent(
      id: 'copper',
      name: 'Hammered Copper',
      base: Color(0xFFB87347),
      bright: Color(0xFFE09E5A),
      deep: Color(0xFF7E4F22),
    ),
    MetalAccent(
      id: 'silver',
      name: 'Sterling Silver',
      base: Color(0xFFB9BDC9),
      bright: Color(0xFFE4E8F2),
      deep: Color(0xFF7E8494),
    ),
    MetalAccent(
      id: 'rose',
      name: 'Rose Gold',
      base: Color(0xFFC08A7A),
      bright: Color(0xFFE8B8A4),
      deep: Color(0xFF8A5A4E),
    ),
    MetalAccent(
      id: 'pewter',
      name: 'Aged Pewter',
      base: Color(0xFF8A8578),
      bright: Color(0xFFB8B2A2),
      deep: Color(0xFF5C574A),
    ),
  ];

  static AtelierThemeDef byId(String id, {String? customJson}) {
    if (id == 'custom' && customJson != null) {
      try {
        final m = jsonDecode(customJson) as Map<String, dynamic>;
        return AtelierThemeDef.fromJsonMap('My Atelier', m);
      } catch (_) {}
    }
    return all.firstWhere((d) => d.id == id, orElse: () => all[0]);
  }

  static MetalAccent accentById(String id) =>
      accents.firstWhere((a) => a.id == id, orElse: () => accents[0]);

  static bool isFree(String id) => freeThemeIds.contains(id);
}
