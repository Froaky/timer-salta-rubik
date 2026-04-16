import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/presentation/widgets/scramble_preview.dart';

import '../../support/test_helpers.dart';

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

  testWidgets('renders preview for supported 3x3 scrambles', (tester) async {
    await tester.pumpWidget(buildPreview('3x3', "R U R' U'"));
    await tester.pump();

    expect(find.byKey(const ValueKey('scramble-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('scramble-preview-svg')), findsOneWidget);
  });

  testWidgets('rotates the back face in cube previews for correct orientation',
      (tester) async {
    await tester.pumpWidget(buildPreview('3x3', 'R U2 F B'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('scramble-preview-back-face')),
      findsOneWidget,
    );
  });

  testWidgets('renders preview for clock scrambles', (tester) async {
    await tester.pumpWidget(buildPreview('clock', 'UR4+ DR3- y2 U1+'));
    await tester.pump();

    expect(find.byKey(const ValueKey('scramble-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('scramble-preview-svg')), findsOneWidget);
  });

  testWidgets('renders preview for pyraminx scrambles', (tester) async {
    await tester.pumpWidget(buildPreview('pyraminx', "R' U L' r b u'"));
    await tester.pump();

    expect(find.byKey(const ValueKey('scramble-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('scramble-preview-svg')), findsOneWidget);
  });
}
