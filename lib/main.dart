import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _storageKey = 'wallet_keeper_entries_v1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFF5F7FB),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const WalletKeeperApp());
}

class WalletKeeperApp extends StatelessWidget {
  const WalletKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wallet Keeper',
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('ja'),
        Locale('zh', 'Hans'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        final code = locale?.languageCode.toLowerCase();
        if (code == 'ko') return const Locale('ko');
        if (code == 'ja') return const Locale('ja');
        if (code == 'zh') return const Locale('zh', 'Hans');
        if (code == 'en') return const Locale('en');
        return const Locale('en');
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6BFF),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFFF5F7FB),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          titleTextStyle: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE1E7F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF2F6BFF), width: 1.4),
          ),
        ),
      ),
      home: const LedgerHomePage(),
    );
  }
}

class LedgerHomePage extends StatefulWidget {
  const LedgerHomePage({super.key});

  @override
  State<LedgerHomePage> createState() => _LedgerHomePageState();
}

class _LedgerHomePageState extends State<LedgerHomePage> {
  final LedgerRepository _repository = LedgerRepository();
  List<LedgerEntry> _entries = const [];
  int _selectedIndex = 0;
  int _returnIndex = 0;
  LedgerEntry? _editingEntry;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await _repository.load();
    if (!mounted) return;
    setState(() => _entries = loaded);
  }

  Future<void> _saveEntry(LedgerEntry entry) async {
    final next = [..._entries];
    final index = next.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      next[index] = entry;
    } else {
      next.add(entry);
    }
    next.sort((a, b) => b.date.compareTo(a.date));
    await _repository.save(next);
    if (!mounted) return;
    setState(() {
      _entries = next;
      _selectedIndex = 1;
      _editingEntry = null;
    });
    await showAppToast(
      tr(context, ko: '내역을 저장했습니다.', en: 'Saved.', ja: '保存しました。', zh: '已保存。'),
    );
  }

  Future<void> _deleteEntry(LedgerEntry entry) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              tr(
                context,
                ko: '내역 삭제',
                en: 'Delete entry',
                ja: '明細を削除',
                zh: '删除记录',
              ),
            ),
            content: Text(
              tr(
                context,
                ko: '이 내역을 삭제할까요?',
                en: 'Delete this entry?',
                ja: 'この明細を削除しますか？',
                zh: '要删除这条记录吗？',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  tr(context, ko: '취소', en: 'Cancel', ja: 'キャンセル', zh: '取消'),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  tr(context, ko: '삭제', en: 'Delete', ja: '削除', zh: '删除'),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final next = _entries.where((item) => item.id != entry.id).toList();
    await _repository.save(next);
    if (!mounted) return;
    setState(() => _entries = next);
    await showAppToast(
      tr(context, ko: '삭제했습니다.', en: 'Deleted.', ja: '削除しました。', zh: '已删除。'),
    );
  }

  void _openComposer({LedgerEntry? existing}) {
    setState(() {
      _returnIndex = _selectedIndex == 4 ? 0 : _selectedIndex;
      _editingEntry = existing;
      _selectedIndex = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = LedgerSummary.fromEntries(_entries);
    final pages = [
      OverviewPage(summary: summary, entries: _entries, onEdit: _openComposer),
      EntryListPage(
        entries: _entries,
        onEdit: _openComposer,
        onDelete: _deleteEntry,
      ),
      CalendarPage(entries: _entries, onEdit: _openComposer),
      InsightPage(summary: summary),
      EntryEditorPage(
        existing: _editingEntry,
        onCancel: () => setState(() {
          _editingEntry = null;
          _selectedIndex = _returnIndex;
        }),
        onSave: _saveEntry,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle(context, _selectedIndex))),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            const _BackgroundGlow(),
            IndexedStack(index: _selectedIndex, children: pages),
            Align(
              alignment: Alignment.bottomCenter,
              child: WalletKeeperBottomBar(
                selectedIndex: _selectedIndex,
                onAdd: () => _openComposer(),
                onSelected: (index) => setState(() => _selectedIndex = index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pageTitle(BuildContext context, int index) {
    switch (index) {
      case 0:
        return tr(
          context,
          ko: '머니케어',
          en: 'Money Care',
          ja: 'Money Care',
          zh: 'Money Care',
        );
      case 1:
        return tr(context, ko: '내역', en: 'Entries', ja: '明細', zh: '明细');
      case 2:
        return tr(context, ko: '달력', en: 'Calendar', ja: 'カレンダー', zh: '日历');
      case 3:
        return tr(context, ko: '리포트', en: 'Reports', ja: 'レポート', zh: '报告');
      default:
        return tr(
          context,
          ko: '내역 추가',
          en: 'Add Entry',
          ja: '明細追加',
          zh: '添加记录',
        );
    }
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({
    super.key,
    required this.summary,
    required this.entries,
    required this.onEdit,
  });

  final LedgerSummary summary;
  final List<LedgerEntry> entries;
  final void Function({LedgerEntry? existing}) onEdit;

  @override
  Widget build(BuildContext context) {
    final latest = entries.take(4).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 150),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF183B56), Color(0xFF2F6BFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(
                  context,
                  ko: '지출과 수입을 가볍게 관리하세요',
                  en: 'Keep your wallet under control simply',
                  ja: '支出と収入をシンプルに管理',
                  zh: '轻松管理收支',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr(
                  context,
                  ko: '지갑지켜는 빠른 가계부 기록과 월별 합계, 카테고리 통계를 쉽게 확인하는 생활형 예산 앱입니다.',
                  en: 'Wallet Keeper focuses on fast entries, monthly totals, and category insights for everyday budgeting.',
                  ja: 'すばやい記録、月別合計、カテゴリ分析に集中した家計簿アプリです。',
                  zh: '专注于快速记账、月度汇总和分类统计的生活记账应用。',
                ),
                style: const TextStyle(color: Color(0xDDEAF2FF), height: 1.5),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroStat(
                    label: tr(
                      context,
                      ko: '이번 달 수입',
                      en: 'Income',
                      ja: '収入',
                      zh: '收入',
                    ),
                    value: formatCurrency(summary.monthIncome),
                  ),
                  _HeroStat(
                    label: tr(
                      context,
                      ko: '이번 달 지출',
                      en: 'Expense',
                      ja: '支出',
                      zh: '支出',
                    ),
                    value: formatCurrency(summary.monthExpense),
                  ),
                  _HeroStat(
                    label: tr(
                      context,
                      ko: '잔액',
                      en: 'Balance',
                      ja: '残高',
                      zh: '结余',
                    ),
                    value: formatCurrency(summary.balance),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: tr(
                  context,
                  ko: '고정지출',
                  en: 'Fixed',
                  ja: '固定支出',
                  zh: '固定支出',
                ),
                value: formatCurrency(summary.fixedExpense),
                tint: const Color(0xFFFFF7ED),
                accent: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: tr(
                  context,
                  ko: '저축/이체',
                  en: 'Transfer',
                  ja: '振替',
                  zh: '转账',
                ),
                value: formatCurrency(summary.transferAmount),
                tint: const Color(0xFFF0FDF4),
                accent: const Color(0xFF15803D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: tr(
            context,
            ko: '최근 내역',
            en: 'Recent entries',
            ja: '最近の明細',
            zh: '最近记录',
          ),
          subtitle: tr(
            context,
            ko: '최근 기록한 항목을 다시 열어 수정할 수 있습니다.',
            en: 'Open recent entries and edit them quickly.',
            ja: '最近の明細をすぐ開いて編集できます。',
            zh: '可快速打开并修改最近记录。',
          ),
          child: latest.isEmpty
              ? _EmptyBlock(
                  message: tr(
                    context,
                    ko: '아직 기록이 없습니다. 중앙 추가 버튼으로 첫 내역을 입력해보세요.',
                    en: 'No entries yet. Use the center add button to record your first item.',
                    ja: 'まだ記録がありません。中央の追加ボタンから始めてください。',
                    zh: '还没有记录，请用中间的添加按钮开始。',
                  ),
                )
              : Column(
                  children: latest
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _EntryTile(
                            entry: entry,
                            onTap: () => onEdit(existing: entry),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class EntryListPage extends StatefulWidget {
  const EntryListPage({
    super.key,
    required this.entries,
    required this.onEdit,
    required this.onDelete,
  });

  final List<LedgerEntry> entries;
  final void Function({LedgerEntry? existing}) onEdit;
  final Future<void> Function(LedgerEntry entry) onDelete;

  @override
  State<EntryListPage> createState() => _EntryListPageState();
}

class _EntryListPageState extends State<EntryListPage> {
  EntryType? _filter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.entries.where((entry) {
      final matchesType = _filter == null || entry.type == _filter;
      final q = _query.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          entry.title.toLowerCase().contains(q) ||
          entry.category.toLowerCase().contains(q) ||
          entry.note.toLowerCase().contains(q);
      return matchesType && matchesQuery;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: tr(
                    context,
                    ko: '제목, 카테고리, 메모 검색',
                    en: 'Search title, category, note',
                    ja: 'タイトル・カテゴリ・メモ検索',
                    zh: '搜索标题、分类、备注',
                  ),
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: tr(
                        context,
                        ko: '전체',
                        en: 'All',
                        ja: 'すべて',
                        zh: '全部',
                      ),
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 8),
                    ...EntryType.values.map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: type.label(context),
                          selected: _filter == type,
                          onTap: () => setState(() => _filter = type),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyBlock(
                  message: tr(
                    context,
                    ko: '조건에 맞는 내역이 없습니다.',
                    en: 'No matching entries.',
                    ja: '条件に合う明細がありません。',
                    zh: '没有符合条件的记录。',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 150),
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => widget.onEdit(existing: entry),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        widget.onEdit(existing: entry);
                                      } else if (value == 'delete') {
                                        widget.onDelete(entry);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text(
                                          tr(
                                            context,
                                            ko: '수정',
                                            en: 'Edit',
                                            ja: '編集',
                                            zh: '编辑',
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          tr(
                                            context,
                                            ko: '삭제',
                                            en: 'Delete',
                                            ja: '削除',
                                            zh: '删除',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _Pill(
                                    text: entry.type.label(context),
                                    bg: entry.type.color.withValues(
                                      alpha: 0.14,
                                    ),
                                    fg: entry.type.color,
                                  ),
                                  _Pill(
                                    text: entry.category,
                                    bg: const Color(0xFFEFF4FF),
                                    fg: const Color(0xFF2F6BFF),
                                  ),
                                  _Pill(
                                    text: formatDate(entry.date),
                                    bg: const Color(0xFFF3F4F6),
                                    fg: const Color(0xFF4B5563),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                formatCurrency(entry.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  color: entry.type.color,
                                ),
                              ),
                              if (entry.note.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  entry.note,
                                  style: const TextStyle(
                                    color: Color(0xFF667085),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemCount: filtered.length,
                ),
        ),
      ],
    );
  }
}

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key, required this.entries, required this.onEdit});

  final List<LedgerEntry> entries;
  final void Function({LedgerEntry? existing}) onEdit;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<LedgerEntry>>{};
    for (final entry in entries) {
      final key = DateFormat('yyyy-MM-dd').format(entry.date);
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return keys.isEmpty
        ? _EmptyBlock(
            message: tr(
              context,
              ko: '표시할 일정이 없습니다.',
              en: 'No dated entries yet.',
              ja: '表示する明細がありません。',
              zh: '暂无可显示的记录。',
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 150),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final dayEntries = grouped[key]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _SectionCard(
                  title: key,
                  subtitle: tr(
                    context,
                    ko: '${dayEntries.length}건 기록',
                    en: '${dayEntries.length} entries',
                    ja: '${dayEntries.length}件',
                    zh: '${dayEntries.length}条记录',
                  ),
                  child: Column(
                    children: dayEntries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _EntryTile(
                              entry: entry,
                              onTap: () => onEdit(existing: entry),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          );
  }
}

class InsightPage extends StatelessWidget {
  const InsightPage({super.key, required this.summary});

  final LedgerSummary summary;

  @override
  Widget build(BuildContext context) {
    final topCategories = summary.topCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 150),
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: tr(
                  context,
                  ko: '이번 달 지출',
                  en: 'Expense',
                  ja: '支出',
                  zh: '支出',
                ),
                value: formatCurrency(summary.monthExpense),
                tint: const Color(0xFFFFF7ED),
                accent: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: tr(
                  context,
                  ko: '이번 달 수입',
                  en: 'Income',
                  ja: '収入',
                  zh: '收入',
                ),
                value: formatCurrency(summary.monthIncome),
                tint: const Color(0xFFF0FDF4),
                accent: const Color(0xFF15803D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: tr(
            context,
            ko: '카테고리 지출 상위',
            en: 'Top spending categories',
            ja: '支出カテゴリ上位',
            zh: '支出分类排行',
          ),
          subtitle: tr(
            context,
            ko: '이번 달 기준입니다.',
            en: 'Based on this month.',
            ja: '今月 기준です。',
            zh: '基于本月。',
          ),
          child: topCategories.isEmpty
              ? _EmptyBlock(
                  message: tr(
                    context,
                    ko: '아직 지출 데이터가 없습니다.',
                    en: 'No expense data yet.',
                    ja: '支出データがまだありません。',
                    zh: '暂无支出数据。',
                  ),
                )
              : Column(
                  children: topCategories.take(5).map((entry) {
                    final max = topCategories.first.value;
                    final ratio = max == 0 ? 0.0 : entry.value / max;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                formatCurrency(entry.value),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 10,
                              backgroundColor: const Color(0xFFE6ECF5),
                              color: const Color(0xFF2F6BFF),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class EntryEditorPage extends StatefulWidget {
  const EntryEditorPage({
    super.key,
    this.existing,
    required this.onSave,
    required this.onCancel,
  });

  final LedgerEntry? existing;
  final Future<void> Function(LedgerEntry entry) onSave;
  final VoidCallback onCancel;

  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _noteController;
  late EntryType _type;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _amountController = TextEditingController(
      text: existing?.amount.toStringAsFixed(0) ?? '',
    );
    _categoryController = TextEditingController(text: existing?.category ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
    _type = existing?.type ?? EntryType.expense;
    _date = existing?.date ?? DateTime.now();
  }

  @override
  void didUpdateWidget(covariant EntryEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.existing?.id != widget.existing?.id) {
      final existing = widget.existing;
      _titleController.text = existing?.title ?? '';
      _amountController.text = existing?.amount.toStringAsFixed(0) ?? '';
      _categoryController.text = existing?.category ?? '';
      _noteController.text = existing?.note ?? '';
      _type = existing?.type ?? EntryType.expense;
      _date = existing?.date ?? DateTime.now();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(
      () => _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();
    final amount = double.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );
    if (title.isEmpty || category.isEmpty || amount == null || amount <= 0) {
      await showAppToast(
        tr(
          context,
          ko: '제목, 카테고리, 금액을 확인해주세요.',
          en: 'Please check title, category, and amount.',
          ja: 'タイトル・カテゴリ・金額を確認してください。',
          zh: '请检查标题、分类和金额。',
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final existing = widget.existing;
    final entry = LedgerEntry(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: category,
      note: _noteController.text.trim(),
      type: _type,
      date: _date,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    await widget.onSave(entry);
    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 150),
      children: [
        _SectionCard(
          title: tr(
            context,
            ko: '기본 정보',
            en: 'Basic Info',
            ja: '基本情報',
            zh: '基本信息',
          ),
          subtitle: tr(
            context,
            ko: '빠르게 입력할 수 있도록 항목을 최소화했습니다.',
            en: 'Kept minimal for quick entry.',
            ja: '素早く記録できるよう最小構成です。',
            zh: '为快速记账做了最小化设计。',
          ),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: tr(
                    context,
                    ko: '제목',
                    en: 'Title',
                    ja: 'タイトル',
                    zh: '标题',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr(
                          context,
                          ko: '금액',
                          en: 'Amount',
                          ja: '金額',
                          zh: '金额',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: tr(
                          context,
                          ko: '카테고리',
                          en: 'Category',
                          ja: 'カテゴリ',
                          zh: '分类',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<EntryType>(
                segments: EntryType.values
                    .map(
                      (type) => ButtonSegment(
                        value: type,
                        label: Text(type.label(context)),
                        icon: Icon(type.icon),
                      ),
                    )
                    .toList(),
                selected: {_type},
                onSelectionChanged: (value) =>
                    setState(() => _type = value.first),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE1E7F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: Color(0xFF2F6BFF),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          formatDate(_date),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: tr(
                    context,
                    ko: '메모',
                    en: 'Note',
                    ja: 'メモ',
                    zh: '备注',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      child: Text(
                        tr(
                          context,
                          ko: '취소',
                          en: 'Cancel',
                          ja: 'キャンセル',
                          zh: '取消',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(
                        _saving
                            ? tr(
                                context,
                                ko: '저장 중',
                                en: 'Saving',
                                ja: '保存中',
                                zh: '保存中',
                              )
                            : tr(
                                context,
                                ko: '저장',
                                en: 'Save',
                                ja: '保存',
                                zh: '保存',
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WalletKeeperBottomBar extends StatelessWidget {
  const WalletKeeperBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.onAdd,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: SizedBox(
          height: 110,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(
                top: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _BottomItem(
                          icon: Icons.home_rounded,
                          label: tr(
                            context,
                            ko: '홈',
                            en: 'Home',
                            ja: 'ホーム',
                            zh: '首页',
                          ),
                          selected: selectedIndex == 0,
                          onTap: () => onSelected(0),
                        ),
                      ),
                      Expanded(
                        child: _BottomItem(
                          icon: Icons.receipt_long_rounded,
                          label: tr(
                            context,
                            ko: '내역',
                            en: 'Entries',
                            ja: '明細',
                            zh: '明细',
                          ),
                          selected: selectedIndex == 1,
                          onTap: () => onSelected(1),
                        ),
                      ),
                      const SizedBox(width: 76),
                      Expanded(
                        child: _BottomItem(
                          icon: Icons.calendar_today_rounded,
                          label: tr(
                            context,
                            ko: '달력',
                            en: 'Calendar',
                            ja: '予定',
                            zh: '日历',
                          ),
                          selected: selectedIndex == 2,
                          onTap: () => onSelected(2),
                        ),
                      ),
                      Expanded(
                        child: _BottomItem(
                          icon: Icons.bar_chart_rounded,
                          label: tr(
                            context,
                            ko: '리포트',
                            en: 'Reports',
                            ja: '分析',
                            zh: '报告',
                          ),
                          selected: selectedIndex == 3,
                          onTap: () => onSelected(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(28),
                  child: Ink(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF183B56),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22183B56),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white),
                        Text(
                          tr(context, ko: '추가', en: 'Add', ja: '追加', zh: '添加'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF2F6BFF)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected
                    ? const Color(0xFF2F6BFF)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x55BFD6FF), Color(0x00BFD6FF)],
              ),
            ),
          ),
        ),
        Positioned(
          right: -40,
          top: 140,
          child: Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x44D9F99D), Color(0x00D9F99D)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF667085), height: 1.45),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.tint,
    required this.accent,
  });

  final String title;
  final String value;
  final Color tint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xDDEAF2FF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onTap});

  final LedgerEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: entry.type.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(entry.type.icon, color: entry.type.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.category} · ${formatDate(entry.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF667085)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatCurrency(entry.amount),
              style: TextStyle(
                color: entry.type.color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF667085), height: 1.5),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : const Color(0xFF344054),
      ),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF2F6BFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide.none,
      ),
    );
  }
}

class LedgerRepository {
  Future<List<LedgerEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return decoded.map(LedgerEntry.fromJson).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> save(List<LedgerEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }
}

class LedgerSummary {
  const LedgerSummary({
    required this.monthIncome,
    required this.monthExpense,
    required this.fixedExpense,
    required this.transferAmount,
    required this.topCategories,
  }) : balance = monthIncome - monthExpense;

  final double monthIncome;
  final double monthExpense;
  final double fixedExpense;
  final double transferAmount;
  final double balance;
  final Map<String, double> topCategories;

  factory LedgerSummary.fromEntries(List<LedgerEntry> entries) {
    final now = DateTime.now();
    double income = 0;
    double expense = 0;
    double fixed = 0;
    double transfer = 0;
    final top = <String, double>{};
    for (final entry in entries) {
      if (entry.date.year != now.year || entry.date.month != now.month) {
        continue;
      }
      if (entry.type == EntryType.income) {
        income += entry.amount;
      } else {
        expense += entry.amount;
        top.update(
          entry.category,
          (value) => value + entry.amount,
          ifAbsent: () => entry.amount,
        );
        if (entry.category.contains('고정') ||
            entry.category.toLowerCase().contains('fixed')) {
          fixed += entry.amount;
        }
      }
      if (entry.type == EntryType.transfer) transfer += entry.amount;
    }
    return LedgerSummary(
      monthIncome: income,
      monthExpense: expense,
      fixedExpense: fixed,
      transferAmount: transfer,
      topCategories: top,
    );
  }
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.note,
    required this.type,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final String note;
  final EntryType type;
  final DateTime date;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'note': note,
    'type': type.name,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: json['category'] as String,
    note: json['note'] as String? ?? '',
    type: EntryType.values.byName(json['type'] as String),
    date: DateTime.parse(json['date'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

enum EntryType {
  expense(Icons.arrow_upward_rounded, Color(0xFFD92D20)),
  income(Icons.arrow_downward_rounded, Color(0xFF16A34A)),
  transfer(Icons.swap_horiz_rounded, Color(0xFF2F6BFF));

  const EntryType(this.icon, this.color);
  final IconData icon;
  final Color color;

  String label(BuildContext context) {
    switch (this) {
      case EntryType.expense:
        return tr(context, ko: '지출', en: 'Expense', ja: '支出', zh: '支出');
      case EntryType.income:
        return tr(context, ko: '수입', en: 'Income', ja: '収入', zh: '收入');
      case EntryType.transfer:
        return tr(context, ko: '이체', en: 'Transfer', ja: '振替', zh: '转账');
    }
  }
}

String tr(
  BuildContext context, {
  required String ko,
  required String en,
  required String ja,
  required String zh,
}) {
  final locale = Localizations.localeOf(context);
  switch (locale.languageCode) {
    case 'ko':
      return ko;
    case 'ja':
      return ja;
    case 'zh':
      return zh;
    default:
      return en;
  }
}

String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'ko_KR',
    symbol: '₩',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

String formatDate(DateTime date) => DateFormat('yyyy.MM.dd').format(date);

Future<void> showAppToast(String message) async {
  await Fluttertoast.cancel();
  await Fluttertoast.showToast(
    msg: message,
    gravity: ToastGravity.BOTTOM,
    toastLength: Toast.LENGTH_SHORT,
  );
}
