import 'package:flutter_test/flutter_test.dart';

import 'package:salta_rubik/injection_container.dart';
import 'package:salta_rubik/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await sl.reset();
    await configureDependencies();
  });

  testWidgets('App starts smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SaltaRubikApp());
    await tester.pump();

    expect(find.text('Salta Rubik'), findsOneWidget);
  });
}
