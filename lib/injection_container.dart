import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
  // Database
  final database = await _initDatabase();
  sl.registerSingleton<Database>(database);
  
  // Data sources
  sl.registerLazySingleton<LocalDatabase>(
    () => LocalDatabase(),
  );
  
  sl.registerLazySingleton<SolveLocalDataSource>(
    () => SolveLocalDataSourceImpl(sl()),
  );
  
  sl.registerLazySingleton<SessionLocalDataSource>(
    () => SessionLocalDataSourceImpl(sl()),
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

Future<Database> _initDatabase() async {
  final databasesPath = await getDatabasesPath();
  final path = join(databasesPath, 'salta_rubik.db');
  
  return await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE sessions(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          cube_type TEXT NOT NULL DEFAULT '3x3',
          created_at INTEGER NOT NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE solves(
          id TEXT PRIMARY KEY,
          session_id TEXT NOT NULL,
          time_ms INTEGER NOT NULL,
          penalty TEXT,
          scramble TEXT NOT NULL,
          cube_type TEXT NOT NULL DEFAULT '3x3',
          lane INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (session_id) REFERENCES sessions (id)
        )
      ''');
      
      // Create default session
      await db.insert('sessions', {
        'id': 'default',
        'name': 'Default Session',
        'cube_type': '3x3',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    },
  );
}