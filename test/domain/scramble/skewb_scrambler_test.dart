import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/scramble/skewb_scrambler.dart';

void main() {
  final scrambler = SkewbScrambler.instance;

  group('SkewbScrambler', () {
    test('subespacios densos: 360 centros y 8748 esquinas', () {
      // Fuerza la construcción y valida la identificación de piezas + BFS.
      scrambler.scrambleForState(0, 0);
      expect(scrambler.centerSubspaceCount, 360);
      expect(scrambler.cornerSubspaceCount, 8748);
      expect(scrambler.stateCount, 3149280);
    });

    test('produce scrambles válidos y óptimos (<= 11, solo R/U/L/B)', () {
      final movePattern = RegExp(r"^[RULB]'?$");
      final random = Random(5);

      for (var i = 0; i < 500; i++) {
        final moves = scrambler.generateScramble(random);
        expect(moves.length, lessThanOrEqualTo(11));
        expect(moves.every(movePattern.hasMatch), isTrue, reason: '$moves');
        for (var m = 1; m < moves.length; m++) {
          expect(moves[m - 1][0] == moves[m][0], isFalse,
              reason: 'caras consecutivas iguales: $moves');
        }
      }
    });

    test('el scramble reproduce el estado sorteado (ida y vuelta)', () {
      final random = Random(20);

      for (var i = 0; i < 1000; i++) {
        final ce = random.nextInt(scrambler.centerSubspaceCount);
        final co = random.nextInt(scrambler.cornerSubspaceCount);

        final scramble = scrambler.scrambleForState(ce, co);
        expect(scrambler.applyMovesToSolved(scramble), [ce, co],
            reason: 'estado ($ce,$co) scramble=$scramble');
      }
    });
  });
}
