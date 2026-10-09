import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/atelier.dart';

/// Physical atelier widget library — velvet, walnut, brass and faceted
/// gemstones, rendered natively in Flutter from the Stitch art direction
/// (stitch-batch5/jewelmatch/DESIGN.md). No neon, no Material look.

/// Burgundy velvet backdrop: radial lamplight from the upper left,
/// vignette edges, subtle fabric noise.
class VelvetBackdrop extends StatelessWidget {
  final Widget child;
  const VelvetBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.45, -0.55),
          radius: 1.35,
          colors: [
            Color(0xFF6E2A38),
            Atelier.velvet,
            Atelier.velvetDeep,
            Color(0xFF220C13),
          ],
          stops: [0.0, 0.45, 0.78, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _VelvetGrainPainter(),
        child: child,
      ),
    );
  }
}

class _VelvetGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(77);
    final paint = Paint()..strokeWidth = 1.0;
    for (int i = 0; i < 90; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final len = 6 + rng.nextDouble() * 14;
      paint.color =
          Colors.black.withValues(alpha: 0.03 + rng.nextDouble() * 0.04);
      canvas.drawLine(Offset(x, y), Offset(x + len * 0.3, y + len), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Walnut display-case panel with beveled edges and wood grain.
class WalnutPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  const WalnutPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.radius = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Atelier.walnutLight,
            Atelier.walnutMid,
            Atelier.walnutDark,
            Color(0xFF1E1209),
          ],
          stops: [0.0, 0.35, 0.75, 1.0],
        ),
        border: Border.all(color: Atelier.brassDeep, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Colors.black54, blurRadius: 16, offset: Offset(0, 7)),
          BoxShadow(
              color: Colors.white10, blurRadius: 2, offset: Offset(0, -1)),
        ],
      ),
      child: CustomPaint(
        painter: _WoodGrainPainter(),
        child: child,
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (int i = 0; i < 14; i++) {
      final y = rng.nextDouble() * size.height;
      paint.color = Colors.black.withValues(alpha: 0.06 + rng.nextDouble() * 0.06);
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 36) {
        path.lineTo(x, y + sin(x / 80 + i * 1.7) * 5 + rng.nextDouble() * 2);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// A beveled brass plaque button with corner rivets and engraved lettering.
class BrassButton extends StatefulWidget {
  final String label;
  final String? sublabel;
  final VoidCallback? onTap;
  final bool primary;
  final double fontSize;

  const BrassButton({
    super.key,
    required this.label,
    this.sublabel,
    this.onTap,
    this.primary = true,
    this.fontSize = 20,
  });

  @override
  State<BrassButton> createState() => _BrassButtonState();
}

class _BrassButtonState extends State<BrassButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: widget.primary
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Atelier.brassBright,
                        Atelier.brass,
                        Atelier.brassDeep
                      ],
                      stops: [0.0, 0.55, 1.0],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Atelier.walnutMid, Color(0xFF241408)],
                    ),
              border: Border.all(
                color: widget.primary
                    ? Atelier.walnutDark
                    : Atelier.brassDeep,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: _down ? 4 : 10,
                  offset: Offset(0, _down ? 2 : 5),
                ),
                BoxShadow(
                  color: Colors.white
                      .withValues(alpha: widget.primary ? 0.25 : 0.07),
                  blurRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: (widget.primary
                                ? Atelier.displayOnBrass
                                : Atelier.display)
                            .copyWith(
                                fontSize: widget.fontSize,
                                letterSpacing: 2.0),
                      ),
                      if (widget.sublabel != null)
                        Text(
                          widget.sublabel!,
                          textAlign: TextAlign.center,
                          style: Atelier.bodyItalic.copyWith(
                            fontSize: 12,
                            color: widget.primary
                                ? Atelier.walnutDark
                                : Atelier.brassBright,
                          ),
                        ),
                    ],
                  ),
                ),
                for (final pos in const [
                  Alignment.topLeft,
                  Alignment.topRight,
                  Alignment.bottomLeft,
                  Alignment.bottomRight,
                ])
                  Align(
                    alignment: pos,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFFF5D9A0),
                            Atelier.brassDeep
                          ],
                        ),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black54,
                              blurRadius: 2,
                              offset: Offset(0, 1))
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round brass icon button (pause, back, hint loupe).
class BrassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final String? badge;
  const BrassIconButton(
      {super.key,
      required this.icon,
      this.onTap,
      this.size = 46,
      this.badge});

  @override
  State<BrassIconButton> createState() => _BrassIconButtonState();
}

