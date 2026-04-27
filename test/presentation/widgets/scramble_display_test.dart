import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_bloc.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_state.dart';
import 'package:salta_rubik/presentation/widgets/scramble_display.dart';

import '../../support/test_helpers.dart';

void main() {
  setUpAll(registerTestFallbacks);

  Widget buildDisplay(SolveState solveState, {double width = 280}) {
    final solveBloc = MockSolveBloc();
    whenListen(
      solveBloc,
      const Stream<SolveState>.empty(),
      initialState: solveState,
    );
    when(() => solveBloc.state).thenReturn(solveState);

    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<SolveBloc>.value(
          value: solveBloc,
          child: Center(
            child: SizedBox(
              width: width,
              child: const ScrambleDisplay(),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('reduces text size for longer scrambles', (tester) async {
    TextStyle? textStyleOfCurrentScramble() {
      final selectableText = tester.widget<SelectableText>(
        find.byKey(const ValueKey('main-scramble-text')),
      );
      return selectableText.style;
    }

    final shortState = SolveState.initial().copyWith(
      status: SolveStatus.loaded,
      currentScramble: buildScramble(
        notation: "R U R' U'",
        cubeType: '2x2',
      ),
    );
    final longState = SolveState.initial().copyWith(
      status: SolveStatus.loaded,
      currentScramble: buildScramble(
        notation:
            "Rw U2 3Fw' Rw2 U' 3Uw2 F2 3Rw' U2 Rw U2 3Fw U' Rw2 3Uw' Fw2 U Rw' "
            "3Uw R2 Fw' U2 3Rw2 Dw 3Fw U' Rw F2 3Uw' Dw2",
        cubeType: '6x6',
      ),
    );

    await tester.pumpWidget(buildDisplay(shortState));
    await tester.pumpAndSettle();
    final shortFontSize = textStyleOfCurrentScramble()?.fontSize;

    await tester.pumpWidget(buildDisplay(longState));
    await tester.pumpAndSettle();
    final longFontSize = textStyleOfCurrentScramble()?.fontSize;

    expect(shortFontSize, isNotNull);
    expect(longFontSize, isNotNull);
    expect(longFontSize!, lessThan(shortFontSize!));
  });

  testWidgets('keeps 2x2 scramble visible on narrow viewports (FIX-019)',
      (tester) async {
    final state = SolveState.initial().copyWith(
      status: SolveStatus.loaded,
      currentScramble: buildScramble(
        notation: "R U' R2 F R F' U2 R U'",
        cubeType: '2x2',
      ),
    );

    await tester.pumpWidget(buildDisplay(state, width: 280));
    await tester.pumpAndSettle();

    final card = tester.getRect(find.byKey(const ValueKey('main-scramble-card')));
    expect(card.height, greaterThan(0));
    expect(card.height, lessThan(140));

    final text = find.byKey(const ValueKey('main-scramble-text'));
    expect(text, findsOneWidget);
  });

  testWidgets('keeps long 7x7 scramble fully readable via internal scroll '
      '(FIX-019)', (tester) async {
    // ~100 wide moves, mimicking 7x7 length.
    final notation = List.generate(
      100,
      (i) => i.isEven ? 'Rw' : '3Fw\'',
    ).join(' ');

    final state = SolveState.initial().copyWith(
      status: SolveStatus.loaded,
      currentScramble: buildScramble(
        notation: notation,
        cubeType: '7x7',
      ),
    );

    await tester.pumpWidget(buildDisplay(state, width: 320));
    await tester.pumpAndSettle();

    final card = tester.getRect(find.byKey(const ValueKey('main-scramble-card')));
    // Card must remain bounded so the timer keeps usable space.
    expect(card.height, lessThanOrEqualTo(220));

    final text = find.byKey(const ValueKey('main-scramble-text'));
    expect(text, findsOneWidget);
  });
}
