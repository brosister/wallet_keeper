part of '../main.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({
    super.key,
    required this.summary,
    required this.entries,
    required this.budgets,
    required this.smsDraftCount,
    required this.selectedTab,
    required this.onSelectedTabChanged,
    required this.onEdit,
    required this.onOpenBudgetSettings,
    required this.onOpenSmsPage,
    required this.onDelete,
  });

  final LedgerSummary summary;
  final List<LedgerEntry> entries;
  final List<WalletKeeperBudgetSetting> budgets;
  final int smsDraftCount;
  final int selectedTab;
  final ValueChanged<int> onSelectedTabChanged;
  final Future<void> Function({LedgerEntry? existing}) onEdit;
  final Future<void> Function({required DateTime month}) onOpenBudgetSettings;
  final VoidCallback onOpenSmsPage;
  final Future<void> Function(LedgerEntry entry) onDelete;

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
  late final ScrollController _monthTabScrollController;
  late final ScrollController _yearTabScrollController;
  int _currentMonthPage = _initialMonthPage;
  int _currentYearPage = _initialYearPage;
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
    _monthTabScrollController = ScrollController();
    _yearTabScrollController = ScrollController();
    _expandedMonthlyAccordionMonth = now.month;
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _yearPageController.dispose();
    _monthTabScrollController.dispose();
    _yearTabScrollController.dispose();
    super.dispose();
  }

  void _resetTabScroll(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = index == 2 ? _yearTabScrollController : _monthTabScrollController;
      if (controller.hasClients) {
        controller.jumpTo(0);
      }
    });
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

  ({double income, double expense, double total}) _monthSummary(DateTime month) {
    final monthEntries = widget.entries.where((entry) {
      return entry.date.year == month.year && entry.date.month == month.month;
    });
    final income = monthEntries
        .where((entry) => entry.type == EntryType.income)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final expense = monthEntries
        .where((entry) => entry.type == EntryType.expense)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    return (income: income, expense: expense, total: income - expense);
  }

  ({double income, double expense, double total}) _yearSummary(DateTime year) {
    final visibleMonths = _visibleMonthCountForYear(year);
    final yearEntries = widget.entries.where((entry) {
      return entry.date.year == year.year && entry.date.month <= visibleMonths;
    });
    final income = yearEntries
        .where((entry) => entry.type == EntryType.income)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final expense = yearEntries
        .where((entry) => entry.type == EntryType.expense)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    return (income: income, expense: expense, total: income - expense);
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
    final grouped = _groupEntriesByDay(monthEntries);

    return ListView(
      controller: _monthTabScrollController,
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomInset + 28),
      children: [
        if (widget.selectedTab == 0)
          _CalendarLedgerTab(
            groups: grouped,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
            month: month,
          )
        else if (widget.selectedTab == 1)
          _DailyLedgerTab(
            groups: grouped,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
          )
        else if (widget.selectedTab == 2)
          const SizedBox.shrink()
        else
          _SettlementLedgerTab(
            entries: monthEntries,
            budgets: widget.budgets
                .where(
                  (budget) =>
                      budget.monthKey == DateFormat('yyyy-MM').format(month),
                )
                .toList(),
            month: month,
            onOpenSettings: () => widget.onOpenBudgetSettings(month: month),
          ),
      ],
    );
  }

  Widget _buildYearPage({
    required DateTime year,
    required double bottomInset,
  }) {
    final visibleMonths = _visibleMonthCountForYear(year);

    return ListView(
      controller: _yearTabScrollController,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = bottomOverlayHeightOf(context);
    final showYearMode = widget.selectedTab == 2;
    final currentSummary =
        showYearMode ? _yearSummary(_selectedYear) : _monthSummary(_selectedMonth);
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
                labels: const ['달력', '일별', '월별', '예산'],
                selectedIndex: widget.selectedTab,
                onSelected: (index) {
                  if (index == widget.selectedTab) return;
                  setState(() {
                    if (index == 2) {
                      _selectedYear = DateTime(_selectedMonth.year);
                      _expandedMonthlyAccordionMonth =
                          _defaultExpandedMonthForYear(_selectedYear);
                      final yearOffset = _selectedYear.year - _pageOriginYear.year;
                      _currentYearPage = _initialYearPage + yearOffset;
                      if (_yearPageController.hasClients) {
                        _yearPageController.jumpToPage(_currentYearPage);
                      }
                    }
                  });
                  widget.onSelectedTabChanged(index);
                  _resetTabScroll(index);
                },
              ),
            _OverviewSummaryStrip(
              income: currentSummary.income,
              expense: currentSummary.expense,
              total: currentSummary.total,
            ),
            Expanded(
              child: showYearMode
                ? PageView.builder(
                    controller: _yearPageController,
                    itemCount: _initialYearPage + 1,
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
                    physics: const PageScrollPhysics(),
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
                value: income,
                formatter: (value) => value.round() == 0
                    ? '0'
                    : '+${_compactDailyAmount(value)}',
                color: const Color(0xFF56A0FF),
              ),
            ),
            Expanded(
              child: _OverviewSummaryCell(
                label: '지출',
                value: expense,
                formatter: (value) => value.round() == 0
                    ? '0'
                    : '-${_compactDailyAmount(value)}',
                color: const Color(0xFFFF6A5F),
              ),
            ),
            Expanded(
              child: _OverviewSummaryCell(
                label: '남은금액',
                value: total,
                formatter: (value) => value.round() == 0
                    ? '0'
                    : value < 0
                    ? '-${_compactDailyAmount(value.abs())}'
                    : '+${_compactDailyAmount(value)}',
                color: total < 0 ? const Color(0xFFFF6A5F) : const Color(0xFF56A0FF),
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
    required this.formatter,
    required this.color,
  });

  final String label;
  final double value;
  final String Function(double value) formatter;
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
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: value),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, child) {
                return Text(
                  formatter(animatedValue),
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
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
        color: Colors.white,
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
                      icon: Icons.receipt_long_rounded,
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
                      icon: Icons.assessment_outlined,
                      label: '리포트',
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
                top: -8,
                child: GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 70,
                    height: 70,
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
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 34),
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
  final Future<void> Function({LedgerEntry? existing}) onEdit;
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
    final dayGroups = groups.entries.toList();
    return Column(
      children: dayGroups.asMap().entries.map((dayEntry) {
        final index = dayEntry.key;
        final group = dayEntry.value;
        final income = group.value
            .where((entry) => entry.type == EntryType.income)
            .fold<double>(0, (sum, entry) => sum + entry.amount);
        final expense = group.value
            .where((entry) => entry.type == EntryType.expense)
            .fold<double>(0, (sum, entry) => sum + entry.amount);
        final total = income - expense;
        return Column(
          children: [
            _LedgerDayHeader(
              date: group.key,
              income: income,
              expense: expense,
              total: total,
            ),
            ...group.value.map(
              (entry) => _LedgerRowItem(
                entry: entry,
                onTap: () => onEdit(existing: entry),
                onDelete: () => onDelete(entry),
              ),
            ),
            if (index != dayGroups.length - 1)
              Container(
                height: 8,
                color: const Color(0xFFF1F3F6),
              ),
          ],
        );
      }).toList(),
    );
  }
}

