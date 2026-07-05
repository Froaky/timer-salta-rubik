import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/puzzles/megaminx_simulator.dart';

void main() {
  group('MegaminxSimulator', () {
    test('solved state keeps each face uniform', () {
      final state = MegaminxSimulator().apply('');

      for (var face = 0; face < 12; face++) {
        expect(state.faces[face], everyElement(face));
      }
    });

    test('U keeps the U face color and cycles the top band', () {
      final state = MegaminxSimulator().apply('U');

      expect(state.faces[0], everyElement(0));
      // La cara 1 recibe la tira superior (esquinas 3 y 4, arista 8) de la
      // cara 5, según la permutación de csTimer.
      expect(state.faces[1][3], 5);
      expect(state.faces[1][4], 5);
      expect(state.faces[1][8], 5);
      // La flor inferior no cambia con U.
      for (var face = 6; face < 12; face++) {
        expect(state.faces[face], everyElement(face));
      }
    });

    test('five U turns are the identity', () {
      final state = MegaminxSimulator().apply('U U U U U');

      expect(_changedStickers(state), 0);
    });

    test('five R++ turns are the identity', () {
      final state = MegaminxSimulator().apply('R++ R++ R++ R++ R++');

      expect(_changedStickers(state), 0);
    });

    test('five D-- turns are the identity', () {
      final state = MegaminxSimulator().apply('D-- D-- D-- D-- D--');

      expect(_changedStickers(state), 0);
    });

    test('a sequence plus its mirrored inverse is the identity', () {
      final state = MegaminxSimulator().apply("R++ D-- U U' D++ R--");

      expect(_changedStickers(state), 0);
    });

    test('sticker color counts are conserved on a full scramble line', () {
      final state = MegaminxSimulator()
          .apply('R-- D++ R++ D++ R++ D-- R-- D-- R-- D++ U');

      final counts = List<int>.filled(12, 0);
      for (final face in state.faces) {
        for (final sticker in face) {
          counts[sticker]++;
        }
      }
      expect(counts, everyElement(11));
    });
  });
}

int _changedStickers(MegaminxFacelets state) {
  var changed = 0;
  for (var face = 0; face < 12; face++) {
    for (var i = 0; i < 11; i++) {
      if (state.faces[face][i] != face) {
        changed++;
      }
    }
  }
  return changed;
}
