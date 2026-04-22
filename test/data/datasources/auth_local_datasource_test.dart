import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salta_rubik/data/datasources/auth_local_datasource.dart';
import 'package:salta_rubik/data/models/auth_session_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns cached session immediately after save', () async {
    final dataSource = AuthLocalDataSourceImpl();
    const session = AuthSessionModel(
      accessToken: 'token',
      userId: 'user-1',
      email: 'mateo@example.com',
      name: 'Mateo Coca',
      providers: [
        AuthProviderProfileModel(
          provider: 'wca',
          wcaId: '2024TEST01',
          countryIso2: 'AR',
        ),
      ],
    );

    await dataSource.saveSession(session);
    final stored = await dataSource.getStoredSession();

    expect(stored, session);
  });

  test('clearSession clears both memory and persisted storage', () async {
    final dataSource = AuthLocalDataSourceImpl();
    const session = AuthSessionModel(
      accessToken: 'token',
      userId: 'user-1',
      providers: [],
    );

    await dataSource.saveSession(session);
    await dataSource.clearSession();

    final stored = await dataSource.getStoredSession();
    expect(stored, isNull);
  });
}
