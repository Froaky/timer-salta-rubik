import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/scramble.dart';
import '../theme/app_theme.dart';
import 'cube_preview_engine.dart';

class ScramblePreview extends StatelessWidget {
  const ScramblePreview({
    super.key,
    required this.scramble,
    this.width = 220,
    this.height = 170,
    this.showLabel = true,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(12),
    this.containerKey,
    this.svgKey,
  });

  final Scramble scramble;
  final double width;
  final double height;
  final bool showLabel;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final Key? containerKey;
  final Key? svgKey;

  static const Map<String, int> _cubeSizeByType = {
    '2x2': 2,
    '3x3': 3,
    '3x3oh': 3,
    '3x3bf': 3,
    '3x3fm': 3,
    '4x4': 4,
    '444bf': 4,
    '5x5': 5,
    '555bf': 5,
    '6x6': 6,
    '7x7': 7,
  };

  static bool supports(String cubeType) =>
      _cubeSizeByType.containsKey(cubeType) ||
      cubeType == 'clock' ||
      cubeType == 'pyraminx' ||
      cubeType == 'skewb';

  @override
  Widget build(BuildContext context) {
    final content = _buildPreviewContent(context);
    if (content == null) {
      return const SizedBox.shrink();
    }

    return Container(
      key: containerKey ?? const ValueKey('scramble-preview'),
      constraints: BoxConstraints(maxWidth: width + 24),
      padding: padding,
      decoration: BoxDecoration(
        color:
            backgroundColor ?? AppTheme.backgroundColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textMuted.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[
            Text(
              'Preview',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            key: svgKey ?? const ValueKey('scramble-preview-svg'),
            width: width,
            height: height,
            child: content,
          ),
        ],
      ),
    );
  }

  Widget? _buildPreviewContent(BuildContext context) {
    final size = _cubeSizeByType[scramble.cubeType];
    if (size != null) {
      final net = CubePreviewEngine(size: size).apply(scramble.notation);
      return _CubeNet(
        net: net,
        width: width,
        height: height,
      );
    }

    if (scramble.cubeType == 'clock') {
      final state = _ClockPreviewEngine.apply(scramble.notation);
      return _ClockPreview(
        state: state,
        width: width,
        height: height,
      );
    }

    if (scramble.cubeType == 'pyraminx') {
      final state = _PyraminxPreviewEngine.apply(scramble.notation);
      return _PyraminxPreview(
        state: state,
        width: width,
        height: height,
      );
    }

    if (scramble.cubeType == 'skewb') {
      final state = _SkewbPreviewEngine.apply(scramble.notation);
      return _SkewbPreview(
        state: state,
        width: width,
        height: height,
      );
    }

    return null;
  }
}

class _CubeNet extends StatelessWidget {
  const _CubeNet({
    required this.net,
    required this.width,
    required this.height,
  });

  final CubeNetData net;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final faceGap = math.max(3.0, math.min(width, height) * 0.035);
    final faceSize =
        math.min((width - faceGap * 3) / 4, (height - faceGap * 2) / 3);
    final totalWidth = faceSize * 4 + faceGap * 3;
    final totalHeight = faceSize * 3 + faceGap * 2;
    final offsetX = (width - totalWidth) / 2;
    final offsetY = (height - totalHeight) / 2;

    return Stack(
      children: [
        _positionFace(
          net.up,
          offsetX + faceSize + faceGap,
          offsetY,
          faceSize,
        ),
        _positionFace(
          net.left,
          offsetX,
          offsetY + faceSize + faceGap,
          faceSize,
        ),
        _positionFace(
          net.front,
          offsetX + faceSize + faceGap,
          offsetY + faceSize + faceGap,
          faceSize,
        ),
        _positionFace(
          net.right,
          offsetX + (faceSize + faceGap) * 2,
          offsetY + faceSize + faceGap,
          faceSize,
        ),
        _positionFace(
          net.back,
          offsetX + (faceSize + faceGap) * 3,
          offsetY + faceSize + faceGap,
          faceSize,
          rotationAngle: math.pi,
          key: const ValueKey('scramble-preview-back-face'),
        ),
        _positionFace(
          net.down,
          offsetX + faceSize + faceGap,
          offsetY + (faceSize + faceGap) * 2,
          faceSize,
        ),
      ],
    );
  }

  Widget _positionFace(
    List<CubePreviewColor> face,
    double left,
    double top,
    double size, {
    double rotationAngle = 0,
    Key? key,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        key: key,
        angle: rotationAngle,
        child: _CubeFace(
          colors: face,
          size: size,
          dimension: net.size,
        ),
      ),
    );
  }
}

