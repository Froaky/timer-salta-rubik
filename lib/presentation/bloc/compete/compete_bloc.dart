import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/generate_scramble.dart';
import 'compete_event.dart';
import 'compete_state.dart';

class CompeteBloc extends Bloc<CompeteEvent, CompeteState> {
  final GenerateScramble generateScramble;

  CompeteBloc({
    required this.generateScramble,
  }) : super(CompeteState.initial()) {
    on<StartCompeteRound>(_onStartCompeteRound);
    on<AddCompeteSolve>(_onAddCompeteSolve);
    on<ResetCompete>(_onResetCompete);
    on<UpdateLaneTimer>(_onUpdateLaneTimer);
    on<GenerateCompeteScrambles>(_onGenerateCompeteScrambles);
    on<AwardPoint>(_onAwardPoint);
    on<StartLane>(_onStartLane);
    on<StopLane>(_onStopLane);
  }

  Future<void> _onStartCompeteRound(StartCompeteRound event, Emitter<CompeteState> emit) async {
    try {
      final scramble1 = generateScramble(event.cubeType);
      final scramble2 = event.useSameScramble ? scramble1 : generateScramble(event.cubeType);
      
      emit(state.copyWith(
        status: CompeteStatus.ready,
        scrambleLane1: scramble1,
        scrambleLane2: scramble2,
        lane1: const LaneData(solves: []),
        lane2: const LaneData(solves: []),
        winner: null,
        useSameScramble: event.useSameScramble,
      ));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onAddCompeteSolve(AddCompeteSolve event, Emitter<CompeteState> emit) async {
    // Solo guardar el solve; la puntuación por ronda se maneja en Start/Stop
    if (event.lane == 1) {
      final updatedLane1 = state.lane1.copyWith(
        solves: [...state.lane1.solves, event.solve],
        currentTimeMs: event.solve.effectiveTimeMs,
        isFinished: true,
      );
      emit(state.copyWith(
        lane1: updatedLane1,
      ));
    } else if (event.lane == 2) {
      final updatedLane2 = state.lane2.copyWith(
        solves: [...state.lane2.solves, event.solve],
        currentTimeMs: event.solve.effectiveTimeMs,
        isFinished: true,
      );
      emit(state.copyWith(
        lane2: updatedLane2,
      ));
    }
  }

  Future<void> _onStartLane(StartLane event, Emitter<CompeteState> emit) async {
    final isLane1 = event.lane == 1;
    final alreadyRunning = isLane1 ? state.lane1Running : state.lane2Running;
    if (alreadyRunning) return; // Ignore repeated starts

    // If previous round was scored, start a new round: clear finished times and reset roundScored
    CompeteState next = state;
    if (state.roundScored) {
      next = next.copyWith(
        lane1FinishedAtMs: null,
        lane2FinishedAtMs: null,
        roundScored: false,
      );
    }

    if (isLane1) {
      emit(next.copyWith(lane1Running: true, status: CompeteStatus.inProgress));
    } else {
      emit(next.copyWith(lane2Running: true, status: CompeteStatus.inProgress));
    }
  }

  Future<void> _onStopLane(StopLane event, Emitter<CompeteState> emit) async {
    final isLane1 = event.lane == 1;
    final wasRunning = isLane1 ? state.lane1Running : state.lane2Running;
    if (!wasRunning) return; // Ignore stop when not running

    // Update running flag and finishedAtMs
    CompeteState updated = state.copyWith(
      lane1Running: isLane1 ? false : state.lane1Running,
      lane2Running: isLane1 ? state.lane2Running : false,
      lane1FinishedAtMs: isLane1 ? event.finishedAtMs : state.lane1FinishedAtMs,
      lane2FinishedAtMs: isLane1 ? state.lane2FinishedAtMs : event.finishedAtMs,
    );

    // Check scoring condition: both not running, both have finished time, and not yet scored this round
    final bothStopped = !updated.lane1Running && !updated.lane2Running;
    final bothHaveTimes = updated.lane1FinishedAtMs != null && updated.lane2FinishedAtMs != null;
    if (bothStopped && bothHaveTimes && !updated.roundScored) {
      final t1 = updated.lane1FinishedAtMs!;
      final t2 = updated.lane2FinishedAtMs!;
      int lane1Score = updated.lane1Score;
      int lane2Score = updated.lane2Score;
      String? winner;

      if (t1 < t2) {
        lane1Score += 1;
        winner = 'lane1';
      } else if (t2 < t1) {
        lane2Score += 1;
        winner = 'lane2';
      } else {
        // exact tie -> nobody scores
        winner = 'tie';
      }

      updated = updated.copyWith(
        lane1Score: lane1Score,
        lane2Score: lane2Score,
        roundScored: true,
        status: CompeteStatus.finished,
        winner: winner,
      );
    }

    emit(updated);
  }

  Future<void> _onResetCompete(ResetCompete event, Emitter<CompeteState> emit) async {
    emit(CompeteState.initial());
  }

  Future<void> _onUpdateLaneTimer(UpdateLaneTimer event, Emitter<CompeteState> emit) async {
    if (event.lane == 1) {
      final updatedLane1 = state.lane1.copyWith(
        currentTimeMs: event.elapsedMs,
      );
      emit(state.copyWith(lane1: updatedLane1));
    } else if (event.lane == 2) {
      final updatedLane2 = state.lane2.copyWith(
        currentTimeMs: event.elapsedMs,
      );
      emit(state.copyWith(lane2: updatedLane2));
    }
  }
  
  Future<void> _onGenerateCompeteScrambles(GenerateCompeteScrambles event, Emitter<CompeteState> emit) async {
    try {
      final scramble1 = generateScramble(event.cubeType);
      final useSameScramble = event.useSameScramble ?? state.useSameScramble;
      final scramble2 = useSameScramble ? scramble1 : generateScramble(event.cubeType);
      
      emit(state.copyWith(
        scrambleLane1: scramble1,
        scrambleLane2: scramble2,
        useSameScramble: useSameScramble,
      ));
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> _onAwardPoint(AwardPoint event, Emitter<CompeteState> emit) async {
    if (event.lane == 1) {
      emit(state.copyWith(
        lane1Score: state.lane1Score + 1,
      ));
    } else if (event.lane == 2) {
      emit(state.copyWith(
        lane2Score: state.lane2Score + 1,
      ));
    }
  }
}