import 'package:flutter/material.dart';

import '../../../domain/puzzles/nxn_cube_simulator.dart';
import 'preview_fit.dart';
import 'puzzle_palettes.dart';

/// Dibuja el net en cruz de un cubo NxN:
///
/// ```
///     U
///   L F R B
///     D
/// ```
class CubeNetPainter extends CustomPainter {
  CubeNetPainter({required this.facelets, required this.notation});

  final NxnCubeFacelets facelets;

  /// Scramble que originó el estado; usado solo para `shouldRepaint`.
  final String notation;

  static const double _faceGap = 0.06;

  @override
  void paint(Canvas canvas, Size size) {
    const contentWidth = 4 + 3 * _faceGap;
    const contentHeight = 3 + 2 * _faceGap;
    PreviewFit.contain(size, contentWidth, contentHeight).applyTo(canvas);

    void drawAt(int column, int row, List<int> face) {
      _drawFace(
        canvas,
        face,
        Offset(column * (1 + _faceGap), row * (1 + _faceGap)),
      );
    }

    drawAt(1, 0, facelets.up);
    drawAt(0, 1, facelets.left);
    drawAt(1, 1, facelets.front);
    drawAt(2, 1, facelets.right);
    drawAt(3, 1, facelets.back);
    drawAt(1, 2, facelets.down);
  }

  void _drawFace(Canvas canvas, List<int> face, Offset origin) {
    final n = facelets.size;
    final stickerSize = 1 / n;
    final gap = stickerSize * 0.08;
    final radius = Radius.circular(stickerSize * 0.16);

    for (var i = 0; i < face.length; i++) {
      final row = i ~/ n;
      final column = i % n;
      final rect = Rect.fromLTWH(
        origin.dx + column * stickerSize,
        origin.dy + row * stickerSize,
        stickerSize - gap,
        stickerSize - gap,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = PuzzlePalettes.cube[face[i]],
      );
    }
  }

  @override
  bool shouldRepaint(covariant CubeNetPainter oldDelegate) =>
      oldDelegate.notation != notation ||
      oldDelegate.facelets.size != facelets.size;
}