class _CubeFace extends StatelessWidget {
  const _CubeFace({
    required this.colors,
    required this.size,
    required this.dimension,
  });

  final List<CubePreviewColor> colors;
  final double size;
  final int dimension;

  @override
  Widget build(BuildContext context) {
    final stickerGap = math.max(0.5, size * 0.035);

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        children: List.generate(dimension, (row) {
          return Expanded(
            child: Row(
              children: List.generate(dimension, (column) {
                final index = row * dimension + column;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.all(stickerGap / 2),
                    decoration: BoxDecoration(
                      color: colors[index].color,
                      borderRadius: BorderRadius.circular(size * 0.02),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _ClockPreviewEngine {
  static final Map<String, List<int>> _frontMasks = {
    'UR': [1, 2, 4, 5],
    'DR': [4, 5, 7, 8],
    'DL': [3, 4, 6, 7],
    'UL': [0, 1, 3, 4],
    'U': [0, 1, 2],
    'R': [2, 5, 8],
    'D': [6, 7, 8],
    'L': [0, 3, 6],
    'ALL': List<int>.generate(9, (index) => index),
  };

  static _ClockState apply(String notation) {
    final front = List<int>.filled(9, 0);
    final back = List<int>.filled(9, 0);
    var target = front;

    for (final token in notation.split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      if (token == 'y2') {
        target = back;
        continue;
      }

      final match =
          RegExp(r'^(UR|DR|DL|UL|U|R|D|L|ALL)(\d+)([+-])$').firstMatch(token);
      if (match == null) {
        continue;
      }

      final group = match.group(1)!;
      final value = int.parse(match.group(2)!);
      final signedValue = match.group(3) == '+' ? value : -value;
      final mask = _frontMasks[group]!;

      for (final index in mask) {
        target[index] = (target[index] + signedValue) % 12;
      }
    }

    return _ClockState(
      front: front.map(_normalizeDial).toList(growable: false),
      back: back.map(_normalizeDial).toList(growable: false),
    );
  }

  static int _normalizeDial(int value) => ((value % 12) + 12) % 12;
}

class _ClockPreview extends StatelessWidget {
  const _ClockPreview({
    required this.state,
    required this.width,
    required this.height,
  });

  final _ClockState state;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : width;
        final availableHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : height;
        final faceGap = math.max(8.0, availableWidth * 0.05);
        final faceSize =
            math.min((availableWidth - faceGap) / 2, availableHeight);

        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ClockFace(
                dials: state.front,
                size: faceSize,
                faceColor: const Color(0xFF3F83CC),
                pinColor: const Color(0xFF9A6B00),
              ),
              SizedBox(width: faceGap),
              _ClockFace(
                dials: state.back,
                size: faceSize,
                faceColor: const Color(0xFF56C7FF),
                pinColor: const Color(0xFFFFEB3B),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClockFace extends StatelessWidget {
  const _ClockFace({
    required this.dials,
    required this.size,
    required this.faceColor,
    required this.pinColor,
  });

  final List<int> dials;
  final double size;
  final Color faceColor;
  final Color pinColor;

  @override
  Widget build(BuildContext context) {
    final dialSize = size / 3.5;
    final pinSize = dialSize * 0.28;
    final spacing = dialSize * 0.15;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          for (var row = 0; row < 3; row++)
            for (var col = 0; col < 3; col++)
              Positioned(
                left: col * (dialSize + spacing),
                top: row * (dialSize + spacing),
                child: _ClockDial(
                  value: dials[row * 3 + col],
                  size: dialSize,
                  faceColor: faceColor,
                ),
              ),
          Positioned(
            left: dialSize + spacing * 0.55,
            top: dialSize + spacing * 0.2,
            child: _ClockPin(size: pinSize, color: pinColor),
          ),
          Positioned(
            right: dialSize + spacing * 0.55,
            top: dialSize + spacing * 0.2,
            child: _ClockPin(size: pinSize, color: pinColor),
          ),
          Positioned(
            left: dialSize + spacing * 0.55,
            bottom: dialSize + spacing * 0.2,
            child: _ClockPin(size: pinSize, color: pinColor),
          ),
          Positioned(
            right: dialSize + spacing * 0.55,
            bottom: dialSize + spacing * 0.2,
            child: _ClockPin(size: pinSize, color: pinColor),
          ),
        ],
      ),
    );
  }
}

class _ClockDial extends StatelessWidget {
  const _ClockDial({
    required this.value,
    required this.size,
    required this.faceColor,
  });

  final int value;
  final double size;
  final Color faceColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ClockDialPainter(
        value: value,
        faceColor: faceColor,
      ),
    );
  }
}

class _ClockDialPainter extends CustomPainter {
  const _ClockDialPainter({
    required this.value,
    required this.faceColor,
  });

  final int value;
  final Color faceColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final fillPaint = Paint()..color = faceColor;
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.width * 0.04);

    canvas.drawCircle(center, radius * 0.92, fillPaint);
    canvas.drawCircle(center, radius * 0.92, rimPaint);

    final angle = (-math.pi / 2) + (value * math.pi / 6);
    final handLength = radius * 0.6;
    final handEnd = Offset(
      center.dx + math.cos(angle) * handLength,
      center.dy + math.sin(angle) * handLength,
    );

    final handPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = math.max(1.2, size.width * 0.06)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, handEnd, handPaint);

    final tipPath = Path()
      ..moveTo(handEnd.dx, handEnd.dy)
      ..lineTo(
        handEnd.dx + math.cos(angle + math.pi * 0.82) * radius * 0.18,
        handEnd.dy + math.sin(angle + math.pi * 0.82) * radius * 0.18,
      )
      ..lineTo(
        handEnd.dx + math.cos(angle - math.pi * 0.82) * radius * 0.18,
        handEnd.dy + math.sin(angle - math.pi * 0.82) * radius * 0.18,
      )
      ..close();

    canvas.drawPath(
      tipPath,
      Paint()..color = Colors.yellowAccent,
    );
    canvas.drawCircle(center, radius * 0.11, Paint()..color = Colors.redAccent);
  }

  @override
  bool shouldRepaint(covariant _ClockDialPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.faceColor != faceColor;
  }
}

class _ClockPin extends StatelessWidget {
  const _ClockPin({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.35),
          width: math.max(0.5, size * 0.08),
        ),
      ),
    );
  }
}

