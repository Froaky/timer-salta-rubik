import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/puzzles/square1_simulator.dart';

void main() {
  // Estado resuelto en slots (csTimer): aristas 1 slot, esquinas 2 slots.
  const solvedPieces = [
    0, 1, 1, 2, 3, 3, 4, 5, 5, 6, 7, 7, //
    9, 9, 8, 11, 11, 10, 13, 13, 12, 15, 15, 14,
  ];

  group('Square1Cubie', () {
    test('solved cube exposes the csTimer piece layout', () {
      final cubie = Square1Cubie();

      expect(List.generate(24, cubie.pieceAt), solvedPieces);
      expect(cubie.middleOffset, 0);
    });

    test('both layers are sliceable from solved', () {
      final cubie = Square1Cubie();

      expect(cubie.topSliceable, isTrue);
      expect(cubie.bottomSliceable, isTrue);
    });

    test('detects a corner blocking the top slice', () {
      final cubie = Square1Cubie()..doMove(2);

      // Tras girar 2 slots la esquina UBL queda atravesando el corte 11|0.
      expect(cubie.pieceAt(11), cubie.pieceAt(0));
      expect(cubie.topSliceable, isFalse);
    });

    test('detects a corner blocking the bottom slice', () {
      final cubie = Square1Cubie()..doMove(-1);

      expect(cubie.pieceAt(17), cubie.pieceAt(18));
      expect(cubie.bottomSliceable, isFalse);
    });

    test('a full turn of twelve is the identity', () {
      final cubie = Square1Cubie()
        ..doMove(12 - 5)
        ..doMove(5);

      expect(List.generate(24, cubie.pieceAt), solvedPieces);
    });
  });

  group('Square1Simulator', () {
    test('empty scramble keeps the solved state with square middle', () {
      final state = Square1Simulator().apply('');

      expect(state.pieces, solvedPieces);
      expect(state.middleIsSquare, isTrue);
    });

    test('a single slice swaps the top-right and bottom-left halves', () {
      final state = Square1Simulator().apply('(0,0) / (0,0)');

      expect(state.pieces.sublist(0, 6), solvedPieces.sublist(0, 6));
      expect(state.pieces.sublist(6, 12), solvedPieces.sublist(12, 18));
      expect(state.pieces.sublist(12, 18), solvedPieces.sublist(6, 12));
      expect(state.pieces.sublist(18, 24), solvedPieces.sublist(18, 24));
      expect(state.middleIsSquare, isFalse);
    });

    test('two consecutive slices cancel out', () {
      final withDoubleSlice = Square1Simulator().apply('(3,4) / (0,0) / (0,0)');
      final rotationsOnly = Square1Simulator().apply('(3,4)');

      expect(withDoubleSlice.pieces, rotationsOnly.pieces);
      expect(withDoubleSlice.middleIsSquare, isTrue);
    });

    test('rotations parse signed values like the WCA notation', () {
      final negative = Square1Simulator().apply('(-3,-2)');
      final normalized = Square1Simulator().apply('(9,10)');

      expect(negative.pieces, normalized.pieces);
    });

    test('piece multiset is conserved across a scramble', () {
      final state = Square1Simulator()
          .apply('(0,-1) / (3,0) / (-3,-3) / (6,3) / (1,-4) / (0,2)');

      final counts = List<int>.filled(16, 0);
      for (final piece in state.pieces) {
        counts[piece]++;
      }
      for (var piece = 0; piece < 16; piece++) {
        // Esquinas (impares) ocupan dos slots, aristas (pares) uno.
        expect(counts[piece], piece.isOdd ? 2 : 1, reason: 'piece $piece');
      }
    });
  });
}
