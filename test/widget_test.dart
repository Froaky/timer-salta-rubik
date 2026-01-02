import 'package:flutter_test/flutter_test.dart';

import 'package:salta_rubik/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SaltaRubikApp());

    // Verify that the title exists
    expect(find.text('Salta Rubik'), findsOneWidget);
  });
}
