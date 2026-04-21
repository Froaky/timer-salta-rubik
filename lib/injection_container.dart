import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;

import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/local_database.dart';
import 'data/datasources/solve_local_datasource.dart';
import 'data/datasources/session_local_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/solve_repository_impl.dart';
import 'data/repositories/session_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/solve_repository.dart';
import 'domain/repositories/session_repository.dart';
import 'domain/usecases/add_solve.dart';
import 'domain/usecases/build_wca_login_uri.dart';
import 'domain/usecases/clear_auth_session.dart';
import 'domain/usecases/complete_wca_callback.dart';
import 'domain/usecases/get_solves.dart';
import 'domain/usecases/get_statistics.dart';
import 'domain/usecases/get_stored_auth_session.dart';
import 'domain/usecases/update_solve.dart';
import 'domain/usecases/delete_solve.dart';
import 'domain/usecases/delete_solves_by_session.dart';
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
  sl.registerLazySingleton<http.Client>(
    () => http.Client(),
  );

  // Database helper
  sl.registerLazySingleton<LocalDatabase>(
    () => LocalDatabase(),
  );

  // Data sources
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<http.Client>()),
  );

  sl.registerLazySingleton<SolveLocalDataSource>(
    () => SolveLocalDataSourceImpl(sl<LocalDatabase>()),
  );

  sl.registerLazySingleton<SessionLocalDataSource>(
    () => SessionLocalDataSourceImpl(sl<LocalDatabase>()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<SolveRepository>(
    () => SolveRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<SessionRepository>(
    () => SessionRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => AddSolve(sl()));
  sl.registerLazySingleton(() => BuildWcaLoginUri(sl()));
  sl.registerLazySingleton(() => ClearAuthSession(sl()));
  sl.registerLazySingleton(() => CompleteWcaCallback(sl()));
  sl.registerLazySingleton(() => GetSolves(sl()));
  sl.registerLazySingleton(() => GetStatistics(sl()));
  sl.registerLazySingleton(() => GetStoredAuthSession(sl()));
  sl.registerLazySingleton(() => UpdateSolve(sl()));
  sl.registerLazySingleton(() => DeleteSolve(sl()));
  sl.registerLazySingleton(() => DeleteSolvesBySession(sl()));
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
        deleteSolvesBySession: sl(),
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
