import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'data/datasources/local_database.dart';
import 'data/datasources/solve_local_datasource.dart';
import 'data/datasources/session_local_datasource.dart';
import 'data/repositories/solve_repository_impl.dart';
import 'data/repositories/session_repository_impl.dart';
import 'domain/repositories/solve_repository.dart';
import 'domain/repositories/session_repository.dart';
import 'domain/usecases/add_solve.dart';
import 'domain/usecases/get_solves.dart';
import 'domain/usecases/get_statistics.dart';
import 'domain/usecases/update_solve.dart';
import 'domain/usecases/delete_solve.dart';
import 'domain/usecases/create_session.dart';
import 'domain/usecases/get_sessions.dart';
import 'domain/usecases/update_session.dart';
import 'domain/usecases/delete_session.dart';
import 'domain/usecases/generate_scramble.dart';
import 'presentation/bloc/timer/timer_bloc.dart';
import 'presentation/bloc/solve/solve_bloc.dart';
import 'presentation/bloc/session/session_bloc.dart';
import 'presentation/bloc/compete/compete_bloc.dart';

final sl = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // Database helper
  sl.registerLazySingleton<LocalDatabase>(
    () => LocalDatabase(),
  );

  // Data sources
  sl.registerLazySingleton<SolveLocalDataSource>(
    () => SolveLocalDataSourceImpl(sl<LocalDatabase>()),
  );

  sl.registerLazySingleton<SessionLocalDataSource>(
    () => SessionLocalDataSourceImpl(sl<LocalDatabase>()),
  );

  // Repositories
  sl.registerLazySingleton<SolveRepository>(
    () => SolveRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<SessionRepository>(
    () => SessionRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => AddSolve(sl()));
  sl.registerLazySingleton(() => GetSolves(sl()));
  sl.registerLazySingleton(() => GetStatistics(sl()));
  sl.registerLazySingleton(() => UpdateSolve(sl()));
  sl.registerLazySingleton(() => DeleteSolve(sl()));
  sl.registerLazySingleton(() => CreateSession(sl()));
  sl.registerLazySingleton(() => GetSessions(sl()));
  sl.registerLazySingleton(() => UpdateSession(sl()));
  sl.registerLazySingleton(() => DeleteSession(sl()));
  sl.registerLazySingleton(() => GenerateScramble());

  // BLoCs
  sl.registerFactory(() => TimerBloc());
  sl.registerFactory(() => SolveBloc(
        addSolve: sl(),
        getSolves: sl(),
        getStatistics: sl(),
        generateScramble: sl(),
        updateSolve: sl(),
        deleteSolve: sl(),
      ));
  sl.registerFactory(() => SessionBloc(
        createSession: sl(),
        getSessions: sl(),
        updateSession: sl(),
        deleteSession: sl(),
      ));
  sl.registerFactory(() => CompeteBloc(
        generateScramble: sl(),
      ));
}
