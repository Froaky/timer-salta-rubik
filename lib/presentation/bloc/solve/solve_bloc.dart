import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/add_solve.dart';
import '../../../domain/usecases/get_solves.dart';
import '../../../domain/usecases/get_statistics.dart';
import '../../../domain/usecases/generate_scramble.dart';
import '../../../domain/usecases/update_solve.dart';
import '../../../domain/usecases/delete_solve.dart';
import 'solve_event.dart';
import 'solve_state.dart';

class SolveBloc extends Bloc<SolveEvent, SolveState> {
  final AddSolve addSolve;
  final GetSolves getSolves;
  final GetStatistics getStatistics;
  final GenerateScramble generateScramble;
  final UpdateSolve updateSolve;
  final DeleteSolve deleteSolve;

  SolveBloc({
    required this.addSolve,
    required this.getSolves,
    required this.getStatistics,
    required this.generateScramble,
    required this.updateSolve,
    required this.deleteSolve,
  }) : super(SolveState.initial()) {
    on<LoadSolves>(_onLoadSolves);
    on<AddSolveEvent>(_onAddSolve);
    on<UpdateSolveEvent>(_onUpdateSolve);
    on<DeleteSolveEvent>(_onDeleteSolve);
    on<GenerateNewScramble>(_onGenerateNewScramble);
    on<LoadStatistics>(_onLoadStatistics);
  }

  Future<void> _onLoadSolves(LoadSolves event, Emitter<SolveState> emit) async {
    final isSwitchingSession = state.sessionId != event.sessionId;
    emit(state.copyWith(
      status: SolveStatus.loading,
      sessionId: event.sessionId,
      solves: isSwitchingSession ? const [] : null,
      statistics: isSwitchingSession ? null : state.statistics,
      errorMessage: null,
    ));

    try {
      final params = GetSolvesParams(
        sessionId: event.sessionId,
        limit: event.limit,
        offset: event.offset,
      );

      final solves = await getSolves(params);

      if (state.sessionId != event.sessionId) {
        return;
      }

      emit(state.copyWith(
        status: SolveStatus.loaded,
        sessionId: event.sessionId,
        solves: solves,
      ));
    } catch (e) {
      if (state.sessionId != event.sessionId) {
        return;
      }
      emit(state.copyWith(
        status: SolveStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddSolve(
      AddSolveEvent event, Emitter<SolveState> emit) async {
    try {
      await addSolve(event.solve);

      // Reload solves and statistics
      add(LoadSolves(sessionId: event.solve.sessionId));
      add(LoadStatistics(event.solve.sessionId));

      // Generate new scramble
      add(GenerateNewScramble(event.solve.cubeType));
    } catch (e) {
      emit(state.copyWith(
        status: SolveStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateSolve(
      UpdateSolveEvent event, Emitter<SolveState> emit) async {
    try {
      await updateSolve(event.solve);
      // Reload solves and statistics after update
      add(LoadSolves(sessionId: event.solve.sessionId));
      add(LoadStatistics(event.solve.sessionId));
    } catch (e) {
      emit(state.copyWith(
        status: SolveStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteSolve(
      DeleteSolveEvent event, Emitter<SolveState> emit) async {
    try {
      await deleteSolve(event.solveId);
      // Determine session to reload
      final currentSessionId = state.sessionId ??
          (state.solves.isNotEmpty ? state.solves.first.sessionId : 'default');
      add(LoadSolves(sessionId: currentSessionId));
      add(LoadStatistics(currentSessionId));
    } catch (e) {
      emit(state.copyWith(
        status: SolveStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onGenerateNewScramble(
      GenerateNewScramble event, Emitter<SolveState> emit) async {
    emit(state.copyWith(isGeneratingScramble: true));

    try {
      final scramble = generateScramble(event.cubeType);

      emit(state.copyWith(
        currentScramble: scramble,
        isGeneratingScramble: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SolveStatus.error,
        errorMessage: e.toString(),
        isGeneratingScramble: false,
      ));
    }
  }

  Future<void> _onLoadStatistics(
      LoadStatistics event, Emitter<SolveState> emit) async {
    if (state.sessionId != null && state.sessionId != event.sessionId) {
      emit(state.copyWith(
        sessionId: event.sessionId,
        statistics: null,
        errorMessage: null,
      ));
    }

    try {
      final statistics = await getStatistics(event.sessionId);

      if (state.sessionId != null && state.sessionId != event.sessionId) {
        return;
      }

      emit(state.copyWith(
        sessionId: event.sessionId,
        statistics: statistics,
      ));
    } catch (e) {
      if (state.sessionId != null && state.sessionId != event.sessionId) {
        return;
      }
      emit(state.copyWith(
        status: SolveStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}
