import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_keeper/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cloud bundle preserves every record type and excludes settings', () {
    final now = DateTime(2026, 8, 4, 12, 30);
    final bundle = WalletKeeperSyncBundle(
      entries: [
        LedgerEntry(
          id: 'fixed-entry',
          title: '카드대금',
          amount: 965257,
          category: '고정비',
          note: '매월 결제',
          attachmentPaths: const [
            'https://app-master.officialsite.kr/uploads/wallet-keeper/user/photo.jpg',
          ],
          type: EntryType.expense,
          date: now,
          createdAt: now,
          fixedDay: 31,
          assetId: 'asset-1',
          sourceNotification: WalletKeeperNotificationSource(
            sourceType: 'app_notification',
            address: 'com.kbcard.kbkookmincard',
            appName: 'KB Pay',
            title: '카드 결제',
            body: '카드대금 965,257원',
            appIconBase64: 'icon',
            receivedAt: now,
          ),
        ),
      ],
      memos: [
        WalletKeeperMemo(
          id: 'memo-1',
          title: '메모',
          content: '내용',
          monthKey: '2026-08',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      budgets: [
        WalletKeeperBudgetSetting(
          id: 'budget-1',
          category: '식비',
          amount: 500000,
          monthKey: '2026-08',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      assets: [
        WalletKeeperAsset(
          id: 'asset-1',
          name: '국민은행 생활비',
          institution: 'KB국민은행',
          type: WalletKeeperAssetType.account,
          openingBalance: 2102267,
          lastFour: '0071',
          memo: '주계좌',
          brandKey: 'kb',
          iconBase64: 'asset-icon',
          createdAt: now,
        ),
      ],
      smsDrafts: [
        WalletKeeperSmsDraft(
          id: 'draft-1',
          title: '씨유등촌점',
          amount: 2300,
          category: '식비',
          note: '',
          rawBody: '2,300원 결제 KB국민체크 | 씨유등촌점',
          type: EntryType.expense,
          date: now,
          sourceAddress: 'com.viva.republica.toss',
          sourceType: 'app_notification',
          institution: '토스',
          eventType: 'payment',
          matchedRule: 'financial_notification',
          sourceAppIconBase64: 'draft-icon',
          sourceAppName: '토스',
          sourceNotificationTitle: '2,300원 결제',
          sourceNotificationBody: 'KB국민체크 | 씨유등촌점',
          sourceReceivedAt: now,
        ),
      ],
    );

    final json = bundle.toJson();
    expect(json.containsKey('smsSettings'), isFalse);
    expect(json['drafts'], hasLength(1));

    final restored = WalletKeeperSyncBundle.fromJson(
      (jsonDecode(jsonEncode(json)) as Map).cast<String, dynamic>(),
    );
    expect(restored.hasMeaningfulData, isTrue);
    expect(restored.entries.single.fixedDay, 31);
    expect(restored.entries.single.assetId, 'asset-1');
    expect(restored.entries.single.sourceNotification?.appName, 'KB Pay');
    expect(restored.entries.single.attachmentPaths, hasLength(1));
    expect(restored.budgets.single.amount, 500000);
    expect(restored.assets.single.openingBalance, 2102267);
    expect(restored.smsDrafts.single.rawBody, contains('씨유등촌점'));
    expect(restored.smsDrafts.single.sourceAppName, '토스');
  });

  test('a draft-only bundle is meaningful for login conflict handling', () {
    final now = DateTime(2026, 8, 4);
    final bundle = WalletKeeperSyncBundle(
      entries: const [],
      memos: const [],
      budgets: const [],
      assets: const [],
      smsDrafts: [
        WalletKeeperSmsDraft(
          id: 'draft-only',
          title: '입금',
          amount: 1,
          category: '수입',
          note: '',
          rawBody: '1원 입금',
          type: EntryType.income,
          date: now,
          sourceAddress: '1588',
          sourceType: 'sms',
          institution: '은행',
          eventType: 'deposit',
          matchedRule: 'sms',
          sourceAppIconBase64: '',
        ),
      ],
    );

    expect(bundle.hasMeaningfulData, isTrue);
  });

  test('attachment path helper distinguishes server URLs from local files', () {
    expect(
      walletKeeperIsRemoteAttachmentPath(
        'https://app-master.officialsite.kr/uploads/photo.jpg',
      ),
      isTrue,
    );
    expect(
      walletKeeperIsRemoteAttachmentPath('/data/user/0/cache/photo.jpg'),
      isFalse,
    );
  });

  test('precise Flutter parsing replaces a native realtime draft', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = WalletKeeperSmsAutomationRepository();
    final now = DateTime(2026, 8, 4, 13, 10);
    final nativeDraft = WalletKeeperSmsDraft(
      id: 'native-draft',
      title: '결제',
      amount: 2300,
      category: '지출',
      note: '',
      rawBody: '2,300원 결제 KB국민체크 | 씨유등촌점',
      type: EntryType.expense,
      date: now,
      sourceAddress: 'com.viva.republica.toss',
      sourceType: 'app_notification',
      institution: '토스',
      eventType: '결제',
      matchedRule: 'native_financial_notification',
      sourceAppIconBase64: '',
    );
    await repository.replaceInboxDrafts([nativeDraft]);

    final preciseDraft = nativeDraft.copyWith(
      title: '씨유등촌점',
      category: '식비',
      matchedRule: 'financial_notification',
      sourceAppIconBase64: 'saved-icon',
    );
    await repository.saveInboxDrafts([preciseDraft]);

    final stored = await repository.loadInboxDrafts();
    expect(stored, hasLength(1));
    expect(stored.single.title, '씨유등촌점');
    expect(stored.single.category, '식비');
    expect(stored.single.sourceAppIconBase64, 'saved-icon');
  });

  test('automatic input removes a matching native realtime draft', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = WalletKeeperSmsAutomationRepository();
    final now = DateTime(2026, 8, 4, 13, 10);
    final draft = WalletKeeperSmsDraft(
      id: 'auto-draft',
      title: '급여',
      amount: 3000000,
      category: '급여',
      note: '',
      rawBody: '3,000,000원 입금',
      type: EntryType.income,
      date: now,
      sourceAddress: 'bank.app',
      sourceType: 'app_notification',
      institution: '은행',
      eventType: '입금',
      matchedRule: 'native_financial_notification',
      sourceAppIconBase64: '',
    );
    await repository.replaceInboxDrafts([draft]);

    final result = await repository.handleIncomingDraft(
      draft.copyWith(matchedRule: 'financial_notification'),
      autoSaveToLedger: true,
    );

    expect(result?.savedDirectly, isTrue);
    expect(await repository.loadInboxDrafts(), isEmpty);
    expect((await LedgerRepository().load()).single.id, 'auto-draft');
  });

  test('automatic input connects the configured preferred asset', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 8, 4, 15);
    final preferredAsset = WalletKeeperAsset(
      id: 'preferred-asset',
      name: '생활비 계좌',
      institution: 'KB국민은행',
      type: WalletKeeperAssetType.account,
      openingBalance: 100000,
      lastFour: '1234',
      memo: '',
      brandKey: 'kb',
      iconBase64: '',
      createdAt: now,
    );
    await WalletKeeperAssetRepository().save([preferredAsset]);
    final settings = WalletKeeperSmsSettings(
      smsReceiveEnabled: true,
      autoInputEnabled: true,
      showNotification: true,
      shareHeuristicReports: false,
      importWindowDays: 60,
      autoInputAssetId: preferredAsset.id,
    );
    await WalletKeeperSmsSettingsRepository().save(settings);
    expect(
      (await WalletKeeperSmsSettingsRepository().load()).autoInputAssetId,
      preferredAsset.id,
    );

    final draft = WalletKeeperSmsDraft(
      id: 'preferred-entry',
      title: '편의점',
      amount: 1500,
      category: '식비',
      note: '',
      rawBody: '1,500원 결제',
      type: EntryType.expense,
      date: now,
      sourceAddress: 'card.app',
      sourceType: 'app_notification',
      institution: '카드사',
      eventType: 'payment',
      matchedRule: 'test',
      sourceAppIconBase64: '',
    );
    final result = await WalletKeeperSmsAutomationRepository()
        .handleIncomingDraft(
          draft,
          autoSaveToLedger: true,
          preferredAssetId: settings.autoInputAssetId,
        );

    expect(result?.savedDirectly, isTrue);
    expect(
      (await LedgerRepository().load()).single.assetId,
      preferredAsset.id,
    );
  });
}
