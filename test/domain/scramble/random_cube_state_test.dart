import 'dart:math';

import 'package:cuber/cuber.dart' as cuber;
import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/scramble/random_cube_state.dart';

void main() {
  group('randomThreeByThreeState', () {
    test('siempre produce un estado válido y resoluble', () {
      final random = Random(3);
      var solvedCount = 0;

      for (var i = 0; i < 300; i++) {
        final cube = randomThreeByThreeState(random);

        // verify() chequea las 3 restricciones (orientaciones y paridad).
        expect(cube.verify(), cuber.CubeStatus.ok,
            reason: 'estado inválido en iteración $i');

        if (cube.isSolved) solvedCount++;
      }

      // Un estado uniforme prácticamente nunca sale resuelto.
      expect(solvedCount, 0);
    });

    test('el estado uniforme es realmente resoluble por Kociemba', () {
      final random = Random(7);

      for (var i = 0; i < 20; i++) {
        final cube = randomThreeByThreeState(random);
        final solution = cube.solve(maxDepth: 25);
        expect(solution, isNotNull, reason: 'sin solución en iteración $i');
      }
    });
  });
}
