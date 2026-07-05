import 'package:flutter/material.dart';

import '../../../domain/puzzles/skewb_simulator.dart';
import 'preview_fit.dart';
import 'puzzle_palettes.dart';

/// Dibuja el net desplegado de Skewb con la geometría de csTimer: cada cara
/// es un rombo/paralelogramo con un cuadrado central y 4 triángulos.
class SkewbNetPainter extends CustomPainter {
  SkewbNetPainter({required this.facelets, required this.notation});

  final SkewbFacelets facelets;
  final String notation;

  static const double _hsq3 = 0.8660254037844386;
  static const double _gap = 0.1;

  /// Transformación afín por cara `[m00, m01, tx, m10, m11, ty]`
  /// (tabla exacta de csTimer con ancho de cara normalizado a 1).
  static const List<List<double>> _faceTransforms = [
    [_hsq3, _hsq3, (4 + 1.5 * _gap) * _hsq3, -0.5, 0.5, 1.0],
    [_hsq3, 0, (7 + 3 * _gap) * _hsq3, -0.5, 1.0, 1.5],
    [_hsq3, 0, (5 + 2 * _gap) * _hsq3, -0.5, 1.0, 2.5 + 0.5 * _gap],
    [0, -_hsq3, (3 + _gap) * _hsq3, 1.0, -0.5, 4.5 + 1.5 * _gap],
    [_hsq3, 0, (3 + _gap) * _hsq3, 0.5, 1.0, 2.5 + 0.5 * _gap],
    [_hsq3, 0, _hsq3, 0.5, 1.0, 1.5],
  ];

  /// Polígonos locales de los 5 stickers: centro y 4 esquinas.
  static const List<List<Offset>> _stickerShapes = [
    [Offset(-1, 0), Offset(0, 1), Offset(1, 0), Offset(0, -1)],
    [Offset(-1, 0), Offset(-1, -1), Offset(0, -1)],
    [Offset(0, -1), Offset(1, -1), Offset(1, 0)],
    [Offset(-1, 0), Offset(-1, 1), Offset(0, 1)],
    [Offset(0, 1), Offset(1, 1), Offset(1, 0)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const contentWidth = 8 * _hsq3 + 0.3;
    const contentHeight = 6.2;
    PreviewFit.contain(size, contentWidth, contentHeight).applyTo(canvas);

    for (var face = 0; face < 6; face++) {
      final transform = _faceTransforms[face];
      for (var sticker = 0; sticker < 5; sticker++) {
        final points = _stickerShapes[sticker]
            .map((p) => _applyAffine(p, transform))
            .toList(growable: false);
        _drawSticker(
          canvas,
          points,
          PuzzlePalettes.skewb[facelets.faces[face][sticker]],
        );
      }
    }
  }

  static Offset _applyAffine(Offset p, List<double> t) => Offset(
        p.dx * t[0] + p.dy * t[1] + t[2],
        p.dx * t[3] + p.dy * t[4] + t[5],
      );

  void _drawSticker(Canvas canvas, List<Offset> points, Color color) {
    var cx = 0.0;
    var cy = 0.0;
    for (final p in points) {
      cx += p.dx;
      cy += p.dy;
    }
    final centroid = Offset(cx / points.length, cy / points.length);

    const shrink = 0.93;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = centroid + (points[i] - centroid) * shrink;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.022
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant SkewbNetPainter oldDelegate) =>
      oldDelegate.notation != notation;
}
