import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:salta_rubik/domain/entities/session.dart';
import 'package:salta_rubik/presentation/bloc/session/session_bloc.dart';
import 'package:salta_rubik/presentation/bloc/session/session_state.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_bloc.dart';
import 'package:salta_rubik/presentation/bloc/session/session_event.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_event.dart';
import 'package:salta_rubik/presentation/bloc/solve/solve_state.dart';
import 'package:salta_rubik/presentation/theme/app_theme.dart';
import 'package:salta_rubik/presentation/widgets/session_selector.dart';

import '../../support/test_helpers.dart';

void main() {
  late MockSessionBloc sessionBloc;
  late MockSolveBloc solveBloc;

  setUpAll(registerTestFallbacks);

  setUp(() {
    sessionBloc = MockSessionBloc();
    solveBloc = MockSolveBloc();
  });

  Widget buildWidget(SessionState sessionState) {
    when(() => sessionBloc.state).thenReturn(sessionState);
    when(() => sessionBloc.stream)
        .thenAnswer((_) => const Stream<SessionState>.empty());
    when(() => solveBloc.state).thenReturn(SolveState.initial());
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
          body: SessionSelector(),
        ),
      ),
    );
  }

  testWidgets('selecting the current session does not regenerate scramble',
      (tester) async {
    final currentSession = buildSession(id: 'session-1', name: 'mi sesiÃ³n');
    final otherSession = buildSession(id: 'session-2', name: 'otra sesiÃ³n');

    await tester.pumpWidget(
      buildWidget(
        SessionState.initial().copyWith(
          status: SessionStatus.loaded,
          sessions: [currentSession, otherSession],
          currentSession: currentSession,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<Session>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('mi sesiÃ³n').last);
    await tester.pumpAndSettle();

    verifyNever(() => sessionBloc.add(any(that: isA<SelectSession>())));
    verifyNever(() => solveBloc.add(any(that: isA<GenerateNewScramble>())));
  });
}
