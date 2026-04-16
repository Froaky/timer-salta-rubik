import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/presentation/bloc/timer/timer_bloc.dart';
import 'package:salta_rubik/presentation/bloc/timer/timer_event.dart';
import 'package:salta_rubik/presentation/bloc/timer/timer_state.dart';

void main() {
  group('TimerBloc', () {
    test('starts in idle state', () async {
      final bloc = TimerBloc();

      expect(bloc.state, TimerState.initial());

      await bloc.close();
    });

    test('transitions from hold to armed as thresholds elapse', () async {
      final bloc = TimerBloc(
        yellowThresholdMs: 60,
        greenThresholdMs: 120,
      );

      bloc.add(const TimerStartHold());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.status, TimerStatus.holdPending);
      expect(bloc.state.color, TimerColor.red);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(bloc.state.status, TimerStatus.holdPending);
      expect(bloc.state.color, TimerColor.yellow);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(bloc.state.status, TimerStatus.armed);
      expect(bloc.state.color, TimerColor.green);

      await bloc.close();
    });

    test('releasing before armed resets timer', () async {
      final bloc = TimerBloc(
        yellowThresholdMs: 20,
        greenThresholdMs: 40,
      );

      bloc.add(const TimerStartHold());
      await Future<void>.delayed(const Duration(milliseconds: 15));
      bloc.add(const TimerStopHold());
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(bloc.state, TimerState.initial());

      await bloc.close();
    });

    test('releasing after armed starts the timer and stop records elapsed time',
        () async {
      final bloc = TimerBloc(
        yellowThresholdMs: 20,
        greenThresholdMs: 40,
      );

      bloc.add(const TimerStartHold());
      await Future<void>.delayed(const Duration(milliseconds: 55));
      expect(bloc.state.status, TimerStatus.armed);

      bloc.add(const TimerStopHold());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(bloc.state.status, TimerStatus.running);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      bloc.add(const TimerStop());
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(bloc.state.status, TimerStatus.stopped);
      expect(bloc.state.elapsedMs, inInclusiveRange(20, 60));

      await bloc.close();
    });

    test('stop uses the provided stoppedAt timestamp exactly', () async {
      final bloc = TimerBloc(
        yellowThresholdMs: 20,
        greenThresholdMs: 40,
      );

      bloc.add(const TimerStartHold());
      await Future<void>.delayed(const Duration(milliseconds: 55));
      expect(bloc.state.status, TimerStatus.armed);

      bloc.add(const TimerStopHold());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(bloc.state.status, TimerStatus.running);

      final startTime = bloc.state.startTime;
      expect(startTime, isNotNull);

      bloc.add(
        TimerStop(
          stoppedAt: startTime!.add(const Duration(milliseconds: 1234)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(bloc.state.status, TimerStatus.stopped);
      expect(bloc.state.elapsedMs, 1234);

      await bloc.close();
    });

    test('stop uses elapsed override when provided', () async {
      final bloc = TimerBloc(
        yellowThresholdMs: 20,
        greenThresholdMs: 40,
      );

      bloc.add(const TimerStartHold());
      await Future<void>.delayed(const Duration(milliseconds: 55));
      expect(bloc.state.status, TimerStatus.armed);

      bloc.add(const TimerStopHold());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(bloc.state.status, TimerStatus.running);

      bloc.add(
        TimerStop(
          stoppedAt: DateTime.now().add(const Duration(milliseconds: 50)),
          elapsedMsOverride: 150,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(bloc.state.status, TimerStatus.stopped);
      expect(bloc.state.elapsedMs, 150);

      await bloc.close();
    });

    test('toggle events update feature flags', () async {
      final bloc = TimerBloc();

      bloc.add(const TimerToggleInspection());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.inspectionEnabled, isTrue);

      bloc.add(const TimerToggleHideTimer());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.hideTimerEnabled, isTrue);

      bloc.add(const TimerToggleCompeteMode());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.competeMode, isTrue);

      await bloc.close();
    });

    test('inspection start enters inspection mode', () async {
      final bloc = TimerBloc(inspectionDurationMs: 40);

      bloc.add(const TimerToggleInspection());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TimerStartHold());
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(bloc.state.status, TimerStatus.inspection);
      expect(bloc.state.inspectionRemainingMs, 40);

      await bloc.close();
    });

    test('inspection over configured threshold applies plus two penalty',
        () async {
      final bloc = TimerBloc(
        inspectionDurationMs: 80,
        inspectionPlusTwoThresholdMs: 80,
        inspectionDnfThresholdMs: 200,
      );

      bloc.add(const TimerToggleInspection());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TimerStartHold());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      bloc.add(const TimerStopHold());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(bloc.state.status, TimerStatus.armed);

      bloc.add(const TimerStopHold());
      await Future<void>.delayed(const Duration(milliseconds: 15));
      bloc.add(const TimerStop());
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(bloc.state.status, TimerStatus.stopped);
      expect(bloc.state.elapsedMs, inInclusiveRange(2005, 2070));

      await bloc.close();
    });

    test('inspection over configured dnf threshold produces dnf', () async {
      final bloc = TimerBloc(
        inspectionDurationMs: 80,
        inspectionPlusTwoThresholdMs: 80,
        inspectionDnfThresholdMs: 140,
      );

      bloc.add(const TimerToggleInspection());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const TimerStartHold());
      await Future<void>.delayed(const Duration(milliseconds: 160));

      bloc.add(const TimerStopHold());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const TimerStopHold());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const TimerStop());
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(bloc.state.status, TimerStatus.stopped);
      expect(bloc.state.elapsedMs, -1);

      await bloc.close();
    });
  });
}
