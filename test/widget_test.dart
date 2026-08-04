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

  testWidgets('ios shows a keyboard dismiss action above the keyboard', (
    WidgetTester tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              viewInsets: const EdgeInsets.only(bottom: 300),
            ),
            child: WalletKeeperKeyboardDismissOverlay(
              child: Scaffold(
                body: TextField(focusNode: focusNode, autofocus: true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    expect(find.text('내리기'), findsOneWidget);

    await tester.tap(find.text('내리기'));
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
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

  testWidgets('sms import dialog renders its content and actions', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmsInboxPage(
            drafts: const [],
            featureAccess: const WalletKeeperFeatureAccess(
              onboardingSeen: true,
              smsGranted: true,
              notificationGranted: true,
            ),
            settings: const WalletKeeperSmsSettings(
              smsReceiveEnabled: true,
              autoInputEnabled: false,
              showNotification: true,
              shareHeuristicReports: false,
              importWindowDays: 60,
            ),
            onBack: () {},
            onOpenSettingsPage: () {},
            onImportRecent: (_) async {},
            onOpenDraft: (_) {},
            onRequestSmsAccess: () async {},
            onQuickAutoInput: (_) async {},
            onDeleteSelected: (_) async {},
            onPasteFromClipboard: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('문자 가져오기').last);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('휴대폰에 저장된 최근'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    expect(find.text('가져오기'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('ios sms inbox only shows the paste action', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: SmsInboxPage(
            drafts: const [],
            featureAccess: const WalletKeeperFeatureAccess(
              onboardingSeen: true,
              smsGranted: false,
              notificationGranted: true,
            ),
            settings: const WalletKeeperSmsSettings(
              smsReceiveEnabled: false,
              autoInputEnabled: false,
              showNotification: true,
              shareHeuristicReports: false,
              importWindowDays: 60,
            ),
            onBack: () {},
            onOpenSettingsPage: () {},
            onImportRecent: (_) async {},
            onOpenDraft: (_) {},
            onRequestSmsAccess: () async {},
            onQuickAutoInput: (_) async {},
            onDeleteSelected: (_) async {},
            onPasteFromClipboard: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('문자 가져오기'), findsNothing);
    expect(find.text('문자 붙여넣기'), findsOneWidget);
  });

  testWidgets('sms inbox restores its scroll offset after reopening a draft', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime(2026, 8, 4, 12);
    final drafts = List.generate(
      24,
      (index) => WalletKeeperSmsDraft(
        id: 'scroll-$index',
        title: '감지 내역 $index',
        amount: 1000 + index.toDouble(),
        category: '지출',
        note: '',
        rawBody: '감지된 금융 문자 $index 1,000원 결제',
        type: EntryType.expense,
        date: now.subtract(Duration(minutes: index)),
        sourceAddress: '1588',
        sourceType: 'sms',
        institution: '은행',
        eventType: 'payment',
        matchedRule: 'test',
        sourceAppIconBase64: '',
      ),
    );
    var savedOffset = 0.0;

    Widget buildInbox(double initialOffset) {
      return MaterialApp(
        home: Scaffold(
          body: SmsInboxPage(
            drafts: drafts,
            featureAccess: const WalletKeeperFeatureAccess(
              onboardingSeen: true,
              smsGranted: true,
              notificationGranted: true,
            ),
            settings: const WalletKeeperSmsSettings(
              smsReceiveEnabled: true,
              autoInputEnabled: false,
              showNotification: true,
              shareHeuristicReports: false,
              importWindowDays: 60,
            ),
            initialScrollOffset: initialOffset,
            onScrollOffsetChanged: (offset) => savedOffset = offset,
            onBack: () {},
            onOpenSettingsPage: () {},
            onImportRecent: (_) async {},
            onOpenDraft: (_) {},
            onRequestSmsAccess: () async {},
            onQuickAutoInput: (_) async {},
            onDeleteSelected: (_) async {},
            onPasteFromClipboard: () async {},
          ),
        ),
      );
    }

    await tester.pumpWidget(buildInbox(0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(savedOffset, greaterThan(0));
    final previousOffset = savedOffset;

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();
    await tester.pumpWidget(buildInbox(previousOffset));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.pixels, closeTo(previousOffset, 1));
  });

  testWidgets('sms auto input uses the existing asset selector sheet', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime(2026, 8, 4);
    final asset = WalletKeeperAsset(
      id: 'asset-auto',
      name: '국민은행 생활비',
      institution: 'KB국민은행',
      type: WalletKeeperAssetType.account,
      openingBalance: 100000,
      lastFour: '1234',
      memo: '',
      brandKey: 'kb',
      iconBase64: '',
      createdAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmsSettingsPage(
            featureAccess: const WalletKeeperFeatureAccess(
              onboardingSeen: true,
              smsGranted: true,
              notificationGranted: true,
            ),
            settings: const WalletKeeperSmsSettings(
              smsReceiveEnabled: true,
              autoInputEnabled: true,
              showNotification: true,
              shareHeuristicReports: false,
              importWindowDays: 60,
              autoInputAssetId: 'asset-auto',
            ),
            assets: [asset],
            entries: const [],
            financialAppNotificationEnabled: true,
            onBack: () {},
            onOpenFinancialAppNotificationSettings: () async {},
            onChanged: (_) async {},
            onCreateAsset: () async => null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('자동입력 연결 자산'), findsOneWidget);
    expect(find.text('국민은행 생활비'), findsOneWidget);
    await tester.tap(find.text('국민은행 생활비'));
    await tester.pumpAndSettle();

    expect(find.text('연결할 자산'), findsOneWidget);
    expect(find.text('연결 안 함'), findsOneWidget);
    expect(find.text('새 자산 추가'), findsOneWidget);
  });

  testWidgets('new entry starts selected date at midnight', (
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
            initialDate: DateTime(2026, 5, 11, 18, 42),
            categorySuggestions: const [],
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

    expect(find.textContaining('26/5/11'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
  });

  testWidgets('entry editor shows the captured source notification', (
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
            existing: LedgerEntry(
              id: 'entry-with-source',
              title: '오픈뱅킹출금',
              amount: 2300,
              category: '지출',
              note: '',
              attachmentPaths: const [],
              type: EntryType.expense,
              date: DateTime(2026, 8, 3, 14, 34),
              createdAt: DateTime(2026, 8, 3, 14, 35),
              sourceNotification: WalletKeeperNotificationSource(
                sourceType: 'app_notification',
                address: 'viva.republica.toss',
                appName: '토스',
                title: '출금 2,300원',
                body: '이*현님 토스뱅크에서 출금되었습니다.',
                appIconBase64: '',
                receivedAt: DateTime(2026, 8, 3, 14, 35),
              ),
            ),
            categorySuggestions: const ['지출'],
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

    expect(find.text('감지된 원본 알림'), findsOneWidget);
    expect(find.text('토스'), findsOneWidget);
    expect(find.text('출금 2,300원'), findsOneWidget);
    expect(find.text('이*현님 토스뱅크에서 출금되었습니다.'), findsOneWidget);
  });
}
