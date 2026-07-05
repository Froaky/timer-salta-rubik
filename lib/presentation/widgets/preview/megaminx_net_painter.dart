import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/puzzles/megaminx_simulator.dart';
import 'preview_fit.dart';
import 'puzzle_palettes.dart';

/// Dibuja el net de Megaminx como dos "flores" de 6 pentágonos (geometría de
/// csTimer): a la izquierda U y sus 5 caras vecinas, a la derecha D y las
/// suyas. Las caras U y F llevan etiqueta para orientarse.
class MegaminxNetPainter extends CustomPainter {
  MegaminxNetPainter({required this.facelets, required this.notation});

  final MegaminxFacelets facelets;
  final String notation;

  static const double _cfrac = 0.5;
  static final double _phi = (math.sqrt(5) + 1) / 2;
  static final double _d2x = (1 - _cfrac) / 2 / math.tan(math.pi / 5);

  // Polígonos locales (esquina, arista, centro) de una cara resuelta,
  // apuntando "hacia arriba"; se rotan por múltiplos de 72°.
  static final List<Offset> _cornerShape = [
    const Offset(0, -1),
    Offset(_d2x, -(1 + _cfrac) / 2),
    const Offset(0, -_cfrac),
    Offset(-_d2x, -(1 + _cfrac) / 2),
  ];
  static final List<Offset> _edgeShape = [
    Offset(math.cos(math.pi * 0.1) - _d2x,
        -math.sin(math.pi * 0.1) + (_cfrac - 1) / 2),
    Offset(_d2x, -(1 + _cfrac) / 2),
    const Offset(0, -_cfrac),
    Offset(
      math.sin(math.pi * 0.4) * _cfrac,
      -math.cos(math.pi * 0.4) * _cfrac,
    ),
  ];
  static final List<Offset> _centerShape = List.generate(
    5,
    (i) => Offset(
      math.sin(math.pi * 0.4 * i) * _cfrac,
      -math.cos(math.pi * 0.4 * i) * _cfrac,
    ),
  );

  static const Offset _upFlower = Offset(2.6, 2.2);
  static final Offset _downFlower = Offset(
    2.6 + math.cos(math.pi * 0.1) * 3 * _phi,
    2.2 + math.sin(math.pi * 0.1) * _phi,
  );

  /// Posición y rotación de cada cara (tabla de csTimer).
  static final List<(Offset, double)> _facePlacements = [
    (_upFlower, 0),
    (_upFlower + _polar(0.1) * _phi, math.pi * 0.2),
    (_upFlower + _polar(0.5) * _phi, math.pi * 0.6),
    (_upFlower + _polar(0.9) * _phi, math.pi * 1.0),
    (_upFlower + _polar(1.3) * _phi, math.pi * 1.4),
    (_upFlower + _polar(1.7) * _phi, math.pi * 1.8),
    (_downFlower + _polar(0.7) * _phi, 0),
    (_downFlower + _polar(0.3) * _phi, math.pi * 1.6),
    (_downFlower + _polar(1.9) * _phi, math.pi * 1.2),
    (_downFlower + _polar(1.5) * _phi, math.pi * 0.8),
    (_downFlower + _polar(1.1) * _phi, math.pi * 0.4),
    (_downFlower, math.pi),
  ];

  static Offset _polar(double halfTurns) => Offset(
        math.cos(math.pi * halfTurns),
        math.sin(math.pi * halfTurns),
      );

  @override
  void paint(Canvas canvas, Size size) {
    const contentWidth = 9.8;
    const contentHeight = 4.9;
    PreviewFit.contain(size, contentWidth, contentHeight).applyTo(canvas);

    for (var face = 0; face < 12; face++) {
      _drawFace(canvas, face);
    }

    _drawLabel(canvas, 'U', _facePlacements[0].$1);
    _drawLabel(canvas, 'F', _facePlacements[2].$1);
  }

  void _drawFace(Canvas canvas, int face) {
    final (offset, rotation) = _facePlacements[face];
    final stickers = facelets.faces[face];

    for (var i = 0; i < 5; i++) {
      final angle = math.pi * 2 / 5 * i + rotation;
      _drawSticker(
        canvas,
        _cornerShape,
        angle,
        offset,
        PuzzlePalettes.megaminx[stickers[i]],
      );
      _drawSticker(
        canvas,
        _edgeShape,
        angle,
        offset,
        PuzzlePalettes.megaminx[stickers[i + 5]],
      );
    }
    _drawSticker(
      canvas,
      _centerShape,
      rotation,
      offset,
      PuzzlePalettes.megaminx[stickers[10]],
    );
  }

  void _drawSticker(
    Canvas canvas,
    List<Offset> shape,
    double angle,
    Offset offset,
    Color color,
  ) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final points = shape
        .map(
          (p) => Offset(
            p.dx * cosA - p.dy * sinA + offset.dx,
            p.dx * sinA + p.dy * cosA + offset.dy,
          ),
        )
        .toList(growable: false);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.018
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset center) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 0.42,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant MegaminxNetPainter oldDelegate) =>
      oldDelegate.notation != notation;
}