class _ClockState {
  const _ClockState({
    required this.front,
    required this.back,
  });

  final List<int> front;
  final List<int> back;
}

/// Pyraminx preview engine based on WCA TNoodle official reference.
///
/// Face layout and sticker indices per face (viewed from outside):
/// ```
///      ____  ____  ____
///     \    /\    /\    /
///      \0 /1 \2 /4 \3 /     tips: 0, 3, 6
///       \/____\/____\/      edges: 1, 5, 8
///        \    /\    /       centers: 2, 4, 7
///         \8 /7 \5 /
///          \/____\/
///           \    /
///            \6 /
///             \/
/// ```
///
/// Faces: F(0)=Green, D(1)=Yellow, L(2)=Red, R(3)=Blue
/// Axes:  U=0, L=1, R=2, B=3
class _PyraminxPreviewEngine {
  /// 4 faces × 9 stickers. Index: F=0, D=1, L=2, R=3.
  static const _faceColors = [
    CubePreviewColor.green, // F
    CubePreviewColor.yellow, // D
    CubePreviewColor.red, // L
    CubePreviewColor.blue, // R
  ];

  static _PyraminxState apply(String notation) {
    // image[face][sticker] — starts solved
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
      front: _toColors(image[0]),
      down: _toColors(image[1]),
      left: _toColors(image[2]),
      right: _toColors(image[3]),
    );
  }

  static List<CubePreviewColor> _toColors(List<int> face) {
    return face.map((i) => _faceColors[i]).toList(growable: false);
  }

  /// Parse a pyraminx notation token into (axis, tipOnly, direction).
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

  /// Pyraminx Moves based on standard orientation: Yellow Down, Green Front.
  /// Faces: 0=Front(G), 1=Down(Y), 2=Left(R), 3=Right(B).
  static void _turn(int axis, List<List<int>> image) {
    switch (axis) {
      case 0: // U move (CW): Swap(F, R, L) around U corner
        _swap3(image, 0, 8, 3, 4, 2, 0); // Tip
        _swap3(image, 0, 3, 3, 1, 2, 1); // Center A
        _swap3(image, 0, 6, 3, 6, 2, 3); // Center B
        _swap3(image, 0, 7, 3, 5, 2, 2); // Edge
        break;
      case 1: // L move (CW): Swap(F, L, D) around L corner
        _swap3(image, 0, 4, 2, 4, 1, 0); // Tip
        _swap3(image, 0, 1, 2, 1, 1, 2); // Center A
        _swap3(image, 0, 6, 2, 6, 1, 5); // Center B
        _swap3(image, 0, 5, 2, 5, 1, 1); // Edge
        break;
      case 2: // R move (CW): Swap(F, D, R) around R corner
        _swap3(image, 0, 0, 1, 4, 3, 0); // Tip
        _swap3(image, 0, 1, 1, 2, 3, 1); // Center A
        _swap3(image, 0, 3, 1, 7, 3, 6); // Center B
        _swap3(image, 0, 2, 1, 3, 3, 2); // Edge
        break;
      case 3: // B move (CW): Swap(D, L, R) around B corner
        _swap3(image, 1, 8, 2, 8, 3, 8); // Tip
        _swap3(image, 1, 5, 2, 6, 3, 3); // Center A
        _swap3(image, 1, 7, 2, 3, 3, 6); // Center B
        _swap3(image, 1, 6, 2, 7, 3, 5); // Edge
        break;
    }
    _turnTip(axis, image);
  }

  static void _turnTip(int axis, List<List<int>> image) {
    switch (axis) {
      case 0: _swap3(image, 0, 8, 3, 4, 2, 0); break;
      case 1: _swap3(image, 0, 4, 2, 4, 1, 0); break;
      case 2: _swap3(image, 0, 0, 1, 4, 3, 0); break;
      case 3: _swap3(image, 1, 8, 2, 8, 3, 8); break;
    }
  }



  /// 3-cycle swap: a → b → c → a
  static void _swap3(
    List<List<int>> image,
    int f1,
    int s1,
    int f2,
    int s2,
    int f3,
    int s3,
  ) {
    final temp = image[f1][s1];
    image[f1][s1] = image[f2][s2];
    image[f2][s2] = image[f3][s3];
    image[f3][s3] = temp;
  }
}

