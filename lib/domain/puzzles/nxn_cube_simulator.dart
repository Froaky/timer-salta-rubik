/// Simulador facelet puro (sin Flutter) para cubos NxN (2x2 .. 7x7).
///
/// Orientación WCA de scramble: blanco en U, verde en F.
/// Los ids de color de sticker son los de [CubeColorIds]. Cada cara se expone
/// row-major vista desde afuera del cubo, con B desplegada a la derecha de R
/// (net estándar tipo csTimer).
///
/// La lógica de giros fue validada contra el paquete `cuber` (ver tests en
/// `test/domain/puzzles/nxn_cube_simulator_test.dart`).
library;

/// Ids de color usados por [NxnCubeSimulator].
abstract final class CubeColorIds {
  static const int white = 0;
  static const int yellow = 1;
  static const int green = 2;
  static const int blue = 3;
  static const int red = 4;
  static const int orange = 5;
}

/// Estado facelet resultante de aplicar un scramble a un cubo NxN.
class NxnCubeFacelets {
  const NxnCubeFacelets({
    required this.size,
    required this.up,
    required this.right,
    required this.front,
    required this.down,
    required this.left,
    required this.back,
  });

  final int size;
  final List<int> up;
  final List<int> right;
  final List<int> front;
  final List<int> down;
  final List<int> left;
  final List<int> back;
}

class NxnCubeSimulator {
  NxnCubeSimulator({required this.size})
      : assert(size >= 2),
        _stickers = _buildSolvedStickers(size);

  final int size;
  final List<_Sticker> _stickers;