class _BrassIconButtonState extends State<BrassIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.35, -0.35),
                  radius: 1.2,
                  colors: [
                    Atelier.brassBright,
                    Atelier.brass,
                    Atelier.brassDeep
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
                border:
                    Border.all(color: Atelier.walnutDark, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: _down ? 3 : 8,
                    offset: Offset(0, _down ? 2 : 4),
                  ),
                ],
              ),
              child: Icon(widget.icon,
                  color: Atelier.walnutDark, size: widget.size * 0.48),
            ),
            if (widget.badge != null)
              Positioned(
                right: -4,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Atelier.velvetDeep,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Atelier.brassBright, width: 1),
                  ),
                  child: Text(widget.badge!,
                      style: Atelier.caption.copyWith(fontSize: 10)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Brass toggle switch for settings.
class BrassToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const BrassToggle(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 62,
        height: 33,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: value ? Atelier.brassDeep : const Color(0xFF241708),
          border: Border.all(color: Atelier.brass, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        alignment:
            value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 25,
          height: 25,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(-0.3, -0.3),
              colors: [
                Color(0xFFF5D9A0),
                Atelier.brass,
                Atelier.brassDeep
              ],
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black45,
                  blurRadius: 3,
                  offset: Offset(0, 1))
            ],
          ),
        ),
      ),
    );
  }
}

/// Brass-inlaid slider for volume.
class BrassSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const BrassSlider(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 8,
        activeTrackColor: Atelier.brass,
        inactiveTrackColor: const Color(0xFF241708),
        thumbColor: Atelier.brassBright,
        thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayShape:
            const RoundSliderOverlayShape(overlayRadius: 20),
        overlayColor: Atelier.brass.withValues(alpha: 0.25),
      ),
      child: Slider(value: value, onChanged: onChanged),
    );
  }
}

/// Engraved divider with a center diamond.
class EngravedDivider extends StatelessWidget {
  const EngravedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
            child: Divider(color: Atelier.brassDeep, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Transform.rotate(
            angle: pi / 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Atelier.brass,
                border:
                    Border.all(color: Atelier.brassBright, width: 1),
              ),
            ),
          ),
        ),
        const Expanded(
            child: Divider(color: Atelier.brassDeep, thickness: 1)),
      ],
    );
  }
}

/// Brass star medal with ribbon (earned / unearned states).
class StarMedal extends StatelessWidget {
  final bool earned;
  final double size;
  const StarMedal({super.key, this.earned = false, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.28,
      child: CustomPaint(painter: _StarMedalPainter(earned)),
    );
  }
}

class _StarMedalPainter extends CustomPainter {
  final bool earned;
  _StarMedalPainter(this.earned);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // ribbon
    final ribbon = Paint()
      ..color = earned ? Atelier.velvet : Atelier.velvetDeep;
    final rw = size.width * 0.30;
    canvas.drawRect(
        Rect.fromLTWH(cx - rw / 2, 0, rw, size.height * 0.42), ribbon);
    canvas.drawRect(
        Rect.fromLTWH(cx - rw / 2, 0, rw * 0.32, size.height * 0.42),
        Paint()..color = Colors.black.withValues(alpha: 0.25));
    // medallion
    final c = Offset(cx, size.height * 0.62);
    final r = size.width * 0.44;
    final body = Paint()
      ..color = earned ? Atelier.brass : const Color(0xFF4A3A24);
    final edge = Paint()
      ..color = earned ? Atelier.brassBright : Atelier.creamFaint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
        c + const Offset(0, 3), r, Paint()..color = Colors.black45);
    canvas.drawCircle(c, r, body);
    canvas.drawCircle(c, r, edge);
    canvas.drawCircle(c, r * 0.72, edge);
    // star
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final a = -pi / 2 + i * pi / 5;
      final rr = i.isEven ? r * 0.58 : r * 0.26;
      final p = Offset(c.dx + cos(a) * rr, c.dy + sin(a) * rr);
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(
        star,
        Paint()
          ..color = earned
              ? Atelier.lampCream
              : Colors.black.withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(covariant _StarMedalPainter old) =>
      old.earned != earned;
}