class _PyraminxState {
  const _PyraminxState({
    required this.front,
    required this.down,
    required this.left,
    required this.right,
  });

  final List<CubePreviewColor> front;
  final List<CubePreviewColor> down;
  final List<CubePreviewColor> left;
  final List<CubePreviewColor> right;
}

/// Draws the pyraminx net matching the TNoodle/csTimer layout:
///
/// ```
///   L (↓)     R (↓)
///      F (↑)
///      D (↓)
/// ```
class _PyraminxPreview extends StatelessWidget {
  const _PyraminxPreview({
    required this.state,
    required this.width,
    required this.height,
  });

  final _PyraminxState state;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _PyraminxNetPainter(state: state),
    );
  }
}

/// Renders the full pyraminx net using CustomPainter for pixel-perfect layout.
///
/// Sticker order within each face triangle (TNoodle convention):
/// ```
///      ____  ____  ____
///     \    /\    /\    /
///      \0 /1 \2 /4 \3 /
///       \/____\/____\/
///        \    /\    /
///         \8 /7 \5 /
///          \/____\/
///           \    /
///            \6 /
///             \/
/// ```
///
/// For an upward-pointing face the tip (sticker 0) is at the top.
/// For a downward-pointing face (L, R, D) the tip (sticker 0) is at the bottom
/// when rendered inverted, but we keep the same sticker order and just flip
/// the triangle geometry.
class _PyraminxNetPainter extends CustomPainter {
  const _PyraminxNetPainter({required this.state});

  final _PyraminxState state;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 2.0;
    final triSide = math.min(
      (size.width - gap * 2) / 2.0,
      (size.height - gap * 2) / 2.0,
    );
    final triH = triSide * _sqrt3over2;

    final ox = (size.width - triSide * 2) / 2;
    final oy = (size.height - triH * 2) / 2;

    // Face 2 (Left): Top UP
    _drawFace(canvas, state.left, ox + triSide / 2, oy, triSide, triH, true);
    
    // Face 1 (Down): Center DOWN
    _drawFace(canvas, state.down, ox + triSide / 2, oy + triH, triSide, triH, false);

    // Face 3 (Right): Bottom-Left UP
    _drawFace(canvas, state.right, ox, oy + triH, triSide, triH, true);

