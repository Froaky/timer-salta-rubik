import 'package:cuber/cuber.dart' as cuber;
import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/puzzles/nxn_cube_simulator.dart';

void main() {
  group('NxnCubeSimulator 3x3', () {
    test('keeps solved colors with no moves', () {
      final net = NxnCubeSimulator(size: 3).apply('');

      expect(_face(net.up, 3), equals(['WWW', 'WWW', 'WWW']));
      expect(_face(net.right, 3), equals(['RRR', 'RRR', 'RRR']));
      expect(_face(net.front, 3), equals(['GGG', 'GGG', 'GGG']));
      expect(_face(net.down, 3), equals(['YYY', 'YYY', 'YYY']));
      expect(_face(net.left, 3), equals(['OOO', 'OOO', 'OOO']));
      expect(_face(net.back, 3), equals(['BBB', 'BBB', 'BBB']));
    });

    test('applies U from white-up green-front orientation', () {
      final net = NxnCubeSimulator(size: 3).apply('U');

      expect(_face(net.up, 3), equals(['WWW', 'WWW', 'WWW']));
      expect(_face(net.front, 3), equals(['RRR', 'GGG', 'GGG']));
      expect(_face(net.right, 3), equals(['BBB', 'RRR', 'RRR']));
      expect(_face(net.back, 3), equals(['OOO', 'BBB', 'BBB']));
      expect(_face(net.left, 3), equals(['GGG', 'OOO', 'OOO']));
      expect(_face(net.down, 3), equals(['YYY', 'YYY', 'YYY']));
    });

    test('returns to solved state after inverse sequence', () {
      final net = NxnCubeSimulator(size: 3).apply("R U F F' U' R'");

      expect(_face(net.up, 3), equals(['WWW', 'WWW', 'WWW']));
      expect(_face(net.front, 3), equals(['GGG', 'GGG', 'GGG']));
    });

    test('matches cuber for all base quarter turns', () {
      const moves = ['U', 'R', 'F', 'D', 'L', 'B'];

      for (final move in moves) {
        final actual = _definition(NxnCubeSimulator(size: 3).apply(move));
        final expected = _mapCuberDefinition(
          cuber.Algorithm.parse(move).apply(cuber.Cube.solved).definition,
        );

        expect(actual, equals(expected), reason: 'Mismatch on $move');
      }
    });

    test('matches cuber for a full WCA-style scramble', () {
      const sequence =
          "D2 L2 B' U2 R F B' U' D2 F2 U2 L2 U2 F' D2 R2 B2 D2 B' L2";

      final actual = _definition(NxnCubeSimulator(size: 3).apply(sequence));
      final expected = _mapCuberDefinition(
        cuber.Algorithm.parse(sequence).apply(cuber.Cube.solved).definition,
      );

      expect(actual, equals(expected));
    });
  });

  group('NxnCubeSimulator rotations', () {
    test('y shows the right face color at the front', () {
      final net = NxnCubeSimulator(size: 3).apply('y');

      expect(_face(net.front, 3), equals(['RRR', 'RRR', 'RRR']));
      expect(_face(net.right, 3), equals(['BBB', 'BBB', 'BBB']));
      expect(_face(net.up, 3), equals(['WWW', 'WWW', 'WWW']));
    });

    test('x shows the down face color at the front', () {
      final net = NxnCubeSimulator(size: 3).apply('x');

      expect(_face(net.front, 3), equals(['YYY', 'YYY', 'YYY']));
      expect(_face(net.up, 3), equals(['GGG', 'GGG', 'GGG']));
    });

    test('z shows the left face color at the top', () {
      final net = NxnCubeSimulator(size: 3).apply('z');

      expect(_face(net.up, 3), equals(['OOO', 'OOO', 'OOO']));
      expect(_face(net.front, 3), equals(['GGG', 'GGG', 'GGG']));
    });

    test('rotation plus inverse is identity', () {
      final net = NxnCubeSimulator(size: 3).apply("x y z z' y' x'");

      expect(_face(net.up, 3), equals(['WWW', 'WWW', 'WWW']));
      expect(_face(net.front, 3), equals(['GGG', 'GGG', 'GGG']));
    });
  });

  group('NxnCubeSimulator wide moves', () {
    test('Rw on 4x4 moves the two right columns', () {
      final net = NxnCubeSimulator(size: 4).apply('Rw');

      expect(_face(net.up, 4), equals(['WWGG', 'WWGG', 'WWGG', 'WWGG']));
      expect(_face(net.front, 4), equals(['GGYY', 'GGYY', 'GGYY', 'GGYY']));
    });

    test('3Rw on 6x6 moves three layers', () {
      final net = NxnCubeSimulator(size: 6).apply('3Rw');

      expect(
        _face(net.up, 6),
        equals(List.filled(6, 'WWWGGG')),
      );
    });

    test('wide move plus inverse is identity on 5x5', () {
      final net = NxnCubeSimulator(size: 5).apply("Uw Fw Fw' Uw'");

      expect(_face(net.up, 5), equals(List.filled(5, 'WWWWW')));
      expect(_face(net.front, 5), equals(List.filled(5, 'GGGGG')));
    });
  });
}

const _symbols = ['W', 'Y', 'G', 'B', 'R', 'O'];

List<String> _face(List<int> stickers, int size) {
  return List.generate(
    size,
    (row) => List.generate(
      size,
      (column) => _symbols[stickers[row * size + column]],
    ).join(),
  );
}

String _definition(NxnCubeFacelets net) {
  return [
    ...net.up,
    ...net.right,
    ...net.front,
    ...net.down,
    ...net.left,
    ...net.back,
  ].map((id) => _symbols[id]).join();
}

/// `cuber` describe facelets con letras de cara (URFDLB); las traducimos a
/// nuestros símbolos de color con blanco arriba y verde al frente.
String _mapCuberDefinition(String definition) {
  const mapping = {
    'U': 'W',
    'R': 'R',
    'F': 'G',
    'D': 'Y',
    'L': 'O',
    'B': 'B',
  };
  return definition.split('').map((c) => mapping[c] ?? c).join();
}
