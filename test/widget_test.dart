import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_keeper/main.dart';

void main() {
  testWidgets('wallet keeper splash renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WalletKeeperCustomSplashScreen()),
    );

    expect(find.byType(WalletKeeperCustomSplashScreen), findsOneWidget);
  });
}