    // Face 0 (Front): Bottom-Right UP
    _drawFace(canvas, state.front, ox + triSide, oy + triH, triSide, triH, true);
  }


  static const _sqrt3over2 = 0.8660254037844386; // sqrt(3)/2

  /// Draw one pyraminx face as a triangle subdivided into 9 stickers.
  void _drawFace(
    Canvas canvas,
    List<CubePreviewColor> stickers,
    double x,
    double y,
    double side,
    double h,
    bool pointUp,
  ) {
    // Compute the 3 vertices of the big triangle
    late final List<Offset> verts;
    if (pointUp) {
      verts = [
        Offset(x + side / 2, y), // top
        Offset(x, y + h), // bottom-left
        Offset(x + side, y + h), // bottom-right
      ];
    } else {
      verts = [
        Offset(x, y), // top-left
        Offset(x + side, y), // top-right
        Offset(x + side / 2, y + h), // bottom
      ];
    }

    final paths = <Path>[];
    final unit = side / 3;
    final hUnit = h / 3;

    if (pointUp) {
      // Row 0: 1 triangle
      paths.add(_tri(x + side / 2, y, unit, hUnit, true));
      // Row 1: 3 triangles
      paths.add(_tri(x + unit, y + hUnit, unit, hUnit, true));
      paths.add(_tri(x + unit * 1.5, y + hUnit, unit, hUnit, false));
      paths.add(_tri(x + unit * 2, y + hUnit, unit, hUnit, true));
      // Row 2: 5 triangles
      paths.add(_tri(x + unit * 0.5, y + hUnit * 2, unit, hUnit, true));
      paths.add(_tri(x + unit, y + hUnit * 2, unit, hUnit, false));
      paths.add(_tri(x + unit * 1.5, y + hUnit * 2, unit, hUnit, true));
      paths.add(_tri(x + unit * 2, y + hUnit * 2, unit, hUnit, false));
      paths.add(_tri(x + unit * 2.5, y + hUnit * 2, unit, hUnit, true));
    } else {
      // Row 0: 5 triangles
      paths.add(_tri(x, y, unit, hUnit, false));
      paths.add(_tri(x + unit * 0.5, y, unit, hUnit, true));
      paths.add(_tri(x + unit, y, unit, hUnit, false));
      paths.add(_tri(x + unit * 1.5, y, unit, hUnit, true));
      paths.add(_tri(x + unit * 2, y, unit, hUnit, false));
      // Row 1: 3 triangles
      paths.add(_tri(x + unit * 0.5, y + hUnit, unit, hUnit, false));
      paths.add(_tri(x + unit, y + hUnit, unit, hUnit, true));
      paths.add(_tri(x + unit * 1.5, y + hUnit, unit, hUnit, false));
      // Row 2: 1 triangle
      paths.add(_tri(x + unit, y + hUnit * 2, unit, hUnit, false));
    }


    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = math.max(0.6, side * 0.01)
      ..strokeJoin = StrokeJoin.round;

    final faceOutlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.8)
      ..strokeWidth = math.max(1.0, side * 0.015)
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < paths.length && i < stickers.length; i++) {
      fillPaint.color = stickers[i].color;
      canvas.drawPath(paths[i], fillPaint);
      canvas.drawPath(paths[i], strokePaint);
    }

    // Draw the bold outline for the whole face
    final outlinePath = Path()
      ..moveTo(verts[0].dx, verts[0].dy)
      ..lineTo(verts[1].dx, verts[1].dy)
      ..lineTo(verts[2].dx, verts[2].dy)
      ..close();
    canvas.drawPath(outlinePath, faceOutlinePaint);
  }

  Path _tri(double x, double y, double side, double h, bool up) {
    if (up) {
      return Path()
        ..moveTo(x, y)
        ..lineTo(x - side / 2, y + h)
        ..lineTo(x + side / 2, y + h)
        ..close();
    } else {
      return Path()
        ..moveTo(x, y)
        ..lineTo(x + side, y)
        ..lineTo(x + side / 2, y + h)
        ..close();
    }
  }


  @override
  bool shouldRepaint(covariant _PyraminxNetPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

// --- Skewb Preview Engine & Rendering ---

class _SkewbState {
  const _SkewbState({required this.faces});
  final List<List<CubePreviewColor>> faces;
}

class _SkewbPreviewEngine {
  static _SkewbState apply(String notation) {
    // Initial state: 6 faces, each with 5 stickers
    // Layout: 0:Center, 1:Top, 2:Right, 3:Bottom, 4:Left
    final List<List<CubePreviewColor>> faces = [
      List.filled(5, CubePreviewColor.white),  // 0: U
      List.filled(5, CubePreviewColor.yellow), // 1: D
      List.filled(5, CubePreviewColor.orange), // 2: L
      List.filled(5, CubePreviewColor.red),    // 3: R
      List.filled(5, CubePreviewColor.green),  // 4: F
      List.filled(5, CubePreviewColor.blue),   // 5: B
    ];

    for (final token in notation.split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      final isPrime = token.endsWith("'");
      final move = token.replaceAll("'", "");
      final count = isPrime ? 2 : 1; 

      for (var i = 0; i < count; i++) {
        switch (move) {
          case 'U': _rotateU(faces); break;
          case 'R': _rotateR(faces); break;
          case 'L': _rotateL(faces); break;
          case 'B': _rotateB(faces); break;
        }
      }
    }

    return _SkewbState(faces: faces);
  }

  // WCA Skewb Move Permutations
  // Move X rotates the piece at corner X and the 3 adjacent centers.
  
  static void _rotateU(List<List<CubePreviewColor>> f) {
    // Centers: U(0), R(3), F(4)
    _swap3(f, 0, 0, 3, 0, 4, 0);
    // Corners:
    // UFR rotates in place
    _swap3(f, 0, 4, 3, 1, 4, 2);
    // UFL -> UBR -> DFR
    _swap3(f, 0, 3, 0, 2, 4, 4); // U-corners
    _swap3(f, 4, 1, 5, 1, 3, 3); // Front/Back/Right
    _swap3(f, 2, 2, 3, 2, 1, 2); // Left/Right/Down
  }

  static void _rotateR(List<List<CubePreviewColor>> f) {
    // Centers: D(1), R(3), F(4)
    _swap3(f, 1, 0, 3, 0, 4, 0);
    // DFR rotates in place
    _swap3(f, 1, 2, 4, 4, 3, 3);
    // UFR -> DBR -> DFL
    _swap3(f, 0, 4, 3, 4, 1, 1); // U/R/D
    _swap3(f, 3, 1, 5, 3, 2, 4); // R/B/L
    _swap3(f, 4, 2, 1, 4, 4, 3); // F/D/F
  }

  static void _rotateL(List<List<CubePreviewColor>> f) {
    // Centers: D(1), F(4), L(2)
    _swap3(f, 1, 0, 4, 0, 2, 0);
    // DFL rotates in place
    _swap3(f, 1, 1, 2, 4, 4, 3);
    // UFL -> DFR -> DBL
    _swap3(f, 0, 3, 1, 2, 1, 3); // U/D/D
    _swap3(f, 4, 1, 3, 3, 5, 4); // F/R/B
    _swap3(f, 2, 2, 4, 4, 2, 3); // L/F/L
  }

  static void _rotateB(List<List<CubePreviewColor>> f) {
    // Centers: D(1), B(5), R(3)
    _swap3(f, 1, 0, 5, 0, 3, 0);
    // DBR rotates in place
    _swap3(f, 1, 4, 3, 4, 5, 3);
    // UBR -> DBL -> DFR
    _swap3(f, 0, 2, 1, 3, 1, 2); // U/D/D
    _swap3(f, 5, 1, 2, 3, 4, 4); // B/L/F
    _swap3(f, 3, 2, 5, 4, 3, 3); // R/B/R
  }

  static void _swap3(List<List<CubePreviewColor>> f, int f1, int s1, int f2, int s2, int f3, int s3) {
    final temp = f[f1][s1];
    f[f1][s1] = f[f3][s3];
    f[f3][s3] = f[f2][s2];
    f[f2][s2] = temp;
  }
}

class _SkewbPreview extends StatelessWidget {
  const _SkewbPreview({
    required this.state,
    required this.width,
    required this.height,
  });

  final _SkewbState state;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SkewbNetPainter(state: state),
    );
  }
}

