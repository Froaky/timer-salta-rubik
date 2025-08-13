import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/add_solve.dart';
import '../../../domain/usecases/get_solves.dart';
import '../../../domain/usecases/get_statistics.dart';
import '../../../domain/usecases/generate_scramble.dart';
import 'solve_event.dart';
import 'solve_state.dart';

class SolveBloc extends Bloc<SolveEvent, SolveState> {
  final AddSolve addSolve;
  final GetSolves getSolves;
  final GetStatistics getStatistics;
  final GenerateScramble generateScramble;

  SolveBloc({
    required this.addSolve,
    required this.getSolves,
    required this.getStatistics,
    required this.generateScramble,
  }) : super(SolveState.initial()) {
    on<LoadSolves>(_onLoadSolves);
    on<AddSolveEvent>(_onAddSolve);
    on<UpdateSolveEvent>(_onUpdateSolve);
    on<DeleteSolveEvent>(_onDeleteSolve);
    on<GenerateNewScramble>(_onGenerateNewScramble);
    on<LoadStatistics>(_onLoadStatistics);
  }

  Future<void> _onLoadSolves(LoadSolves event, Emitter<SolveState> emit) async {
    emit(state.copyWith(status: SolveStatus.loading));

    try {
      final params = GetSolvesParams(
        sessionId: event.sessionId,
        limit: event.limit,
        offset: event.offset,
      );
      
      final solves = await getSolves(params);
      
      emit(state.copyWith(
        status: SolveStatus.loaded,
        solves: solves,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SolveStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddSolve(AddSolveEvent event, Emitter<SolveState> emit) async {
    print('DEBUG: _onAddSolve called with solve: ${event.solve.id}');
    try {
      print('DEBUG: Calling addSolve usecase');
      await addSolve(event.solve);
      print('DEBUG: addSolve completed successfully');
      
      // Reload solves and statistics
      add(LoadSolves(sessionId: event.solve.sessionId));
      add(LoadStatistics(event.solve.sessionId));
      
      // Generate new scramble
      add(GenerateNewScramble(event.solve.cubeType));
    } catch (e) {
      print('DEBUG: Error in _onAddSolve: $e');
      emit(state.copyWith(
        status: SolveStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateSolve(UpdateSolveEvent event, Emitter<SolveState> emit) async {
    try {
      // Update solve in repository would be implemented here
      // For now, just reload
      add(LoadSolves(sessionId: event.solve.sessionId));
      add(LoadStatistics(event.solve.sessionId));
    } catch (e) {
      emit(state.copyWith(
        status: SolveStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteSolve(DeleteSolveEvent event, Emitter<SolveState> emit) async {
    try {
      // Delete solve would be implemented here
      // For now, just reload
      final currentSessionId = state.solves.isNotEmpty ? state.solves.first.sessionId : 'default';
      add(LoadSolves(sessionId: currentSessionId));
      add(LoadStatistics(currentSessionId));
    } catch (e) {
      emit(state.copyWith(
        status: SolveStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onGenerateNewScramble(GenerateNewScramble event, Emitter<SolveState> emit) async {
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

  Future<void> _onLoadStatistics(LoadStatistics event, Emitter<SolveState> emit) async {
    try {
      final statistics = await getStatistics(event.sessionId);
      
      emit(state.copyWith(statistics: statistics));
    } catch (e) {
      emit(state.copyWith(
        status: SolveStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}