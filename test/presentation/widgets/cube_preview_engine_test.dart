import 'package:cuber/cuber.dart' as cuber;
import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/presentation/widgets/cube_preview_engine.dart';

void main() {
  group('CubePreviewEngine', () {
    test('keeps solved colors with no moves', () {
      final net = CubePreviewEngine(size: 3).apply('');

      expect(_face(net.up), equals(['WWW', 'WWW', 'WWW']));
      expect(_face(net.right), equals(['RRR', 'RRR', 'RRR']));
      expect(_face(net.front), equals(['GGG', 'GGG', 'GGG']));
      expect(_face(net.down), equals(['YYY', 'YYY', 'YYY']));
      expect(_face(net.left), equals(['OOO', 'OOO', 'OOO']));
      expect(_face(net.back), equals(['BBB', 'BBB', 'BBB']));
    });

    test('applies U from white-up green-front orientation', () {
      final net = CubePreviewEngine(size: 3).apply('U');

      expect(_face(net.up), equals(['WWW', 'WWW', 'WWW']));
      expect(_face(net.front), equals(['RRR', 'GGG', 'GGG']));
      expect(_face(net.right), equals(['BBB', 'RRR', 'RRR']));
      expect(_face(net.back), equals(['OOO', 'BBB', 'BBB']));
      expect(_face(net.left), equals(['GGG', 'OOO', 'OOO']));
      expect(_face(net.down), equals(['YYY', 'YYY', 'YYY']));
    });

    test('applies R from white-up green-front orientation', () {
      final net = CubePreviewEngine(size: 3).apply('R');

      expect(_face(net.up), equals(['WWG', 'WWG', 'WWG']));
      expect(_face(net.front), equals(['GGY', 'GGY', 'GGY']));
      expect(_face(net.down), equals(['YYB', 'YYB', 'YYB']));
      expect(_face(net.back), equals(['WBB', 'WBB', 'WBB']));
      expect(_face(net.right), equals(['RRR', 'RRR', 'RRR']));
      expect(_face(net.left), equals(['OOO', 'OOO', 'OOO']));
    });

    test('applies F from white-up green-front orientation', () {
      final net = CubePreviewEngine(size: 3).apply('F');

      expect(_face(net.up), equals(['WWW', 'WWW', 'OOO']));
      expect(_face(net.right), equals(['WRR', 'WRR', 'WRR']));
      expect(_face(net.down), equals(['RRR', 'YYY', 'YYY']));
      expect(_face(net.left), equals(['OOY', 'OOY', 'OOY']));
      expect(_face(net.front), equals(['GGG', 'GGG', 'GGG']));
      expect(_face(net.back), equals(['BBB', 'BBB', 'BBB']));
    });

    test('applies D from white-up green-front orientation', () {
      final net = CubePreviewEngine(size: 3).apply('D');

      expect(_face(net.up), equals(['WWW', 'WWW', 'WWW']));
      expect(_face(net.front), equals(['GGG', 'GGG', 'OOO']));
      expect(_face(net.right), equals(['RRR', 'RRR', 'GGG']));
      expect(_face(net.back), equals(['BBB', 'BBB', 'RRR']));
      expect(_face(net.left), equals(['OOO', 'OOO', 'BBB']));
      expect(_face(net.down), equals(['YYY', 'YYY', 'YYY']));
    });

    test('applies L from white-up green-front orientation', () {
      final net = CubePreviewEngine(size: 3).apply('L');

      expect(_face(net.up), equals(['BWW', 'BWW', 'BWW']));
      expect(_face(net.front), equals(['WGG', 'WGG', 'WGG']));
      expect(_face(net.down), equals(['GYY', 'GYY', 'GYY']));
      expect(_face(net.back), equals(['BBY', 'BBY', 'BBY']));
      expect(_face(net.left), equals(['OOO', 'OOO', 'OOO']));
      expect(_face(net.right), equals(['RRR', 'RRR', 'RRR']));
    });

    test('applies B from white-up green-front orientation', () {
      final net = CubePreviewEngine(size: 3).apply('B');

      expect(_face(net.up), equals(['RRR', 'WWW', 'WWW']));
      expect(_face(net.right), equals(['RRY', 'RRY', 'RRY']));
      expect(_face(net.down), equals(['YYY', 'YYY', 'OOO']));
      expect(_face(net.left), equals(['WOO', 'WOO', 'WOO']));
      expect(_face(net.front), equals(['GGG', 'GGG', 'GGG']));
      expect(_face(net.back), equals(['BBB', 'BBB', 'BBB']));
    });

    test('returns to solved state after inverse sequence', () {
      final net = CubePreviewEngine(size: 3).apply("R U F F' U' R'");

      expect(_face(net.up), equals(['WWW', 'WWW', 'WWW']));
      expect(_face(net.right), equals(['RRR', 'RRR', 'RRR']));
      expect(_face(net.front), equals(['GGG', 'GGG', 'GGG']));
      expect(_face(net.down), equals(['YYY', 'YYY', 'YYY']));
      expect(_face(net.left), equals(['OOO', 'OOO', 'OOO']));
      expect(_face(net.back), equals(['BBB', 'BBB', 'BBB']));
    });

    test('matches cuber for all base quarter turns', () {
      const moves = ['U', 'R', 'F', 'D', 'L', 'B'];

      for (final move in moves) {
        final actual = _definition(CubePreviewEngine(size: 3).apply(move));
        final expected = _mapCuberDefinition(
          cuber.Algorithm.parse(move).apply(cuber.Cube.solved).definition,
        );

        expect(actual, equals(expected), reason: 'Mismatch on $move');
      }
    });

    test('matches cuber for a common trigger sequence', () {
      const sequence = "R U R' U'";

      final actual = _definition(CubePreviewEngine(size: 3).apply(sequence));
      final expected = _mapCuberDefinition(
        cuber.Algorithm.parse(sequence).apply(cuber.Cube.solved).definition,
      );

      expect(actual, equals(expected));
    });
  });
}

List<String> _face(List<CubePreviewColor> stickers) {
  const size = 3;
  return List.generate(
    size,
    (row) => List.generate(
      size,
      (column) => _symbol(stickers[row * size + column]),
    ).join(),
  );
}

String _symbol(CubePreviewColor color) {
  switch (color) {
    case CubePreviewColor.white:
      return 'W';
    case CubePreviewColor.yellow:
      return 'Y';
    case CubePreviewColor.green:
      return 'G';
    case CubePreviewColor.blue:
      return 'B';
    case CubePreviewColor.red:
      return 'R';
    case CubePreviewColor.orange:
      return 'O';
  }
}

String _definition(CubeNetData net) {
  return [
    ...net.up,
    ...net.right,
    ...net.front,
    ...net.down,
    ...net.left,
    ...net.back,
  ].map(_symbol).join();
}

String _mapCuberDefinition(String definition) {
  return definition
      .replaceAll('U', 'W')
      .replaceAll('R', 'R')
      .replaceAll('F', 'G')
      .replaceAll('D', 'Y')
      .replaceAll('L', 'O')
      .replaceAll('B', 'B');
}
