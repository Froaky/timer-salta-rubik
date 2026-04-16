import 'package:flutter/material.dart';

enum CubePreviewFace { up, right, front, down, left, back }

enum CubePreviewColor {
  white(Colors.white),
  yellow(Color(0xFFFFEB3B)),
  green(Color(0xFF22C55E)),
  blue(Color(0xFF1D4ED8)),
  red(Color(0xFFF44336)),
  orange(Color(0xFFFF9800));

  const CubePreviewColor(this.color);

  final Color color;
}

class CubeNetData {
  const CubeNetData({
    required this.up,
    required this.right,
    required this.front,
    required this.down,
    required this.left,
    required this.back,
    required this.size,
  });

  final List<CubePreviewColor> up;
  final List<CubePreviewColor> right;
  final List<CubePreviewColor> front;
  final List<CubePreviewColor> down;
  final List<CubePreviewColor> left;
  final List<CubePreviewColor> back;
  final int size;

  List<CubePreviewColor> face(CubePreviewFace face) {
    switch (face) {
      case CubePreviewFace.up:
        return up;
      case CubePreviewFace.right:
        return right;
      case CubePreviewFace.front:
        return front;
      case CubePreviewFace.down:
        return down;
      case CubePreviewFace.left:
        return left;
      case CubePreviewFace.back:
        return back;
    }
  }
}

class CubePreviewEngine {
  CubePreviewEngine({required this.size})
      : _stickers = _buildSolvedStickers(size);

  final int size;
  final List<_Sticker> _stickers;

