import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/scramble.dart';
import '../theme/app_theme.dart';

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
      cubeType == 'pyraminx';

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
      final net = _CubePreviewEngine(size: size).apply(scramble.notation);
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

    return null;
  }
}

class _CubePreviewEngine {
  _CubePreviewEngine({required this.size})
      : faces = {
          _Face.up: _filledFace(size, _StickerColor.white),
          _Face.down: _filledFace(size, _StickerColor.yellow),
          _Face.front: _filledFace(size, _StickerColor.green),
          _Face.back: _filledFace(size, _StickerColor.blue),
          _Face.right: _filledFace(size, _StickerColor.red),
          _Face.left: _filledFace(size, _StickerColor.orange),
        };

  final int size;
  final Map<_Face, List<List<_StickerColor>>> faces;

  static List<List<_StickerColor>> _filledFace(int size, _StickerColor color) {
    return List.generate(
      size,
      (_) => List.generate(size, (_) => color),
    );
  }

  _CubeNetData apply(String notation) {
    for (final token in notation.split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      final move = _MoveToken.parse(token);
      if (move == null) continue;
      _applyMove(move);
    }

    return _CubeNetData(
      up: _flatten(faces[_Face.up]!),
      right: _flatten(faces[_Face.right]!),
      front: _flatten(faces[_Face.front]!),
      down: _flatten(faces[_Face.down]!),
      left: _flatten(faces[_Face.left]!),
      back: _flatten(faces[_Face.back]!),
      size: size,
    );
  }

  List<_StickerColor> _flatten(List<List<_StickerColor>> face) {
    return face.expand((row) => row).toList(growable: false);
  }

  void _applyMove(_MoveToken move) {
    var turns = move.turns;
    if (move.face == 'L' || move.face == 'D' || move.face == 'B') {
      turns = (4 - turns) % 4;
      if (turns == 0) {
        turns = 4;
      }
    }

    for (var i = 0; i < turns; i++) {
      _applyQuarterTurn(move.face, move.layers);
    }
  }

  void _applyQuarterTurn(String face, int layers) {
    switch (face) {
      case 'U':
        for (var layer = 0; layer < layers; layer++) {
          _turnY(size - 1 - layer);
        }
        _rotateFaceClockwise(_Face.up);
        break;
      case 'D':
        for (var layer = 0; layer < layers; layer++) {
          _turnY(layer);
        }
        _rotateFaceCounterClockwise(_Face.down);
        break;
      case 'R':
        for (var layer = 0; layer < layers; layer++) {
          _turnX(size - 1 - layer);
        }
        _rotateFaceClockwise(_Face.right);
        break;
      case 'L':
        for (var layer = 0; layer < layers; layer++) {
          _turnX(layer);
        }
        _rotateFaceCounterClockwise(_Face.left);
        break;
      case 'F':
        for (var layer = 0; layer < layers; layer++) {
          _turnZ(size - 1 - layer);
        }
        _rotateFaceClockwise(_Face.front);
        break;
      case 'B':
        for (var layer = 0; layer < layers; layer++) {
          _turnZ(layer);
        }
        _rotateFaceCounterClockwise(_Face.back);
        break;
    }
  }

  void _turnY(int layer) {
    final front = _row(_Face.front, layerFromTop: size - 1 - layer);
    final right = _row(_Face.right, layerFromTop: size - 1 - layer);
    final back = _row(_Face.back, layerFromTop: size - 1 - layer);
    final left = _row(_Face.left, layerFromTop: size - 1 - layer);

    _setRow(_Face.right, size - 1 - layer, front);
    _setRow(_Face.back, size - 1 - layer, right);
    _setRow(_Face.left, size - 1 - layer, back);
    _setRow(_Face.front, size - 1 - layer, left);
  }

  void _turnX(int layer) {
    final up = _column(_Face.up, layer);
    final front = _column(_Face.front, layer);
    final down = _column(_Face.down, layer);
    final back = _column(_Face.back, size - 1 - layer, reversed: true);

    _setColumn(_Face.front, layer, up);
    _setColumn(_Face.down, layer, front);
    _setColumn(_Face.back, size - 1 - layer, down.reversed.toList());
    _setColumn(_Face.up, layer, back);
  }

  void _turnZ(int layer) {
    final up = _row(_Face.up, layerFromTop: size - 1 - layer);
    final right = _column(_Face.right, layer, reversed: true);
    final down = _row(_Face.down, layerFromTop: layer, reversed: true);
    final left = _column(_Face.left, size - 1 - layer);

    _setColumn(_Face.right, layer, up.reversed.toList());
    _setRow(_Face.down, layer, right);
    _setColumn(_Face.left, size - 1 - layer, down);
    _setRow(_Face.up, size - 1 - layer, left.reversed.toList());
  }

