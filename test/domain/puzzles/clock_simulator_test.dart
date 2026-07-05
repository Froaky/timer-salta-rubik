import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/puzzles/clock_simulator.dart';

void main() {
  group('ClockSimulator', () {
    test('empty scramble keeps all dials at 12', () {
      final state = ClockSimulator().apply('');

      expect(state.leftDials, everyElement(0));
      expect(state.rightDials, everyElement(0));
    });

    test('a turn plus its inverse is the identity', () {
      final state = ClockSimulator().apply('UR3+ UR3-');

      expect(state.leftDials, everyElement(0));
      expect(state.rightDials, everyElement(0));
    });

    test('U after y2 turns the six upper front dials', () {
      final state = ClockSimulator().apply('y2 U1+');

      expect(state.frontOnLeft, isTrue);
      // Las dos filas superiores del frente avanzan una hora.
      expect(state.leftDials, [1, 1, 1, 1, 1, 1, 0, 0, 0]);
      // Las esquinas compartidas del dorso giran en sentido inverso.
      expect(state.rightDials, [11, 0, 11, 0, 0, 0, 0, 0, 0]);
    });

    test('corner dials are mirrored between both sides', () {
      final state = ClockSimulator().apply('y2 ALL4+');

      expect(state.leftDials, everyElement(4));
      // En el dorso solo las esquinas están acopladas (invertidas); los
      // demás relojes del dorso no se mueven con un ALL frontal.
      expect(state.rightDials, [8, 0, 8, 0, 0, 0, 8, 0, 8]);
    });

    test('trailing pin tokens raise the matching pins', () {
      final state = ClockSimulator().apply('y2 UL');

      expect(state.pinsUp, [
        true, false, false, false, // frente: solo UL arriba
        true, true, false, true, // dorso: espejo invertido (UL abajo)
      ]);
    });

    test('scramble without pin tokens leaves front pins down', () {
      final state = ClockSimulator().apply('UR1- DR5+ y2 U3- L2+');

      expect(state.pinsUp.sublist(0, 4), everyElement(isFalse));
      expect(state.pinsUp.sublist(4), everyElement(isTrue));
    });

    test('full WCA-style scramble produces valid hours', () {
      final state = ClockSimulator().apply(
          'UR1- DR1+ DL4- UL1+ U0+ R2- D2- L5- ALL3+ y2 U5- R2- D6+ L2- ALL2-');

      for (final hour in [...state.leftDials, ...state.rightDials]) {
        expect(hour, inInclusiveRange(0, 11));
      }
      expect(state.frontOnLeft, isTrue);
    });
  });
}
