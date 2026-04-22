import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salta_rubik/domain/entities/auth_session.dart';
import 'package:salta_rubik/domain/repositories/auth_repository.dart';
import 'package:salta_rubik/domain/usecases/build_wca_login_uri.dart';
import 'package:salta_rubik/domain/usecases/clear_auth_session.dart';
import 'package:salta_rubik/domain/usecases/complete_wca_callback.dart';
import 'package:salta_rubik/domain/usecases/get_stored_auth_session.dart';
import 'package:salta_rubik/presentation/pages/auth_page.dart';
import 'package:salta_rubik/presentation/theme/app_theme.dart';

class _FakeAuthRepository implements AuthRepository {
  AuthSession? storedSession;
  Uri? lastCallbackUri;

  _FakeAuthRepository({this.storedSession});

  @override
  Uri buildWcaLoginUri({required bool isWeb}) {
    return Uri.parse(
      'https://timer-api-production.up.railway.app/api/v1/auth/wca/start',
    );
  }

  @override
  Future<void> clearSession() async {
    storedSession = null;
  }

  @override
  Future<AuthSession?> completeWcaCallback(Uri callbackUri) async {
    lastCallbackUri = callbackUri;
    return storedSession;
  }

  @override
  Future<AuthSession?> getStoredSession() async {
    return storedSession;
  }
}

void main() {
  Widget buildPage(
    _FakeAuthRepository repository, {
    Future<bool> Function(Uri uri)? openWcaLoginUri,
    bool completeWcaCallbackOnLoad = false,
    Uri? initialCallbackUri,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: AuthPage(
        completeWcaCallbackOnLoad: completeWcaCallbackOnLoad,
        buildWcaLoginUri: BuildWcaLoginUri(repository),
        completeWcaCallback: CompleteWcaCallback(repository),
        getStoredAuthSession: GetStoredAuthSession(repository),
        clearAuthSession: ClearAuthSession(repository),
        openWcaLoginUri: openWcaLoginUri,
        initialCallbackUri: initialCallbackUri,
      ),
    );
  }

  testWidgets('shows WCA login button when signed out', (tester) async {
    final repository = _FakeAuthRepository();

    await tester.pumpWidget(buildPage(repository));
    await tester.pumpAndSettle();

    expect(find.text('Continuar con WCA'), findsOneWidget);
    expect(find.text('Sincroniza tus tiempos en la nube'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('pressing WCA button uses injected web redirect handler',
      (tester) async {
    final repository = _FakeAuthRepository();
    Uri? redirectedTo;

    await tester.pumpWidget(
      buildPage(
        repository,
        openWcaLoginUri: (uri) async {
          redirectedTo = uri;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Continuar con WCA'));
    await tester.tap(find.text('Continuar con WCA'));
    await tester.pump();

    expect(
      redirectedTo,
      Uri.parse(
        'https://timer-api-production.up.railway.app/api/v1/auth/wca/start',
      ),
    );
  });

  testWidgets('shows linked WCA account when a stored session exists',
      (tester) async {
    final repository = _FakeAuthRepository(
      storedSession: const AuthSession(
        accessToken: 'token',
        userId: 'user-1',
        email: 'mateo@example.com',
        name: 'Mateo Coca',
        providers: [
          AuthProviderProfile(
            provider: 'wca',
            wcaId: '2024TEST01',
            name: 'Mateo Coca',
            countryIso2: 'AR',
          ),
        ],
      ),
    );

    await tester.pumpWidget(buildPage(repository));
    await tester.pumpAndSettle();

    expect(find.text('Cuenta conectada'), findsOneWidget);
    expect(find.text('Mateo Coca'), findsOneWidget);
    expect(find.text('WCA ID 2024TEST01'), findsOneWidget);
    expect(find.text('2024TEST01'), findsOneWidget);
    expect(find.text('mateo@example.com'), findsOneWidget);
    expect(find.text('AR'), findsOneWidget);
    expect(find.text('Ir al timer'), findsOneWidget);
    expect(find.text('Cerrar sesion'), findsOneWidget);
  });

  testWidgets('uses startup callback uri to complete WCA auth on web callback',
      (tester) async {
    final repository = _FakeAuthRepository(
      storedSession: const AuthSession(
        accessToken: 'token',
        userId: 'user-1',
        name: 'Mateo Coca',
        providers: [
          AuthProviderProfile(
            provider: 'wca',
            wcaId: '2024TEST01',
          ),
        ],
      ),
    );
    final callbackUri = Uri.parse(
      'https://timer-salta-rubik-production.up.railway.app/auth/callback?access_token=abc123&provider=wca',
    );

    await tester.pumpWidget(
      buildPage(
        repository,
        completeWcaCallbackOnLoad: true,
        initialCallbackUri: callbackUri,
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.lastCallbackUri, callbackUri);
    expect(find.text('Cuenta conectada'), findsOneWidget);
    expect(find.text('Mateo Coca'), findsOneWidget);
  });

  testWidgets('shows callback diagnostics when token is missing',
      (tester) async {
    final repository = _FakeAuthRepository();
    final callbackUri = Uri.parse(
      'https://timer-salta-rubik-production.up.railway.app/auth/callback',
    );

    await tester.pumpWidget(
      buildPage(
        repository,
        completeWcaCallbackOnLoad: true,
        initialCallbackUri: callbackUri,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No llego un token valido desde WCA.'), findsOneWidget);
    expect(find.text('Diagnostico callback web'), findsAtLeastNWidgets(1));
    expect(find.textContaining('hasTokenInParams: false'), findsOneWidget);
    expect(find.textContaining('storedSessionFound: false'), findsOneWidget);
  });
}