/// A faceted pseudo-3D gemstone: cushion-cut with visible facet planes,
/// bevel highlights and a soft drop shadow. Lamp light from upper left.
class GemStone extends StatelessWidget {
  final int type;
  final int special;
  final double size;
  final bool lifted;

  const GemStone({
    super.key,
    required this.type,
    this.special = 0,
    required this.size,
    this.lifted = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GemPainter(
          base: Atelier.gemBase[type.clamp(0, 5)],
          special: special,
          lifted: lifted,
        ),
      ),
    );
  }
}

/// Shared faceted-gem renderer used by [GemStone] and the animated board
/// painter. Pseudo-3D cushion-cut gemstones with facet planes, bevel
/// highlights and soft drop shadows; lamp light from the upper left.
class GemRenderer {
  GemRenderer._();

  static void paint(Canvas canvas, Offset c, double r, int type, int special,
      {bool lifted = false, double scale = 1.0, double alpha = 1.0}) {
    final base = Atelier.gemBase[type.clamp(0, 5)];
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(scale, scale);
    if (alpha < 1.0) {
      canvas.translate(-c.dx, -c.dy);
      _paintWithAlpha(canvas, c, r, base, special, lifted, alpha);
      canvas.restore();
      return;
    }
    canvas.translate(-c.dx, -c.dy);
    _paintBody(canvas, c, r, base, special, lifted);
    canvas.restore();
  }

  static void _paintWithAlpha(Canvas canvas, Offset c, double r, Color base,
      int special, bool lifted, double alpha) {
    final layer = Paint()..color = Colors.white.withValues(alpha: alpha);
    canvas.saveLayer(
        Rect.fromCircle(center: c, radius: r * 1.4), layer);
    _paintBody(canvas, c, r, base, special, lifted);
    canvas.restore();
  }

  static void _paintBody(Canvas canvas, Offset c, double r, Color base,
      int special, bool lifted) {
    if (special == 2) {
      _prismatic(canvas, c, r, lifted);
      return;
    }
    if (special == 1) {
      _bar(canvas, c, r, base);
      return;
    }
    if (special == 3) {
      _brilliant(canvas, c, r, base, lifted);
      return;
    }
    _cushion(canvas, c, r, base, lifted);
  }

  static void _shadow(Canvas canvas, Offset c, double r, bool lifted) {
    canvas.drawOval(
      Rect.fromCenter(
          center: c + Offset(r * 0.12, r * (lifted ? 0.55 : 0.32)),
          width: r * 1.5,
          height: r * (lifted ? 0.5 : 0.32)),
      Paint()..color = Colors.black.withValues(alpha: lifted ? 0.45 : 0.38),
    );
  }