  List<_StickerColor> _row(_Face face,
      {required int layerFromTop, bool reversed = false}) {
    final row = List<_StickerColor>.from(faces[face]![layerFromTop]);
    return reversed ? row.reversed.toList() : row;
  }

  void _setRow(_Face face, int layerFromTop, List<_StickerColor> values) {
    faces[face]![layerFromTop] = List<_StickerColor>.from(values);
  }

  List<_StickerColor> _column(_Face face, int index, {bool reversed = false}) {
    final column = List<_StickerColor>.generate(
      size,
      (row) => faces[face]![row][index],
    );
    return reversed ? column.reversed.toList() : column;
  }

  void _setColumn(_Face face, int index, List<_StickerColor> values) {
    for (var row = 0; row < size; row++) {
      faces[face]![row][index] = values[row];
    }
  }

  void _rotateFaceClockwise(_Face face) {
    final current = faces[face]!;
    final rotated = List.generate(
      size,
      (row) => List.generate(
        size,
        (col) => current[size - 1 - col][row],
      ),
    );
    faces[face] = rotated;
  }

  void _rotateFaceCounterClockwise(_Face face) {
    final current = faces[face]!;
    final rotated = List.generate(
      size,
      (row) => List.generate(
        size,
        (col) => current[col][size - 1 - row],
      ),
    );
    faces[face] = rotated;
  }
}

class _MoveToken {
  const _MoveToken({
    required this.face,
    required this.layers,
    required this.turns,
  });

  final String face;
  final int layers;
  final int turns;

  static _MoveToken? parse(String token) {
    final match =
        RegExp(r"^(\d+)?([URFDLB])(w)?(2|'|)?$").firstMatch(token.trim());
    if (match == null) return null;

    final widthPrefix = match.group(1);
    final face = match.group(2)!;
    final isWide = match.group(3) != null;
    final suffix = match.group(4) ?? '';

    final layers = widthPrefix != null
        ? int.parse(widthPrefix)
        : isWide
            ? 2
            : 1;
    final turns = suffix == '2'
        ? 2
        : suffix == "'"
            ? 3
            : 1;

    return _MoveToken(
      face: face,
      layers: layers,
      turns: turns,
    );
  }
}

class _CubeNet extends StatelessWidget {
  const _CubeNet({
    required this.net,
    required this.width,
    required this.height,
  });

