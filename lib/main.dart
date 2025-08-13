import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Data layer
import 'data/datasources/local_database.dart';
import 'data/datasources/solve_local_datasource.dart';
import 'data/datasources/session_local_datasource.dart';
import 'data/repositories/solve_repository_impl.dart';
import 'data/repositories/session_repository_impl.dart';

// Domain layer
import 'domain/repositories/solve_repository.dart';
import 'domain/repositories/session_repository.dart';
import 'domain/usecases/add_solve.dart';
import 'domain/usecases/get_solves.dart';
import 'domain/usecases/get_statistics.dart';
import 'domain/usecases/create_session.dart';
import 'domain/usecases/get_sessions.dart';
import 'domain/usecases/generate_scramble.dart';

// Presentation layer
import 'presentation/bloc/timer/timer_bloc.dart';
import 'presentation/bloc/solve/solve_bloc.dart';
import 'presentation/bloc/session/session_bloc.dart';
import 'presentation/bloc/compete/compete_bloc.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/pages/timer_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final database = LocalDatabase();
  
  runApp(SaltaRubikApp(database: database));
}

class SaltaRubikApp extends StatelessWidget {
  final LocalDatabase database;
  
  const SaltaRubikApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // Data sources
        RepositoryProvider<SolveLocalDataSource>(
          create: (context) => SolveLocalDataSourceImpl(database),
        ),
        RepositoryProvider<SessionLocalDataSource>(
          create: (context) => SessionLocalDataSourceImpl(database),
        ),
        
        // Repositories
        RepositoryProvider<SolveRepository>(
          create: (context) => SolveRepositoryImpl(
            context.read<SolveLocalDataSource>(),
          ),
        ),
        RepositoryProvider<SessionRepository>(
          create: (context) => SessionRepositoryImpl(
            context.read<SessionLocalDataSource>(),
          ),
        ),
        
        // Use cases
        RepositoryProvider<AddSolve>(
          create: (context) => AddSolve(context.read<SolveRepository>()),
        ),
        RepositoryProvider<GetSolves>(
          create: (context) => GetSolves(context.read<SolveRepository>()),
        ),
        RepositoryProvider<GetStatistics>(
          create: (context) => GetStatistics(context.read<SolveRepository>()),
        ),
        RepositoryProvider<CreateSession>(
          create: (context) => CreateSession(context.read<SessionRepository>()),
        ),
        RepositoryProvider<GetSessions>(
          create: (context) => GetSessions(context.read<SessionRepository>()),
        ),
        RepositoryProvider<GenerateScramble>(
          create: (context) => GenerateScramble(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<TimerBloc>(
            create: (context) => TimerBloc(),
          ),
          BlocProvider<SolveBloc>(
            create: (context) => SolveBloc(
              addSolve: context.read<AddSolve>(),
              getSolves: context.read<GetSolves>(),
              getStatistics: context.read<GetStatistics>(),
              generateScramble: context.read<GenerateScramble>(),
            ),
          ),
          BlocProvider<SessionBloc>(
            create: (context) => SessionBloc(
              createSession: context.read<CreateSession>(),
              getSessions: context.read<GetSessions>(),
            ),
          ),
          BlocProvider<CompeteBloc>(
            create: (context) => CompeteBloc(
              generateScramble: context.read<GenerateScramble>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Salta Rubik',
          theme: AppTheme.darkTheme,
          home: const TimerPage(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
