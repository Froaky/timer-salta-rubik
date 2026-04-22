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
      return startupUri.toString();
    }

    if (kIsWeb && startupUri.path == '/auth') {
      return startupUri.toString();
    }

    return '/';
  }

  Route<dynamic> _buildRoute(RouteSettings settings) {
    final rawName = settings.name ?? '/';
    final parsedUri = Uri.tryParse(rawName);
    final normalizedPath = parsedUri != null && parsedUri.path.isNotEmpty
        ? parsedUri.path
        : rawName;

    switch (normalizedPath) {
      case '/auth/callback':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => AuthPage(
            completeWcaCallbackOnLoad: true,
            initialCallbackUri: _resolveCallbackUri(parsedUri),
          ),
        );
      case '/auth':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const AuthPage(),
        );
      case '/':
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const TimerPage(),
        );
    }
  }

  Uri? _resolveCallbackUri(Uri? parsedUri) {
    if (parsedUri != null && parsedUri.path == '/auth/callback') {
      return parsedUri;
    }

    if (initialBrowserUri != null &&
        initialBrowserUri!.path == '/auth/callback') {
      return initialBrowserUri;
    }

    return null;
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
        onGenerateRoute: _buildRoute,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