  static List<_Sticker> _buildSolvedStickers(int size) {
    final stickers = <_Sticker>[];
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        stickers
          ..add(
            _Sticker(
              position: _positionFor(CubePreviewFace.up, row, column, size),
              normal: const _Vector3(0, 1, 0),
              color: CubePreviewColor.white,
            ),
          )
          ..add(
            _Sticker(
              position: _positionFor(CubePreviewFace.down, row, column, size),
              normal: const _Vector3(0, -1, 0),
              color: CubePreviewColor.yellow,
            ),
          )
          ..add(
            _Sticker(
              position: _positionFor(CubePreviewFace.front, row, column, size),
              normal: const _Vector3(0, 0, 1),
              color: CubePreviewColor.green,
            ),
          )
          ..add(
            _Sticker(
              position: _positionFor(CubePreviewFace.back, row, column, size),
              normal: const _Vector3(0, 0, -1),
              color: CubePreviewColor.blue,
            ),
          )
          ..add(
            _Sticker(
              position: _positionFor(CubePreviewFace.right, row, column, size),
              normal: const _Vector3(1, 0, 0),
              color: CubePreviewColor.red,
            ),
          )
          ..add(
            _Sticker(
              position: _positionFor(CubePreviewFace.left, row, column, size),
              normal: const _Vector3(-1, 0, 0),
              color: CubePreviewColor.orange,
            ),
          );
      }
    }
    return stickers;
  }

  CubeNetData apply(String notation) {
    for (final token in notation.split(RegExp(r'\s+'))) {
      if (token.isEmpty) {
        continue;
      }
      final move = _MoveToken.parse(token);
      if (move == null) {
        continue;
      }
      _applyMove(move);
    }

    return CubeNetData(
      up: _collectFace(CubePreviewFace.up),
      right: _collectFace(CubePreviewFace.right),
      front: _collectFace(CubePreviewFace.front),
      down: _collectFace(CubePreviewFace.down),
      left: _collectFace(CubePreviewFace.left),
      back: _collectFace(CubePreviewFace.back),
      size: size,
    );
  }

  void _applyMove(_MoveToken move) {
    final axis = _axisFor(move.face);
    final outerCoordinate = size - 1;
    final clockwiseDirection = _clockwiseDirection(move.face);
    final quarterTurns = move.turns * clockwiseDirection;

    for (var layer = 0; layer < move.layers; layer++) {
      final layerCoordinate = _isPositiveFace(move.face)
          ? outerCoordinate - (layer * 2)
          : -outerCoordinate + (layer * 2);
      _rotateLayer(
        axis: axis,
        layerCoordinate: layerCoordinate,
        quarterTurns: quarterTurns,
      );
    }
  }

  void _rotateLayer({
    required String axis,
    required int layerCoordinate,
    required int quarterTurns,
  }) {
    final turns = quarterTurns % 4;
    if (turns == 0) {
      return;
    }

    for (var i = 0; i < turns.abs(); i++) {
      final clockwise = turns > 0;
      for (var index = 0; index < _stickers.length; index++) {
        final sticker = _stickers[index];
        if (_coordinateForAxis(sticker.position, axis) != layerCoordinate) {
          continue;
        }

        _stickers[index] = sticker.rotated(
          axis: axis,
          clockwise: clockwise,
        );
      }
    }
  }

  List<CubePreviewColor> _collectFace(CubePreviewFace face) {
    final rows = List.generate(
      size,
      (_) => List.filled(size, CubePreviewColor.white),
    );
    final expectedNormal = _normalForFace(face);

    for (final sticker in _stickers) {
      if (sticker.normal != expectedNormal) {
        continue;
      }

      final row = _rowForFace(face, sticker.position);
      final column = _columnForFace(face, sticker.position);
      rows[row][column] = sticker.color;
    }

    return rows.expand((row) => row).toList(growable: false);
  }

  static _Vector3 _positionFor(
    CubePreviewFace face,
    int row,
    int column,
    int size,
  ) {
    final min = -(size - 1);
    final max = size - 1;
    final x = min + column * 2;
    final y = max - row * 2;
    final zFromTop = min + row * 2;
    final zFromColumn = min + column * 2;
    final inverseColumn = max - column * 2;
    final inverseRow = max - row * 2;

    switch (face) {
      case CubePreviewFace.up:
        return _Vector3(x, max, zFromTop);
      case CubePreviewFace.down:
        return _Vector3(x, min, inverseRow);
      case CubePreviewFace.front:
        return _Vector3(x, y, max);
      case CubePreviewFace.back:
        return _Vector3(inverseColumn, y, min);
      case CubePreviewFace.right:
        return _Vector3(max, y, inverseColumn);
      case CubePreviewFace.left:
        return _Vector3(min, y, zFromColumn);
    }
  }

  static _Vector3 _normalForFace(CubePreviewFace face) {
    switch (face) {
      case CubePreviewFace.up:
        return const _Vector3(0, 1, 0);
      case CubePreviewFace.right:
        return const _Vector3(1, 0, 0);
      case CubePreviewFace.front:
        return const _Vector3(0, 0, 1);
      case CubePreviewFace.down:
        return const _Vector3(0, -1, 0);
      case CubePreviewFace.left:
        return const _Vector3(-1, 0, 0);
      case CubePreviewFace.back:
        return const _Vector3(0, 0, -1);
    }
  }

  int _rowForFace(CubePreviewFace face, _Vector3 position) {
    switch (face) {
      case CubePreviewFace.up:
        return (position.z + (size - 1)) ~/ 2;
      case CubePreviewFace.down:
        return ((size - 1) - position.z) ~/ 2;
      case CubePreviewFace.front:
      case CubePreviewFace.back:
      case CubePreviewFace.right:
      case CubePreviewFace.left:
        return ((size - 1) - position.y) ~/ 2;
    }
  }

  int _columnForFace(CubePreviewFace face, _Vector3 position) {
    switch (face) {
      case CubePreviewFace.up:
      case CubePreviewFace.down:
      case CubePreviewFace.front:
        return (position.x + (size - 1)) ~/ 2;
      case CubePreviewFace.back:
        return ((size - 1) - position.x) ~/ 2;
      case CubePreviewFace.right:
        return ((size - 1) - position.z) ~/ 2;
      case CubePreviewFace.left:
        return (position.z + (size - 1)) ~/ 2;
    }
  }

  static String _axisFor(String face) {
    switch (face) {
      case 'L':
      case 'R':
        return 'x';
      case 'U':
      case 'D':
        return 'y';
      case 'F':
      case 'B':
        return 'z';
      default:
        throw ArgumentError('Unsupported face: $face');
    }
  }

  static bool _isPositiveFace(String face) =>
      face == 'U' || face == 'R' || face == 'F';

  static int _clockwiseDirection(String face) {
    switch (face) {
      case 'U':
      case 'R':
      case 'B':
        return -1;
      case 'F':
      case 'D':
      case 'L':
        return 1;
      default:
        throw ArgumentError('Unsupported face: $face');
    }
  }

  static int _coordinateForAxis(_Vector3 vector, String axis) {
    switch (axis) {
      case 'x':
        return vector.x;
      case 'y':
        return vector.y;
      case 'z':
        return vector.z;
      default:
        throw ArgumentError('Unsupported axis: $axis');
    }
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
    if (match == null) {
      return null;
    }

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

class _Sticker {
  const _Sticker({
    required this.position,
    required this.normal,
    required this.color,
  });

  final _Vector3 position;
  final _Vector3 normal;
  final CubePreviewColor color;

  _Sticker rotated({
    required String axis,
    required bool clockwise,
  }) {
    return _Sticker(
      position: position.rotated(axis: axis, clockwise: clockwise),
      normal: normal.rotated(axis: axis, clockwise: clockwise),
      color: color,
    );
  }
}

class _Vector3 {
  const _Vector3(this.x, this.y, this.z);

  final int x;
  final int y;
  final int z;

  _Vector3 rotated({
    required String axis,
    required bool clockwise,
  }) {
    switch (axis) {
      case 'x':
        return clockwise ? _Vector3(x, -z, y) : _Vector3(x, z, -y);
      case 'y':
        return clockwise ? _Vector3(z, y, -x) : _Vector3(-z, y, x);
      case 'z':
        return clockwise ? _Vector3(y, -x, z) : _Vector3(-y, x, z);
      default:
        throw ArgumentError('Unsupported axis: $axis');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Vector3 && x == other.x && y == other.y && z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);
}