class _CalendarLedgerTab extends StatefulWidget {
  const _CalendarLedgerTab({
    required this.groups,
    required this.onEdit,
    required this.onDelete,
    required this.month,
  });

  final Map<DateTime, List<LedgerEntry>> groups;
  final Future<void> Function({LedgerEntry? existing}) onEdit;
  final Future<void> Function(LedgerEntry entry) onDelete;
  final DateTime month;

  @override
  State<_CalendarLedgerTab> createState() => _CalendarLedgerTabState();
}

class _CalendarLedgerTabState extends State<_CalendarLedgerTab> {
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _defaultSelectedDayForMonth(widget.month);
  }

  @override
  void didUpdateWidget(covariant _CalendarLedgerTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month.year == widget.month.year &&
        oldWidget.month.month == widget.month.month) {
      return;
    }
    _selectedDay = _defaultSelectedDayForMonth(widget.month);
  }

  DateTime? _defaultSelectedDayForMonth(DateTime month) {
    final now = DateTime.now();
    if (month.year != now.year || month.month != now.month) {
      return null;
    }
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final month = widget.month;
    final monthStart = DateTime(month.year, month.month, 1);
    final firstVisibleDay = monthStart.subtract(Duration(days: monthStart.weekday % 7));
    final days = List<DateTime>.generate(42, (index) {
      final day = firstVisibleDay.add(Duration(days: index));
      return DateTime(day.year, day.month, day.day);
    });
    final today = DateTime.now();
    final highlightedToday = DateTime(today.year, today.month, today.day);
    final selectedEntries = _selectedDay == null
        ? const <LedgerEntry>[]
        : widget.groups[_selectedDay!] ?? const <LedgerEntry>[];
    final monthEntries = widget.groups.values.expand((items) => items).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 34,
          color: Colors.white,
          child: Row(
            children: List.generate(7, (index) {
              const labels = ['일', '월', '화', '수', '목', '금', '토'];
                final color = switch (index) {
                  0 => const Color(0xFFE27782),
                  6 => const Color(0xFF56A0FF),
                  _ => const Color(0xFF8E909A),
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
        Container(
          color: Colors.white,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 60,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final entries = widget.groups[day] ?? const <LedgerEntry>[];
              final income = entries
                  .where((entry) => entry.type == EntryType.income)
                  .fold<double>(0, (sum, entry) => sum + entry.amount);
                final expense = entries
                    .where((entry) => entry.type == EntryType.expense)
                    .fold<double>(0, (sum, entry) => sum + entry.amount);
                final isCurrentMonth = day.month == month.month;
                final isToday = day == highlightedToday;
                final isSelected = _selectedDay != null && day == _selectedDay;
                final isHoliday = _isKoreanPublicHoliday(day);
                final dayColor = isHoliday
                    ? const Color(0xFFE35A52)
                    : isCurrentMonth
                        ? const Color(0xFF7B7F89)
                        : const Color(0xFFC1C5CD);
                return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                  });
                },
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: Column(
                    children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE76158)
                                : isToday
                                    ? const Color(0xFFF3F4F7)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            '${day.day}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : dayColor,
                              fontSize: 17,
                            height: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (income > 0)
                        SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                                '+${_compactDailyAmount(income)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF56A0FF),
                                  fontSize: 10,
                                  letterSpacing: -0.7,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (expense > 0)
                        Padding(
                          padding: EdgeInsets.only(top: income > 0 ? 1 : 0),
                          child: SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '-${_compactDailyAmount(expense)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFE27782),
                                  fontSize: 10,
                                  letterSpacing: -0.7,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _selectedDay == null
              ? const SizedBox.shrink()
              : _CalendarSelectedDayPanel(
                  key: ValueKey<String>(
                    'calendar-inline-${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}',
                  ),
                  date: _selectedDay!,
                  entries: selectedEntries,
                  monthEntries: monthEntries
                      .where(
                        (entry) =>
                            entry.date.year == month.year &&
                            entry.date.month == month.month,
                      )
                      .toList(),
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                ),
        ),
      ],
    );
  }
}