  final _CubeNetData net;
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
        _positionFace(net.up, offsetX + faceSize + faceGap, offsetY, faceSize),
        _positionFace(
            net.left, offsetX, offsetY + faceSize + faceGap, faceSize),
        _positionFace(net.front, offsetX + faceSize + faceGap,
            offsetY + faceSize + faceGap, faceSize),
        _positionFace(net.right, offsetX + (faceSize + faceGap) * 2,
            offsetY + faceSize + faceGap, faceSize),
        _positionFace(net.back, offsetX + (faceSize + faceGap) * 3,
            offsetY + faceSize + faceGap, faceSize),
        _positionFace(net.down, offsetX + faceSize + faceGap,
            offsetY + (faceSize + faceGap) * 2, faceSize),
      ],
    );
  }

  Widget _positionFace(
      List<_StickerColor> face, double left, double top, double size) {
    return Positioned(
      left: left,
      top: top,
      child: _CubeFace(
        colors: face,
        size: size,
        dimension: net.size,
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

  final List<_StickerColor> colors;
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

enum _Face { up, right, front, down, left, back }

enum _StickerColor {
  white(Colors.white),
  yellow(Color(0xFFFFEB3B)),
  green(Color(0xFF22C55E)),
  blue(Color(0xFF1D4ED8)),
  red(Color(0xFFF44336)),
  orange(Color(0xFFFF9800));

  const _StickerColor(this.color);

  final Color color;
}

class _CubeNetData {
  const _CubeNetData({
    required this.up,
    required this.right,
    required this.front,
    required this.down,
    required this.left,
    required this.back,
    required this.size,
  });

  final List<_StickerColor> up;
  final List<_StickerColor> right;
  final List<_StickerColor> front;
  final List<_StickerColor> down;
  final List<_StickerColor> left;
  final List<_StickerColor> back;
  final int size;
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

class _PyraminxPreviewEngine {
  static _PyraminxState apply(String notation) {
    final faces = {
      'U': List<_StickerColor>.filled(9, _StickerColor.blue),
      'L': List<_StickerColor>.filled(9, _StickerColor.red),
      'R': List<_StickerColor>.filled(9, _StickerColor.green),
      'B': List<_StickerColor>.filled(9, _StickerColor.yellow),
    };

    for (final token in notation.split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      final parsed = _PyraminxMove.parse(token);
      if (parsed == null) continue;

      final turns = parsed.clockwise ? 1 : 2;
      for (var i = 0; i < turns; i++) {
        _turnFace(faces, parsed.face);
      }
    }

    return _PyraminxState(
      up: faces['U']!,
      left: faces['L']!,
      right: faces['R']!,
      bottom: faces['B']!,
    );
  }

  static void _turnFace(Map<String, List<_StickerColor>> faces, String face) {
    final current = faces[face]!;
    faces[face] = _rotateTriangle(current);
  }

  static List<_StickerColor> _rotateTriangle(List<_StickerColor> face) {
    return [
      face[2],
      face[5],
      face[8],
      face[1],
      face[4],
      face[7],
      face[0],
      face[3],
      face[6],
    ];
  }
}

class _PyraminxMove {
  const _PyraminxMove({
    required this.face,
    required this.clockwise,
  });

  final String face;
  final bool clockwise;

  static _PyraminxMove? parse(String token) {
    final match = RegExp(r"^([RLUBrlub])('?)+?$").firstMatch(token);
    if (match == null) return null;

    return _PyraminxMove(
      face: match.group(1)!.toUpperCase(),
      clockwise: !token.endsWith("'"),
    );
  }
}

class _PyraminxState {
  const _PyraminxState({
    required this.up,
    required this.left,
    required this.right,
    required this.bottom,
  });

  final List<_StickerColor> up;
  final List<_StickerColor> left;
  final List<_StickerColor> right;
  final List<_StickerColor> bottom;
}

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
    final gap = math.max(6.0, width * 0.03);
    final triWidth = math.min((width - gap * 2) / 3, height / 2);
    final triHeight = triWidth * 0.88;
    final centerX = width / 2;

    return Stack(
      children: [
        Positioned(
          left: centerX - triWidth / 2,
          top: 0,
          child: _PyraminxFace(
            stickers: state.up,
            width: triWidth,
            height: triHeight,
            upsideDown: true,
          ),
        ),
        Positioned(
          left: centerX - triWidth - gap / 2,
          top: triHeight * 0.72,
          child: _PyraminxFace(
            stickers: state.left,
            width: triWidth,
            height: triHeight,
          ),
        ),
        Positioned(
          left: centerX + gap / 2,
          top: triHeight * 0.72,
          child: _PyraminxFace(
            stickers: state.right,
            width: triWidth,
            height: triHeight,
          ),
        ),
        Positioned(
          left: centerX - triWidth / 2,
          top: triHeight * 1.58,
          child: _PyraminxFace(
            stickers: state.bottom,
            width: triWidth,
            height: triHeight,
          ),
        ),
      ],
    );
  }
}

class _PyraminxFace extends StatelessWidget {
  const _PyraminxFace({
    required this.stickers,
    required this.width,
    required this.height,
    this.upsideDown = false,
  });

  final List<_StickerColor> stickers;
  final double width;
  final double height;
  final bool upsideDown;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _PyraminxFacePainter(
        stickers: stickers,
        upsideDown: upsideDown,
      ),
    );
  }
}

class _PyraminxFacePainter extends CustomPainter {
  const _PyraminxFacePainter({
    required this.stickers,
    required this.upsideDown,
  });

  final List<_StickerColor> stickers;
  final bool upsideDown;

  @override
  void paint(Canvas canvas, Size size) {
    final rows = [
      [0],
      [1, 2],
      [3, 4, 5],
      [6, 7, 8],
    ];
    var stickerIndex = 0;

    for (var row = 0; row < rows.length; row++) {
      final count = rows[row].length;
      final y = size.height * (row / 4);
      final rowWidth = size.width * ((row + 1) / 4);
      final left = (size.width - rowWidth) / 2;

      for (var col = 0; col < count; col++) {
        final segWidth = rowWidth / count;
        final x = left + col * segWidth;

        final path = Path();
        if (upsideDown) {
          path.moveTo(x, y);
          path.lineTo(x + segWidth, y);
          path.lineTo(x + segWidth / 2, y + size.height / 4);
        } else {
          path.moveTo(x + segWidth / 2, y);
          path.lineTo(x, y + size.height / 4);
          path.lineTo(x + segWidth, y + size.height / 4);
        }
        path.close();

        canvas.drawPath(
          path,
          Paint()..color = stickers[stickerIndex].color,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.6, size.width * 0.008),
        );
        stickerIndex++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PyraminxFacePainter oldDelegate) {
    return oldDelegate.stickers != stickers ||
        oldDelegate.upsideDown != upsideDown;
  }
}
