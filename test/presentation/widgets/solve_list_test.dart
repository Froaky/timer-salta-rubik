import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salta_rubik/presentation/bloc/session/session_bloc.dart';
import 'package:salta_rubik/presentation/bloc/session/session_state.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_bloc.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_event.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_state.dart';
import 'package:salta_rubik/presentation/theme/app_theme.dart';
import 'package:salta_rubik/presentation/widgets/solve_list.dart';

import '../../support/test_helpers.dart';

void main() {
  late MockSessionBloc sessionBloc;
  late MockSolveBloc solveBloc;

  setUpAll(registerTestFallbacks);

  setUp(() {
    sessionBloc = MockSessionBloc();
    solveBloc = MockSolveBloc();
  });

  Widget buildWidget({
    required SessionState sessionState,
    required SolveState solveState,
  }) {
    when(() => sessionBloc.state).thenReturn(sessionState);
    when(() => sessionBloc.stream)
        .thenAnswer((_) => const Stream<SessionState>.empty());
    when(() => solveBloc.state).thenReturn(solveState);
    when(() => solveBloc.stream)
        .thenAnswer((_) => const Stream<SolveState>.empty());
    when(() => sessionBloc.add(any())).thenReturn(null);
    when(() => solveBloc.add(any())).thenReturn(null);

    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionBloc>.value(value: sessionBloc),
        BlocProvider<SolveBloc>.value(value: solveBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SolveList(),
        ),
      ),
    );
  }

  testWidgets('deletes all solves in the active session from header action',
      (tester) async {
    final session = buildSession();
    final solve = buildSolve();

    await tester.pumpWidget(
      buildWidget(
        sessionState: SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [session],
          currentSession: session,
        ),
        solveState: SolveState.initial().copyWith(
          status: SolveStatus.loaded,
          sessionId: session.id,
          solves: [solve],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete all solves in session'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Session Solves'), findsOneWidget);
    expect(find.text('Delete all'), findsOneWidget);

    await tester.tap(find.text('Delete all'));
    await tester.pumpAndSettle();

    verify(() => solveBloc.add(const DeleteSessionSolvesEvent('session-1')))
        .called(1);
  });
}
