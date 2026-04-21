import 'package:flutter/material.dart';
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

  _FakeAuthRepository({this.storedSession});

  @override
  Uri buildWcaLoginUri({required bool isWeb}) {
    return Uri.parse(
        'https://timer-api-production.up.railway.app/api/v1/auth/wca/start');
  }

  @override
  Future<void> clearSession() async {
    storedSession = null;
  }

  @override
  Future<AuthSession?> completeWcaCallback(Uri callbackUri) async {
    return storedSession;
  }

  @override
  Future<AuthSession?> getStoredSession() async {
    return storedSession;
  }
}

void main() {
  Widget buildPage(_FakeAuthRepository repository) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: AuthPage(
        buildWcaLoginUri: BuildWcaLoginUri(repository),
        completeWcaCallback: CompleteWcaCallback(repository),
        getStoredAuthSession: GetStoredAuthSession(repository),
        clearAuthSession: ClearAuthSession(repository),
      ),
    );
  }

  testWidgets('shows WCA login button when signed out', (tester) async {
    final repository = _FakeAuthRepository();

    await tester.pumpWidget(buildPage(repository));
    await tester.pumpAndSettle();

    expect(find.text('Continuar con WCA'), findsOneWidget);
    expect(find.text('Sincroniza tus tiempos en la nube'), findsOneWidget);
  });

  testWidgets('shows linked WCA account when a stored session exists',
      (tester) async {
    final repository = _FakeAuthRepository(
      storedSession: const AuthSession(
        accessToken: 'token',
        userId: 'user-1',
        email: 'mateo@example.com',
        name: 'Mateo',
        providers: [
          AuthProviderProfile(
            provider: 'wca',
            wcaId: '2024TEST01',
            name: 'Mateo',
          ),
        ],
      ),
    );

    await tester.pumpWidget(buildPage(repository));
    await tester.pumpAndSettle();

    expect(find.text('Cuenta conectada'), findsOneWidget);
    expect(find.text('WCA ID: 2024TEST01'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });
}
