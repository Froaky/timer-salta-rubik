import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/presentation/bloc/timer/timer_state.dart';
import 'package:salta_rubik/presentation/widgets/timer/timer_display.dart';

void main() {
  Widget buildDisplay(TimerState state, {bool immersiveMode = false}) {
    return MaterialApp(
      home: Scaffold(
        body: TimerDisplay(
          timerState: state,
          immersiveMode: immersiveMode,
          onTapDown: () {},
          onTapUp: () {},
          onTapCancel: () {},
        ),
      ),
    );
  }

  Widget buildFrozenDisplay(TimerState state, int frozenElapsedMs) {
    return MaterialApp(
      home: Scaffold(
        body: TimerDisplay(
          timerState: state,
          frozenElapsedMs: frozenElapsedMs,
          onTapDown: () {},
          onTapUp: () {},
          onTapCancel: () {},
        ),
      ),
    );
  }

  testWidgets('uses square immersive timer surface while running',
      (tester) async {
    await tester.pumpWidget(
      buildDisplay(
        TimerState.initial().copyWith(status: TimerStatus.running),
        immersiveMode: true,
      ),
    );
    await tester.pumpAndSettle();

    final container =
        tester.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.circular(0));
  });

  testWidgets('dispatches press and release callbacks from raw pointer events',
      (tester) async {
    var downCount = 0;
    var upCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimerDisplay(
            timerState: TimerState.initial(),
            onTapDown: () => downCount++,
            onTapUp: () => upCount++,
            onTapCancel: () {},
          ),
        ),
      ),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(TimerDisplay)));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(downCount, 1);
    expect(upCount, 1);
    expect(find.byType(Listener), findsWidgets);
  });

  testWidgets('uses live elapsed from startTime while running', (tester) async {
    await tester.pumpWidget(
      buildDisplay(
        TimerState.initial().copyWith(
          status: TimerStatus.running,
          elapsedMs: 0,
          startTime: DateTime.now().subtract(const Duration(milliseconds: 250)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('0.00'), findsNothing);
  });

  testWidgets('keeps frozen elapsed while running when stop latch is present',
      (tester) async {
    await tester.pumpWidget(
      buildFrozenDisplay(
        TimerState.initial().copyWith(
          status: TimerStatus.running,
          elapsedMs: 0,
          startTime: DateTime.now().subtract(const Duration(seconds: 1)),
        ),
        880,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('0.88'), findsOneWidget);
    expect(find.text('0.98'), findsNothing);
  });

  testWidgets('reports displayed elapsed values while running', (tester) async {
    int? reportedElapsedMs;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimerDisplay(
            timerState: TimerState.initial().copyWith(
              status: TimerStatus.running,
              elapsedMs: 0,
              startTime:
                  DateTime.now().subtract(const Duration(milliseconds: 120)),
            ),
            onDisplayedElapsedChanged: (elapsedMs) {
              reportedElapsedMs = elapsedMs;
            },
            onTapDown: () {},
            onTapUp: () {},
            onTapCancel: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(reportedElapsedMs, isNotNull);
    expect(reportedElapsedMs, greaterThan(0));
  });
}
