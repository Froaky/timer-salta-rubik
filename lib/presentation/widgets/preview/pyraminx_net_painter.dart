import 'package:flutter/material.dart';

import '../../../domain/puzzles/pyraminx_simulator.dart';
import 'preview_fit.dart';
import 'puzzle_palettes.dart';

/// Dibuja el net estándar de Pyraminx (layout csTimer/WCA):
///
/// ```
///   L | F | R      (banda superior, triángulo grande apuntando abajo)
///       D          (debajo de F)
/// ```
class PyraminxNetPainter extends CustomPainter {
  PyraminxNetPainter({required this.facelets, required this.notation});

  final PyraminxFacelets facelets;
  final String notation;

  static const double _hsq3 = 0.8660254037844386;

  /// Offsets de cada cara en unidades de contenido (x en anchos de sticker,
  /// y en múltiplos de la altura de fila `hsq3`). Orden: F, L, R, D.
  static const List<double> _faceOffsetX = [3.5, 1.5, 5.5, 3.5];
  static const List<double> _faceOffsetY = [0, 3, 3, 6.5];

  /// Posición local (ápice) de cada sticker dentro de una cara.
  static const List<double> _stickerOffsetX = [
    0, -1, 1, 0, 0.5, -0.5, 0, -0.5, 0.5, //
  ];
  static const List<double> _stickerOffsetY = [0, 2, 2, 2, 1, 1, 2, 3, 3];

  @override
  void paint(Canvas canvas, Size size) {
    const contentWidth = 7.0;
    const contentHeight = 6.5 * _hsq3;
    PreviewFit.contain(size, contentWidth, contentHeight).applyTo(canvas);

    for (var face = 0; face < 4; face++) {
      _drawFace(canvas, face);
    }
  }

  void _drawFace(Canvas canvas, int face) {
    // La cara F se dibuja "derecha"; L, R y D se dibujan invertidas.
    final inverted = face != 0;
    final mirror = inverted ? -1.0 : 1.0;

    for (var idx = 0; idx < 9; idx++) {
      final apexX = _faceOffsetX[face] + _stickerOffsetX[idx] * mirror;
      final apexY =
          (_faceOffsetY[face] + _stickerOffsetY[idx] * mirror) * _hsq3;
      final pointsDown = (idx >= 6) != inverted;
      _drawSticker(
        canvas,
        color: PuzzlePalettes.pyraminx[facelets.faces[face][idx]],
        apex: Offset(apexX, apexY),
        pointsDown: pointsDown,
      );
    }
  }

  void _drawSticker(
    Canvas canvas, {
    required Color color,
    required Offset apex,
    required bool pointsDown,
  }) {
    // Triángulo con el ápice en `apex`; la base queda hacia abajo si el
    // sticker "apunta arriba" y hacia arriba si "apunta abajo".
    final baseY = apex.dy + (pointsDown ? -_hsq3 : _hsq3);
    final vertices = [
      Offset(apex.dx - 0.5, baseY),
      Offset(apex.dx + 0.5, baseY),
      apex,
    ];
    final centroid = Offset(
      (vertices[0].dx + vertices[1].dx + vertices[2].dx) / 3,
      (vertices[0].dy + vertices[1].dy + vertices[2].dy) / 3,
    );

    // Encoger hacia el centroide deja un gap visual entre stickers.
    const shrink = 0.9;
    Offset shrunk(Offset v) => centroid + (v - centroid) * shrink;

    final path = Path()
      ..moveTo(shrunk(vertices[0]).dx, shrunk(vertices[0]).dy)
      ..lineTo(shrunk(vertices[1]).dx, shrunk(vertices[1]).dy)
      ..lineTo(shrunk(vertices[2]).dx, shrunk(vertices[2]).dy)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.025
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant PyraminxNetPainter oldDelegate) =>
      oldDelegate.notation != notation;
}
