import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/scramble/pyraminx_scrambler.dart';

void main() {
  final scrambler = PyraminxScrambler.instance;

  group('PyraminxScrambler', () {
    test('el BFS alcanza los 933.120 estados del cuerpo (cobertura total)', () {
      expect(scrambler.reachableStateCount(), scrambler.bodyStateCount);
      expect(scrambler.bodyStateCount, 933120);
    });

    test('produce scrambles válidos (U/L/R/B + puntas u/l/r/b)', () {
      final layerPattern = RegExp(r"^[ULRB]'?$");
      final tipPattern = RegExp(r"^[ulrb]'?$");
      final random = Random(11);

      for (var i = 0; i < 300; i++) {
        final moves = scrambler.generateScramble(random);
        expect(moves, isNotEmpty);

        final tipStart = moves.indexWhere((m) => tipPattern.hasMatch(m));
        final layerMoves = tipStart < 0 ? moves : moves.sublist(0, tipStart);
        final tipMoves = tipStart < 0 ? const [] : moves.sublist(tipStart);

        // Cuerpo: capa óptima <= 11, sin cara repetida consecutiva.
        expect(layerMoves.length, lessThanOrEqualTo(11));
        for (final m in layerMoves) {
          expect(layerPattern.hasMatch(m), isTrue, reason: '$moves');
        }
        for (var k = 1; k < layerMoves.length; k++) {
          expect(layerMoves[k - 1][0] == layerMoves[k][0], isFalse,
              reason: 'caras consecutivas iguales: $moves');
        }

        // Puntas: como mucho una por vértice, todas válidas.
        expect(tipMoves.length, lessThanOrEqualTo(4));
        for (final m in tipMoves) {
          expect(tipPattern.hasMatch(m), isTrue, reason: '$moves');
        }
      }
    });

    test('el scramble reproduce el estado sorteado (ida y vuelta)', () {
      final random = Random(99);

      for (var i = 0; i < 400; i++) {
        final co = [for (var k = 0; k < 4; k++) random.nextInt(3)];
        final ep = _randomEvenPerm(random);
        final eo = _randomEvenOri(random);
        final idx = scrambler.encode(co, ep, eo);

        final scramble = scrambler.scrambleForBodyIndex(idx);
        expect(scrambler.applyBodyMovesToSolved(scramble), idx,
            reason: 'estado $idx  scramble=$scramble');
      }
    });
  });
}

List<int> _randomEvenPerm(Random random) {
  final p = [0, 1, 2, 3, 4, 5];
  for (var i = 5; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final t = p[i];
    p[i] = p[j];
    p[j] = t;
  }
  var inversions = 0;
  for (var i = 0; i < 6; i++) {
    for (var j = i + 1; j < 6; j++) {
      if (p[i] > p[j]) inversions++;
    }
  }
  if (inversions.isOdd) {
    final t = p[0];
    p[0] = p[1];
    p[1] = t;
  }
  return p;
}

List<int> _randomEvenOri(Random random) {
  final eo = List<int>.filled(6, 0);
  var sum = 0;
  for (var i = 0; i < 5; i++) {
    eo[i] = random.nextInt(2);
    sum += eo[i];
  }
  eo[5] = sum & 1;
  return eo;
}
