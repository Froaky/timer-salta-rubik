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
    if (event.lane == 1) {
      final updatedLane1 = state.lane1.copyWith(
        solves: [...state.lane1.solves, event.solve],
        currentTimeMs: event.solve.effectiveTimeMs,
        isFinished: true,
      );
      
      emit(state.copyWith(
        lane1: updatedLane1,
        status: state.lane2.isFinished ? CompeteStatus.finished : CompeteStatus.inProgress,
      ));
    } else if (event.lane == 2) {
      final updatedLane2 = state.lane2.copyWith(
        solves: [...state.lane2.solves, event.solve],
        currentTimeMs: event.solve.effectiveTimeMs,
        isFinished: true,
      );
      
      emit(state.copyWith(
        lane2: updatedLane2,
        status: state.lane1.isFinished ? CompeteStatus.finished : CompeteStatus.inProgress,
      ));
    }
    
    // Check for winner if both lanes finished
    if (state.bothLanesFinished) {
      emit(state.copyWith(
        winner: state.currentWinner,
        status: CompeteStatus.finished,
      ));
    }
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
      final scramble1 = generateScramble('3x3');
      final scramble2 = state.useSameScramble ? scramble1 : generateScramble('3x3');
      
      emit(state.copyWith(
        scrambleLane1: scramble1,
        scrambleLane2: scramble2,
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