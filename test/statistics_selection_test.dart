import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_keeper/main.dart';

void main() {
  final referenceDate = DateTime(2026, 7, 23);

  LedgerEntry entry({
    required String id,
    required EntryType type,
    DateTime? date,
  }) {
    final entryDate = date ?? referenceDate;
    return LedgerEntry(
      id: id,
      title: id,
      amount: 1000,
      category: '테스트',
      note: '',
      attachmentPaths: const [],
      type: type,
      date: entryDate,
      createdAt: entryDate,
    );
  }

  test('현재 월에 수입만 있으면 수입 통계를 기본 선택한다', () {
    expect(
      walletKeeperInitialStatsKind([
        entry(id: 'income', type: EntryType.income),
      ], referenceDate: referenceDate),
      0,
    );
  });

  test('현재 월에 지출만 있으면 지출 통계를 기본 선택한다', () {
    expect(
      walletKeeperInitialStatsKind([
        entry(id: 'expense', type: EntryType.expense),
      ], referenceDate: referenceDate),
      1,
    );
  });

  test('수입과 지출이 모두 있거나 모두 없으면 지출을 기본 선택한다', () {
    expect(
      walletKeeperInitialStatsKind([
        entry(id: 'income', type: EntryType.income),
        entry(id: 'expense', type: EntryType.expense),
      ], referenceDate: referenceDate),
      1,
    );
    expect(
      walletKeeperInitialStatsKind(const [], referenceDate: referenceDate),
      1,
    );
  });

  test('현재 월 밖의 내역은 최초 통계 선택에 사용하지 않는다', () {
    expect(
      walletKeeperInitialStatsKind([
        entry(
          id: 'old-income',
          type: EntryType.income,
          date: DateTime(2026, 6, 30),
        ),
        entry(id: 'expense', type: EntryType.expense),
      ], referenceDate: referenceDate),
      1,
    );
  });
}