  /// Standard cushion-cut gem with facet planes.
  static void _cushion(
      Canvas canvas, Offset c, double r, Color col, bool lifted) {
    _shadow(canvas, c, r, lifted);
    final rad = lifted ? r * 0.96 : r * 0.88;
    final dark = Atelier.gemDark(col);
    final light = Atelier.gemLight(col);

    // base cushion (octagon)
    final pts = <Offset>[];
    for (int i = 0; i < 8; i++) {
      final a = pi / 8 + i * pi / 4;
      pts.add(Offset(c.dx + cos(a) * rad, c.dy + sin(a) * rad));
    }
    final basePath = Path()..addPolygon(pts, true);
    canvas.drawPath(basePath, Paint()..color = col);

    // facet planes: triangles from center, alternating light/dark by lamp
    for (int i = 0; i < 8; i++) {
      final p1 = pts[i];
      final p2 = pts[(i + 1) % 8];
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      // lamp is upper-left: facets facing up-left are lighter
      final facing = (c.dx - mid.dx) + (c.dy - mid.dy);
      final facet = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();
      canvas.drawPath(
          facet,
          Paint()
            ..color =
                (facing > 0 ? light : dark).withValues(alpha: 0.55));
    }
    // table (top facet)
    final table = Path()
      ..addPolygon(
          [
            for (int i = 0; i < 8; i++)
              Offset(c.dx + (pts[i].dx - c.dx) * 0.45,
                  c.dy + (pts[i].dy - c.dy) * 0.45)
          ],
          true);
    canvas.drawPath(table, Paint()..color = light.withValues(alpha: 0.8));
    // specular highlight, upper left
    canvas.drawOval(
      Rect.fromCenter(
          center: c + Offset(-rad * 0.28, -rad * 0.34),
          width: rad * 0.52,
          height: rad * 0.34),
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
    // bevel edge
    canvas.drawPath(
        basePath,
        Paint()
          ..color = dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, r * 0.06));
    canvas.drawPath(
        Path()
          ..addPolygon(
              [
                for (final p in pts)
                  Offset(c.dx + (p.dx - c.dx) * 0.94,
                      c.dy + (p.dy - c.dy) * 0.94)
              ],
              true),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.0, r * 0.03));
  }

  /// Faceted Bar: elongated horizontal bar gem (match-4 special).
  static void _bar(Canvas canvas, Offset c, double r, Color base) {
    final w = r * 1.84, h = r * 1.04;
    final dark = Atelier.gemDark(base);
    final light = Atelier.gemLight(base);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: c + const Offset(2, 4), width: w, height: h),
          const Radius.circular(8)),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );
    final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: w, height: h),
        const Radius.circular(8));
    canvas.drawRRect(rect, Paint()..color = base);
    // vertical facet stripes
    for (int i = 0; i < 5; i++) {
      final x = c.dx - w / 2 + w * (i + 0.5) / 5;
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(x, c.dy),
            width: w / 5 * 0.86,
            height: h * 0.92),
        Paint()
          ..color = (i.isEven ? light : dark).withValues(alpha: 0.6),
      );
    }
    canvas.drawRRect(
        rect,
        Paint()
          ..color = dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    // top sheen
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: c + Offset(0, -h * 0.22),
              width: w * 0.9,
              height: h * 0.28),
          const Radius.circular(6)),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  /// Prismatic Diamond: radiant 12-point star (match-5 special).
  static void _prismatic(Canvas canvas, Offset c, double r, bool lifted) {
    _shadow(canvas, c, r, lifted);
    final rad = r * 0.92;
    final star = Path();
    for (int i = 0; i < 24; i++) {
      final a = i * pi / 12;
      final rr = i.isEven ? rad : rad * 0.58;
      final p = Offset(c.dx + cos(a) * rr, c.dy + sin(a) * rr);
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(
        star,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.3),
            colors: [
              Colors.white,
              Atelier.diamond,
              Color(0xFF9FB3BE),
            ],
            stops: [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: rad)));
    canvas.drawCircle(
        c, rad * 0.3, Paint()..color = Colors.white.withValues(alpha: 0.95));
    canvas.drawPath(
        star,
        Paint()
          ..color = const Color(0xFF9FB3BE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  /// Brilliant: round brilliant with radial facets (L/T special).
  static void _brilliant(
      Canvas canvas, Offset c, double r, Color base, bool lifted) {
    _shadow(canvas, c, r, lifted);
    final rad = r * 0.9;
    final dark = Atelier.gemDark(base);
    final light = Atelier.gemLight(base);
    canvas.drawCircle(c, rad, Paint()..color = base);
    for (int i = 0; i < 12; i++) {
      final a1 = i * pi / 6;
      final a2 = (i + 1) * pi / 6;
      final tri = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + cos(a1) * rad, c.dy + sin(a1) * rad)
        ..lineTo(c.dx + cos(a2) * rad, c.dy + sin(a2) * rad)
        ..close();
      canvas.drawPath(
          tri,
          Paint()
            ..color =
                (i.isEven ? light : dark).withValues(alpha: 0.6));
    }
    canvas.drawCircle(
        c, rad * 0.42, Paint()..color = light.withValues(alpha: 0.9));
    canvas.drawCircle(
        c, rad * 0.16, Paint()..color = Colors.white.withValues(alpha: 0.95));
    canvas.drawCircle(
        c,
        rad,
        Paint()
          ..color = dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }
}

class _GemPainter extends CustomPainter {
  final Color base;
  final int special;
  final bool lifted;
  _GemPainter(
      {required this.base, required this.special, required this.lifted});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final type = Atelier.gemBase.indexOf(base);
    GemRenderer.paint(canvas, c, size.width / 2,
        type < 0 ? 0 : type, special,
        lifted: lifted);
  }

  @override
  bool shouldRepaint(covariant _GemPainter old) =>
      old.base != base ||
      old.special != special ||
      old.lifted != lifted;
}

