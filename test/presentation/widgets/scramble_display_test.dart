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

  Widget buildDisplay(SolveState solveState) {
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
          child: const Center(
            child: SizedBox(
              width: 280,
              child: ScrambleDisplay(),
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
}