class _CalendarSelectedDayPanel extends StatelessWidget {
  const _CalendarSelectedDayPanel({
    super.key,
    required this.date,
    required this.entries,
    required this.monthEntries,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime date;
  final List<LedgerEntry> entries;
  final List<LedgerEntry> monthEntries;
  final Future<void> Function({LedgerEntry? existing}) onEdit;
  final Future<void> Function(LedgerEntry entry) onDelete;

  @override
  Widget build(BuildContext context) {
    final phrase = _buildCalendarExpensePhrase(date, entries, monthEntries);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${date.day}일 ${DateFormat('EEEE', 'ko_KR').format(date)}',
                  style: const TextStyle(
                    color: Color(0xFF14171C),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (phrase != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    phrase.label,
                    style: TextStyle(
                      color: phrase.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '선택한 날짜에 기록이 없습니다.',
                  style: TextStyle(
                    color: Color(0xFF98A1AD),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              ...List.generate(entries.length, (index) {
                final entry = entries[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index == entries.length - 1 ? 0 : 14),
                  child: _CalendarSelectedDayRow(
                    entry: entry,
                    onTap: () => onEdit(existing: entry),
                    onDelete: () => onDelete(entry),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _CalendarExpensePhrase {
  const _CalendarExpensePhrase({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
}

_CalendarExpensePhrase? _buildCalendarExpensePhrase(
  DateTime selectedDay,
  List<LedgerEntry> selectedEntries,
  List<LedgerEntry> monthEntries,
) {
  final selectedExpense = selectedEntries
      .where((entry) => entry.type == EntryType.expense)
      .fold<double>(0, (sum, entry) => sum + entry.amount);
  if (selectedExpense <= 0) return null;

  final expenseByDay = <DateTime, double>{};
  for (final entry in monthEntries.where((entry) => entry.type == EntryType.expense)) {
    final key = DateTime(entry.date.year, entry.date.month, entry.date.day);
    expenseByDay.update(key, (value) => value + entry.amount, ifAbsent: () => entry.amount);
  }
  if (expenseByDay.isEmpty) return null;
  final averageExpense =
      expenseByDay.values.fold<double>(0, (sum, value) => sum + value) / expenseByDay.length;
  if (averageExpense <= 0) return null;

  if (selectedExpense >= averageExpense * 1.2) {
    return const _CalendarExpensePhrase(
      label: '평소보다 많이 쓴 날',
      color: Color(0xFFFF695D),
    );
  }
  if (selectedExpense <= averageExpense * 0.8) {
    return const _CalendarExpensePhrase(
      label: '평소보다 덜 쓴 날',
      color: Color(0xFF56A0FF),
    );
  }
  return null;
}

class _CalendarSelectedDayRow extends StatefulWidget {
  const _CalendarSelectedDayRow({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final LedgerEntry entry;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  State<_CalendarSelectedDayRow> createState() => _CalendarSelectedDayRowState();
}

class _CalendarSelectedDayRowState extends State<_CalendarSelectedDayRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final accent = _calendarEntryAccent(entry);
    final icon = _entryCategoryIcon(entry);
    final detailLine = _buildCalendarDetailLine(entry);
    final amountText = entry.type == EntryType.expense
        ? '-${_compactDailyAmount(entry.amount)}원'
        : '+${_compactDailyAmount(entry.amount)}원';
    final valueColor = entry.type == EntryType.expense
        ? const Color(0xFFFF695D)
        : const Color(0xFF56A0FF);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onDelete,
        borderRadius: BorderRadius.circular(18),
        onHighlightChanged: (value) {
          if (_pressed == value) return;
          setState(() => _pressed = value);
        },
        splashColor: const Color(0x12000000),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          decoration: BoxDecoration(
            color: _pressed ? const Color(0xFFF4F6F9) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      amountText,
                      style: TextStyle(
                        color: valueColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detailLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF59606B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _buildCalendarDetailLine(LedgerEntry entry) {
  final cleanedNote = _cleanEntryDisplayNote(entry.note);
  final primary = entry.title.trim();
  final secondary = cleanedNote.split('\n').first.trim();
  if (secondary.isEmpty || secondary == primary) {
    return primary;
  }
  return '$primary | $secondary';
}

Color _calendarEntryAccent(LedgerEntry entry) {
  final category = entry.category.toLowerCase();
  if (category.contains('식') || category.contains('food') || category.contains('cafe')) {
    return const Color(0xFFFFA83D);
  }
  if (category.contains('교') || category.contains('taxi') || category.contains('car')) {
    return const Color(0xFF4B8EFF);
  }
  if (category.contains('쇼') || category.contains('mart') || category.contains('shop')) {
    return const Color(0xFF2FB16D);
  }
  if (entry.type == EntryType.transfer) {
    return const Color(0xFF4B8EFF);
  }
  if (entry.type == EntryType.income) {
    return const Color(0xFF56A0FF);
  }
  return const Color(0xFFE76158);
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
          _MonthlyMetricsRow(
            income: income,
            expense: expense,
            total: total,
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
        color: highlighted ? const Color(0xFFFFF1EF) : const Color(0xFFF7F8FA),
        border: const Border(bottom: BorderSide(color: Color(0xFFE6EAF0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${DateFormat('MM.dd').format(start)} ~ ${DateFormat('MM.dd').format(end)}',
              style: TextStyle(
                color: const Color(0xFF14171C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _MonthlyMetricsRow(
            income: income,
            expense: expense,
            total: total,
          ),
        ],
      ),
    );
  }
}

class _MonthlyMetricsRow extends StatelessWidget {
  const _MonthlyMetricsRow({
    required this.income,
    required this.expense,
    required this.total,
  });

  final double income;
  final double expense;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LedgerDayMetric(
          label: '수입',
          value: income.round() == 0 ? '0' : '+${_compactDailyAmount(income)}',
          color: const Color(0xFF56A0FF),
        ),
        const SizedBox(width: 14),
        _LedgerDayMetric(
          label: '지출',
          value: expense.round() == 0 ? '0' : '-${_compactDailyAmount(expense)}',
          color: const Color(0xFFFF7A70),
        ),
        const SizedBox(width: 14),
        _LedgerDayMetric(
          label: '남은금액',
          value: total.round() == 0
              ? '0'
              : total < 0
                  ? '-${_compactDailyAmount(total.abs())}'
                  : '+${_compactDailyAmount(total)}',
          color: total < 0
              ? const Color(0xFFFF7A70)
              : const Color(0xFF56A0FF),
        ),
      ],
    );
  }
}

class _SettlementLedgerTab extends StatelessWidget {
  const _SettlementLedgerTab({
    required this.entries,
    required this.budgets,
    required this.month,
    required this.onOpenSettings,
  });

  final List<LedgerEntry> entries;
  final List<WalletKeeperBudgetSetting> budgets;
  final DateTime month;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final expenseEntries = entries.where((entry) => entry.type == EntryType.expense).toList();
    final totalBudget = budgets.fold<double>(0, (sum, budget) => sum + budget.amount);
    final totalSpent = expenseEntries.fold<double>(0, (sum, entry) => sum + entry.amount);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final todayRatio = DateTime.now().year == month.year && DateTime.now().month == month.month
        ? (DateTime.now().day / daysInMonth).clamp(0.0, 1.0)
        : (DateTime.now().isBefore(month) ? 0.0 : 1.0);

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
              InkWell(
                onTap: onOpenSettings,
                borderRadius: BorderRadius.circular(12),
                child: Container(
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
              ),
            ],
          ),
        ),
        if (budgets.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Text(
              '설정된 예산이 없습니다.\n예산설정에서 분류별 예산을 추가하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF878B95),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else ...[
          const SizedBox(height: 12),
          _BudgetProgressRow(
            label: '전체예산',
            budgetAmount: totalBudget,
            spentAmount: totalSpent,
            progressRatio: todayRatio,
            showTodayMarker: true,
          ),
          ...budgets.map((budget) {
            final spent = expenseEntries
                .where((entry) => entry.category.trim() == budget.category.trim())
                .fold<double>(0, (sum, entry) => sum + entry.amount);
            return _BudgetProgressRow(
              label: budget.category,
              budgetAmount: budget.amount,
              spentAmount: spent,
              progressRatio: budget.amount <= 0
                  ? 0
                  : (spent / budget.amount).clamp(0.0, 1.0),
              showTodayMarker: false,
            );
          }),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _BudgetProgressRow extends StatelessWidget {
  const _BudgetProgressRow({
    required this.label,
    required this.budgetAmount,
    required this.spentAmount,
    required this.progressRatio,
    required this.showTodayMarker,
  });

  final String label;
  final double budgetAmount;
  final double spentAmount;
  final double progressRatio;
  final bool showTodayMarker;

  @override
  Widget build(BuildContext context) {
    final remaining = budgetAmount - spentAmount;
    final overBudget = remaining < 0;
    final barColor = overBudget ? const Color(0xFFFF7A70) : const Color(0xFF56A0FF);
    final visibleProgress = overBudget ? 1.0 : progressRatio.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(bottom: BorderSide(color: Color(0xFFE6EAF0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF14171C),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _compactDailyAmount(budgetAmount),
                  style: const TextStyle(
                    color: Color(0xFF14171C),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: visibleProgress,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (showTodayMarker)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: -30,
                        child: SizedBox(
                          height: 60,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final markerLeft = (constraints.maxWidth * progressRatio)
                                  .clamp(18.0, constraints.maxWidth - 18.0);
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: markerLeft - 1,
                                    top: 22,
                                    child: Container(
                                      width: 2,
                                      height: 30,
                                      color: const Color(0xFF6A6D74),
                                    ),
                                  ),
                                  Positioned(
                                    left: markerLeft - 26,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF909090),
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          child: const Text(
                                            '오늘',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        CustomPaint(
                                          size: const Size(12, 8),
                                          painter: _BudgetMarkerTrianglePainter(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      _compactDailyAmount(spentAmount),
                      style: TextStyle(
                        color: barColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      overBudget
                          ? '초과 -${_compactDailyAmount(remaining.abs())}'
                          : _compactDailyAmount(remaining),
                      style: TextStyle(
                        color: overBudget ? const Color(0xFFFF695D) : const Color(0xFF14171C),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetMarkerTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF909090);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LedgerDayHeader extends StatelessWidget {
  const _LedgerDayHeader({
    required this.date,
    required this.income,
    required this.expense,
    required this.total,
  });

  final DateTime date;
  final double income;
  final double expense;
  final double total;

  @override
  Widget build(BuildContext context) {
    final isHoliday = _isKoreanPublicHoliday(date);
    final dayNumberColor = isHoliday
        ? const Color(0xFFE35A52)
        : const Color(0xFF14171C);
    final weekdayBadgeColor = isHoliday
        ? const Color(0xFFFFE7E5)
        : const Color(0xFF8B8D93);
    final weekdayTextColor = isHoliday
        ? const Color(0xFFE35A52)
        : const Color(0xFFF4F5F7);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(bottom: BorderSide(color: Color(0xFFE6EAF0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                  DateFormat('d').format(date),
                  style: TextStyle(
                    color: dayNumberColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('yyyy.MM').format(date),
                      style: const TextStyle(
                        color: Color(0xFFADAFB6),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: weekdayBadgeColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          DateFormat('EEEE', 'ko_KR').format(date),
                          style: TextStyle(
                            color: weekdayTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  _LedgerDayMetric(
                    label: '수입',
                    value: income.round() == 0 ? '0' : '+${_compactDailyAmount(income)}',
                    color: const Color(0xFF56A0FF),
                  ),
                  const SizedBox(width: 14),
                  _LedgerDayMetric(
                    label: '지출',
                    value: expense.round() == 0 ? '0' : '-${_compactDailyAmount(expense)}',
                    color: const Color(0xFFFF695D),
                  ),
                  const SizedBox(width: 14),
                  _LedgerDayMetric(
                    label: '남은금액',
                    value: total.round() == 0
                        ? '0'
                        : total > 0
                            ? '+${_compactDailyAmount(total)}'
                            : '-${_compactDailyAmount(total.abs())}',
                    color: total < 0
                        ? const Color(0xFFFF695D)
                        : const Color(0xFF56A0FF),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}

bool _isKoreanPublicHoliday(DateTime date) {
  if (date.weekday == DateTime.sunday) {
    return true;
  }
  final key = DateFormat('yyyy-MM-dd').format(date);
  const fixedHolidays = {
    '01-01',
    '03-01',
    '05-05',
    '06-06',
    '08-15',
    '10-03',
    '10-09',
    '12-25',
  };
  final monthDay = DateFormat('MM-dd').format(date);
  if (fixedHolidays.contains(monthDay)) {
    return true;
  }
  const mappedHolidays = {
    '2025-01-28',
    '2025-01-29',
    '2025-01-30',
    '2025-03-03',
    '2025-05-06',
    '2025-06-03',
    '2025-10-05',
    '2025-10-06',
    '2025-10-07',
    '2025-10-08',
    '2026-02-16',
    '2026-02-17',
    '2026-02-18',
    '2026-03-02',
    '2026-05-25',
    '2026-09-24',
    '2026-09-25',
    '2026-09-26',
    '2026-09-28',
    '2027-02-06',
    '2027-02-07',
    '2027-02-08',
    '2027-03-01',
    '2027-05-13',
    '2027-09-14',
    '2027-09-15',
    '2027-09-16',
  };
  return mappedHolidays.contains(key);
}

class _LedgerDayMetric extends StatelessWidget {
  const _LedgerDayMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF98A1AD),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _LedgerRowItem extends StatefulWidget {
  const _LedgerRowItem({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final LedgerEntry entry;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  State<_LedgerRowItem> createState() => _LedgerRowItemState();
}

class _LedgerRowItemState extends State<_LedgerRowItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final valueColor = entry.type == EntryType.expense
        ? const Color(0xFFFF695D)
        : const Color(0xFF56A0FF);
    final cleanedNote = _cleanEntryDisplayNote(entry.note);
    final detailLine = cleanedNote.isEmpty ? entry.title : cleanedNote.split('\n').first;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onDelete,
        onHighlightChanged: (value) {
          if (_pressed == value) return;
          setState(() => _pressed = value);
        },
        splashColor: const Color(0x14000000),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
          color: _pressed ? const Color(0xFFF1F3F6) : const Color(0xFFFFFFFF),
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
                        fontSize: 13,
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
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.type == EntryType.expense
                    ? '-${_compactDailyAmount(entry.amount)}'
                    : '+${_compactDailyAmount(entry.amount)}',
                style: TextStyle(
                  color: valueColor,
                  fontSize: 13,
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

String _compactDailyAmount(double amount) {
  final formatted = NumberFormat('#,###', 'ko_KR').format(amount.round());
  return formatted;
}

IconData _entryCategoryIcon(LedgerEntry entry) {
  return _walletKeeperCategoryDisplayIcon(
    entry.category,
    fallbackType: entry.type,
  );
}
