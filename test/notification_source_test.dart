import 'package:flutter_test/flutter_test.dart';

import 'package:wallet_keeper/main.dart';

void main() {
  test('바로 저장한 금융앱 알림 원본을 기록에 보존한다', () {
    final receivedAt = DateTime(2026, 8, 3, 14, 35);
    final draft = WalletKeeperSmsDraft(
      id: 'notification-1',
      title: '오픈뱅킹출금',
      amount: 2300,
      category: '지출',
      note: '',
      rawBody: '출금 2,300원 토스뱅크 오픈뱅킹출금',
      type: EntryType.expense,
      date: DateTime(2026, 8, 3, 14, 34),
      sourceAddress: 'viva.republica.toss',
      sourceType: 'app_notification',
      institution: '토스',
      eventType: 'withdrawal',
      matchedRule: 'app_notification',
      sourceAppIconBase64: 'saved-icon',
      sourceAppName: '토스',
      sourceNotificationTitle: '출금 2,300원',
      sourceNotificationBody: '이*현님 토스뱅크에서 출금되었습니다.',
      sourceReceivedAt: receivedAt,
    );

    final restored = LedgerEntry.fromJson(draft.toEntry().toJson());
    final source = restored.sourceNotification;

    expect(source, isNotNull);
    expect(source!.sourceType, 'app_notification');
    expect(source.address, 'viva.republica.toss');
    expect(source.appName, '토스');
    expect(source.title, '출금 2,300원');
    expect(source.body, '이*현님 토스뱅크에서 출금되었습니다.');
    expect(source.appIconBase64, 'saved-icon');
    expect(source.receivedAt, receivedAt);
  });
}
