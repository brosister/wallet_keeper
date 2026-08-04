import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:wallet_keeper/main.dart';

void main() {
  LedgerEntry expense({
    required String id,
    required DateTime date,
    int? fixedDay,
    String title = '국민카드 카드대금',
  }) {
    return LedgerEntry(
      id: id,
      title: title,
      amount: 965257,
      category: '카드대금',
      note: '자동이체 납부',
      attachmentPaths: const [],
      type: EntryType.expense,
      date: date,
      createdAt: date,
      fixedDay: fixedDay,
    );
  }

  test('과거 단건 카드대금은 예정 지출로 재생성하지 않는다', () {
    final result = buildWalletKeeperUpcomingFixedExpenses(
      [expense(id: 'old-card-bill', date: DateTime(2026, 7, 12))],
      now: DateTime(2026, 8, 4, 16),
      startOfToday: DateTime(2026, 8, 4),
    );

    expect(result, isEmpty);
  });

  test('반복 패턴이 있어도 고정으로 명시하지 않은 내역은 제외한다', () {
    final result = buildWalletKeeperUpcomingFixedExpenses(
      [
        expense(id: 'june', date: DateTime(2026, 6, 12)),
        expense(id: 'july', date: DateTime(2026, 7, 12)),
      ],
      now: DateTime(2026, 8, 4, 16),
      startOfToday: DateTime(2026, 8, 4),
    );

    expect(result, isEmpty);
  });

  test('명시적 고정 지출만 이번 달 날짜로 계산한다', () {
    final result = buildWalletKeeperUpcomingFixedExpenses(
      [
        expense(
          id: 'fixed-card-bill',
          date: DateTime(2026, 7, 12, 9, 30),
          fixedDay: 12,
        ),
      ],
      now: DateTime(2026, 8, 4, 16),
      startOfToday: DateTime(2026, 8, 4),
    );

    expect(result, hasLength(1));
    expect(result.single.date, DateTime(2026, 8, 12, 9, 30));
    expect(result.single.amount, 965257);
  });

  test('이번 달 납부일이 지났으면 다음 달 일정을 보여준다', () {
    final result = buildWalletKeeperUpcomingFixedExpenses(
      [
        expense(
          id: 'fixed-card-bill',
          date: DateTime(2026, 7, 12),
          fixedDay: 12,
        ),
      ],
      now: DateTime(2026, 8, 20, 16),
      startOfToday: DateTime(2026, 8, 20),
    );

    expect(result.single.date, DateTime(2026, 9, 12));
  });

  testWidgets('예정 내역을 탭하면 수정 콜백으로 연결한다', (tester) async {
    await initializeDateFormatting('ko_KR');
    final now = DateTime.now();
    final entry = expense(
      id: 'editable-fixed-expense',
      date: now,
      fixedDay: now.day,
      title: '수정할 고정비',
    );
    LedgerEntry? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: AssetUpcomingExpensesPage(
          entries: [entry],
          onBack: () {},
          onEditEntry: (value) => selected = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('수정할 고정비').last);
    await tester.pump();

    expect(selected?.id, 'editable-fixed-expense');
  });

  testWidgets('자산 탭 다가오는 지출 미리보기도 수정으로 연결한다', (tester) async {
    await initializeDateFormatting('ko_KR');
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final entry = expense(
      id: 'preview-fixed-expense',
      date: now,
      fixedDay: now.day,
      title: '미리보기 고정비',
    );
    LedgerEntry? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: AssetPage(
          entries: [entry],
          assets: const [],
          session: null,
          onAddAsset: () {},
          onEditAsset: (_) {},
          onConnectUnlinkedEntries: () {},
          onEditUpcomingExpense: (value) => selected = value,
          onOpenUpcomingExpenses: () {},
          onOpenAllAssetHistory: () {},
          onOpenAssetHistory: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final previewEntry = find.text('미리보기 고정비').last;
    await tester.ensureVisible(previewEntry);
    await tester.tap(previewEntry);
    await tester.pump();

    expect(selected?.id, 'preview-fixed-expense');
  });
}
