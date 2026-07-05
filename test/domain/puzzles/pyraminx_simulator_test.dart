import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/puzzles/pyraminx_simulator.dart';

void main() {
  group('PyraminxSimulator', () {
    test('solved state keeps each face uniform', () {
      final state = PyraminxSimulator().apply('');

      for (var face = 0; face < 4; face++) {
        expect(state.faces[face], everyElement(face));
      }
    });

    test('a full turn moves exactly 12 stickers', () {
      final state = PyraminxSimulator().apply('U');

      expect(_changedStickers(state), 12);
    });

    test('a tip turn moves exactly 3 stickers', () {
      final state = PyraminxSimulator().apply('u');

      expect(_changedStickers(state), 3);
      // Ciclo del tip U (tabla csTimer): F.0 → L.1 → R.2 → F.0.
      expect(state.faces[0][0], 2);
      expect(state.faces[1][1], 0);
      expect(state.faces[2][2], 1);
    });

    test('three equal turns are the identity', () {
      for (final move in ['U', 'L', 'R', 'B']) {
        final state = PyraminxSimulator().apply('$move $move $move');
        expect(_changedStickers(state), 0, reason: 'Mismatch on $move');
      }
    });

    test('a move plus its inverse is the identity', () {
      final state = PyraminxSimulator().apply("U L R B B' R' L' U'");

      expect(_changedStickers(state), 0);
    });

    test('sticker color counts are conserved', () {
      final state = PyraminxSimulator().apply("B' U R B U B' L R' l' r b'");

      final counts = List<int>.filled(4, 0);
      for (final face in state.faces) {
        for (final sticker in face) {
          counts[sticker]++;
        }
      }
      expect(counts, everyElement(9));
    });

    test('U does not touch the down face', () {
      final state = PyraminxSimulator().apply('U');

      expect(state.faces[3], everyElement(3));
    });
  });
}

int _changedStickers(PyraminxFacelets state) {
  var changed = 0;
  for (var face = 0; face < 4; face++) {
    for (var i = 0; i < 9; i++) {
      if (state.faces[face][i] != face) {
        changed++;
      }
    }
  }
  return changed;
}
