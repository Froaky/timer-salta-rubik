import 'package:flutter_test/flutter_test.dart';
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
      final movePattern = RegExp(r"^(R|U|F|L|D|B|Rw|Uw|Fw|Lw|Dw|Bw)(2|'|)?$");

      expect(scramble.cubeType, '4x4');
      expect(scramble.moves.length, 40);
      expect(scramble.moves.every(movePattern.hasMatch), isTrue);
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

    test('generates square-1 scrambles with ten slash-separated moves', () {
      final scramble = usecase('sq1');

      expect(scramble.cubeType, 'sq1');
      expect(scramble.moves.length, 10);
      expect(scramble.notation.split(' / ').length, 10);
    });

    test('supports all configured public puzzle types', () {
      const cubeTypes = [
        '3x3',
        '3x3oh',
        '3x3bf',
        '3x3fm',
        '2x2',
        '4x4',
        '444bf',
        '5x5',
        '555bf',
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
