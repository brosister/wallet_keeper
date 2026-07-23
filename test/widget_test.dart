import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:wallet_keeper/main.dart';

void main() {
  testWidgets('wallet keeper splash renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WalletKeeperCustomSplashScreen()),
    );

    expect(find.byType(WalletKeeperCustomSplashScreen), findsOneWidget);
  });

  testWidgets('entry editor switches to fixed mode without stale render object', (
    WidgetTester tester,
  ) async {
    await initializeDateFormatting('ko_KR');
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: EntryEditorPage(
            categorySuggestions: const ['식비', '교통'],
            assets: const [],
            featureAccess: const WalletKeeperFeatureAccess(
              onboardingSeen: true,
              smsGranted: true,
              notificationGranted: true,
            ),
            onRequestSmsAccess: () async {},
            onCreateAsset: (_) async => null,
            onSave: (_) async {},
            onCancel: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('고정').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('반복일'), findsOneWidget);
  });

  testWidgets('category autocomplete opens and closes without overlay assertion', (
    WidgetTester tester,
  ) async {
    await initializeDateFormatting('ko_KR');
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: EntryEditorPage(
            categorySuggestions: const ['식비', '교통'],
            assets: const [],
            featureAccess: const WalletKeeperFeatureAccess(
              onboardingSeen: true,
              smsGranted: true,
              notificationGranted: true,
            ),
            onRequestSmsAccess: () async {},
            onCreateAsset: (_) async => null,
            onSave: (_) async {},
            onCancel: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final categoryField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == '분류 입력',
    );
    final amountField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == '0',
    );

    await tester.tap(categoryField);
    await tester.pumpAndSettle();
    expect(find.text('식비'), findsOneWidget);

    await tester.tap(amountField);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
