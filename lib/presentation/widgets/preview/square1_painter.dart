import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/puzzles/square1_simulator.dart';
import 'preview_fit.dart';
import 'puzzle_palettes.dart';

/// Dibuja el Square-1 con la vista de csTimer: dos discos (capa U a la
/// izquierda, capa D a la derecha) con los stickers laterales como cuñas y el
/// sticker superior como la misma cuña reducida, más la franja de la capa
/// media que muestra si quedó cuadrada o desfasada.
class Square1Painter extends CustomPainter {
  Square1Painter({required this.state, required this.notation});

  final Square1State state;
  final String notation;

  static const double _hsq3 = 0.8660254037844386;
  static const double _sqa = _hsq3 + 1;
  static final double _sqb = _sqa * math.sqrt(2);

  /// Color lateral de las esquinas, indexado por id de pieza (csTimer `ccol`).
  static const String _cornerSideColors = 'RBBLLFFRRFFLLBBR';

  /// Color lateral de las aristas, indexado por id de pieza (csTimer `ecol`).
  static const String _edgeSideColors = 'R-B-L-F-F-L-B-R-';

  // Polígonos locales (sin rotar), anclados al centro del disco.
  static const List<Offset> _edgeSide = [
    Offset(0, 0),
    Offset(-0.5, -_sqa),
    Offset(0.5, -_sqa),
  ];
  static const List<Offset> _cornerSideRight = [
    Offset(0, 0),
    Offset(-0.5, -_sqa),
    Offset(-_sqa, -_sqa),
  ];
  static const List<Offset> _cornerSideLeft = [
    Offset(0, 0),
    Offset(-_sqa, -_sqa),
    Offset(-_sqa, -0.5),
  ];
  static const List<Offset> _cornerTop = [
    Offset(0, 0),
    Offset(-0.5, -_sqa),
    Offset(-_sqa, -_sqa),
    Offset(-_sqa, -0.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final contentWidth = 4 * _sqb;
    final contentHeight = 2 * _sqb;
    PreviewFit.contain(size, contentWidth, contentHeight).applyTo(canvas);

    _drawLayer(canvas, isTop: true);
    _drawLayer(canvas, isTop: false);
    _drawMiddle(canvas);
  }

  void _drawLayer(Canvas canvas, {required bool isTop}) {
    final base = isTop ? 0 : 12;
    final center = Offset(isTop ? _sqb : 3 * _sqb, _sqb);
    final drawn = List<bool>.filled(12, false);

    for (var slot = 0; slot < 12; slot++) {
      if (drawn[slot]) {
        continue;
      }
      final piece = state.pieces[base + slot];
      final isCorner = piece.isOdd;

      if (!isCorner) {
        drawn[slot] = true;
        final angle = -_slotIndexFor(base + slot, edge: true) * math.pi / 6;
        _drawSticker(
          canvas,
          _edgeSide,
          angle,
          center,
          _sideColor(_edgeSideColors[piece]),
        );
        _drawSticker(
          canvas,
          _scaled(_edgeSide, 0.66),
          angle,
          center,
          _faceColor(piece),
        );
        continue;
      }

      // Una esquina ocupa dos slots contiguos; el ancla es el primero. Si la
      // pieza cruza el límite 11|0 el ancla es el slot 11 (csTimer no
      // contempla ese caso y dibuja corrido).
      final nextSlot = (slot + 1) % 12;
      final anchor =
          state.pieces[base + nextSlot] == piece ? slot : (slot + 11) % 12;
      drawn[anchor] = true;
      drawn[(anchor + 1) % 12] = true;

      final angle = -(_slotIndexFor(base + anchor, edge: false)) * math.pi / 6;
      _drawSticker(
        canvas,
        _cornerSideRight,
        angle,
        center,
        _sideColor(_cornerSideColors[piece - 1]),
      );
      _drawSticker(
        canvas,
        _cornerSideLeft,
        angle,
        center,
        _sideColor(_cornerSideColors[piece]),
      );
      _drawSticker(
        canvas,
        _scaled(_cornerTop, 0.66),
        angle,
        center,
        _faceColor(piece),
      );
    }
  }

  /// Índice de rotación de csTimer: las esquinas usan `i - 1` en la capa de
  /// arriba e `i - 6` en la de abajo; las aristas `i` e `i - 5`.
  double _slotIndexFor(int globalSlot, {required bool edge}) {
    if (globalSlot < 12) {
      return (edge ? globalSlot : globalSlot - 1).toDouble();
    }
    return (edge ? globalSlot - 5 : globalSlot - 6).toDouble();
  }

  void _drawMiddle(Canvas canvas) {
    final anchors = [
      Offset(_sqb, _sqb + _sqa),
      Offset(3 * _sqb, _sqb - _sqa - 0.7),
    ];
    for (final anchor in anchors) {
      _drawQuad(
        canvas,
        const [
          Offset(-_sqa, 0),
          Offset(-_sqa, 0.7),
          Offset(-0.5, 0.7),
          Offset(-0.5, 0),
        ],
        anchor,
        _sideColor('L'),
      );
      if (state.middleIsSquare) {
        _drawQuad(
          canvas,
          const [
            Offset(_sqa, 0),
            Offset(_sqa, 0.7),
            Offset(-0.5, 0.7),
            Offset(-0.5, 0),
          ],
          anchor,
          _sideColor('L'),
        );
      } else {
        _drawQuad(
          canvas,
          const [
            Offset(_hsq3, 0),
            Offset(_hsq3, 0.7),
            Offset(-0.5, 0.7),
            Offset(-0.5, 0),
          ],
          anchor,
          _sideColor('R'),
        );
      }
    }
  }

  static List<Offset> _scaled(List<Offset> shape, double factor) =>
      shape.map((p) => p * factor).toList(growable: false);

  Color _faceColor(int piece) =>
      piece >= 8 ? PuzzlePalettes.square1['D']! : PuzzlePalettes.square1['U']!;

  Color _sideColor(String face) => PuzzlePalettes.square1[face]!;

  void _drawSticker(
    Canvas canvas,
    List<Offset> shape,
    double angle,
    Offset center,
    Color color,
  ) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final points = shape
        .map(
          (p) => Offset(
            p.dx * cosA - p.dy * sinA + center.dx,
            p.dx * sinA + p.dy * cosA + center.dy,
          ),
        )
        .toList(growable: false);
    _drawPath(canvas, points, color);
  }

  void _drawQuad(
    Canvas canvas,
    List<Offset> shape,
    Offset offset,
    Color color,
  ) {
    final points = shape.map((p) => p + offset).toList(growable: false);
    _drawPath(canvas, points, color);
  }

  void _drawPath(Canvas canvas, List<Offset> points, Color color) {
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
        ..color = Colors.black.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.03
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant Square1Painter oldDelegate) =>
      oldDelegate.notation != notation;
}