class _SkewbNetPainter extends CustomPainter {
  const _SkewbNetPainter({required this.state});
  final _SkewbState state;

  @override
  void paint(Canvas canvas, Size size) {
    // Exact Isometric Perspective (csTimer Style)
    final s = math.min(size.width / 4.4, size.height / 3.4);
    final ox = size.width / 2;
    final oy = size.height / 2;

    final c30 = math.cos(math.pi / 6); // 0.866
    final s30 = math.sin(math.pi / 6); // 0.5 (2*s30 = 1.0)

    // Layout: U, L, R meet at (ox, oy)
    // 0:U (Top-style), 1:D (Top-style), 2:L (Left-style), 3:R (Right-style), 4:F (Right-style), 5:B (Left-style)
    
    // Core 3 faces meeting at center
    _drawIso(canvas, state.faces[0], ox, oy, s, c30, s30, 0); // U (Top)
    _drawIso(canvas, state.faces[2], ox, oy, s, c30, s30, 1); // L (Left)
    _drawIso(canvas, state.faces[3], ox, oy, s, c30, s30, 2); // R (Right)
    
    // Extensions
    _drawIso(canvas, state.faces[5], ox - s * c30, oy - s * s30, s, c30, s30, 1); // B (Attached to L/U)
    _drawIso(canvas, state.faces[4], ox + s * c30, oy - s * s30, s, c30, s30, 2); // F (Attached to R/U)
    _drawIso(canvas, state.faces[1], ox, oy + 2 * s, s, c30, s30, 0);             // D (Attached below L/R)
  }

