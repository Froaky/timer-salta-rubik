import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/navigation/web_redirect.dart';
// Presentation layer
import 'presentation/bloc/timer/timer_bloc.dart';
import 'presentation/bloc/solve/solve_bloc.dart';
import 'presentation/bloc/session/session_bloc.dart';
import 'presentation/bloc/compete/compete_bloc.dart';
import 'presentation/pages/auth_page.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/pages/timer_page.dart';

import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialBrowserUri = kIsWeb ? getCurrentBrowserUri() : null;

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Initialize dependency injection
  await configureDependencies();

  runApp(SaltaRubikApp(initialBrowserUri: initialBrowserUri));
}

class SaltaRubikApp extends StatelessWidget {
  final Uri? initialBrowserUri;

  const SaltaRubikApp({
    super.key,
    this.initialBrowserUri,
  });

  String _resolveInitialRoute() {
    final startupUri = initialBrowserUri ?? Uri.base;

    if (kIsWeb && startupUri.path == '/auth/callback') {
      return '/auth/callback';
    }

    if (kIsWeb && startupUri.path == '/auth') {
      return '/auth';
    }

    return '/';
  }

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
        initialRoute: _resolveInitialRoute(),
        routes: {
          '/': (context) => const TimerPage(),
          '/auth': (context) => const AuthPage(),
          '/auth/callback': (context) => AuthPage(
                completeWcaCallbackOnLoad: true,
                initialCallbackUri: initialBrowserUri,
              ),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
