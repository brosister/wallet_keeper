import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_keeper/main.dart';

void main() {
  testWidgets('wallet keeper app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const WalletKeeperApp());

    expect(find.byType(WalletKeeperBottomBar), findsOneWidget);
  });
}
