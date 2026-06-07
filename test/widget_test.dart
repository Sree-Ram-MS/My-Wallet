// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_wallet/main.dart';

void main() {
  testWidgets('App smoke test - verifies AuthScreen renders', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyWalletApp());

    // Verify that the AuthScreen is present by checking for the MyWallet logo text
    expect(find.text('My Wallet'), findsOneWidget);
    expect(find.text('Log In with Google'), findsOneWidget);
  });
}
