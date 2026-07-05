import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/puzzles/skewb_simulator.dart';

void main() {
  group('SkewbSimulator', () {
    test('solved state keeps each face uniform', () {
      final state = SkewbSimulator().apply('');

      for (var face = 0; face < 6; face++) {
        expect(state.faces[face], everyElement(face));
      }
    });

    test('U cycles the centers of faces 0, 5 and 1', () {
      final state = SkewbSimulator().apply('U');

      // Ciclo de centros de la tabla csTimer: 0 → 5 → 1 → 0.
      expect(state.faces[5][0], 0);
      expect(state.faces[1][0], 5);
      expect(state.faces[0][0], 1);
    });

    test('a move affects exactly 15 stickers', () {
      for (final move in ['R', 'U', 'L', 'B']) {
        final state = SkewbSimulator().apply(move);
        expect(_changedStickers(state), 15, reason: 'Mismatch on $move');
      }
    });

    test('three equal turns are the identity', () {
      for (final move in ['R', 'U', 'L', 'B']) {
        final state = SkewbSimulator().apply('$move $move $move');
        expect(_changedStickers(state), 0, reason: 'Mismatch on $move');
      }
    });

    test('a move plus its inverse is the identity', () {
      final state = SkewbSimulator().apply("R U L B B' L' U' R'");

      expect(_changedStickers(state), 0);
    });

    test('sticker color counts are conserved', () {
      final state = SkewbSimulator().apply("L R L U R B' U' B L'");

      final counts = List<int>.filled(6, 0);
      for (final face in state.faces) {
        for (final sticker in face) {
          counts[sticker]++;
        }
      }
      expect(counts, everyElement(5));
    });
  });
}

int _changedStickers(SkewbFacelets state) {
  var changed = 0;
  for (var face = 0; face < 6; face++) {
    for (var i = 0; i < 5; i++) {
      if (state.faces[face][i] != face) {
        changed++;
      }
    }
  }
  return changed;
}
