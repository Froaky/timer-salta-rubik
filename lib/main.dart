import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Presentation layer
import 'presentation/bloc/timer/timer_bloc.dart';
import 'presentation/bloc/solve/solve_bloc.dart';
import 'presentation/bloc/session/session_bloc.dart';
import 'presentation/bloc/compete/compete_bloc.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/pages/timer_page.dart';

import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await configureDependencies();

  runApp(const SaltaRubikApp());
}

class SaltaRubikApp extends StatelessWidget {
  const SaltaRubikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TimerBloc>(
          create: (context) => sl<TimerBloc>(),
        ),
        BlocProvider<SolveBloc>(
          create: (context) => sl<SolveBloc>(),
        ),
        BlocProvider<SessionBloc>(
          create: (context) => sl<SessionBloc>(),
        ),
        BlocProvider<CompeteBloc>(
          create: (context) => sl<CompeteBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Salta Rubik',
        theme: AppTheme.darkTheme,
        home: const TimerPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
