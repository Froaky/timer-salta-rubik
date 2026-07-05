import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/puzzles/square1_simulator.dart';
import 'package:salta_rubik/domain/usecases/generate_scramble.dart';

void main() {
  final usecase = GenerateScramble();

  group('GenerateScramble', () {
    test('falls back to 3x3 for unknown cube types', () {
      final scramble = usecase('unknown');

      expect(scramble.cubeType, '3x3');
      expect(scramble.moves, isNotEmpty);
      expect(scramble.notation, isNotEmpty);
    });

    test('generates constrained 2x2 scrambles', () {
      final scramble = usecase('2x2');
      final movePattern = RegExp(r"^(R|U|F)(2|'|)?$");

      expect(scramble.cubeType, '2x2');
      expect(scramble.moves.length, inInclusiveRange(9, 10));
      expect(scramble.moves.every(movePattern.hasMatch), isTrue);
    });

    test('generates official style 4x4 scrambles', () {
      final scramble = usecase('4x4');
      final movePattern = RegExp(r"^(R|U|F|L|D|B|Rw|Uw|Fw)(2|'|)?$");

      expect(scramble.cubeType, '4x4');
      expect(scramble.moves.length, 40);
      expect(scramble.moves.every(movePattern.hasMatch), isTrue);
    });

    test('4x4 scrambles never emit Dw, Lw or Bw wides (FIX-017)', () {
      final forbidden = RegExp(r"^(Dw|Lw|Bw)");

      for (final cubeType in const ['4x4', '444bf']) {
        for (var i = 0; i < 30; i++) {
          final scramble = usecase(cubeType);
          for (final move in scramble.moves) {
            expect(
              forbidden.hasMatch(move),
              isFalse,
              reason: 'Move "$move" appeared in $cubeType scramble (run $i)',
            );
          }
        }
      }
    });

    test('4x4 scrambles start with a 3x3 style outer block (FIX-017)', () {
      final outerOnly = RegExp(r"^(R|U|F|L|D|B)(2|'|)?$");

      for (var i = 0; i < 30; i++) {
        final scramble = usecase('4x4');
        final prefix = scramble.moves.take(8).toList();
        for (final move in prefix) {
          expect(
            outerOnly.hasMatch(move),
            isTrue,
            reason:
                'Prefix move "$move" should be outer-only (3x3 block), full=$prefix',
          );
        }
      }
    });

    test('generates official style 6x6 scrambles with wide 3-layer moves', () {
      final scramble = usecase('6x6');
      final movePattern = RegExp(
          r"^(R|U|F|L|D|B|Rw|Uw|Fw|Lw|Dw|Bw|3Rw|3Uw|3Fw|3Lw|3Dw|3Bw)(2|'|)?$");

      expect(scramble.cubeType, '6x6');
      expect(scramble.moves.length, 80);
      expect(scramble.moves.every(movePattern.hasMatch), isTrue);
    });

    test('generates megaminx scrambles in seven-line format', () {
      final scramble = usecase('megaminx');

      expect(scramble.cubeType, 'megaminx');
      expect('\n'.allMatches(scramble.notation).length, 6);
      expect(scramble.moves.length, 77);
    });

    test('generates clock scrambles using the fixed WCA-style pattern', () {
      final scramble = usecase('clock');
      const turnPattern = r'(UR|DR|DL|UL|U|R|D|L|ALL)[0-6][+-]';
      final fullPattern = RegExp(
        '^$turnPattern $turnPattern $turnPattern $turnPattern '
        '$turnPattern $turnPattern $turnPattern $turnPattern $turnPattern '
        'y2 '
        '$turnPattern $turnPattern $turnPattern $turnPattern $turnPattern\$',
      );

      expect(scramble.cubeType, 'clock');
      expect(scramble.moves.length, 15);
      expect(scramble.moves[9], 'y2');
      expect(fullPattern.hasMatch(scramble.notation), isTrue);
    });

    test('generates clock scrambles with fixed pin order around y2', () {
      final scramble = usecase('clock');

      expect(
        scramble.moves
            .take(9)
            .map((move) => move.replaceFirst(RegExp(r'[0-6][+-]$'), ''))
            .toList(),
        ['UR', 'DR', 'DL', 'UL', 'U', 'R', 'D', 'L', 'ALL'],
      );
      expect(
        scramble.moves
            .skip(10)
            .map((move) => move.replaceFirst(RegExp(r'[0-6][+-]$'), ''))
            .toList(),
        ['U', 'R', 'D', 'L', 'ALL'],
      );
    });

    test('generates clock scrambles with 6 always positive', () {
      var sawPositiveSix = false;

      for (var i = 0; i < 50; i++) {
        final scramble = usecase('clock');

        expect(
          scramble.moves.where((move) => move != 'y2'),
          isNot(contains(endsWith('6-'))),
        );

        if (scramble.moves.any((move) => move.endsWith('6+'))) {
          sawPositiveSix = true;
        }
      }

      expect(sawPositiveSix, isTrue);
    });

    test('generates square-1 scrambles with thirteen slash-separated pairs',
        () {
      final scramble = usecase('sq1');

      expect(scramble.cubeType, 'sq1');
      expect(scramble.moves.length, 13);
      expect(scramble.notation.split(' / ').length, 13);
    });

    test('square-1 pairs are well-formed, in range and never (0,0)', () {
      final pairPattern = RegExp(r'^\((-?\d+),(-?\d+)\)$');

      for (var i = 0; i < 30; i++) {
        final scramble = usecase('sq1');

        for (final move in scramble.moves) {
          final match = pairPattern.firstMatch(move);
          expect(match, isNotNull, reason: 'Malformed token: $move');

          final top = int.parse(match!.group(1)!);
          final bottom = int.parse(match.group(2)!);
          expect(top, inInclusiveRange(-5, 6), reason: move);
          expect(bottom, inInclusiveRange(-5, 6), reason: move);
          expect(top != 0 || bottom != 0, isTrue,
              reason: 'Null pair (0,0) emitted');
        }
      }
    });

    test('square-1 scrambles only contain executable slices', () {
      final pairPattern = RegExp(r'^\((-?\d+),(-?\d+)\)$');

      for (var i = 0; i < 30; i++) {
        final scramble = usecase('sq1');
        final cubie = Square1Cubie();

        for (var m = 0; m < scramble.moves.length; m++) {
          final match = pairPattern.firstMatch(scramble.moves[m])!;
          final top = (int.parse(match.group(1)!) + 12) % 12;
          final bottom = (int.parse(match.group(2)!) + 12) % 12;

          if (top != 0) {
            cubie.doMove(top);
          }
          if (bottom != 0) {
            cubie.doMove(-bottom);
          }

          final isLast = m == scramble.moves.length - 1;
          if (!isLast) {
            expect(cubie.topSliceable, isTrue,
                reason: 'Blocked top slice after ${scramble.moves[m]} '
                    'in ${scramble.notation}');
            expect(cubie.bottomSliceable, isTrue,
                reason: 'Blocked bottom slice after ${scramble.moves[m]} '
                    'in ${scramble.notation}');
            cubie.doMove(0);
          }
        }
      }
    });

    test('bld and selector aliases map to their base puzzle scrambles', () {
      expect(usecase('4x4bf').cubeType, '4x4');
      expect(usecase('5x5bf').cubeType, '5x5');
      expect(usecase('444bf').cubeType, '4x4');
      expect(usecase('555bf').cubeType, '5x5');
      expect(usecase('3x3mbf').cubeType, '3x3');
      expect(usecase('square-1').cubeType, 'sq1');

      // Regresión del bug: '4x4bf'/'5x5bf' caían al default y devolvían 3x3.
      final fourBf = usecase('4x4bf');
      expect(fourBf.moves.length, greaterThan(30));
    });

    test('supports all configured public puzzle types', () {
      const cubeTypes = [
        '3x3',
        '3x3oh',
        '3x3bf',
        '3x3fm',
        '3x3mbf',
        '2x2',
        '4x4',
        '444bf',
        '4x4bf',
        '5x5',
        '555bf',
        '5x5bf',
        '6x6',
        '7x7',
        'pyraminx',
        'megaminx',
        'skewb',
        'clock',
        'sq1',
      ];

      for (final cubeType in cubeTypes) {
        final scramble = usecase(cubeType);

        expect(scramble.moves, isNotEmpty, reason: cubeType);
        expect(scramble.notation, isNotEmpty, reason: cubeType);
      }
    });
  });
}
