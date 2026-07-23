import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_keeper/main.dart';

void main() {
  test('자산 종류별로 선택 가능한 금융사만 제공한다', () {
    final expectedMinimumCounts = {
      WalletKeeperAssetType.account: 40,
      WalletKeeperAssetType.card: 25,
      WalletKeeperAssetType.securities: 25,
      WalletKeeperAssetType.crypto: 20,
      WalletKeeperAssetType.loan: 50,
      WalletKeeperAssetType.cash: 1,
    };

    for (final entry in expectedMinimumCounts.entries) {
      final brands = walletKeeperAssetBrands
          .where((brand) => brand.supports(entry.key))
          .toList();
      expect(brands.length, greaterThanOrEqualTo(entry.value));
      expect(brands.every((brand) => brand.supports(entry.key)), isTrue);
    }
  });

  test('기존 카드 자산의 공용 금융사 키를 카드사 키로 변환한다', () {
    final asset = WalletKeeperAsset.fromJson({
      'id': 'legacy-card',
      'name': '신한 카드',
      'institution': '신한카드',
      'type': 'card',
      'openingBalance': 0,
      'lastFour': '',
      'memo': '',
      'brandKey': 'shinhan',
      'iconBase64': '',
      'createdAt': DateTime(2026, 7, 23).toIso8601String(),
    });

    expect(asset.brandKey, 'shinhan_card');
  });

  test('같은 금융그룹은 더 구체적인 카드사 명칭을 우선 감지한다', () {
    expect(
      walletKeeperAssetBrandFromText('카카오뱅크 체크카드 12,000원 결제')?.key,
      'kakaobank_card',
    );
    expect(
      walletKeeperAssetBrandFromText(
        'viva.republica.toss [KB국민카드] 2,300원 결제',
      )?.key,
      'kb_card',
    );
  });

  test('자동 생성된 자산 이름만 금융사 변경 시 교체한다', () {
    final kbBank = walletKeeperAssetBrandByKey('kb_bank');

    expect(
      walletKeeperIsGeneratedAssetName(
        name: 'KB국민은행 계좌',
        institution: 'KB국민은행',
        type: WalletKeeperAssetType.account,
        brand: kbBank,
      ),
      isTrue,
    );
    expect(
      walletKeeperIsGeneratedAssetName(
        name: '월급 통장',
        institution: 'KB국민은행',
        type: WalletKeeperAssetType.account,
        brand: kbBank,
      ),
      isFalse,
    );
  });

  test('국내외 주요 코인 거래소를 선택할 수 있다', () {
    final cryptoKeys = walletKeeperAssetBrands
        .where((brand) => brand.supports(WalletKeeperAssetType.crypto))
        .map((brand) => brand.key)
        .toSet();

    expect(
      cryptoKeys,
      containsAll(['upbit', 'binance', 'coinbase', 'bybit', 'okx', 'mexc']),
    );
  });

  test('수입과 지출 중 유효한 자산에 연결되지 않은 내역만 찾는다', () {
    final now = DateTime(2026, 7, 23);
    final asset = WalletKeeperAsset(
      id: 'account',
      name: '생활비 통장',
      institution: 'KB국민은행',
      type: WalletKeeperAssetType.account,
      openingBalance: 0,
      lastFour: '',
      memo: '',
      brandKey: 'kb_bank',
      iconBase64: '',
      createdAt: now,
    );
    LedgerEntry entry({
      required String id,
      required EntryType type,
      String? assetId,
    }) => LedgerEntry(
      id: id,
      title: id,
      amount: 1000,
      category: '테스트',
      note: '',
      attachmentPaths: const [],
      type: type,
      date: now,
      createdAt: now,
      assetId: assetId,
    );

    final result = walletKeeperUnlinkedAssetEntries([
      entry(id: 'expense', type: EntryType.expense),
      entry(id: 'income', type: EntryType.income, assetId: 'missing'),
      entry(id: 'connected', type: EntryType.expense, assetId: asset.id),
      entry(id: 'transfer', type: EntryType.transfer),
    ], [
      asset,
    ]);

    expect(result.map((item) => item.id), containsAll(['expense', 'income']));
    expect(result.map((item) => item.id), isNot(contains('connected')));
    expect(result.map((item) => item.id), isNot(contains('transfer')));
  });

  test('금융 문자에서 같은 금융사의 카드 자산을 우선 감지한다', () {
    final now = DateTime(2026, 7, 23);
    final draft = WalletKeeperSmsDraft(
      id: 'sms-1',
      title: '편의점 결제',
      amount: 2300,
      category: '카드',
      note: '',
      rawBody: '[KB국민카드] 2,300원 일시불',
      type: EntryType.expense,
      date: now,
      sourceAddress: '15881688',
      sourceType: 'sms',
      institution: 'KB국민카드',
      eventType: 'payment',
      matchedRule: 'card_payment',
      sourceAppIconBase64: '',
    );
    final assets = [
      WalletKeeperAsset(
        id: 'kb-bank',
        name: '월급 통장',
        institution: 'KB국민은행',
        type: WalletKeeperAssetType.account,
        openingBalance: 1000000,
        lastFour: '',
        memo: '',
        brandKey: 'kb_bank',
        iconBase64: '',
        createdAt: now,
      ),
      WalletKeeperAsset(
        id: 'kb-card',
        name: '생활비 카드',
        institution: 'KB국민카드',
        type: WalletKeeperAssetType.card,
        openingBalance: 0,
        lastFour: '',
        memo: '',
        brandKey: 'kb_card',
        iconBase64: '',
        createdAt: now,
      ),
    ];

    expect(detectWalletKeeperAsset(draft, assets)?.id, 'kb-card');
  });

  test('연결 거래는 계좌와 카드 잔액에 서로 다른 방향으로 반영된다', () {
    final now = DateTime(2026, 7, 23);
    final account = WalletKeeperAsset(
      id: 'account',
      name: '생활비 통장',
      institution: 'KB국민은행',
      type: WalletKeeperAssetType.account,
      openingBalance: 100000,
      lastFour: '',
      memo: '',
      brandKey: 'kb_bank',
      iconBase64: '',
      createdAt: now,
    );
    final card = account.copyWith(
      id: 'card',
      name: '생활비 카드',
      type: WalletKeeperAssetType.card,
      openingBalance: 0,
      brandKey: 'kb_card',
    );
    LedgerEntry expenseFor(String assetId) => LedgerEntry(
      id: 'entry-$assetId',
      title: '편의점',
      amount: 10000,
      category: '생활',
      note: '',
      attachmentPaths: const [],
      type: EntryType.expense,
      date: now,
      createdAt: now,
      assetId: assetId,
    );

    expect(walletKeeperAssetCurrentBalance(account, [expenseFor('account')]), 90000);
    expect(walletKeeperAssetCurrentBalance(card, [expenseFor('card')]), 10000);
  });

  test('순자산 카드에는 금액이 큰 자산 종류 두 개를 표시한다', () {
    final now = DateTime(2026, 7, 23);
    WalletKeeperAsset asset({
      required String id,
      required WalletKeeperAssetType type,
      required double amount,
    }) => WalletKeeperAsset(
      id: id,
      name: id,
      institution: '',
      type: type,
      openingBalance: amount,
      lastFour: '',
      memo: '',
      brandKey: '',
      iconBase64: '',
      createdAt: now,
    );

    final items = walletKeeperTopAssetSummaryItems([
      asset(id: 'account', type: WalletKeeperAssetType.account, amount: 1000),
      asset(id: 'crypto', type: WalletKeeperAssetType.crypto, amount: 3000),
      asset(id: 'loan-a', type: WalletKeeperAssetType.loan, amount: 2500),
      asset(id: 'loan-b', type: WalletKeeperAssetType.loan, amount: 2000),
    ], const []);

    expect(items.map((item) => item.label), ['대출 잔액', '코인 자산']);
    expect(items.map((item) => item.amount), [4500, 3000]);
  });

  test('값이 있는 자산 종류가 하나면 해당 지표만 표시한다', () {
    final now = DateTime(2026, 7, 23);
    final items = walletKeeperTopAssetSummaryItems([
      WalletKeeperAsset(
        id: 'cash',
        name: '현금',
        institution: '',
        type: WalletKeeperAssetType.cash,
        openingBalance: 50000,
        lastFour: '',
        memo: '',
        brandKey: '',
        iconBase64: '',
        createdAt: now,
      ),
    ], const []);

    expect(items.length, 1);
    expect(items.single.label, '현금');
    expect(items.single.amount, 50000);
  });

  test('자산별 입출금 내역은 이체를 제외하고 최신순으로 정렬한다', () {
    final base = DateTime(2026, 7, 20, 10);
    LedgerEntry entry({
      required String id,
      required EntryType type,
      required DateTime date,
      required String assetId,
      DateTime? createdAt,
    }) => LedgerEntry(
      id: id,
      title: id,
      amount: 1000,
      category: '테스트',
      note: '',
      attachmentPaths: const [],
      type: type,
      date: date,
      createdAt: createdAt ?? date,
      assetId: assetId,
    );

    final result = walletKeeperAssetEntries('target', [
      entry(
        id: 'old',
        type: EntryType.expense,
        date: base,
        assetId: 'target',
      ),
      entry(
        id: 'same-day-newer',
        type: EntryType.income,
        date: base.add(const Duration(days: 2)),
        createdAt: base.add(const Duration(days: 2, hours: 2)),
        assetId: 'target',
      ),
      entry(
        id: 'same-day-older',
        type: EntryType.expense,
        date: base.add(const Duration(days: 2)),
        createdAt: base.add(const Duration(days: 2, hours: 1)),
        assetId: 'target',
      ),
      entry(
        id: 'transfer',
        type: EntryType.transfer,
        date: base.add(const Duration(days: 3)),
        assetId: 'target',
      ),
      entry(
        id: 'other-asset',
        type: EntryType.income,
        date: base.add(const Duration(days: 4)),
        assetId: 'other',
      ),
    ]);

    expect(
      result.map((entry) => entry.id),
      ['same-day-newer', 'same-day-older', 'old'],
    );
  });

  test('현재 금액을 수정해도 연결 거래가 중복 반영되지 않는다', () {
    final now = DateTime(2026, 7, 23);
    final expense = LedgerEntry(
      id: 'expense',
      title: '식비',
      amount: 10000,
      category: '식비',
      note: '',
      attachmentPaths: const [],
      type: EntryType.expense,
      date: now,
      createdAt: now,
      assetId: 'account',
    );
    final original = WalletKeeperAsset(
      id: 'account',
      name: '생활비 통장',
      institution: 'KB국민은행',
      type: WalletKeeperAssetType.account,
      openingBalance: 100000,
      lastFour: '',
      memo: '',
      brandKey: 'kb_bank',
      iconBase64: '',
      createdAt: now,
    );

    expect(
      walletKeeperAssetCurrentBalance(original, [expense], asOf: now),
      90000,
    );

    const editedCurrentBalance = 80000.0;
    final adjustedOpeningBalance =
        editedCurrentBalance -
        walletKeeperAssetLinkedBalanceDelta(
          assetId: original.id,
          type: original.type,
          entries: [expense],
          asOf: now,
        );
    final edited = original.copyWith(openingBalance: adjustedOpeningBalance);

    expect(
      walletKeeperAssetCurrentBalance(edited, [expense], asOf: now),
      editedCurrentBalance,
    );
  });

  test('전체 자산 기록은 등록된 자산의 수입과 지출만 최신순으로 모은다', () {
    final now = DateTime(2026, 7, 23);
    WalletKeeperAsset asset(String id) => WalletKeeperAsset(
      id: id,
      name: id,
      institution: '',
      type: WalletKeeperAssetType.account,
      openingBalance: 0,
      lastFour: '',
      memo: '',
      brandKey: '',
      iconBase64: '',
      createdAt: now,
    );
    LedgerEntry entry({
      required String id,
      required EntryType type,
      required DateTime date,
      String? assetId,
    }) => LedgerEntry(
      id: id,
      title: id,
      amount: 1000,
      category: '테스트',
      note: '',
      attachmentPaths: const [],
      type: type,
      date: date,
      createdAt: date,
      assetId: assetId,
    );

    final result = walletKeeperAllAssetEntries(
      [asset('a'), asset('b')],
      [
        entry(
          id: 'asset-a',
          type: EntryType.expense,
          date: now,
          assetId: 'a',
        ),
        entry(
          id: 'asset-b',
          type: EntryType.income,
          date: now.add(const Duration(days: 1)),
          assetId: 'b',
        ),
        entry(
          id: 'deleted-asset',
          type: EntryType.expense,
          date: now.add(const Duration(days: 2)),
          assetId: 'missing',
        ),
        entry(
          id: 'transfer',
          type: EntryType.transfer,
          date: now.add(const Duration(days: 3)),
          assetId: 'a',
        ),
        entry(
          id: 'unlinked',
          type: EntryType.expense,
          date: now.add(const Duration(days: 4)),
        ),
      ],
    );

    expect(result.map((entry) => entry.id), ['asset-b', 'asset-a']);
  });
}