  void _drawIso(Canvas canvas, List<CubePreviewColor> stickers, double cx, double cy, double s, double c30, double s30, int type) {
    late final List<Offset> v;
    if (type == 0) { // Top-style (U, D)
      v = [
        Offset(cx, cy),
        Offset(cx + s * c30, cy - s * s30),
        Offset(cx, cy - 2 * s * s30),
        Offset(cx - s * c30, cy - s * s30),
      ];
    } else if (type == 1) { // Left-style (L, B)
      v = [
        Offset(cx, cy),
        Offset(cx - s * c30, cy - s * s30),
        Offset(cx - s * c30, cy + s - s * s30),
        Offset(cx, cy + s),
      ];
    } else { // Right-style (R, F)
      v = [
        Offset(cx, cy),
        Offset(cx, cy + s),
        Offset(cx + s * c30, cy + s - s * s30),
        Offset(cx + s * c30, cy - s * s30),
      ];
    }

    // Midpoints for sticker subdivision
    final m01 = Offset((v[0].dx + v[1].dx) / 2, (v[0].dy + v[1].dy) / 2);
    final m12 = Offset((v[1].dx + v[2].dx) / 2, (v[1].dy + v[2].dy) / 2);
    final m23 = Offset((v[2].dx + v[3].dx) / 2, (v[2].dy + v[3].dy) / 2);
    final m30 = Offset((v[3].dx + v[0].dx) / 2, (v[3].dy + v[0].dy) / 2);

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    // Center Sticker
    _drawPath(canvas, Path()..moveTo(m01.dx, m01.dy)..lineTo(m12.dx, m12.dy)..lineTo(m23.dx, m23.dy)..lineTo(m30.dx, m30.dy)..close(), stickers[0], fillPaint, strokePaint);
    // Corner Stickers
    _drawPath(canvas, Path()..moveTo(v[1].dx, v[1].dy)..lineTo(m01.dx, m01.dy)..lineTo(m12.dx, m12.dy)..close(), stickers[1], fillPaint, strokePaint);
    _drawPath(canvas, Path()..moveTo(v[2].dx, v[2].dy)..lineTo(m12.dx, m12.dy)..lineTo(m23.dx, m23.dy)..close(), stickers[2], fillPaint, strokePaint);
    _drawPath(canvas, Path()..moveTo(v[3].dx, v[3].dy)..lineTo(m23.dx, m23.dy)..lineTo(m30.dx, m30.dy)..close(), stickers[3], fillPaint, strokePaint);
    _drawPath(canvas, Path()..moveTo(v[0].dx, v[0].dy)..lineTo(m30.dx, m30.dy)..lineTo(m01.dx, m01.dy)..close(), stickers[4], fillPaint, strokePaint);

    // Bold Face Outline
    canvas.drawPath(
      Path()..moveTo(v[0].dx, v[0].dy)..lineTo(v[1].dx, v[1].dy)..lineTo(v[2].dx, v[2].dy)..lineTo(v[3].dx, v[3].dy)..close(),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black.withValues(alpha: 0.8)
        ..strokeWidth = 1.2,
    );
  }

  void _drawPath(Canvas canvas, Path path, CubePreviewColor color, Paint fill, Paint stroke) {
    fill.color = color.color;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _SkewbNetPainter oldDelegate) => oldDelegate.state != state;
}