/// Brass name plaque: engraved title on brass.
class BrassPlaque extends StatelessWidget {
  final String text;
  final double fontSize;
  final double letterSpacing;
  const BrassPlaque(
      {super.key,
      required this.text,
      this.fontSize = 22,
      this.letterSpacing = 3.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Atelier.brassBright,
            Atelier.brass,
            Atelier.brassDeep
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: Atelier.walnutDark, width: 2),
        boxShadow: const [
          BoxShadow(
              color: Colors.black54, blurRadius: 10, offset: Offset(0, 5)),
          BoxShadow(
              color: Colors.white24, blurRadius: 2, offset: Offset(0, -1)),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Atelier.displayOnBrass.copyWith(
            fontSize: fontSize, letterSpacing: letterSpacing),
      ),
    );
  }
}

/// Moves-left dial: brass ring with engraved number.
class MovesDial extends StatelessWidget {
  final int moves;
  final double size;
  const MovesDial({super.key, required this.moves, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final low = moves <= 5;
    return SizedBox(
      width: size,
      height: size + 14,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.3),
                colors: [
                  Atelier.brassBright,
                  Atelier.brass,
                  Atelier.brassDeep
                ],
                stops: [0.0, 0.55, 1.0],
              ),
              border: Border.all(color: Atelier.walnutDark, width: 2.5),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Center(
              child: Text(
                '$moves',
                style: Atelier.numeralOnBrass
                    .copyWith(fontSize: size * 0.42),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text('MOVES',
              style: Atelier.caption.copyWith(
                  fontSize: 10,
                  color: low ? Atelier.coinGold : Atelier.creamDim)),
        ],
      ),
    );
  }
}

/// Score tablet: brass plate with engraved score + target progress.
class ScorePlate extends StatelessWidget {
  final int score;
  final int target;
  const ScorePlate({super.key, required this.score, required this.target});

  @override
  Widget build(BuildContext context) {
    final p = (score / target).clamp(0.0, 1.0);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Atelier.brassBright,
            Atelier.brass,
            Atelier.brassDeep
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: Atelier.walnutDark, width: 2),
        boxShadow: const [
          BoxShadow(
              color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SCORE', style: Atelier.caption.copyWith(
              color: Atelier.walnutDark, fontSize: 10)),
          Text('$_fmt(score)',
              style: Atelier.numeralOnBrass.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          SizedBox(
            width: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: p,
                minHeight: 7,
                backgroundColor:
                    Atelier.walnutDark.withValues(alpha: 0.45),
                valueColor: AlwaysStoppedAnimation<Color>(
                    p >= 1 ? Atelier.emerald : Atelier.walnutDark),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text('GOAL ${_fmt(target)}',
              style: Atelier.caption.copyWith(
                  color: Atelier.walnutDark, fontSize: 10)),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

/// Quota inset: velvet navy inset showing collection progress.
class QuotaInset extends StatelessWidget {
  final int tier;
  final int collected;
  final int count;
  const QuotaInset(
      {super.key,
      required this.tier,
      required this.collected,
      required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Atelier.velvetNavyDeep,
        border: Border.all(color: Atelier.brassDeep, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GemStone(type: tier, size: 26),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('COLLECT ${Atelier.gemNames[tier].toUpperCase()}',
                  style: Atelier.caption.copyWith(fontSize: 10)),
              Text('$collected / $count',
                  style: Atelier.numeral.copyWith(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
