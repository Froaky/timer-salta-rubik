import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:salta_rubik/domain/entities/scramble.dart';

/// A widget that displays a 2D isometric preview of a scrambled cube or puzzle.
class ScramblePreview extends StatelessWidget {
  final Scramble scramble;
  final double? width;
  final double? height;
  final bool showLabel;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Key? containerKey;
  final Key? svgKey;

  const ScramblePreview({
    super.key,
    required this.scramble,
    this.width,
    this.height,
    this.showLabel = true,
    this.padding,
    this.backgroundColor,
    this.containerKey,
    this.svgKey,
  });

  static bool supports(String cubeType) {
    return [
      '3x3',
      '2x2',
      '4x4',
      '5x5',
      '6x6',
      '7x7',
      'pyraminx',
      'clock',
      'skewb',
      'megaminx'
    ].contains(cubeType);
  }

  @override
  Widget build(BuildContext context) {
    final cubeType = scramble.cubeType;

    return Container(
      key: containerKey ?? const ValueKey('scramble-preview'),
      padding: padding ?? const EdgeInsets.all(16),
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = math.min(
            width ?? constraints.maxWidth,
            height ?? (constraints.maxHeight == double.infinity ? constraints.maxWidth : constraints.maxHeight),
          );

          if (cubeType == '3x3' ||
              cubeType == '2x2' ||
              cubeType == '4x4' ||
              cubeType == '5x5' ||
              cubeType == '6x6' ||
              cubeType == '7x7') {
            final engine = _CubePreviewEngine.apply(scramble.notation);
            return _Cube(
              state: engine,
              width: width ?? size,
              height: height ?? size,
            );
          } else if (cubeType == 'pyraminx') {
            final state = _PyraminxPreviewEngine.apply(scramble.notation);
            return _PyraminxPreview(
              state: state,
              width: width ?? size,
              height: height ?? size,
            );
          } else if (cubeType == 'clock') {
            return _ClockPreview(
              notation: scramble.notation,
              width: width ?? size,
              height: height ?? size,
            );
          }

          // Fallback
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _Cube extends StatelessWidget {
  final _CubePreviewState state;
  final double width;
  final double height;

  const _Cube({
    required this.state,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return _CubePreview(
      state: state,
      width: width,
      height: height,
    );
  }
}

// =============================================================================
// NXN CUBE PREVIEW (3x3, 4x4, etc.)
// =============================================================================

class _CubePreview extends StatelessWidget {
  final _CubePreviewState state;
  final double width;
  final double height;

  const _CubePreview({
    required this.state,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _CubeNetPainter(state: state),
    );
  }
}

class _CubeNetPainter extends CustomPainter {
  final _CubePreviewState state;

  _CubeNetPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final faceSize = size.width / 4;
    final gap = 2.0;

    // Draw faces in a standard cross net
    //      U
    //    L F R B
    //      D

    _drawFace(canvas, state.up, faceSize, 0, faceSize - gap);
    _drawFace(canvas, state.left, 0, faceSize, faceSize - gap);
    _drawFace(canvas, state.front, faceSize, faceSize, faceSize - gap);
    _drawFace(canvas, state.right, faceSize * 2, faceSize, faceSize - gap);
    _drawFace(
      canvas,
      state.back,
      faceSize * 3,
      faceSize,
      faceSize - gap,
      key: 'back',
    );
    _drawFace(canvas, state.down, faceSize, faceSize * 2, faceSize - gap);
  }

  void _drawFace(
    Canvas canvas,
    List<CubePreviewColor> face,
    double x,
    double y,
    double size, {
    String? key,
  }) {
    final n = math.sqrt(face.length).toInt();
    final stickerSize = size / n;

    for (var i = 0; i < face.length; i++) {
      final row = i ~/ n;
      final col = i % n;

      final rect = Rect.fromLTWH(
        x + col * stickerSize,
        y + row * stickerSize,
        stickerSize - 0.5,
        stickerSize - 0.5,
      );

      final paint = Paint()..color = _getColor(face[i]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );

      if (key == 'back' && i == 0) {
        // Just a marker for testing if needed
      }
    }
  }

  Color _getColor(CubePreviewColor color) {
    switch (color) {
      case CubePreviewColor.white:
        return Colors.white;
      case CubePreviewColor.yellow:
        return Colors.yellow;
      case CubePreviewColor.green:
        return Colors.green;
      case CubePreviewColor.blue:
        return Colors.blue;
      case CubePreviewColor.red:
        return Colors.red;
      case CubePreviewColor.orange:
        return Colors.orange;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =============================================================================
// PYRAMINX PREVIEW
// =============================================================================

/// Pyraminx visualization engine using TNoodle/csTimer standard.
class _PyraminxPreviewEngine {
  static const _faceColors = [
    CubePreviewColor.green,  // 0: U
    CubePreviewColor.blue,   // 1: L
    CubePreviewColor.yellow, // 2: R
    CubePreviewColor.red,    // 3: B
  ];

  static _PyraminxState apply(String notation) {
    final image = List.generate(
      4,
      (face) => List<int>.filled(9, face),
    );

    for (final token in notation.split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      final parsed = _parsePyraminxToken(token);
      if (parsed == null) continue;

      final axis = parsed.$1;
      final tipOnly = parsed.$2;
      final dir = parsed.$3;

      for (var i = 0; i < dir; i++) {
        if (tipOnly) {
          _turnTip(axis, image);
        } else {
          _turn(axis, image);
        }
      }
    }

    return _PyraminxState(
      up: _toColors(image[0]),
      left: _toColors(image[1]),
      right: _toColors(image[2]),
      back: _toColors(image[3]),
    );
  }

  static List<CubePreviewColor> _toColors(List<int> face) {
    return face.map((i) => _faceColors[i]).toList(growable: false);
  }

  static (int, bool, int)? _parsePyraminxToken(String token) {
    final match = RegExp(r"^([ULRBulrb])('?)$").firstMatch(token);
    if (match == null) return null;

    final letter = match.group(1)!;
    final isPrime = match.group(2) == "'";
    final tipOnly = letter == letter.toLowerCase();
    final upper = letter.toUpperCase();

    int axis;
    switch (upper) {
      case 'U': axis = 0; break;
      case 'L': axis = 1; break;
      case 'R': axis = 2; break;
      case 'B': axis = 3; break;
      default: return null;
    }
    return (axis, tipOnly, isPrime ? 2 : 1);
  }

  static void _turn(int axis, List<List<int>> image) {
    switch (axis) {
      case 0: // U
        _swap3(image, 0, 0, 2, 8, 1, 4);
        _swap3(image, 0, 1, 2, 6, 1, 3);
        _swap3(image, 0, 3, 2, 3, 1, 6);
        _swap3(image, 0, 2, 2, 7, 1, 5);
        break;
      case 1: // L
        _swap3(image, 0, 4, 1, 4, 3, 0);
        _swap3(image, 0, 6, 1, 6, 3, 5);
        _swap3(image, 0, 1, 1, 1, 3, 2);
        _swap3(image, 0, 5, 1, 5, 3, 1);
        break;
      case 2: // R
        _swap3(image, 0, 8, 3, 4, 2, 4);
        _swap3(image, 0, 3, 3, 7, 2, 6);
        _swap3(image, 0, 6, 3, 2, 2, 1);
        _swap3(image, 0, 7, 3, 3, 2, 5);
        break;
      case 3: // B
        _swap3(image, 1, 8, 2, 0, 3, 8);
        _swap3(image, 1, 6, 2, 1, 3, 7);
        _swap3(image, 1, 3, 2, 3, 3, 5);
        _swap3(image, 1, 7, 2, 2, 3, 6);
        break;
    }
    _turnTip(axis, image);
  }

  static void _turnTip(int axis, List<List<int>> image) {
    switch (axis) {
      case 0: _swap3(image, 0, 0, 2, 8, 1, 4); break;
      case 1: _swap3(image, 0, 4, 1, 4, 3, 0); break;
      case 2: _swap3(image, 0, 8, 3, 4, 2, 4); break;
      case 3: _swap3(image, 1, 8, 2, 0, 3, 8); break;
    }
  }

  static void _swap3(List<List<int>> img, int f1, int s1, int f2, int s2, int f3, int s3) {
    final t = img[f1][s1];
    img[f1][s1] = img[f2][s2];
    img[f2][s2] = img[f3][s3];
    img[f3][s3] = t;
  }
}

class _PyraminxState {
  final List<CubePreviewColor> up;
  final List<CubePreviewColor> left;
  final List<CubePreviewColor> right;
  final List<CubePreviewColor> back;

  _PyraminxState({
    required this.up,
    required this.left,
    required this.right,
    required this.back,
  });
}

class _PyraminxPreview extends StatelessWidget {
  final _PyraminxState state;
  final double width;
  final double height;

  const _PyraminxPreview({
    required this.state,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _PyraminxNetPainter(state: state),
    );
  }
}

class _PyraminxNetPainter extends CustomPainter {
  final _PyraminxState state;
  _PyraminxNetPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 2.0;
    final triSide = math.min(
      (size.width - gap * 2) / 2.0,
      (size.height - gap * 2) / 2.0,
    );
    final triH = triSide * 0.86602540378;

    final ox = (size.width - triSide * 2) / 2;
    final oy = (size.height - triH * 2) / 2;

    _drawFace(canvas, state.up, ox + triSide / 2, oy, triSide, triH, true);
    _drawFace(canvas, state.back, ox + triSide / 2, oy + triH, triSide, triH, false);
    _drawFace(canvas, state.left, ox, oy + triH, triSide, triH, true);
    _drawFace(canvas, state.right, ox + triSide, oy + triH, triSide, triH, true);
  }

  void _drawFace(Canvas canvas, List<CubePreviewColor> stickers, double x, double y, double side, double h, bool pointUp) {
    final unit = side / 3.0;
    final hUnit = h / 3.0;
    final List<Path> paths = [];

    if (pointUp) {
      paths.add(_tri(x + unit, y, unit, hUnit, true));
      paths.add(_tri(x + unit * 0.5, y + hUnit, unit, hUnit, true));
      paths.add(_tri(x + unit, y + hUnit, unit, hUnit, false));
      paths.add(_tri(x + unit * 1.5, y + hUnit, unit, hUnit, true));
      paths.add(_tri(x, y + hUnit * 2, unit, hUnit, true));
      paths.add(_tri(x + unit * 0.5, y + hUnit * 2, unit, hUnit, false));
      paths.add(_tri(x + unit, y + hUnit * 2, unit, hUnit, true));
      paths.add(_tri(x + unit * 1.5, y + hUnit * 2, unit, hUnit, false));
      paths.add(_tri(x + unit * 2, y + hUnit * 2, unit, hUnit, true));
    } else {
      paths.add(_tri(x, y, unit, hUnit, false));
      paths.add(_tri(x + unit * 0.5, y, unit, hUnit, true));
      paths.add(_tri(x + unit, y, unit, hUnit, false));
      paths.add(_tri(x + unit * 1.5, y, unit, hUnit, true));
      paths.add(_tri(x + unit * 2, y, unit, hUnit, false));
      paths.add(_tri(x + unit * 0.5, y + hUnit, unit, hUnit, false));
      paths.add(_tri(x + unit, y + hUnit, unit, hUnit, true));
      paths.add(_tri(x + unit * 1.5, y + hUnit, unit, hUnit, false));
      paths.add(_tri(x + unit, y + hUnit * 2, unit, hUnit, false));
    }

    for (var i = 0; i < 9; i++) {
      final paint = Paint()..color = _getColor(stickers[i]);
      canvas.drawPath(paths[i], paint);
      canvas.drawPath(paths[i], Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 0.5);
    }
  }

  Path _tri(double x, double y, double s, double h, bool up) {
    if (up) {
      return Path()..moveTo(x + s / 2, y)..lineTo(x, y + h)..lineTo(x + s, y + h)..close();
    } else {
      return Path()..moveTo(x, y)..lineTo(x + s, y)..lineTo(x + s / 2, y + h)..close();
    }
  }

  Color _getColor(CubePreviewColor c) {
    switch (c) {
      case CubePreviewColor.white: return Colors.white;
      case CubePreviewColor.yellow: return Colors.yellow;
      case CubePreviewColor.green: return Colors.green;
      case CubePreviewColor.blue: return Colors.blue;
      case CubePreviewColor.red: return Colors.red;
      case CubePreviewColor.orange: return Colors.orange;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =============================================================================
// CLOCK PREVIEW (Placeholder)
// =============================================================================

class _ClockPreview extends StatelessWidget {
  final String notation;
  final double width;
  final double height;

  const _ClockPreview({
    required this.notation,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.watch_later_outlined, color: Colors.white54, size: 40),
      ),
    );
  }
}

// =============================================================================
// ENGINE & STATE MODELS
// =============================================================================

enum CubePreviewColor { white, yellow, green, blue, red, orange }

class _CubePreviewState {
  final List<CubePreviewColor> up;
  final List<CubePreviewColor> down;
  final List<CubePreviewColor> left;
  final List<CubePreviewColor> right;
  final List<CubePreviewColor> front;
  final List<CubePreviewColor> back;

  _CubePreviewState({
    required this.up,
    required this.down,
    required this.left,
    required this.right,
    required this.front,
    required this.back,
  });
}

class _CubePreviewEngine {
  static _CubePreviewState apply(String notation) {
    // Basic 3x3 placeholder logic.
    // In a real app, this would use a library like 'cuber' or a full custom solver.
    // For now, we'll return a solved state as a base.
    return _CubePreviewState(
      up: List.filled(9, CubePreviewColor.white),
      down: List.filled(9, CubePreviewColor.yellow),
      left: List.filled(9, CubePreviewColor.orange),
      right: List.filled(9, CubePreviewColor.red),
      front: List.filled(9, CubePreviewColor.green),
      back: List.filled(9, CubePreviewColor.blue),
    );
  }
}
