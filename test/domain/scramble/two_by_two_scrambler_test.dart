import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/scramble/two_by_two_scrambler.dart';

void main() {
  final scrambler = TwoByTwoScrambler.instance;

  group('TwoByTwoScrambler', () {
    test('el BFS alcanza los 3.674.160 estados (cobertura total)', () {
      // Si el modelo de movimientos fuera incorrecto, algunos estados quedarían
      // inalcanzables y el generador podría sortear uno sin solución.
      expect(scrambler.reachableStateCount(), scrambler.stateCount);
      expect(scrambler.stateCount, 3674160);
    });

    test('produce scrambles válidos y óptimos (<= 11, solo R/U/F)', () {
      final movePattern = RegExp(r"^(R|U|F)(2|'|)?$");
      final random = Random(42);

      for (var i = 0; i < 500; i++) {
        final moves = scrambler.generateScramble(random);

        expect(moves, isNotEmpty);
        expect(moves.length, lessThanOrEqualTo(11));
        expect(moves.every(movePattern.hasMatch), isTrue, reason: '$moves');

        for (var m = 1; m < moves.length; m++) {
          expect(moves[m - 1][0] == moves[m][0], isFalse,
              reason: 'caras consecutivas iguales: $moves');
        }
      }
    });

    test('el scramble reproduce el estado sorteado (ida y vuelta)', () {
      // Aplicar el scramble a un cubo resuelto debe reconstruir exactamente el
      // estado objetivo: valida modelo de movimientos + coordenadas + solver +
      // inversión, todo junto.
      final random = Random(123);

      for (var i = 0; i < 400; i++) {
        final p = random.nextInt(scrambler.permCount);
        final o = random.nextInt(scrambler.orientationCount);
        final scramble = scrambler.scrambleForState(p, o);

        expect(scrambler.stateAfterMoves(scramble), [p, o],
            reason: 'estado ($p,$o) scramble=$scramble');
      }
    });

    test('cubre longitudes cortas y largas (distribución no degenerada)', () {
      final random = Random(7);
      final lengths = <int>{};

      for (var i = 0; i < 2000; i++) {
        lengths.add(scrambler.generateScramble(random).length);
      }

      // Debe aparecer alguna solución larga (>= 9) y variedad de longitudes.
      expect(lengths.any((l) => l >= 9), isTrue);
      expect(lengths.length, greaterThan(3));
    });
  });
}
