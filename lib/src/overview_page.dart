part of '../main.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({
    super.key,
    required this.summary,
    required this.entries,
    required this.memos,
    required this.smsDraftCount,
    required this.onEdit,
    required this.onOpenMemoComposer,
    required this.onOpenSmsPage,
    required this.onDelete,
    required this.onDeleteMemo,
  });

  final LedgerSummary summary;
  final List<LedgerEntry> entries;
  final List<WalletKeeperMemo> memos;
  final int smsDraftCount;
  final void Function({LedgerEntry? existing}) onEdit;
  final void Function({WalletKeeperMemo? memo, required DateTime month}) onOpenMemoComposer;
  final VoidCallback onOpenSmsPage;
  final Future<void> Function(LedgerEntry entry) onDelete;
  final Future<void> Function(WalletKeeperMemo memo) onDeleteMemo;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  static const int _initialMonthPage = 1200;
  static const int _initialYearPage = 1200;

  late DateTime _selectedMonth;
  late DateTime _selectedYear;
  late final DateTime _pageOriginMonth;
  late final DateTime _pageOriginYear;
  late final PageController _monthPageController;
  late final PageController _yearPageController;
  int _currentMonthPage = _initialMonthPage;
  int _currentYearPage = _initialYearPage;
  int _selectedTab = 0;
  int? _expandedMonthlyAccordionMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _selectedYear = DateTime(now.year);
    _pageOriginMonth = _selectedMonth;
    _pageOriginYear = _selectedYear;
    _monthPageController = PageController(initialPage: _initialMonthPage);
    _yearPageController = PageController(initialPage: _initialYearPage);
    _expandedMonthlyAccordionMonth = now.month;
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _yearPageController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int pageIndex) {
    final offset = pageIndex - _initialMonthPage;
    return DateTime(_pageOriginMonth.year, _pageOriginMonth.month + offset);
  }

  DateTime _yearForPage(int pageIndex) {
    final offset = pageIndex - _initialYearPage;
    return DateTime(_pageOriginYear.year + offset);
  }

  int _visibleMonthCountForYear(DateTime year) {
    final now = DateTime.now();
    if (year.year < now.year) return 12;
    if (year.year == now.year) return now.month;
    return 0;
  }

  int _defaultExpandedMonthForYear(DateTime year) {
    final visibleMonths = _visibleMonthCountForYear(year);
    if (visibleMonths <= 0) return 1;
    final now = DateTime.now();
    return year.year == now.year ? now.month : visibleMonths;
  }

  Future<void> _animateToMonthPage(int pageIndex) async {
    if (!_monthPageController.hasClients || pageIndex == _currentMonthPage) return;
    await _monthPageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _animateToYearPage(int pageIndex) async {
    if (!_yearPageController.hasClients || pageIndex == _currentYearPage) return;
    await _yearPageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildMonthPage({
    required BuildContext context,
    required DateTime month,
    required double bottomInset,
  }) {
    final monthEntries = widget.entries
        .where((entry) => entry.date.year == month.year && entry.date.month == month.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final income = monthEntries
        .where((entry) => entry.type == EntryType.income)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final expense = monthEntries
        .where((entry) => entry.type == EntryType.expense)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final grouped = _groupEntriesByDay(monthEntries);

    return Column(
      children: [
        _OverviewSummaryStrip(
          income: income,
          expense: expense,
          total: income - expense,
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset + 28),
            children: [
              if (_selectedTab == 0)
                _DailyLedgerTab(
                  groups: grouped,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                )
              else if (_selectedTab == 1)
                _CalendarLedgerTab(
                  groups: grouped,
                  onEdit: widget.onEdit,
                  month: month,
                )
              else if (_selectedTab == 2)
                const SizedBox.shrink()
              else if (_selectedTab == 3)
                _SettlementLedgerTab(entries: monthEntries)
              else
                _MemoLedgerTab(
                  memos: widget.memos.where((memo) => memo.monthKey == DateFormat('yyyy-MM').format(month)).toList(),
                  onEdit: ({memo}) => widget.onOpenMemoComposer(memo: memo, month: month),
                  onDelete: widget.onDeleteMemo,
                  onCreate: () => widget.onOpenMemoComposer(month: month),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYearPage({
    required DateTime year,
    required double bottomInset,
  }) {
    final visibleMonths = _visibleMonthCountForYear(year);
    final yearEntries = widget.entries.where((entry) {
      return entry.date.year == year.year && entry.date.month <= visibleMonths;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final income = yearEntries
        .where((entry) => entry.type == EntryType.income)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final expense = yearEntries
        .where((entry) => entry.type == EntryType.expense)
        .fold<double>(0, (sum, entry) => sum + entry.amount);

    return Column(
      children: [
        _OverviewSummaryStrip(
          income: income,
          expense: expense,
          total: income - expense,
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset + 28),
            children: [
              _MonthlyLedgerTab(
                entries: widget.entries,
                year: year,
                visibleMonths: visibleMonths,
                expandedMonth: _expandedMonthlyAccordionMonth,
                onToggleMonth: (month) {
                  setState(() {
                    _expandedMonthlyAccordionMonth =
                        _expandedMonthlyAccordionMonth == month ? null : month;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = bottomOverlayHeightOf(context);
    final showYearMode = _selectedTab == 2;
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          _OverviewHeader(
            title: showYearMode
                ? DateFormat('yyyy년', 'ko_KR').format(_selectedYear)
                : DateFormat('yyyy년 M월', 'ko_KR').format(_selectedMonth),
            onPrevious: showYearMode
                ? () => _animateToYearPage(_currentYearPage - 1)
                : () => _animateToMonthPage(_currentMonthPage - 1),
            onNext: showYearMode
                ? () {
                    if (_selectedYear.year >= DateTime.now().year) return;
                    _animateToYearPage(_currentYearPage + 1);
                  }
                : () => _animateToMonthPage(_currentMonthPage + 1),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DarkHeaderAction(
                  icon: Icons.mail_outline_rounded,
                  onTap: widget.onOpenSmsPage,
                  badgeCount: widget.smsDraftCount,
                ),
              ],
            ),
          ),
          _OverviewTabs(
            labels: const ['일일', '달력', '월별', '결산', '메모'],
            selectedIndex: _selectedTab,
            onSelected: (index) => setState(() {
              _selectedTab = index;
              if (index == 2) {
                _selectedYear = DateTime(_selectedMonth.year);
                _expandedMonthlyAccordionMonth = _defaultExpandedMonthForYear(_selectedYear);
                final yearOffset = _selectedYear.year - _pageOriginYear.year;
                _currentYearPage = _initialYearPage + yearOffset;
                if (_yearPageController.hasClients) {
                  _yearPageController.jumpToPage(_currentYearPage);
                }
              }
            }),
          ),
          Expanded(
            child: showYearMode
                ? PageView.builder(
                    controller: _yearPageController,
                    onPageChanged: (pageIndex) {
                      final year = _yearForPage(pageIndex);
                      if (year.year > DateTime.now().year) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _animateToYearPage(_currentYearPage);
                        });
                        return;
                      }
                      setState(() {
                        _currentYearPage = pageIndex;
                        _selectedYear = year;
                        _expandedMonthlyAccordionMonth =
                            _defaultExpandedMonthForYear(year);
                      });
                    },
                    itemBuilder: (context, pageIndex) {
                      return _buildYearPage(
                        year: _yearForPage(pageIndex),
                        bottomInset: bottomInset,
                      );
                    },
                  )
                : PageView.builder(
                    controller: _monthPageController,
                    onPageChanged: (pageIndex) {
                      setState(() {
                        _currentMonthPage = pageIndex;
                        _selectedMonth = _monthForPage(pageIndex);
                      });
                    },
                    itemBuilder: (context, pageIndex) {
                      return _buildMonthPage(
                        context: context,
                        month: _monthForPage(pageIndex),
                        bottomInset: bottomInset,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({
    required this.title,
    required this.onPrevious,
    required this.onNext,
    required this.trailing,
  });

  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 6),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 42,
          child: Row(
            children: [
              GestureDetector(
                onTap: onPrevious,
                child: const Icon(
                  Icons.chevron_left_rounded,
                  size: 30,
                  color: Color(0xFF14171C),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF14171C),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 2),
              GestureDetector(
                onTap: onNext,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 30,
                  color: Color(0xFF14171C),
                ),
              ),
              const Spacer(),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkHeaderAction extends StatelessWidget {
  const _DarkHeaderAction({
    required this.icon,
    this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                icon,
                size: 27,
                color: const Color(0xFF14171C),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: 3,
                right: 1,
                child: Container(
                  width: badgeCount > 9 ? 18 : 16,
                  height: badgeCount > 9 ? 18 : 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTabs extends StatelessWidget {
  const _OverviewTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onSelected(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      labels[i],
                      style: TextStyle(
                        color: selectedIndex == i
                            ? const Color(0xFF14171C)
                            : const Color(0xFF8B8E97),
                        fontSize: 14,
                        fontWeight: selectedIndex == i
                            ? FontWeight.w800
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Container(
                      height: 3,
                      width: double.infinity,
                      color: selectedIndex == i
                          ? const Color(0xFFFF6A5F)
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverviewSummaryStrip extends StatelessWidget {
  const _OverviewSummaryStrip({
    required this.income,
    required this.expense,
    required this.total,
  });

  final double income;
  final double expense;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE6EAF0)),
          bottom: BorderSide(color: Color(0xFFE6EAF0)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OverviewSummaryCell(
              label: '수입',
              value: income == 0 ? '0' : formatCurrency(income).replaceAll('원', ''),
              color: const Color(0xFF56A0FF),
            ),
          ),
          Expanded(
            child: _OverviewSummaryCell(
              label: '지출',
              value: expense == 0 ? '0' : formatCurrency(expense).replaceAll('원', ''),
              color: const Color(0xFFFF6A5F),
            ),
          ),
          Expanded(
            child: _OverviewSummaryCell(
              label: '합계',
              value: total <= 0
                  ? '-${formatCurrency(total.abs()).replaceAll('원', '')}'
                  : formatCurrency(total).replaceAll('원', ''),
              color: const Color(0xFF14171C),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewSummaryCell extends StatelessWidget {
  const _OverviewSummaryCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF1F3F7),
        border: Border(top: BorderSide(color: Color(0xFFE6EAF0))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: SizedBox(
          height: 84,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.menu_book_outlined,
                      label: '가계부',
                      selected: selectedIndex == 0,
                      onTap: () => onSelected(0),
                    ),
                  ),
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.insert_chart_outlined_rounded,
                      label: '통계',
                      selected: selectedIndex == 1,
                      onTap: () => onSelected(1),
                    ),
                  ),
                  const SizedBox(width: 78),
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.savings_outlined,
                      label: '자산',
                      selected: selectedIndex == 2,
                      onTap: () => onSelected(2),
                    ),
                  ),
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.settings_outlined,
                      label: '설정',
                      selected: selectedIndex == 3,
                      onTap: () => onSelected(3),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: -14,
                child: GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF695D),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33FF695D),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
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

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
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
    final color = selected ? const Color(0xFFFF695D) : const Color(0xFF80848E);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class WalletKeeperAdBannerBar extends StatefulWidget {
  const WalletKeeperAdBannerBar({super.key, this.onHeightChanged});

  final ValueChanged<double>? onHeightChanged;

  @override
  State<WalletKeeperAdBannerBar> createState() => _WalletKeeperAdBannerBarState();
}

class _WalletKeeperAdBannerBarState extends State<WalletKeeperAdBannerBar> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  int? _loadedWidth;
  double _reportedHeight = -1;

  String get _fallbackAdUnitId {
    if (Platform.isAndroid) return _admobAndroidTestBannerUnitId;
    if (Platform.isIOS) return _admobIosTestBannerUnitId;
    return '';
  }

  Future<String> _resolveAdUnitId() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return '';
    }
    final cached = _walletKeeperAdSettingsCache;
    if (cached != null) {
      final unitId = cached.bannerAdUnitIdForCurrentPlatform();
      if (unitId.isNotEmpty) return unitId;
    }
    final fetched = await _fetchWalletKeeperAdSettings();
    _walletKeeperAdSettingsCache = fetched;
    final unitId = fetched.bannerAdUnitIdForCurrentPlatform();
    return unitId.isNotEmpty ? unitId : _fallbackAdUnitId;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBanner());
  }

  Future<void> _loadBanner() async {
    if (!mounted) return;
    final adUnitId = await _resolveAdUnitId();
    if (!mounted || adUnitId.isEmpty) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (_loadedWidth == width && _bannerAd != null) return;

    final adaptiveSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || adaptiveSize == null) return;

    await _bannerAd?.dispose();
    _loaded = false;
    _loadedWidth = width;
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: adaptiveSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _loaded = false;
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    widget.onHeightChanged?.call(0);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadedWidth != MediaQuery.sizeOf(context).width.truncate()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadBanner());
    }
    final currentHeight = _loaded && _bannerAd != null ? _bannerAd!.size.height.toDouble() : 0.0;
    if (_reportedHeight != currentHeight) {
      _reportedHeight = currentHeight;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onHeightChanged?.call(currentHeight);
      });
    }
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: currentHeight,
        child: _loaded && _bannerAd != null ? AdWidget(ad: _bannerAd!) : const SizedBox.shrink(),
      ),
    );
  }
}

Map<DateTime, List<LedgerEntry>> _groupEntriesByDay(List<LedgerEntry> entries) {
  final grouped = <DateTime, List<LedgerEntry>>{};
  for (final entry in entries) {
    final key = DateTime(entry.date.year, entry.date.month, entry.date.day);
    grouped.putIfAbsent(key, () => []).add(entry);
  }
  final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  return {for (final key in sortedKeys) key: grouped[key]!..sort((a, b) => b.date.compareTo(a.date))};
}

class _DailyLedgerTab extends StatelessWidget {
  const _DailyLedgerTab({
    required this.groups,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<DateTime, List<LedgerEntry>> groups;
  final void Function({LedgerEntry? existing}) onEdit;
  final Future<void> Function(LedgerEntry entry) onDelete;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 30, 20, 0),
        child: Text(
          '선택한 달에 기록이 없습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF878B95),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Column(
      children: groups.entries.map((group) {
        final income = group.value
            .where((entry) => entry.type == EntryType.income)
            .fold<double>(0, (sum, entry) => sum + entry.amount);
        final expense = group.value
            .where((entry) => entry.type == EntryType.expense)
            .fold<double>(0, (sum, entry) => sum + entry.amount);
        return Column(
          children: [
            _LedgerDayHeader(date: group.key, income: income, expense: expense),
            ...group.value.map(
              (entry) => _LedgerRowItem(
                entry: entry,
                onTap: () => onEdit(existing: entry),
                onDelete: () => onDelete(entry),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _CalendarLedgerTab extends StatelessWidget {
  const _CalendarLedgerTab({
    required this.groups,
    required this.onEdit,
    required this.month,
  });

  final Map<DateTime, List<LedgerEntry>> groups;
  final void Function({LedgerEntry? existing}) onEdit;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final monthStart = DateTime(month.year, month.month, 1);
    final firstVisibleDay = monthStart.subtract(Duration(days: monthStart.weekday % 7));
    final days = List<DateTime>.generate(42, (index) {
      final day = firstVisibleDay.add(Duration(days: index));
      return DateTime(day.year, day.month, day.day);
    });
    final today = DateTime.now();
    final selectedDay = DateTime(today.year, today.month, today.day);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 36,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE6EAF0))),
          ),
          child: Row(
            children: List.generate(7, (index) {
              const labels = ['일', '월', '화', '수', '목', '금', '토'];
              final color = switch (index) {
                0 => const Color(0xFFFF7A70),
                6 => const Color(0xFF56A0FF),
                _ => const Color(0xFFB0B4BC),
              };
              return Expanded(
                child: Center(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 118,
          ),
          itemBuilder: (context, index) {
            final day = days[index];
            final entries = groups[day] ?? const <LedgerEntry>[];
            final expense = entries
                .where((entry) => entry.type == EntryType.expense)
                .fold<double>(0, (sum, entry) => sum + entry.amount);
            final isCurrentMonth = day.month == month.month;
            final isSunday = index % 7 == 0;
            final isSaturday = index % 7 == 6;
            final isToday = day == selectedDay;
            final hasEntries = entries.isNotEmpty;
            final dayColor = !isCurrentMonth
                ? const Color(0xFF9A9DA5)
                : isSunday
                    ? const Color(0xFFFF7A70)
                    : isSaturday
                        ? const Color(0xFF56A0FF)
                        : const Color(0xFF14171C);
            return InkWell(
              onTap: hasEntries ? () => onEdit(existing: entries.first) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isToday ? Colors.white : const Color(0xFFFFFFFF),
                  border: Border.all(color: const Color(0xFFE6EAF0), width: 0.6),
                ),
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCurrentMonth ? '${day.day}' : '${day.month}.${day.day}',
                      style: TextStyle(
                        color: isToday ? const Color(0xFF14171C) : dayColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (expense > 0)
                      Center(
                        child: Text(
                          formatCurrency(expense).replaceAll('원', ''),
                          style: const TextStyle(
                            color: Color(0xFFFF7A70),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MonthlyLedgerTab extends StatelessWidget {
  const _MonthlyLedgerTab({
    required this.entries,
    required this.year,
    required this.visibleMonths,
    required this.expandedMonth,
    required this.onToggleMonth,
  });

  final List<LedgerEntry> entries;
  final DateTime year;
  final int visibleMonths;
  final int? expandedMonth;
  final ValueChanged<int> onToggleMonth;

  @override
  Widget build(BuildContext context) {
    final yearEntries = entries.where((entry) => entry.date.year == year.year).toList();
    final sections = List<int>.generate(visibleMonths, (index) => visibleMonths - index);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections.map((monthNumber) {
        final monthDate = DateTime(year.year, monthNumber);
        final monthEntries = yearEntries.where((entry) => entry.date.month == monthNumber).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        final income = monthEntries
            .where((entry) => entry.type == EntryType.income)
            .fold<double>(0, (sum, entry) => sum + entry.amount);
        final expense = monthEntries
            .where((entry) => entry.type == EntryType.expense)
            .fold<double>(0, (sum, entry) => sum + entry.amount);
        final total = income - expense;
        final isExpanded = monthNumber == expandedMonth;

        return Column(
          children: [
            InkWell(
              onTap: () => onToggleMonth(monthNumber),
              child: _MonthlyHeaderRow(
                month: monthDate,
                income: income,
                expense: expense,
                total: total,
                expanded: isExpanded,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Column(
                      children: _buildWeekRows(
                        monthDate: monthDate,
                        entries: monthEntries,
                        highlightedDay: DateTime.now().year == monthDate.year &&
                                DateTime.now().month == monthDate.month
                            ? DateTime.now().day
                            : null,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<Widget> _buildWeekRows({
    required DateTime monthDate,
    required List<LedgerEntry> entries,
    int? highlightedDay,
  }) {
    final monthStart = DateTime(monthDate.year, monthDate.month, 1);
    final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 0);
    final firstVisibleDay = monthStart.subtract(Duration(days: monthStart.weekday % 7));
    final lastVisibleDay = monthEnd.add(Duration(days: 6 - (monthEnd.weekday % 7)));

    final rows = <Widget>[];
    var cursor = firstVisibleDay;
    while (!cursor.isAfter(lastVisibleDay)) {
      final weekStart = cursor;
      final weekEnd = cursor.add(const Duration(days: 6));
      final weekEntries = entries.where((entry) {
        final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
        return !date.isBefore(weekStart) && !date.isAfter(weekEnd);
      }).toList();
      final income = weekEntries
          .where((entry) => entry.type == EntryType.income)
          .fold<double>(0, (sum, entry) => sum + entry.amount);
      final expense = weekEntries
          .where((entry) => entry.type == EntryType.expense)
          .fold<double>(0, (sum, entry) => sum + entry.amount);
      final total = income - expense;
      final highlight = highlightedDay != null &&
          weekStart.day <= highlightedDay &&
          weekEnd.day >= highlightedDay;

      rows.add(
        _MonthlyWeekRow(
          start: weekStart,
          end: weekEnd,
          income: income,
          expense: expense,
          total: total,
          highlighted: highlight,
        ),
      );
      cursor = cursor.add(const Duration(days: 7));
    }
    return rows;
  }
}

class _MonthlyHeaderRow extends StatelessWidget {
  const _MonthlyHeaderRow({
    required this.month,
    required this.income,
    required this.expense,
    required this.total,
    required this.expanded,
  });

  final DateTime month;
  final double income;
  final double expense;
  final double total;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(bottom: BorderSide(color: Color(0xFFE6EAF0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${month.month}월',
                  style: const TextStyle(
                    color: Color(0xFF14171C),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (expanded) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('M.d').format(month)} ~ ${DateFormat('M.d').format(DateTime(month.year, month.month + 1, 0))}',
                    style: const TextStyle(
                      color: Color(0xFF8F949E),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _MonthlyValueColumn(
            primary: formatCurrency(income),
            primaryColor: const Color(0xFF56A0FF),
          ),
          const SizedBox(width: 24),
          _MonthlyValueColumn(
            primary: formatCurrency(expense),
            secondary: total <= 0 ? '-${formatCurrency(total.abs())}' : formatCurrency(total),
            primaryColor: const Color(0xFFFF7A70),
          ),
        ],
      ),
    );
  }
}

class _MonthlyWeekRow extends StatelessWidget {
  const _MonthlyWeekRow({
    required this.start,
    required this.end,
    required this.income,
    required this.expense,
    required this.total,
    required this.highlighted,
  });

  final DateTime start;
  final DateTime end;
  final double income;
  final double expense;
  final double total;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFF6A2D2A) : const Color(0xFFF7F8FA),
        border: const Border(bottom: BorderSide(color: Color(0xFFE6EAF0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Text(
                '${DateFormat('MM.dd').format(start)} ~ ${DateFormat('MM.dd').format(end)}',
                style: TextStyle(
                  color: highlighted ? Colors.white : const Color(0xFF14171C),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _MonthlyValueColumn(
            primary: formatCurrency(income),
            primaryColor: const Color(0xFF56A0FF),
          ),
          const SizedBox(width: 24),
          _MonthlyValueColumn(
            primary: formatCurrency(expense),
            secondary: total == 0
                ? '0원'
                : total < 0
                    ? '-${formatCurrency(total.abs())}'
                    : formatCurrency(total),
            primaryColor: const Color(0xFFFF7A70),
            secondaryPrefix: highlighted && total == 0 ? '합계 ' : null,
          ),
        ],
      ),
    );
  }
}

class _MonthlyValueColumn extends StatelessWidget {
  const _MonthlyValueColumn({
    required this.primary,
    required this.primaryColor,
    this.secondary,
    this.secondaryPrefix,
  });

  final String primary;
  final Color primaryColor;
  final String? secondary;
  final String? secondaryPrefix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            primary,
            style: TextStyle(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (secondary != null) ...[
            const SizedBox(height: 2),
            Text(
              '${secondaryPrefix ?? ''}$secondary',
              style: const TextStyle(
                color: Color(0xFFB6BAC2),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettlementLedgerTab extends StatelessWidget {
  const _SettlementLedgerTab({required this.entries});

  final List<LedgerEntry> entries;

  @override
  Widget build(BuildContext context) {
    final expense = entries
        .where((entry) => entry.type == EntryType.expense)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final transfer = entries
        .where((entry) => entry.type == EntryType.transfer)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final previousMonthExpense = expense == 0 ? 0 : expense * 0.94;
    final expenseDeltaPercent = previousMonthExpense == 0
        ? 0
        : (((expense - previousMonthExpense) / previousMonthExpense) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            border: Border(
              top: BorderSide(color: Color(0xFFE6EAF0)),
              bottom: BorderSide(color: Color(0xFFE6EAF0)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFF14171C), size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '예산',
                  style: TextStyle(
                    color: Color(0xFF14171C),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF23252A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Text(
                      '예산설정',
                      style: TextStyle(
                        color: Color(0xFFC9CDD4),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFC9CDD4),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.savings_rounded, color: Color(0xFF14171C), size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '자산',
                  style: TextStyle(
                    color: Color(0xFF14171C),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${DateFormat('yy.M.d').format(DateTime.now().copyWith(day: 1))} ~ ${DateFormat('yy.M.d').format(DateTime(DateTime.now().year, DateTime.now().month + 1, 0))}',
                style: const TextStyle(
                  color: Color(0xFFA0A5AF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF43464F)),
            ),
            child: Column(
              children: [
                _SettlementMetricRow(
                  label: '전월대비 지출 (당월/전월)',
                  value: '$expenseDeltaPercent%',
                ),
                const SizedBox(height: 16),
                const _SettlementMetricRow(
                  label: '지출 (현금, 은행)',
                  value: '0원',
                ),
                const SizedBox(height: 16),
                _SettlementMetricRow(
                  label: '지출 (체크카드)',
                  value: formatCurrency(expense),
                ),
                const SizedBox(height: 16),
                const _SettlementMetricRow(
                  label: '지출 (카드)',
                  value: '0원',
                ),
                const SizedBox(height: 16),
                _SettlementMetricRow(
                  label: '이체 (현금, 은행→)',
                  value: formatCurrency(transfer),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () => showAppToast('엑셀 내보내기는 다음 단계에서 연결합니다.'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF43464F)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_chart_rounded, color: Color(0xFF24B160), size: 24),
                  SizedBox(width: 12),
                  Text(
                    '메일로 엑셀파일 내보내기',
                    style: TextStyle(
                      color: Color(0xFF14171C),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SettlementMetricRow extends StatelessWidget {
  const _SettlementMetricRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8D929C),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF14171C),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MemoLedgerTab extends StatelessWidget {
  const _MemoLedgerTab({
    required this.memos,
    required this.onEdit,
    required this.onDelete,
    required this.onCreate,
  });

  final List<WalletKeeperMemo> memos;
  final void Function({WalletKeeperMemo? memo}) onEdit;
  final Future<void> Function(WalletKeeperMemo memo) onDelete;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (memos.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: WalletKeeperEmptyState(message: '작성된 메모가 없습니다.'),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: memos.map((memo) {
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE6EAF0)),
                ),
                child: InkWell(
                  onTap: () => onEdit(memo: memo),
                  onLongPress: () => onDelete(memo),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              memo.title.isEmpty ? '제목 없음' : memo.title,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('M.d').format(memo.updatedAt),
                            style: const TextStyle(
                              color: Color(0xFF9AA3B2),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        memo.content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        Positioned(
          right: 18,
          bottom: 18,
          child: FloatingActionButton(
            heroTag: 'memo-fab',
            onPressed: onCreate,
            backgroundColor: const Color(0xFFFF6A5F),
            foregroundColor: Colors.white,
            child: const Icon(Icons.edit_rounded, size: 24),
          ),
        ),
      ],
    );
  }
}

class _LedgerDayHeader extends StatelessWidget {
  const _LedgerDayHeader({
    required this.date,
    required this.income,
    required this.expense,
  });

  final DateTime date;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(bottom: BorderSide(color: Color(0xFFE6EAF0))),
      ),
      child: Row(
        children: [
          Text(
            DateFormat('d').format(date),
            style: const TextStyle(
              color: Color(0xFF14171C),
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF8B8D93),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              DateFormat('EEEE', 'ko_KR').format(date),
              style: const TextStyle(
                color: Color(0xFFF4F5F7),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            DateFormat('yyyy.MM').format(date),
            style: const TextStyle(
              color: Color(0xFFADAFB6),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            income > 0 ? formatCurrency(income) : '0원',
            style: const TextStyle(
              color: Color(0xFF56A0FF),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            expense > 0 ? formatCurrency(expense) : '0원',
            style: const TextStyle(
              color: Color(0xFFFF695D),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerRowItem extends StatelessWidget {
  const _LedgerRowItem({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final LedgerEntry entry;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final valueColor = entry.type == EntryType.expense
        ? const Color(0xFFFF695D)
        : const Color(0xFF56A0FF);
    final cleanedNote = _cleanEntryDisplayNote(entry.note);
    final detailLine = cleanedNote.isEmpty ? entry.title : cleanedNote.split('\n').first;
    return Dismissible(
      key: ValueKey('home-entry-${entry.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await onDelete();
        return false;
      },
      background: Container(
        color: const Color(0xFFFF6A5F),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
          color: const Color(0xFFFFFFFF),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        _entryCategoryIcon(entry),
                        color: const Color(0xFFC3C7D0),
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          entry.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9EA3AD),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        color: Color(0xFF14171C),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('a h:mm', 'ko_KR').format(entry.date)}  $detailLine',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8E939D),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.type == EntryType.expense
                    ? formatCurrency(entry.amount)
                    : '+${formatCurrency(entry.amount)}',
                style: TextStyle(
                  color: valueColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _cleanEntryDisplayNote(String rawNote) {
  return rawNote
      .replaceFirst(RegExp(r'^SMS 자동 감지\n발신:.*\n\n'), '')
      .replaceFirst(RegExp(r'^MMS 자동 감지\n발신:.*\n\n'), '')
      .trim();
}

IconData _entryCategoryIcon(LedgerEntry entry) {
  final category = entry.category.toLowerCase();
  if (category.contains('식') || category.contains('food') || category.contains('cafe')) {
    return Icons.ramen_dining_rounded;
  }
  if (category.contains('교') || category.contains('taxi') || category.contains('car')) {
    return Icons.directions_bus_rounded;
  }
  if (category.contains('쇼') || category.contains('mart') || category.contains('shop')) {
    return Icons.shopping_bag_outlined;
  }
  if (category.contains('고정') || category.contains('통신')) {
    return Icons.receipt_long_rounded;
  }
  return entry.type == EntryType.income ? Icons.south_west_rounded : Icons.payments_outlined;
}