  static List<_Sticker> _buildSolvedStickers(int size) {
    final stickers = <_Sticker>[];
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        stickers
          ..add(_Sticker(
            position: _positionFor(_Face.up, row, column, size),
            normal: const _Vector3(0, 1, 0),
            color: CubeColorIds.white,
          ))
          ..add(_Sticker(
            position: _positionFor(_Face.down, row, column, size),
            normal: const _Vector3(0, -1, 0),
            color: CubeColorIds.yellow,
          ))
          ..add(_Sticker(
            position: _positionFor(_Face.front, row, column, size),
            normal: const _Vector3(0, 0, 1),
            color: CubeColorIds.green,
          ))
          ..add(_Sticker(
            position: _positionFor(_Face.back, row, column, size),
            normal: const _Vector3(0, 0, -1),
            color: CubeColorIds.blue,
          ))
          ..add(_Sticker(
            position: _positionFor(_Face.right, row, column, size),
            normal: const _Vector3(1, 0, 0),
            color: CubeColorIds.red,
          ))
          ..add(_Sticker(
            position: _positionFor(_Face.left, row, column, size),
            normal: const _Vector3(-1, 0, 0),
            color: CubeColorIds.orange,
          ));
      }
    }
    return stickers;
  }

  /// Aplica una secuencia en notación WCA y devuelve el estado resultante.
  ///
  /// Soporta caras externas (`R`, `U'`, `F2`), wide moves (`Rw`, `3Fw2`) y
  /// rotaciones de cubo completo (`x`, `y'`, `z2`). Tokens desconocidos se
  /// ignoran para que un scramble con notación extra no rompa el preview.
  NxnCubeFacelets apply(String notation) {
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

    return NxnCubeFacelets(
      size: size,
      up: _collectFace(_Face.up),
      right: _collectFace(_Face.right),
      front: _collectFace(_Face.front),
      down: _collectFace(_Face.down),
      left: _collectFace(_Face.left),
      back: _collectFace(_Face.back),
    );
  }

  void _applyMove(_MoveToken move) {
    if (move.isRotation) {
      _applyRotation(move);
      return;
    }

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

  void _applyRotation(_MoveToken move) {
    // x gira como R, y como U, z como F, sobre todas las capas.
    final referenceFace = switch (move.face) {
      'x' => 'R',
      'y' => 'U',
      _ => 'F',
    };
    final axis = _axisFor(referenceFace);
    final quarterTurns = move.turns * _clockwiseDirection(referenceFace);
    final turns = quarterTurns % 4;
    if (turns == 0) {
      return;
    }
    for (var i = 0; i < turns.abs(); i++) {
      for (var index = 0; index < _stickers.length; index++) {
        _stickers[index] = _stickers[index].rotated(
          axis: axis,
          clockwise: turns > 0,
        );
      }
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

  List<int> _collectFace(_Face face) {
    final rows = List.generate(
      size,
      (_) => List.filled(size, CubeColorIds.white),
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

  static _Vector3 _positionFor(_Face face, int row, int column, int size) {
    final min = -(size - 1);
    final max = size - 1;
    final x = min + column * 2;
    final y = max - row * 2;
    final zFromTop = min + row * 2;
    final zFromColumn = min + column * 2;
    final inverseColumn = max - column * 2;
    final inverseRow = max - row * 2;

    switch (face) {
      case _Face.up:
        return _Vector3(x, max, zFromTop);
      case _Face.down:
        return _Vector3(x, min, inverseRow);
      case _Face.front:
        return _Vector3(x, y, max);
      case _Face.back:
        return _Vector3(inverseColumn, y, min);
      case _Face.right:
        return _Vector3(max, y, inverseColumn);
      case _Face.left:
        return _Vector3(min, y, zFromColumn);
    }
  }

  static _Vector3 _normalForFace(_Face face) {
    switch (face) {
      case _Face.up:
        return const _Vector3(0, 1, 0);
      case _Face.right:
        return const _Vector3(1, 0, 0);
      case _Face.front:
        return const _Vector3(0, 0, 1);
      case _Face.down:
        return const _Vector3(0, -1, 0);
      case _Face.left:
        return const _Vector3(-1, 0, 0);
      case _Face.back:
        return const _Vector3(0, 0, -1);
    }
  }

  int _rowForFace(_Face face, _Vector3 position) {
    switch (face) {
      case _Face.up:
        return (position.z + (size - 1)) ~/ 2;
      case _Face.down:
        return ((size - 1) - position.z) ~/ 2;
      case _Face.front:
      case _Face.back:
      case _Face.right:
      case _Face.left:
        return ((size - 1) - position.y) ~/ 2;
    }
  }

  int _columnForFace(_Face face, _Vector3 position) {
    switch (face) {
      case _Face.up:
      case _Face.down:
      case _Face.front:
        return (position.x + (size - 1)) ~/ 2;
      case _Face.back:
        return ((size - 1) - position.x) ~/ 2;
      case _Face.right:
        return ((size - 1) - position.z) ~/ 2;
      case _Face.left:
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

enum _Face { up, right, front, down, left, back }

class _MoveToken {
  const _MoveToken({
    required this.face,
    required this.layers,
    required this.turns,
    this.isRotation = false,
  });

  final String face;
  final int layers;
  final int turns;
  final bool isRotation;

  static _MoveToken? parse(String token) {
    final trimmed = token.trim();

    final rotation = RegExp(r"^([xyz])(2|')?$").firstMatch(trimmed);
    if (rotation != null) {
      return _MoveToken(
        face: rotation.group(1)!,
        layers: 0,
        turns: _turnsForSuffix(rotation.group(2)),
        isRotation: true,
      );
    }

    final match = RegExp(r"^(\d+)?([URFDLB])(w)?(2|')?$").firstMatch(trimmed);
    if (match == null) {
      return null;
    }

    final widthPrefix = match.group(1);
    final face = match.group(2)!;
    final isWide = match.group(3) != null;
    final layers = widthPrefix != null
        ? int.parse(widthPrefix)
        : isWide
            ? 2
            : 1;

    return _MoveToken(
      face: face,
      layers: layers,
      turns: _turnsForSuffix(match.group(4)),
    );
  }

  static int _turnsForSuffix(String? suffix) {
    switch (suffix) {
      case '2':
        return 2;
      case "'":
        return 3;
      default:
        return 1;
    }
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
  final int color;

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
