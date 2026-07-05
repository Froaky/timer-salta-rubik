import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/puzzles/nxn_cube_simulator.dart';
import 'package:salta_rubik/presentation/widgets/preview/clock_painter.dart';
import 'package:salta_rubik/presentation/widgets/preview/cube_net_painter.dart';
import 'package:salta_rubik/presentation/widgets/preview/megaminx_net_painter.dart';
import 'package:salta_rubik/presentation/widgets/preview/pyraminx_net_painter.dart';
import 'package:salta_rubik/presentation/widgets/preview/skewb_net_painter.dart';
import 'package:salta_rubik/presentation/widgets/preview/square1_painter.dart';
import 'package:salta_rubik/presentation/widgets/scramble_preview.dart';

import '../../support/test_helpers.dart';

const _solvedSquare1 = [
  0, 1, 1, 2, 3, 3, 4, 5, 5, 6, 7, 7, //
  9, 9, 8, 11, 11, 10, 13, 13, 12, 15, 15, 14,
];

/// Cantidad de stickers que no están en su cara de origen (0 = resuelto).
int _changedFacelets(List<List<int>> faces) {
  var changed = 0;
  for (var face = 0; face < faces.length; face++) {
    for (final sticker in faces[face]) {
      if (sticker != face) {
        changed++;
      }
    }
  }
  return changed;
}

void main() {
  Widget buildPreview(String cubeType, String notation) {
    return MaterialApp(
      home: Scaffold(
        body: ScramblePreview(
          scramble: buildScramble(
            cubeType: cubeType,
            notation: notation,
          ),
        ),
      ),
    );
  }

  CustomPaint findPreviewPaint(WidgetTester tester) {
    return tester.widget<CustomPaint>(
      find.byKey(const ValueKey('scramble-preview-svg')),
    );
  }

  testWidgets('renders preview for supported 3x3 scrambles', (tester) async {
    await tester.pumpWidget(buildPreview('3x3', "R U R' U'"));
    await tester.pump();

    expect(find.byKey(const ValueKey('scramble-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('scramble-preview-svg')), findsOneWidget);
    expect(findPreviewPaint(tester).painter, isA<CubeNetPainter>());
  });

  testWidgets('cube preview paints the scrambled state, not the solved cube',
      (tester) async {
    await tester.pumpWidget(buildPreview('3x3', 'R U2 F B'));
    await tester.pump();

    final painter = findPreviewPaint(tester).painter as CubeNetPainter;
    final solvedUp = List.filled(9, CubeColorIds.white);
    expect(painter.facelets.up, isNot(equals(solvedUp)));
  });

  testWidgets('bld variants reuse the base puzzle preview', (tester) async {
    expect(ScramblePreview.supports('444bf'), isTrue);
    expect(ScramblePreview.supports('3x3oh'), isTrue);

    // Render directo con el cubeType alias, no con el puzzle base.
    await tester.pumpWidget(buildPreview('444bf', "Rw U2 F' Uw2"));
    await tester.pump();

    final painter = findPreviewPaint(tester).painter as CubeNetPainter;
    expect(painter.facelets.size, 4);
    expect(
      painter.facelets.up,
      isNot(equals(List.filled(16, CubeColorIds.white))),
    );
  });

  testWidgets('renders preview for clock scrambles', (tester) async {
    await tester.pumpWidget(buildPreview('clock', 'UR4+ DR3- y2 U1+'));
    await tester.pump();

    expect(find.byKey(const ValueKey('scramble-preview')), findsOneWidget);
    final painter = findPreviewPaint(tester).painter as ClockPainter;
    // El scramble debe mover relojes: no pueden quedar todos en 12.
    expect(
      [...painter.state.leftDials, ...painter.state.rightDials],
      isNot(everyElement(0)),
    );
  });

  testWidgets('renders preview for pyraminx scrambles', (tester) async {
    await tester.pumpWidget(buildPreview('pyraminx', "R' U L' r b u'"));
    await tester.pump();

    final painter = findPreviewPaint(tester).painter as PyraminxNetPainter;
    // El scramble debe alterar stickers respecto del estado resuelto.
    final changed = [
      for (var face = 0; face < 4; face++)
        for (final sticker in painter.facelets.faces[face])
          if (sticker != face) sticker,
    ];
    expect(changed, isNotEmpty);
  });

  testWidgets('renders preview for skewb scrambles', (tester) async {
    await tester.pumpWidget(buildPreview('skewb', "L R L U R B' U' B L'"));
    await tester.pump();

    final painter = findPreviewPaint(tester).painter as SkewbNetPainter;
    expect(_changedFacelets(painter.facelets.faces), greaterThan(0));
  });

  testWidgets('renders preview for megaminx scrambles', (tester) async {
    await tester.pumpWidget(
      buildPreview('megaminx', 'R-- D++ R++ D++ R++ D-- R-- D-- R-- D++ U'),
    );
    await tester.pump();

    final painter = findPreviewPaint(tester).painter as MegaminxNetPainter;
    expect(_changedFacelets(painter.facelets.faces), greaterThan(0));
  });

  testWidgets('renders preview for square-1 scrambles', (tester) async {
    expect(ScramblePreview.supports('sq1'), isTrue);

    await tester.pumpWidget(buildPreview('sq1', '(0,-1) / (3,0) / (-3,-3)'));
    await tester.pump();

    final painter = findPreviewPaint(tester).painter as Square1Painter;
    // Con slices en el medio, el estado no puede seguir resuelto.
    expect(painter.state.pieces, isNot(equals(_solvedSquare1)));
  });

  testWidgets('unsupported categories render nothing', (tester) async {
    expect(ScramblePreview.supports('unknown-puzzle'), isFalse);

    await tester.pumpWidget(buildPreview('unknown-puzzle', 'R U'));
    await tester.pump();

    expect(find.byKey(const ValueKey('scramble-preview')), findsNothing);
  });
}
