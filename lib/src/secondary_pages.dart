part of '../main.dart';

final Map<String, Future<Uint8List?>> _walletKeeperAppIconFutureCache = {};

class PlaceholderTabPage extends StatelessWidget {
  const PlaceholderTabPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final bottomInset = bottomOverlayHeightOf(context);
    return Container(
      color: const Color(0xFFF7F8FA),
      child: ListView(
        padding: EdgeInsets.fromLTRB(24, 72, 24, bottomInset + 24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE8EBF0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF6A5F), size: 28),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF14171C),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF7E8794),
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatsPage extends StatefulWidget {
  const StatsPage({
    super.key,
    required this.entries,
  });

  final List<LedgerEntry> entries;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

enum _StatsRangeMode { weekly, monthly, yearly, custom }

class _StatsPageState extends State<StatsPage> {
  late DateTime _selectedMonth;
  late DateTime _selectedWeekAnchor;
  late int _selectedYear;
  late DateTime _customStart;
  late DateTime _customEnd;
  _StatsRangeMode _rangeMode = _StatsRangeMode.monthly;
  int _selectedKind = 1;
  int? _selectedCategoryIndex;
  final List<GlobalKey> _categoryRowKeys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _selectedWeekAnchor = _startOfWeek(now);
    _selectedYear = now.year;
    _customStart = DateTime(now.year, 1, 1);
    _customEnd = DateTime(now.year, now.month, now.day);
  }

  void _movePeriod(int offset) {
    setState(() {
      switch (_rangeMode) {
        case _StatsRangeMode.weekly:
          _selectedWeekAnchor = _startOfWeek(
            _selectedWeekAnchor.add(Duration(days: offset * 7)),
          );
        case _StatsRangeMode.monthly:
          _selectedMonth = DateTime(
            _selectedMonth.year,
            _selectedMonth.month + offset,
          );
        case _StatsRangeMode.yearly:
          _selectedYear += offset;
        case _StatsRangeMode.custom:
          break;
      }
      _selectedCategoryIndex = 0;
    });
  }

  void _selectRangeMode(_StatsRangeMode mode) {
    if (_rangeMode == mode) return;
    final now = DateTime.now();
    setState(() {
      _rangeMode = mode;
      if (mode == _StatsRangeMode.weekly) {
        _selectedWeekAnchor = _startOfWeek(now);
      } else if (mode == _StatsRangeMode.monthly) {
        _selectedMonth = DateTime(now.year, now.month);
      } else if (mode == _StatsRangeMode.yearly) {
        _selectedYear = now.year;
      } else if (mode == _StatsRangeMode.custom) {
        _customStart = DateTime(now.year, 1, 1);
        _customEnd = DateTime(now.year, now.month, now.day);
      }
      _selectedCategoryIndex = 0;
    });
  }

  DateTime get _periodStart {
    switch (_rangeMode) {
      case _StatsRangeMode.weekly:
        return _selectedWeekAnchor;
      case _StatsRangeMode.monthly:
        return DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      case _StatsRangeMode.yearly:
        return DateTime(_selectedYear, 1, 1);
      case _StatsRangeMode.custom:
        return DateTime(_customStart.year, _customStart.month, _customStart.day);
    }
  }

  DateTime get _periodEnd {
    switch (_rangeMode) {
      case _StatsRangeMode.weekly:
        return DateTime(
          _selectedWeekAnchor.year,
          _selectedWeekAnchor.month,
          _selectedWeekAnchor.day + 6,
          23,
          59,
          59,
        );
      case _StatsRangeMode.monthly:
        return DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
      case _StatsRangeMode.yearly:
        return DateTime(_selectedYear, 12, 31, 23, 59, 59);
      case _StatsRangeMode.custom:
        return DateTime(_customEnd.year, _customEnd.month, _customEnd.day, 23, 59, 59);
    }
  }

  String get _periodHeaderLabel {
    switch (_rangeMode) {
      case _StatsRangeMode.weekly:
        final end = _periodEnd;
        return '${DateFormat('yy.MM.dd').format(_periodStart)} ~ ${DateFormat('yy.MM.dd').format(end)}';
      case _StatsRangeMode.monthly:
        return DateFormat('yyyy년 M월', 'ko_KR').format(_selectedMonth);
      case _StatsRangeMode.yearly:
        return '$_selectedYear년';
      case _StatsRangeMode.custom:
        return '';
    }
  }

  String get _periodCardLabel {
    switch (_rangeMode) {
      case _StatsRangeMode.weekly:
        final end = _periodEnd;
        return '${DateFormat('M.d').format(_periodStart)} ~ ${DateFormat('M.d').format(end)}';
      case _StatsRangeMode.monthly:
        return DateFormat('M월', 'ko_KR').format(_selectedMonth);
      case _StatsRangeMode.yearly:
        return '$_selectedYear년';
      case _StatsRangeMode.custom:
        return '${DateFormat('yy.MM.dd').format(_customStart)} ~ ${DateFormat('yy.MM.dd').format(_customEnd)}';
    }
  }

  bool get _canMoveForward {
    final now = DateTime.now();
    switch (_rangeMode) {
      case _StatsRangeMode.weekly:
        return _startOfWeek(now).isAfter(_selectedWeekAnchor);
      case _StatsRangeMode.monthly:
        final currentMonth = DateTime(now.year, now.month);
        return currentMonth.isAfter(DateTime(_selectedMonth.year, _selectedMonth.month));
      case _StatsRangeMode.yearly:
        return _selectedYear < now.year;
      case _StatsRangeMode.custom:
        return false;
    }
  }

  Future<void> _pickCustomDate({required bool isStart}) async {
    final initialDate = isStart ? _customStart : _customEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6A5F),
              surface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _customStart = DateTime(picked.year, picked.month, picked.day);
        if (_customStart.isAfter(_customEnd)) {
          _customEnd = _customStart;
        }
      } else {
        _customEnd = DateTime(picked.year, picked.month, picked.day);
        if (_customEnd.isBefore(_customStart)) {
          _customStart = _customEnd;
        }
      }
      _selectedCategoryIndex = 0;
    });
  }

  static DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday % 7));
  }

  void _syncCategoryKeys(int length) {
    while (_categoryRowKeys.length < length) {
      _categoryRowKeys.add(GlobalKey());
    }
    if (_categoryRowKeys.length > length) {
      _categoryRowKeys.removeRange(length, _categoryRowKeys.length);
    }
  }

  Future<void> _selectCategory(
    int index, {
    required int itemCount,
    required bool shouldScrollList,
  }) async {
    if (itemCount == 0) return;
    final clampedIndex = index.clamp(0, itemCount - 1);
    if (!mounted) return;
    final shouldClear = _selectedCategoryIndex == clampedIndex;
    setState(() {
      _selectedCategoryIndex = shouldClear ? null : clampedIndex;
    });
    if (shouldClear) return;
    if (!shouldScrollList) return;
    final targetContext = _categoryRowKeys[clampedIndex].currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectKind(int kind) {
    if (_selectedKind == kind) return;
    setState(() {
      _selectedKind = kind;
      _selectedCategoryIndex = 0;
    });
  }

  void _clearSelectedCategory() {
    if (_selectedCategoryIndex == null) return;
    setState(() {
      _selectedCategoryIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final periodEntries = widget.entries
        .where(
          (entry) =>
              !entry.date.isBefore(_periodStart) &&
              !entry.date.isAfter(_periodEnd),
        )
        .toList();
    final incomeTotal = periodEntries
        .where((entry) => entry.type == EntryType.income)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final expenseTotal = periodEntries
        .where((entry) => entry.type == EntryType.expense)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final targetType = _selectedKind == 0 ? EntryType.income : EntryType.expense;
    final filtered = periodEntries.where((entry) => entry.type == targetType).toList();
    final total = filtered.fold<double>(0, (sum, entry) => sum + entry.amount);
    final byCategory = <String, double>{};
    for (final entry in filtered) {
      byCategory.update(entry.category, (value) => value + entry.amount, ifAbsent: () => entry.amount);
    }
    final items = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    _syncCategoryKeys(items.length);
    final selectedIndex = items.isEmpty
        ? -1
        : (_selectedCategoryIndex ?? 0).clamp(0, items.length - 1);
    final selectedItem = items.isEmpty ? null : items[selectedIndex];
    final selectedRatio = selectedItem == null || total == 0 ? 0.0 : selectedItem.value / total;
    final bottomInset = bottomOverlayHeightOf(context);
    final selectedColor = _selectedKind == 0 ? const Color(0xFF6C9CFF) : const Color(0xFFFF6A5F);
    final statsPalette =
        _selectedKind == 0 ? _statsIncomePalette : _statsExpensePalette;

    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 10, 6),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Expanded(
                      child: _rangeMode == _StatsRangeMode.custom
                          ? Row(
                              children: [
                                const SizedBox(width: 20),
                                Flexible(
                                  child: _StatsDateRangeField(
                                    value: DateFormat('yy.MM.dd').format(_customStart),
                                    onTap: () => _pickCustomDate(isStart: true),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '~',
                                  style: TextStyle(
                                    color: Color(0xFF7B8491),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: _StatsDateRangeField(
                                    value: DateFormat('yy.MM.dd').format(_customEnd),
                                    onTap: () => _pickCustomDate(isStart: false),
                                  ),
                                ),
                              ],
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => _movePeriod(-1),
                                    child: const Icon(
                                      Icons.chevron_left_rounded,
                                      size: 30,
                                      color: Color(0xFF14171C),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _periodHeaderLabel,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: const TextStyle(
                                      color: Color(0xFF14171C),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  GestureDetector(
                                    onTap: _canMoveForward ? () => _movePeriod(1) : null,
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      size: 30,
                                      color: _canMoveForward
                                          ? const Color(0xFF14171C)
                                          : const Color(0xFFCDD4DE),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<_StatsRangeMode>(
                      onSelected: _selectRangeMode,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _StatsRangeMode.weekly,
                          child: Text('주간'),
                        ),
                        PopupMenuItem(
                          value: _StatsRangeMode.monthly,
                          child: Text('월간'),
                        ),
                        PopupMenuItem(
                          value: _StatsRangeMode.yearly,
                          child: Text('연간'),
                        ),
                        PopupMenuItem(
                          value: _StatsRangeMode.custom,
                          child: Text('기간'),
                        ),
                      ],
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFD9DEE6),
                            width: 1.1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              switch (_rangeMode) {
                                _StatsRangeMode.weekly => '주간',
                                _StatsRangeMode.monthly => '월간',
                                _StatsRangeMode.yearly => '연간',
                                _StatsRangeMode.custom => '기간',
                              },
                              style: const TextStyle(
                                color: Color(0xFF14171C),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF14171C),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _clearSelectedCategory,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 18),
                children: [
                Row(
                  children: [
                    _StatsSummaryCard(
                      label: '수입',
                      value: _formatStatsWon(incomeTotal),
                      selected: _selectedKind == 0,
                      onTap: () => _selectKind(0),
                      color: const Color(0xFF6C9CFF),
                    ),
                    const SizedBox(width: 8),
                    _StatsSummaryCard(
                      label: '지출',
                      value: _formatStatsWon(expenseTotal),
                      selected: _selectedKind == 1,
                      onTap: () => _selectKind(1),
                      color: const Color(0xFFFF6A5F),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE6EAF0)),
                    ),
                    child: const Center(
                      child: Text(
                        '표시할 통계가 없습니다.',
                        style: TextStyle(
                          color: Color(0xFF8E939D),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE6EAF0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A14171C),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              targetType == EntryType.income ? '수입 분석' : '지출 분석',
                              style: const TextStyle(
                                color: Color(0xFF14171C),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _periodCardLabel,
                              style: const TextStyle(
                                color: Color(0xFF8E939D),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: _StatsDonutSection(
                            items: items,
                            total: total,
                            selectedIndex: selectedIndex,
                            selectedItem: selectedItem!,
                            selectedRatio: selectedRatio,
                            accentColor: selectedColor,
                            colors: statsPalette,
                            onBackgroundTap: _clearSelectedCategory,
                            animationKey:
                                '${_rangeMode.name}-${_periodStart.toIso8601String()}-${_periodEnd.toIso8601String()}-$_selectedKind-${items.length}-${total.toStringAsFixed(0)}',
                            onSegmentTap: (index) => _selectCategory(
                              index,
                              itemCount: items.length,
                              shouldScrollList: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Column(
                          children: items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final ratio = total == 0 ? 0.0 : item.value / total;
                            return _StatsLegendRow(
                              key: _categoryRowKeys[index],
                              item: item,
                              ratio: ratio,
                              color: statsPalette[index % statsPalette.length],
                              selected: index == selectedIndex,
                              dimmed: selectedIndex >= 0 && index != selectedIndex,
                              onTap: () => _selectCategory(
                                index,
                                itemCount: items.length,
                                shouldScrollList: false,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
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

class _StatsSummaryCard extends StatelessWidget {
  const _StatsSummaryCard({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.value,
    required this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
            color: selected ? color : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
              color: selected ? color : const Color(0xFFE6EAF0),
              ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0814171C),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white.withValues(alpha: 0.22) : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Icon(
                      label == '수입' ? Icons.south_west_rounded : Icons.north_east_rounded,
                      size: 11,
                      color: selected ? Colors.white : color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (!selected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD8DDE5),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF14171C),
                  fontSize: 17,
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

class _StatsDateRangeField extends StatelessWidget {
  const _StatsDateRangeField({
    required this.value,
    required this.onTap,
  });

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF14171C),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: Color(0xFF8D97A5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsDonutSection extends StatelessWidget {
  const _StatsDonutSection({
    required this.items,
    required this.total,
    required this.animationKey,
    required this.selectedIndex,
    required this.selectedItem,
    required this.selectedRatio,
    required this.onSegmentTap,
    required this.accentColor,
    required this.onBackgroundTap,
    required this.colors,
  });

  final List<MapEntry<String, double>> items;
  final double total;
  final String animationKey;
  final int selectedIndex;
  final MapEntry<String, double> selectedItem;
  final double selectedRatio;
  final ValueChanged<int> onSegmentTap;
  final Color accentColor;
  final VoidCallback onBackgroundTap;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(animationKey),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return TweenAnimationBuilder<double>(
          key: ValueKey('$animationKey-$selectedIndex'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          builder: (context, selectionProgress, child) {
            return GestureDetector(
              onTapUp: (details) {
                final index = _StatsDonutPainter.hitTestSegment(
                  size: const Size(212, 212),
                  position: details.localPosition,
                  values: items.map((item) => item.value).toList(),
                );
                if (index != null) {
                  onSegmentTap(index);
                  return;
                }
                onBackgroundTap();
              },
              child: SizedBox(
                width: 212,
                height: 212,
                child: CustomPaint(
                  painter: _StatsDonutPainter(
                    values: items.map((item) => item.value).toList(),
                    colors: List.generate(
                      items.length,
                      (index) => colors[index % colors.length],
                    ),
                    progress: progress,
                    selectedIndex: selectedIndex,
                    selectionProgress: selectionProgress,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.06),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        key: ValueKey('${selectedItem.key}-${selectedItem.value}'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '총 지출',
                            style: TextStyle(
                              color: Color(0xFF8F96A3),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatStatsWon(total),
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            selectedItem.key,
                            style: const TextStyle(
                              color: Color(0xFF14171C),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _formatStatsRatio(selectedRatio),
                            style: const TextStyle(
                              color: Color(0xFF8F96A3),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatsLegendRow extends StatelessWidget {
  const _StatsLegendRow({
    super.key,
    required this.item,
    required this.ratio,
    required this.color,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final MapEntry<String, double> item;
  final double ratio;
  final Color color;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final row = AnimatedScale(
      scale: selected ? 1.015 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF5F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.key,
                style: const TextStyle(
                  color: Color(0xFF14171C),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 54,
              child: Text(
                _formatStatsRatio(ratio),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF8B93A0),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 108,
              child: Text(
                _formatStatsWon(item.value),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF14171C),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: dimmed ? 0.45 : 1,
        child: ImageFiltered(
          imageFilter: dimmed
              ? ImageFilter.blur(sigmaX: 0.75, sigmaY: 0.75)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: row,
        ),
      ),
    );
  }
}

class _StatsDonutPainter extends CustomPainter {
  const _StatsDonutPainter({
    required this.values,
    required this.colors,
    required this.progress,
    required this.selectedIndex,
    required this.selectionProgress,
  });

  final List<double> values;
  final List<Color> colors;
  final double progress;
  final int selectedIndex;
  final double selectionProgress;

  static int? hitTestSegment({
    required Size size,
    required Offset position,
    required List<double> values,
  }) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return null;
    final center = Offset(size.width / 2, size.height / 2);
    final vector = position - center;
    final distance = vector.distance;
    final outerRadius = size.width / 2 - 24;
    const maxStroke = 30.0;
    final innerRadius = outerRadius - maxStroke;
    if (distance < innerRadius || distance > outerRadius + (maxStroke / 2)) {
      return null;
    }
    var angle = math.atan2(vector.dy, vector.dx) + math.pi / 2;
    if (angle < 0) angle += math.pi * 2;
    var cursor = 0.0;
    for (var i = 0; i < values.length; i++) {
      final normalizedSweep = (values[i] / total) * math.pi * 2;
      if (angle >= cursor && angle < cursor + normalizedSweep) {
        return i;
      }
      cursor += normalizedSweep;
    }
    return values.isEmpty ? null : values.length - 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) return;
    const baseStrokeWidth = 24.0;
    const selectedStrokeWidth = 30.0;
    const selectedOuterExtension = 10.0;
    final baseRadius = size.width / 2 - selectedStrokeWidth;
    final baseInnerRadius = baseRadius - (baseStrokeWidth / 2);
    final baseRect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: baseRadius,
    );
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = baseStrokeWidth
      ..color = const Color(0xFFF1F3F7);
    canvas.drawArc(baseRect, 0, math.pi * 2, false, backgroundPaint);
    var startAngle = -math.pi / 2;
    final hasSingleFullSegment = values.length == 1;
    for (var i = 0; i < values.length; i++) {
      final normalizedSweep = (values[i] / total) * math.pi * 2;
      final gap = hasSingleFullSegment ? 0.0 : math.min(0.028, normalizedSweep * 0.18);
      final sweepAngle = math.max(0.0, (normalizedSweep - gap) * progress);
      final isSelected = i == selectedIndex;
      final strokeWidth = isSelected
          ? lerpDouble(baseStrokeWidth, selectedStrokeWidth, selectionProgress) ??
              selectedStrokeWidth
          : lerpDouble(baseStrokeWidth, 18, selectionProgress) ?? 18;
      final segmentRadius = isSelected
          ? baseInnerRadius +
              (strokeWidth / 2) +
              (selectedOuterExtension * selectionProgress)
          : baseRadius;
      final segmentRect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: segmentRadius,
      );
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = strokeWidth
        ..color = isSelected
            ? Color.lerp(colors[i].withValues(alpha: 0.74), colors[i], selectionProgress) ??
                colors[i]
            : Color.lerp(
                  colors[i].withValues(alpha: 0.56),
                  colors[i].withValues(alpha: 0.36),
                  selectionProgress,
                ) ??
                colors[i].withValues(alpha: 0.36);
      canvas.drawArc(segmentRect, startAngle, sweepAngle, false, paint);
      startAngle += normalizedSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _StatsDonutPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.colors != colors ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.selectionProgress != selectionProgress;
  }
}

String _formatStatsWon(double value) {
  return '₩${NumberFormat('#,###').format(value.round())}';
}

String _formatStatsRatio(double ratio) {
  final percent = ratio * 100;
  final rounded = percent.roundToDouble();
  if ((percent - rounded).abs() < 0.05) {
    return '${rounded.toInt()}%';
  }
  return '${percent.toStringAsFixed(1)}%';
}

const List<Color> _statsExpensePalette = [
  Color(0xFFFF6A5F),
  Color(0xFFFFB099),
  Color(0xFFFFC8BF),
  Color(0xFFF3F4F7),
  Color(0xFFE0E8FF),
  Color(0xFFD5F0E4),
];

const List<Color> _statsIncomePalette = [
  Color(0xFF6C9CFF),
  Color(0xFF8BB5FF),
  Color(0xFFB8D2FF),
  Color(0xFFD8E6FF),
  Color(0xFFEAF2FF),
  Color(0xFFF3F7FF),
];


class _CompactPageHeader extends StatelessWidget {
  const _CompactPageHeader({
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 6),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              _CompactHeaderButton(
                icon: Icons.chevron_left_rounded,
                onTap: onBack,
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
              const Spacer(),
              ...?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactHeaderButton extends StatelessWidget {
  const _CompactHeaderButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            size: 30,
            color: onTap == null ? const Color(0xFFCDD4DE) : const Color(0xFF14171C),
          ),
        ),
      ),
    );
  }
}

class _NotificationSourceAppIcon extends StatelessWidget {
  const _NotificationSourceAppIcon({
    required this.packageName,
    required this.iconBase64,
  });

  final String packageName;
  final String iconBase64;

  @override
  Widget build(BuildContext context) {
    if (iconBase64.trim().isNotEmpty) {
      try {
        final bytes = base64Decode(iconBase64.trim());
        if (bytes.isNotEmpty) {
          return _buildIcon(bytes);
        }
      } catch (_) {}
    }
    final normalizedPackage = packageName.trim();
    if (normalizedPackage.isEmpty) {
      return const SizedBox.shrink();
    }
    final future = _walletKeeperAppIconFutureCache.putIfAbsent(
      normalizedPackage,
      () => const WalletKeeperNotificationAccessRepository()
          .getApplicationIconBytes(normalizedPackage),
    );
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildIcon(bytes);
      },
    );
  }

  Widget _buildIcon(Uint8List bytes) {
    return Container(
      width: 18,
      height: 18,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Image.memory(
        bytes,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

class _NotificationSourceSmsIcon extends StatelessWidget {
  const _NotificationSourceSmsIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFFE9F2FF),
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.sms_outlined,
        size: 14,
        color: Color(0xFF4B8EFF),
      ),
    );
  }
}

class SmsInboxPage extends StatefulWidget {
  const SmsInboxPage({
    super.key,
    required this.drafts,
    required this.featureAccess,
    required this.settings,
    required this.onBack,
    required this.onOpenSettingsPage,
    required this.onImportRecent,
    required this.onOpenDraft,
    required this.onRequestSmsAccess,
    required this.onQuickAutoInput,
    required this.onDeleteSelected,
  });

  final List<WalletKeeperSmsDraft> drafts;
  final WalletKeeperFeatureAccess featureAccess;
  final WalletKeeperSmsSettings settings;
  final VoidCallback onBack;
  final VoidCallback onOpenSettingsPage;
  final Future<void> Function(int days) onImportRecent;
  final void Function(WalletKeeperSmsDraft draft) onOpenDraft;
  final Future<void> Function() onRequestSmsAccess;
  final Future<void> Function(WalletKeeperSmsDraft draft) onQuickAutoInput;
  final Future<void> Function(Set<String> ids) onDeleteSelected;

  @override
  State<SmsInboxPage> createState() => _SmsInboxPageState();
}

class _SmsInboxPageState extends State<SmsInboxPage> {
  bool _importing = false;
  bool _deleteMode = false;
  final Set<String> _selectedIds = <String>{};
  final Set<String> _pendingRemovalIds = <String>{};

  List<WalletKeeperSmsDraft> get _visibleDrafts =>
      widget.drafts.where((draft) => !_pendingRemovalIds.contains(draft.id)).toList();

  void _handleBackPressed() {
    if (_deleteMode) {
      setState(() {
        _deleteMode = false;
        _selectedIds.clear();
      });
      return;
    }
    widget.onBack();
  }

  @override
  void didUpdateWidget(covariant SmsInboxPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pendingRemovalIds.removeWhere(
      (id) => !widget.drafts.any((draft) => draft.id == id),
    );
    _selectedIds.removeWhere(
      (id) => !widget.drafts.any((draft) => draft.id == id),
    );
  }

  Future<void> _handleQuickAutoInput(WalletKeeperSmsDraft draft) async {
    setState(() {
      _pendingRemovalIds.add(draft.id);
      _selectedIds.remove(draft.id);
    });
    try {
      await widget.onQuickAutoInput(draft);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingRemovalIds.remove(draft.id));
    }
  }

  Future<void> _handleDismissDelete(WalletKeeperSmsDraft draft) async {
    setState(() {
      _pendingRemovalIds.add(draft.id);
      _selectedIds.remove(draft.id);
    });
    try {
      await widget.onDeleteSelected({draft.id});
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingRemovalIds.remove(draft.id));
    }
  }

  Future<void> _showImportDialog() async {
    final controller = TextEditingController(text: '60');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: const Text(
            '문자 가져오기',
            style: TextStyle(
              color: Color(0xFF14171C),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '휴대폰에 저장된 최근',
                style: TextStyle(
                  color: Color(0xFF6F7782),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 96,
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF14171C),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.only(bottom: 8),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD8DDE5)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFF6A5F), width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      '일 이내의 문자를 가져옵니다.',
                      style: TextStyle(
                        color: Color(0xFF6F7782),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  '아니오',
                  style: TextStyle(
                    color: Color(0xFF5C6470),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  '예',
                  style: TextStyle(
                    color: Color(0xFFFF6A5F),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    final days = int.tryParse(controller.text.trim()) ?? 60;
    setState(() => _importing = true);
    await widget.onImportRecent(days.clamp(1, 365));
    if (!mounted) return;
    setState(() => _importing = false);
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        _visibleDrafts.isNotEmpty && _selectedIds.length == _visibleDrafts.length;
    return PopScope(
      canPop: !_deleteMode,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !_deleteMode) return;
        setState(() {
          _deleteMode = false;
          _selectedIds.clear();
        });
      },
      child: Container(
        color: const Color(0xFFF7F8FA),
        child: Column(
          children: [
            _CompactPageHeader(
              title: '문자함 (${_visibleDrafts.length})',
              onBack: _handleBackPressed,
              trailing: [
                _CompactHeaderButton(
                  icon: _deleteMode ? Icons.close_rounded : Icons.delete_outline_rounded,
                  onTap: _visibleDrafts.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _deleteMode = !_deleteMode;
                            _selectedIds.clear();
                          });
                        },
                ),
                const SizedBox(width: 4),
                _CompactHeaderButton(
                  icon: Icons.settings_outlined,
                  onTap: widget.onOpenSettingsPage,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  color: Colors.white,
                    child: const Text(
                      'SMS, MMS, 금융앱 알림 중 금융 내역 관련 내용이 자동 감지되어 문자함에 담깁니다.\n문자 가져오기는 휴대폰에 저장된 최근 문자를 수동으로 불러옵니다. 왼쪽으로 밀면 삭제, 오른쪽으로 끝까지 밀면 바로 자동입력 저장됩니다.',
                      style: TextStyle(
                        color: Color(0xFF59606B),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_deleteMode)
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (allSelected) {
                          _selectedIds.clear();
                        } else {
                          _selectedIds
                            ..clear()
                            ..addAll(_visibleDrafts.map((draft) => draft.id));
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                      color: Colors.white,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: Checkbox(
                              value: allSelected,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              onChanged: (_) {
                                setState(() {
                                  if (allSelected) {
                                    _selectedIds.clear();
                                  } else {
                                    _selectedIds
                                      ..clear()
                                      ..addAll(_visibleDrafts.map((draft) => draft.id));
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '전체선택',
                            style: TextStyle(
                              color: Color(0xFF20242B),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_visibleDrafts.isEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                    child: const Column(
                      children: [
                        Icon(Icons.mail_outline_rounded, size: 40, color: Color(0xFFB4BDC9)),
                        SizedBox(height: 12),
                        Text(
                          '감지된 금융 문자가 아직 없습니다.',
                          style: TextStyle(
                            color: Color(0xFF6F7782),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._visibleDrafts.map(
                    (draft) {
                      final tile = InkWell(
                        onTap: () {
                          if (_deleteMode) {
                            setState(() {
                              if (_selectedIds.contains(draft.id)) {
                                _selectedIds.remove(draft.id);
                              } else {
                                _selectedIds.add(draft.id);
                              }
                            });
                            return;
                          }
                          widget.onOpenDraft(draft);
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: Color(0xFFEEF1F5))),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (_deleteMode)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: Checkbox(
                                          value: _selectedIds.contains(draft.id),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          onChanged: (_) {
                                            setState(() {
                                              if (_selectedIds.contains(draft.id)) {
                                                _selectedIds.remove(draft.id);
                                              } else {
                                                _selectedIds.add(draft.id);
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      DateFormat('MM.dd HH:mm:ss').format(draft.date),
                                      style: const TextStyle(
                                        color: Color(0xFF98A1AD),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (draft.sourceType == 'app_notification' &&
                                      draft.sourceAddress.isNotEmpty)
                                    _NotificationSourceAppIcon(
                                      packageName: draft.sourceAddress,
                                      iconBase64: draft.sourceAppIconBase64,
                                    )
                                  else if (draft.sourceType == 'sms' ||
                                      draft.sourceType == 'mms')
                                    const _NotificationSourceSmsIcon()
                                  else
                                    Text(
                                      draft.sourceAddress.isEmpty ? '알 수 없음' : draft.sourceAddress,
                                      style: const TextStyle(
                                        color: Color(0xFF98A1AD),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          draft.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF20242B),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          draft.rawBody
                                              .replaceFirst(
                                                RegExp(
                                                  r'^SMS 자동 감지\n발신:.*\n\n',
                                                ),
                                                '',
                                              )
                                              .replaceAll('\n', ' '),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF6F7782),
                                            fontSize: 12,
                                            height: 1.35,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        formatCurrency(draft.amount),
                                        style: TextStyle(
                                          color: draft.type == EntryType.expense
                                              ? const Color(0xFFFF6A5F)
                                              : draft.type == EntryType.income
                                                  ? const Color(0xFF1FA463)
                                                  : const Color(0xFF2F6BFF),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Color(0xFFB3BBC7),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                      if (_deleteMode) {
                        return tile;
                      }
                      return Dismissible(
                        key: ValueKey('sms_draft_${draft.id}'),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          color: const Color(0xFF1FA463),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: const [
                              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text(
                                '바로 저장',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          color: const Color(0xFFFF6A5F),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: const [
                              Text(
                                '삭제',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            return true;
                          }
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              title: const Text('문자 삭제'),
                              content: const Text('이 감지 문자를 문자함에서 삭제할까요?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('취소'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6A5F),
                                  ),
                                  child: const Text('삭제'),
                                ),
                              ],
                            ),
                          );
                          return confirmed == true;
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.startToEnd) {
                            _handleQuickAutoInput(draft);
                          } else {
                            _handleDismissDelete(draft);
                          }
                        },
                        child: tile,
                      );
                    },
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _deleteMode
                    ? FilledButton(
                        onPressed: _selectedIds.isEmpty
                            ? null
                            : () async {
                                await widget.onDeleteSelected(_selectedIds);
                                if (!mounted) return;
                                setState(() {
                                  _selectedIds.clear();
                                  _deleteMode = false;
                                });
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6A5F),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('선택삭제'),
                      )
                    : FilledButton(
                        onPressed: _importing ? null : _showImportDialog,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6A5F),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(_importing ? '가져오는 중' : '문자 가져오기'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmsSettingsPage extends StatelessWidget {
  const SmsSettingsPage({
    super.key,
    required this.featureAccess,
    required this.settings,
    required this.financialAppNotificationEnabled,
    required this.onBack,
    required this.onOpenFinancialAppNotificationSettings,
    required this.onChanged,
  });

  final WalletKeeperFeatureAccess featureAccess;
  final WalletKeeperSmsSettings settings;
  final bool financialAppNotificationEnabled;
  final VoidCallback onBack;
  final Future<void> Function() onOpenFinancialAppNotificationSettings;
  final Future<void> Function(WalletKeeperSmsSettings settings) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          _CompactPageHeader(
            title: '문자설정',
            onBack: onBack,
          ),
          Expanded(
            child: ListView(
              children: [
                const _SettingsSectionTitle('기본 설정', topPadding: 0),
                _SettingsSwitchRow(
                  title: 'SMS 수신 기능',
                  value: settings.smsReceiveEnabled,
                  onChanged: (value) => onChanged(settings.copyWith(smsReceiveEnabled: value)),
                ),
                _SettingsSwitchRow(
                  title: '금융 어플 알림 설정',
                  value: financialAppNotificationEnabled,
                  highlighted: !financialAppNotificationEnabled,
                  emphasisLabel: !financialAppNotificationEnabled ? '알림 접근 권한 필요' : null,
                  onChanged: (_) => onOpenFinancialAppNotificationSettings(),
                ),
                const _SettingsSectionTitle('문자설정'),
                _SettingsSwitchRow(
                  title: '문자 자동 입력 기능',
                  value: settings.autoInputEnabled,
                  onChanged: (value) => onChanged(settings.copyWith(autoInputEnabled: value)),
                ),
                _SettingsSwitchRow(
                  title: '알림바에 문자 수신 알림 표시하기',
                  value: settings.showNotification,
                  onChanged: (value) => onChanged(settings.copyWith(showNotification: value)),
                ),
                _SettingsActionRow(
                  title: '문자 가져오기 기간 설정',
                  value: '최근 ${settings.importWindowDays}일',
                  onTap: () async {
                    final controller = TextEditingController(
                      text: settings.importWindowDays.toString(),
                    );
                    final result = await showDialog<int>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        title: const Text('가져오기 기간 설정'),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '일 수 입력'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(
                              int.tryParse(controller.text.trim()),
                            ),
                            child: const Text('저장'),
                          ),
                        ],
                      ),
                    );
                    if (result == null) return;
                    await onChanged(
                      settings.copyWith(importWindowDays: result.clamp(1, 365)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(
    this.title, {
    this.topPadding = 18,
  });

  final String title;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 10),
      color: const Color(0xFFF7F8FA),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF888D96),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.highlighted = false,
    this.emphasisLabel,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool highlighted;
  final String? emphasisLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFF4F2) : const Color(0xFFFFFFFF),
        border: const Border(bottom: BorderSide(color: Color(0xFFE6EAF0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF14171C),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (emphasisLabel != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    emphasisLabel!,
                    style: const TextStyle(
                      color: Color(0xFFFF6A5F),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 50,
            height: 30,
            child: Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFFFF6A5F),
              inactiveTrackColor: const Color(0xFFE4E7EC),
              inactiveThumbColor: Colors.white,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.title,
    this.value,
    required this.onTap,
  });

  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          border: Border(bottom: BorderSide(color: Color(0xFFE6EAF0))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF14171C),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: const TextStyle(
                  color: Color(0xFFFF6A5F),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EntryEditorPage extends StatefulWidget {
  const EntryEditorPage({
    super.key,
    this.existing,
    this.smsDraft,
    required this.featureAccess,
    required this.onRequestSmsAccess,
    required this.onSave,
    required this.onCancel,
    this.onDeleteDraft,
  });

  final LedgerEntry? existing;
  final WalletKeeperSmsDraft? smsDraft;
  final WalletKeeperFeatureAccess featureAccess;
  final Future<void> Function() onRequestSmsAccess;
  final Future<void> Function(LedgerEntry entry) onSave;
  final Future<void> Function() onCancel;
  final Future<void> Function()? onDeleteDraft;

  @override
  State<EntryEditorPage> createState() => _EntryEditorPageState();
}

class _EntryEditorPageState extends State<EntryEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _noteController;
  List<String> _attachmentPaths = const [];
  late EntryType _type;
  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _categoryEditedByUser = false;
  bool _applyingCategoryText = false;

  bool get hasUnsavedChanges {
    if (_saving) return false;
    final source = widget.existing;
    final draft = widget.smsDraft;
    if (source == null && draft == null) {
      return _titleController.text.trim().isNotEmpty ||
          _amountController.text.trim().isNotEmpty ||
          _categoryController.text.trim().isNotEmpty ||
          _noteController.text.trim().isNotEmpty ||
          _attachmentPaths.isNotEmpty;
    }
    final sourceTitle = source?.title ?? draft?.title ?? '';
    final sourceAmount = _formatAmountForEditing(source?.amount ?? draft?.amount ?? 0);
    final sourceCategory = source?.category ?? draft?.category ?? '';
    final sourceNote = source?.note ?? draft?.note ?? '';
    final sourceType = source?.type ?? draft?.type ?? EntryType.expense;
    final sourceDate = source?.date ?? draft?.date;
    final sourceAttachments = source?.attachmentPaths ?? const <String>[];
    return _titleController.text.trim() != sourceTitle.trim() ||
        _amountController.text.trim() != sourceAmount.trim() ||
        _categoryController.text.trim() != sourceCategory.trim() ||
        _noteController.text.trim() != sourceNote.trim() ||
        _type != sourceType ||
        !_isSameMinute(_date, sourceDate) ||
        !_isSamePathList(_attachmentPaths, sourceAttachments);
  }

  bool get _fromSmsDraft => widget.smsDraft != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _categoryController = TextEditingController();
    _noteController = TextEditingController();
    _applySource();
  }

  @override
  void didUpdateWidget(covariant EntryEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.existing?.id != widget.existing?.id ||
        oldWidget.smsDraft?.id != widget.smsDraft?.id) {
      _applySource();
      if (mounted) setState(() {});
    }
  }

  void _applySource() {
    final draft = widget.smsDraft;
    final existing = widget.existing;
    if (draft != null) {
      final cleanedNote = _cleanSmsDraftBody(draft.note);
      final normalizedTitle = draft.title.trim();
      _titleController.text = normalizedTitle.isEmpty || normalizedTitle == draft.sourceAddress
          ? (cleanedNote.isEmpty ? '' : cleanedNote.split('\n').first)
          : normalizedTitle;
      _setAmountText(draft.amount.toStringAsFixed(0));
      _setCategoryText(draft.category);
      _noteController.text = '';
      _type = draft.type;
      _date = draft.date;
      return;
    }
    _titleController.text = existing?.title ?? '';
    _setAmountText(existing?.amount.toStringAsFixed(0) ?? '');
    _setCategoryText(existing?.category ?? '', editedByUser: existing != null);
    _noteController.text = existing?.note ?? '';
    _attachmentPaths = List<String>.from(existing?.attachmentPaths ?? const []);
    _type = existing?.type ?? EntryType.expense;
    _date = existing?.date ?? DateTime.now();
  }

  void _setCategoryText(String value, {bool editedByUser = false}) {
    _applyingCategoryText = true;
    _categoryController.text = value;
    _applyingCategoryText = false;
    _categoryEditedByUser = editedByUser;
  }

  void _handleTypeChanged(EntryType type) {
    if (_type == type) return;
    final shouldAutoReplaceCategory =
        widget.existing == null && !_categoryEditedByUser;
    setState(() {
      _type = type;
      if (shouldAutoReplaceCategory) {
        _setCategoryText(type.label(context));
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<bool> confirmDiscardIfNeeded() async {
    if (!hasUnsavedChanges) return true;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '작성 중인 내용이 있습니다',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        content: const Text(
          '정말로 나가시겠습니까?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE76158),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              '나가기',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    return shouldLeave == true;
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFFF6A5F)),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFFF6A5F)),
        ),
        child: child!,
      ),
    );
    if (pickedTime == null) return;
    setState(() {
      _date = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _setAmountText(String rawValue) {
    final digits = rawValue.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _amountController.value = const TextEditingValue(text: '');
      return;
    }
    final formatted = _ThousandsSeparatorInputFormatter.formatDigits(digits);
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '').trim());
    if (_titleController.text.trim().isEmpty ||
        _categoryController.text.trim().isEmpty ||
        amount == null ||
        amount <= 0) {
      await showAppToast('제목, 카테고리, 금액을 확인해주세요.');
      return;
    }
    setState(() => _saving = true);
    final existing = widget.existing;
    final entry = LedgerEntry(
      id: existing?.id ?? widget.smsDraft?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      amount: amount,
      category: _categoryController.text.trim(),
      note: _noteController.text.trim(),
      attachmentPaths: List<String>.from(_attachmentPaths),
      type: _type,
      date: _date,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    await widget.onSave(entry);
    if (!mounted) return;
    setState(() => _saving = false);
  }

  String _formatAmountForEditing(double amount) {
    final value = amount.round();
    if (value <= 0) return '';
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < raw.length; index++) {
      final reversedIndex = raw.length - index;
      buffer.write(raw[index]);
      if (reversedIndex > 1 && reversedIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  bool _isSameMinute(DateTime current, DateTime? source) {
    if (source == null) return false;
    return current.year == source.year &&
        current.month == source.month &&
        current.day == source.day &&
        current.hour == source.hour &&
        current.minute == source.minute;
  }

  bool _isSamePathList(List<String> current, List<String> source) {
    if (current.length != source.length) return false;
    for (var index = 0; index < current.length; index++) {
      if (current[index] != source[index]) return false;
    }
    return true;
  }

  Future<void> _openPhotoPicker() async {
    final selectedPaths = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (context) => WalletKeeperPhotoPickerPage(
          initialPaths: _attachmentPaths,
        ),
      ),
    );
    if (selectedPaths == null || !mounted) return;
    setState(() {
      _attachmentPaths = selectedPaths;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = bottomOverlayHeightOf(context);
    final actionBarBottomInset = math.max(0.0, bottomInset - 38);
    final applySystemBottomSafeArea = bottomInset == 0;
    final actionBarBottomPadding = bottomInset > 0 ? 22.0 : 12.0;
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          _CompactPageHeader(
            title: _type.label(context),
            onBack: widget.onCancel,
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              children: [
                Row(
                  children: EntryType.values.map((type) {
                    final selected = _type == type;
                    final isLast = type == EntryType.transfer;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: isLast ? 0 : 10),
                        child: GestureDetector(
                          onTap: () => _handleTypeChanged(type),
                        child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? const Color(0xFFFF6A5F) : const Color(0xFFDDE3EA),
                                width: selected ? 2 : 1.2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              type.label(context),
                              style: TextStyle(
                                color: selected ? const Color(0xFFFF6A5F) : const Color(0xFF5F6671),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _EditorRow(
                  label: '날짜',
                  child: InkWell(
                    onTap: _pickDateTime,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('yy/M/d (E)  a h:mm', 'ko_KR').format(_date),
                            style: const TextStyle(
                              color: Color(0xFF20242B),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.sync_rounded,
                            color: Color(0xFF98A1AD),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _EditorRow(
                  label: '금액',
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [_ThousandsSeparatorInputFormatter()],
                    style: const TextStyle(
                      color: Color(0xFF20242B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0원',
                      hintStyle: TextStyle(
                        color: Color(0xFFA5ACB7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                _EditorRow(
                  label: '분류',
                  child: TextField(
                    controller: _categoryController,
                    onChanged: (_) {
                      if (_applyingCategoryText) return;
                      _categoryEditedByUser = true;
                    },
                    style: const TextStyle(
                      color: Color(0xFF20242B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '분류 입력',
                      hintStyle: TextStyle(
                        color: Color(0xFFA5ACB7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                _EditorRow(
                  label: '내용',
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: Color(0xFF20242B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '내용 입력',
                      hintStyle: TextStyle(
                        color: Color(0xFFA5ACB7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5EAF1)),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '메모',
                            style: TextStyle(
                              color: Color(0xFF444B56),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Material(
                            type: MaterialType.transparency,
                            child: IconButton(
                              onPressed: _openPhotoPicker,
                              constraints: const BoxConstraints.tightFor(
                                width: 28,
                                height: 28,
                              ),
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                color: Color(0xFF8C95A2),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _noteController,
                        minLines: 4,
                        maxLines: 7,
                        style: const TextStyle(
                          color: Color(0xFF5A616C),
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '메모를 입력하세요.',
                          hintStyle: TextStyle(
                            color: Color(0xFFA5ACB7),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          isDense: true,
                        ),
                      ),
                      if (_attachmentPaths.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 86,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _attachmentPaths.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final path = _attachmentPaths[index];
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(path),
                                      width: 86,
                                      height: 86,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 86,
                                        height: 86,
                                        color: const Color(0xFFF1F4F8),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.broken_image_outlined,
                                          color: Color(0xFF9AA3B2),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _attachmentPaths = List<String>.from(_attachmentPaths)
                                            ..removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: Color(0xAA14171C),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F8FA),
              border: Border(
                top: BorderSide(color: Color(0xFFE7EBF1)),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              actionBarBottomPadding + actionBarBottomInset,
            ),
            child: SafeArea(
              top: false,
              bottom: applySystemBottomSafeArea,
              child: Row(
                children: _fromSmsDraft
                    ? [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onDeleteDraft,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF343A44),
                              side: const BorderSide(color: Color(0xFFD4DAE3)),
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            label: const Text('삭제'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6A5F),
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(_saving ? '기록 중' : '기록하기'),
                          ),
                        ),
                      ]
                    : [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF343A44),
                              side: const BorderSide(color: Color(0xFFD4DAE3)),
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6A5F),
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(_saving ? '저장 중' : '저장'),
                          ),
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

String _cleanSmsDraftBody(String rawNote) {
  return rawNote
      .replaceFirst(RegExp(r'^SMS 자동 감지\n발신:.*\n\n'), '')
      .replaceFirst(RegExp(r'^MMS 자동 감지\n발신:.*\n\n'), '')
      .trim();
}

class _EditorRow extends StatelessWidget {
  const _EditorRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 66,
            child: Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6F7782),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  const _ThousandsSeparatorInputFormatter();

  static String formatDigits(String digits) {
    final number = int.tryParse(digits);
    if (number == null) return digits;
    return NumberFormat.decimalPattern('ko_KR').format(number);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = formatDigits(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _RootTabHeader extends StatelessWidget {
  const _RootTabHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 6),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              const SizedBox(width: 34),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF14171C),
                  fontSize: 17,
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

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.session,
    required this.smsSettings,
    required this.onOpenSmsSettings,
    required this.onOpenDataSettings,
    required this.onOpenPrivacyInfo,
    required this.onSignInWithKakao,
    required this.onSignInWithGoogle,
    required this.onSignInWithNaver,
    required this.onSignInWithApple,
  });

  final WalletKeeperUserSession? session;
  final WalletKeeperSmsSettings smsSettings;
  final VoidCallback onOpenSmsSettings;
  final VoidCallback onOpenDataSettings;
  final VoidCallback onOpenPrivacyInfo;
  final Future<void> Function() onSignInWithKakao;
  final Future<void> Function() onSignInWithGoogle;
  final Future<void> Function() onSignInWithNaver;
  final Future<void> Function() onSignInWithApple;

  @override
  Widget build(BuildContext context) {
    final bottomInset = bottomOverlayHeightOf(context);
    final account = session;
    final isApplePlatform = Platform.isIOS || Platform.isMacOS;
    final linkedLabel = account == null || account.isGuest
        ? '비회원'
        : '${account.providerLabel} 연결됨';

    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          const _RootTabHeader(title: '설정'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 20),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE6EAF0)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFFFFECE9),
                        backgroundImage: account?.profileImage.isNotEmpty == true
                            ? NetworkImage(account!.profileImage)
                            : null,
                        child: account?.profileImage.isNotEmpty == true
                            ? null
                            : const Icon(
                                Icons.person_rounded,
                                size: 34,
                                color: Color(0xFFFF6A5F),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        account?.name.isNotEmpty == true ? account!.name : '지갑지켜 사용자',
                        style: const TextStyle(
                          color: Color(0xFF14171C),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        account?.email.isNotEmpty == true ? account!.email : linkedLabel,
                        style: const TextStyle(
                          color: Color(0xFF7B8491),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SocialLoginButtonTile(
                        label: '카카오로 시작하기',
                        provider: 'kakao',
                        active: account?.loginType == 'kakao',
                        backgroundColor: const Color(0xFFFFD500),
                        foregroundColor: const Color(0xD9000000),
                        borderColor: Colors.transparent,
                        iconPath: 'assets/icons/kakao_logo.png',
                        onTap: onSignInWithKakao,
                      ),
                      const SizedBox(height: 10),
                      _SocialLoginButtonTile(
                        label: '네이버로 시작하기',
                        provider: 'naver',
                        active: account?.loginType == 'naver',
                        enabled: false,
                        disabledLabel: '네이버 로그인 준비중',
                        backgroundColor: const Color(0xFFB7EBCF),
                        foregroundColor: const Color(0xFF256B46),
                        borderColor: Colors.transparent,
                        iconPath: 'assets/icons/naver_logo.png',
                        onTap: onSignInWithNaver,
                      ),
                      const SizedBox(height: 10),
                      _SocialLoginButtonTile(
                        label: 'Google로 시작하기',
                        provider: 'google',
                        active: account?.loginType == 'google',
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF14171C),
                        borderColor: const Color(0xFFD9DEE6),
                        iconPath: 'assets/icons/google_logo.png',
                        onTap: onSignInWithGoogle,
                      ),
                      if (isApplePlatform) ...[
                        const SizedBox(height: 10),
                        _SocialLoginButtonTile(
                          label: 'Apple로 시작하기',
                          provider: 'apple',
                          active: account?.loginType == 'apple',
                          backgroundColor: const Color(0xFF111111),
                          foregroundColor: Colors.white,
                          borderColor: Colors.transparent,
                          iconPath: 'assets/icons/apple_logo.png',
                          onTap: onSignInWithApple,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SettingsMenuSection(
                  title: '설정',
                  children: [
                    _SettingsMenuTile(
                      icon: Icons.sms_outlined,
                      title: '문자 설정',
                      subtitle: smsSettings.smsReceiveEnabled ? '문자 감지 사용 중' : '문자 감지 꺼짐',
                      onTap: onOpenSmsSettings,
                    ),
                    _SettingsMenuTile(
                      icon: Icons.cloud_outlined,
                      title: '데이터 동기화',
                      subtitle: account == null ? '준비 중' : '서버 저장/연동 상태 확인',
                      onTap: onOpenDataSettings,
                    ),
                    _SettingsMenuTile(
                      icon: Icons.privacy_tip_outlined,
                      title: '개인정보 및 저장 안내',
                      subtitle: '수집 정보와 서버 저장 범위 확인',
                      onTap: onOpenPrivacyInfo,
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

class DataSettingsPage extends StatelessWidget {
  const DataSettingsPage({
    super.key,
    required this.session,
    required this.onBack,
    required this.onSyncNow,
  });

  final WalletKeeperUserSession? session;
  final VoidCallback onBack;
  final Future<void> Function() onSyncNow;

  @override
  Widget build(BuildContext context) {
    final account = session;
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          _CompactPageHeader(title: '데이터 동기화', onBack: onBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _SettingsInfoCard(
                  title: '계정 상태',
                  body: account == null
                      ? '계정 정보를 아직 불러오지 못했습니다.'
                      : '현재 ${account.providerLabel} 기준으로 서버 저장 데이터가 연결됩니다.\n비회원 상태에서는 기기 시리얼 코드로 먼저 서버와 바인딩됩니다.',
                ),
                const SizedBox(height: 14),
                _SettingsKeyValueCard(
                  rows: [
                    _SettingsKeyValue('회원 ID', account?.userId ?? '-'),
                    _SettingsKeyValue('로그인 유형', account?.providerLabel ?? '-'),
                    _SettingsKeyValue('기기 시리얼', account?.deviceSerial ?? '-'),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onSyncNow,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A5F),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('지금 서버 동기화'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AssetPage extends StatelessWidget {
  const AssetPage({
    super.key,
    required this.entries,
    required this.session,
    required this.onOpenFlowHistory,
  });

  final List<LedgerEntry> entries;
  final WalletKeeperUserSession? session;
  final VoidCallback onOpenFlowHistory;

  @override
  Widget build(BuildContext context) {
    final bottomInset = bottomOverlayHeightOf(context);
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final summary = LedgerSummary.fromEntries(entries);
    final thisMonthEntries = entries
        .where(
          (entry) =>
              entry.date.year == now.year && entry.date.month == now.month,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final visibleUpcomingExpenses = _buildUpcomingFixedExpenses(
      entries,
      now: now,
      startOfToday: startOfToday,
    ).take(3).toList();
    final recentFlow = thisMonthEntries.take(3).toList();
    final incomeRatio = (summary.monthIncome <= 0 && summary.monthExpense <= 0)
        ? 0.5
        : summary.monthIncome /
            math.max(1, summary.monthIncome + summary.monthExpense);
    final expenseRatio =
        (summary.monthIncome <= 0 && summary.monthExpense <= 0)
            ? 0.0
            : summary.monthExpense /
                math.max(1, summary.monthIncome + summary.monthExpense);
    final balanceRatio = (summary.monthIncome <= 0)
        ? 0.0
        : (summary.balance / math.max(1, summary.monthIncome)).clamp(0.0, 1.0);

    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          const _RootTabHeader(title: '자산'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 24),
              children: [
                _AssetSoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text(
                            '다가오는 지출',
                            style: TextStyle(
                              color: Color(0xFF14171C),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Spacer(),
                          Text(
                            '전체보기',
                            style: TextStyle(
                              color: Color(0xFF97A1AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Color(0xFF97A1AF),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (visibleUpcomingExpenses.isEmpty)
                        const _AssetSimpleEmpty(
                          title: '예정된 지출이 없습니다.',
                          subtitle: '다가오는 지출이 생기면 이곳에 먼저 표시됩니다.',
                        )
                      else
                        ...List.generate(visibleUpcomingExpenses.length, (index) {
                          final entry = visibleUpcomingExpenses[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == visibleUpcomingExpenses.length - 1
                                  ? 0
                                  : 16,
                            ),
                            child: _UpcomingExpenseRow(entry: entry),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _AssetSoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '자금 흐름',
                            style: TextStyle(
                              color: Color(0xFF14171C),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            summary.balance >= 0 ? '이번 달 양호' : '이번 달 점검',
                            style: TextStyle(
                              color: summary.balance >= 0
                                  ? const Color(0xFF29B15F)
                                  : const Color(0xFFFF6A5F),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text(
                            '수입 대비 비율',
                            style: TextStyle(
                              color: Color(0xFF9BA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(incomeRatio * 100).round()}%',
                            style: const TextStyle(
                              color: Color(0xFF29B15F),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _AssetProgressBar(
                        ratio: incomeRatio,
                        color: const Color(0xFF29B15F),
                      ),
                      const SizedBox(height: 14),
                      _AssetFlowMetricRow(
                        label: '수입',
                        color: const Color(0xFF68A9FF),
                        amount: '+${_formatAssetAmount(summary.monthIncome)}',
                        amountColor: const Color(0xFF68A9FF),
                        ratio: incomeRatio.clamp(0.0, 1.0),
                      ),
                      const SizedBox(height: 10),
                      _AssetFlowMetricRow(
                        label: '지출',
                        color: const Color(0xFFFF6A5F),
                        amount: '-${_formatAssetAmount(summary.monthExpense)}',
                        amountColor: const Color(0xFFFF6A5F),
                        ratio: expenseRatio.clamp(0.0, 1.0),
                      ),
                      const SizedBox(height: 10),
                      _AssetFlowMetricRow(
                        label: '남은금액',
                        color: const Color(0xFF29B15F),
                        amount: '${summary.balance >= 0 ? '+' : '-'}${_formatAssetAmount(summary.balance.abs())}',
                        amountColor: summary.balance >= 0
                            ? const Color(0xFF29B15F)
                            : const Color(0xFFFF6A5F),
                        ratio: balanceRatio,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _AssetSoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '최근 자금 흐름',
                            style: TextStyle(
                              color: Color(0xFF14171C),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: onOpenFlowHistory,
                            behavior: HitTestBehavior.opaque,
                            child: const Row(
                              children: [
                                Text(
                            '전체보기',
                            style: TextStyle(
                              color: Color(0xFF97A1AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                                SizedBox(width: 2),
                                Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Color(0xFF97A1AF),
                          ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (recentFlow.isEmpty)
                        const _AssetSimpleEmpty(
                          title: '최근 자금 흐름이 없습니다.',
                          subtitle: '내역이 쌓이면 최근 변화가 이곳에 정리됩니다.',
                        )
                      else
                        ...List.generate(recentFlow.length, (index) {
                          return Column(
                            children: [
                              _RecentAssetFlowRow(entry: recentFlow[index]),
                              if (index != recentFlow.length - 1)
                                const Divider(
                                  height: 20,
                                  thickness: 1,
                                  color: Color(0xFFE9EDF3),
                                ),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<LedgerEntry> _buildUpcomingFixedExpenses(
  List<LedgerEntry> entries, {
  required DateTime now,
  required DateTime startOfToday,
}) {
  final futureFixed = entries
      .where(
        (entry) =>
            entry.type == EntryType.expense &&
            !entry.date.isBefore(startOfToday) &&
            _looksLikeFixedExpense(entry),
      )
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final groups = <String, List<LedgerEntry>>{};
  for (final entry in entries.where((item) => item.type == EntryType.expense)) {
    groups.putIfAbsent(_fixedExpenseSignature(entry), () => <LedgerEntry>[]).add(entry);
  }

  final projected = <LedgerEntry>[];
  for (final group in groups.values) {
    group.sort((a, b) => b.date.compareTo(a.date));
    final sample = group.first;
    final explicitFixed = _looksLikeFixedExpense(sample);
    final hasMonthlyPattern = _hasMonthlyRecurringPattern(group);
    if (!explicitFixed && !hasMonthlyPattern) continue;

    final dueDay = group.first.date.day;
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final projectedDate = DateTime(
      now.year,
      now.month,
      math.min(dueDay, lastDayOfMonth),
      group.first.date.hour,
      group.first.date.minute,
    );
    if (projectedDate.isBefore(startOfToday)) continue;

    final alreadyOccurredThisMonth = group.any(
      (entry) =>
          entry.date.year == now.year &&
          entry.date.month == now.month &&
          entry.date.day == projectedDate.day,
    );
    if (alreadyOccurredThisMonth) continue;

    final sameFutureAlreadyExists = futureFixed.any(
      (entry) => _fixedExpenseSignature(entry) == _fixedExpenseSignature(sample),
    );
    if (sameFutureAlreadyExists) continue;

    projected.add(
      LedgerEntry(
        id: 'projected:${sample.id}:$projectedDate',
        title: sample.title,
        amount: sample.amount,
        category: sample.category,
        note: sample.note,
        attachmentPaths: const [],
        type: sample.type,
        date: projectedDate,
        createdAt: sample.createdAt,
      ),
    );
  }

  final merged = [...futureFixed, ...projected];
  merged.sort((a, b) => a.date.compareTo(b.date));
  final seen = <String>{};
  return merged.where((entry) {
    final key = '${_fixedExpenseSignature(entry)}|${entry.date.year}-${entry.date.month}-${entry.date.day}';
    if (!seen.add(key)) return false;
    return true;
  }).toList();
}

String _fixedExpenseSignature(LedgerEntry entry) =>
    '${entry.title.trim().toLowerCase()}|${entry.category.trim().toLowerCase()}';

bool _hasMonthlyRecurringPattern(List<LedgerEntry> group) {
  if (group.length < 2) return false;
  final sorted = List<LedgerEntry>.from(group)..sort((a, b) => b.date.compareTo(a.date));
  for (var index = 0; index < sorted.length - 1; index++) {
    final diff = sorted[index].date.difference(sorted[index + 1].date).inDays.abs();
    if (diff >= 25 && diff <= 35) return true;
  }
  return false;
}

bool _looksLikeFixedExpense(LedgerEntry entry) {
  final combined = '${entry.title} ${entry.category} ${entry.note}'.toLowerCase();
  const fixedKeywords = [
    '고정',
    '자동이체',
    '카드대금',
    '통신',
    '보험',
    '관리비',
    '월세',
    '구독',
    '정기',
    '납부',
    '공과금',
    '대출',
    '할부',
    '렌탈',
    '학원',
  ];
  return fixedKeywords.any(combined.contains);
}

class AssetFlowHistoryPage extends StatelessWidget {
  const AssetFlowHistoryPage({
    super.key,
    required this.entries,
    required this.onBack,
  });

  final List<LedgerEntry> entries;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final recentFlow = List<LedgerEntry>.from(entries)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          _CompactPageHeader(
            title: '최근 자금 흐름',
            onBack: onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _AssetSoftCard(
                  child: recentFlow.isEmpty
                      ? const _AssetSimpleEmpty(
                          title: '최근 자금 흐름이 없습니다.',
                          subtitle: '내역이 쌓이면 최근 변화가 이곳에 정리됩니다.',
                        )
                      : Column(
                          children: List.generate(recentFlow.length, (index) {
                            return Column(
                              children: [
                                _RecentAssetFlowRow(entry: recentFlow[index]),
                                if (index != recentFlow.length - 1)
                                  const Divider(
                                    height: 20,
                                    thickness: 1,
                                    color: Color(0xFFE9EDF3),
                                  ),
                              ],
                            );
                          }),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyInfoPage extends StatelessWidget {
  const PrivacyInfoPage({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          _CompactPageHeader(title: '개인정보 및 저장 안내', onBack: onBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                const _SettingsInfoCard(
                  title: '서버 저장 방식',
                  body:
                      '지갑지켜는 기본적으로 비회원 사용자도 고유 시리얼 코드로 users 테이블에 먼저 생성하고, 이후 내역/메모/문자 설정 데이터를 해당 사용자에 묶어 저장합니다.',
                ),
                const SizedBox(height: 12),
                const _SettingsInfoCard(
                  title: '문자 분석 개선 데이터',
                  body:
                      '문자 분석 개선 데이터 제공을 켠 경우에만 감지된 금융 문자 원문을 암호화해 서버에 전송합니다. 이 데이터는 규칙 기반 파서 개선 목적으로만 사용됩니다.',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE6EAF0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '개인정보처리방침 주소',
                        style: TextStyle(
                          color: Color(0xFF14171C),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        _walletKeeperPrivacyUri,
                        style: const TextStyle(
                          color: Color(0xFF5B6470),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: () async {
                          await Clipboard.setData(
                            const ClipboardData(text: _walletKeeperPrivacyUri),
                          );
                          await showAppToast('주소를 복사했습니다.');
                        },
                        child: const Text('주소 복사'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MemoEditorPage extends StatefulWidget {
  const MemoEditorPage({
    super.key,
    this.existing,
    required this.month,
    required this.onBack,
    required this.onSave,
  });

  final WalletKeeperMemo? existing;
  final DateTime month;
  final VoidCallback onBack;
  final Future<void> Function(WalletKeeperMemo memo) onSave;

  @override
  State<MemoEditorPage> createState() => _MemoEditorPageState();
}

class _MemoEditorPageState extends State<MemoEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _saving = false;

  bool get hasUnsavedChanges {
    if (_saving) return false;
    final sourceTitle = widget.existing?.title ?? '';
    final sourceContent = widget.existing?.content ?? '';
    return _titleController.text.trim() != sourceTitle.trim() ||
        _contentController.text.trim() != sourceContent.trim();
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _contentController = TextEditingController(text: widget.existing?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<bool> confirmDiscardIfNeeded() async {
    if (!hasUnsavedChanges) return true;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '작성 중인 내용이 있습니다',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        content: const Text(
          '정말로 나가시겠습니까?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE76158),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '나가기',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    return shouldLeave == true;
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    final title = _titleController.text.trim().isEmpty
        ? (content.isEmpty ? '메모' : content.split('\n').first)
        : _titleController.text.trim();
    if (content.isEmpty) {
      await showAppToast('메모 내용을 입력해주세요.');
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    await widget.onSave(
      WalletKeeperMemo(
        id: widget.existing?.id ?? now.microsecondsSinceEpoch.toString(),
        title: title,
        content: content,
        monthKey: DateFormat('yyyy-MM').format(widget.month),
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          _CompactPageHeader(title: '메모 작성', onBack: widget.onBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE6EAF0)),
                  ),
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: Color(0xFF14171C),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '제목',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE6EAF0)),
                  ),
                  child: TextField(
                    controller: _contentController,
                    minLines: 12,
                    maxLines: 18,
                    style: const TextStyle(
                      color: Color(0xFF14171C),
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '${DateFormat('yyyy년 M월', 'ko_KR').format(widget.month)} 메모를 입력하세요.',
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF343A44),
                        side: const BorderSide(color: Color(0xFFD4DAE3)),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6A5F),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(_saving ? '저장 중' : '저장'),
                    ),
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

class BudgetSettingsSheet extends StatefulWidget {
  const BudgetSettingsSheet({
    super.key,
    required this.month,
    required this.initialBudgets,
    required this.categorySuggestions,
    required this.onSave,
  });

  final DateTime month;
  final List<WalletKeeperBudgetSetting> initialBudgets;
  final List<String> categorySuggestions;
  final Future<void> Function(List<WalletKeeperBudgetSetting> budgets) onSave;

  @override
  State<BudgetSettingsSheet> createState() => _BudgetSettingsSheetState();
}

class _BudgetSettingsSheetState extends State<BudgetSettingsSheet> {
  final List<_BudgetDraftRow> _rows = [];
  bool _saving = false;
  int? _activeRowIndex;

  @override
  void initState() {
    super.initState();
    if (widget.initialBudgets.isEmpty) {
      _rows.add(_BudgetDraftRow.empty());
    } else {
      _rows.addAll(
        widget.initialBudgets.map(
          (budget) => _BudgetDraftRow.fromBudget(budget),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(_BudgetDraftRow.empty());
      _activeRowIndex = _rows.length - 1;
    });
  }

  void _removeRow(int index) {
    final row = _rows.removeAt(index);
    row.dispose();
    if (_rows.isEmpty) {
      _rows.add(_BudgetDraftRow.empty());
    }
    setState(() {
      if (_activeRowIndex != null && _activeRowIndex! >= _rows.length) {
        _activeRowIndex = _rows.length - 1;
      }
    });
  }

  void _applySuggestion(String suggestion) {
    if (_rows.isEmpty) return;
    final targetIndex = _activeRowIndex ?? (_rows.length - 1);
    _rows[targetIndex].categoryController.text = suggestion;
    setState(() {
      _activeRowIndex = targetIndex;
    });
  }

  Future<void> _save() async {
    final monthKey = DateFormat('yyyy-MM').format(widget.month);
    final now = DateTime.now();
    final budgets = _rows
        .map((row) {
          final category = row.categoryController.text.trim();
          final digits = row.amountController.text.replaceAll(',', '').trim();
          final amount = double.tryParse(digits) ?? 0;
          if (category.isEmpty || amount <= 0) return null;
          return WalletKeeperBudgetSetting(
            id: row.id,
            category: category,
            amount: amount,
            monthKey: monthKey,
            createdAt: row.createdAt,
            updatedAt: now,
          );
        })
        .whereType<WalletKeeperBudgetSetting>()
        .toList();
    setState(() => _saving = true);
    await widget.onSave(budgets);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          _CompactPageHeader(
            title: '${DateFormat('M월', 'ko_KR').format(widget.month)} 예산설정',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.categorySuggestions.map((category) {
                    return ActionChip(
                      label: Text(
                        category,
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE5EAF1)),
                      onPressed: () => _applySuggestion(category),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                ..._rows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE5EAF1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: row.categoryController,
                            onTap: () => setState(() => _activeRowIndex = index),
                            style: const TextStyle(
                              color: Color(0xFF20242B),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: '분류 입력',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: row.amountController,
                            onTap: () => setState(() => _activeRowIndex = index),
                            keyboardType: TextInputType.number,
                            inputFormatters: const [_ThousandsSeparatorInputFormatter()],
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF20242B),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: '예산',
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: _rows.length == 1 ? null : () => _removeRow(index),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Color(0xFF9AA3B2),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: _addRow,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE76158),
                    side: const BorderSide(color: Color(0xFFFFD2CD)),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    '분류별 예산 추가',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A5F),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(_saving ? '저장 중' : '저장'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetDraftRow {
  _BudgetDraftRow({
    required this.id,
    required this.createdAt,
    required this.categoryController,
    required this.amountController,
  });

  factory _BudgetDraftRow.empty() {
    return _BudgetDraftRow(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      categoryController: TextEditingController(),
      amountController: TextEditingController(),
    );
  }

  factory _BudgetDraftRow.fromBudget(WalletKeeperBudgetSetting budget) {
    return _BudgetDraftRow(
      id: budget.id,
      createdAt: budget.createdAt,
      categoryController: TextEditingController(text: budget.category),
      amountController: TextEditingController(
        text: _ThousandsSeparatorInputFormatter.formatDigits(
          budget.amount.round().toString(),
        ),
      ),
    );
  }

  final String id;
  final DateTime createdAt;
  final TextEditingController categoryController;
  final TextEditingController amountController;

  void dispose() {
    categoryController.dispose();
    amountController.dispose();
  }
}

class _SocialLoginButtonTile extends StatelessWidget {
  const _SocialLoginButtonTile({
    required this.label,
    required this.provider,
    required this.active,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.iconPath,
    required this.onTap,
    this.enabled = true,
    this.disabledLabel,
  });

  final String label;
  final String provider;
  final bool active;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final String iconPath;
  final Future<void> Function() onTap;
  final bool enabled;
  final String? disabledLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (!enabled || active) ? null : () => onTap(),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: foregroundColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borderColor == Colors.transparent
                ? BorderSide.none
                : BorderSide(color: borderColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                !enabled
                    ? (disabledLabel ?? '$label (준비중)')
                    : active
                        ? '${_providerLabel(provider)} 연결됨'
                        : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 28),
          ],
        ),
      ),
    );
  }
}

String _providerLabel(String provider) {
  switch (provider) {
    case 'kakao':
      return '카카오';
    case 'google':
      return '구글';
    case 'naver':
      return '네이버';
    case 'apple':
      return '애플';
    default:
      return provider;
  }
}

class _SettingsMenuSection extends StatelessWidget {
  const _SettingsMenuSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6F7782),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6EAF0)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsMenuTile extends StatelessWidget {
  const _SettingsMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE6EAF0))),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF14171C)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF14171C),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF7B8491),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF9BA3AF),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetSimpleEmpty extends StatelessWidget {
  const _AssetSimpleEmpty({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF14171C),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF7B8491),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetSoftCard extends StatelessWidget {
  const _AssetSoftCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100A2540),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _UpcomingExpenseRow extends StatelessWidget {
  const _UpcomingExpenseRow({
    required this.entry,
  });

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final accent = _assetAccentForCategory(entry.category, entry.type);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            _assetIconForCategory(entry.category),
            size: 19,
            color: accent,
          ),
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
                style: const TextStyle(
                  color: Color(0xFF14171C),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${DateFormat('M.d').format(entry.date)} · ${entry.category}',
                style: const TextStyle(
                  color: Color(0xFF8D97A5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
          Text(
            _formatAssetAmount(entry.amount),
          style: TextStyle(
            color: entry.type == EntryType.expense
                ? const Color(0xFFFF6A5F)
                : const Color(0xFF2F6BFF),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AssetFlowMetricRow extends StatelessWidget {
  const _AssetFlowMetricRow({
    required this.label,
    required this.color,
    required this.amount,
    required this.amountColor,
    required this.ratio,
  });

  final String label;
  final Color color;
  final String amount;
  final Color amountColor;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7D8896),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                color: amountColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _AssetProgressBar(ratio: ratio, color: color),
      ],
    );
  }
}

class _AssetProgressBar extends StatelessWidget {
  const _AssetProgressBar({
    required this.ratio,
    required this.color,
  });

  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 16,
          child: Stack(
          children: [
            Container(color: const Color(0xFFE9EDF3)),
            FractionallySizedBox(
              widthFactor: ratio.clamp(0.0, 1.0),
              child: Container(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentAssetFlowRow extends StatelessWidget {
  const _RecentAssetFlowRow({
    required this.entry,
  });

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final accent = _assetAccentForCategory(entry.category, entry.type);
    final prefix = entry.type == EntryType.expense ? '-' : '+';
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            _assetIconForCategory(entry.category),
            size: 19,
            color: accent,
          ),
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
                style: const TextStyle(
                  color: Color(0xFF14171C),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${DateFormat('M.d HH:mm').format(entry.date)} · ${entry.category}',
                style: const TextStyle(
                  color: Color(0xFF8D97A5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
          Text(
            '$prefix${_formatAssetAmount(entry.amount)}',
            style: TextStyle(
              color: entry.type == EntryType.expense
                  ? const Color(0xFFFF6A5F)
                : const Color(0xFF2F6BFF),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

String _formatAssetAmount(double amount) {
  return '${formatCurrency(amount).replaceAll('₩', '').trim()}원';
}

Color _assetAccentForCategory(String category, EntryType type) {
  final normalized = category.toLowerCase();
  if (normalized.contains('카드')) return const Color(0xFFFF6A5F);
  if (normalized.contains('고정') || normalized.contains('자동')) {
    return const Color(0xFFFFA15E);
  }
  if (normalized.contains('문자')) return const Color(0xFF68A9FF);
  if (normalized.contains('교통')) return const Color(0xFFFFC04D);
  return type == EntryType.income
      ? const Color(0xFF68A9FF)
      : const Color(0xFF29B15F);
}

IconData _assetIconForCategory(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('카드')) return Icons.credit_card_rounded;
  if (normalized.contains('고정') || normalized.contains('자동')) {
    return Icons.alarm_rounded;
  }
  if (normalized.contains('문자')) return Icons.sms_outlined;
  if (normalized.contains('교통')) return Icons.local_taxi_rounded;
  if (normalized.contains('식비')) return Icons.ramen_dining_rounded;
  return Icons.account_balance_wallet_rounded;
}

class WalletKeeperPhotoPickerPage extends StatefulWidget {
  const WalletKeeperPhotoPickerPage({
    super.key,
    required this.initialPaths,
  });

  final List<String> initialPaths;

  @override
  State<WalletKeeperPhotoPickerPage> createState() =>
      _WalletKeeperPhotoPickerPageState();
}

class _WalletKeeperPhotoPickerPageState
    extends State<WalletKeeperPhotoPickerPage> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  final ValueNotifier<List<String>> _selectedAssetIds =
      ValueNotifier<List<String>>(<String>[]);
  late List<String> _selectedPaths;
  final ScrollController _scrollController = ScrollController();
  List<AssetPathEntity> _albums = const <AssetPathEntity>[];
  AssetPathEntity? _currentAlbum;
  List<AssetEntity> _mediaList = const <AssetEntity>[];
  bool _loading = true;
  bool _permissionDenied = false;
  bool _waitingForSettingsReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedPaths = List<String>.from(widget.initialPaths);
    _loadAlbums();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _selectedAssetIds.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _waitingForSettingsReturn) {
      _waitingForSettingsReturn = false;
      _loadAlbums();
    }
  }

  bool _isPhotoPermissionError(Object error) {
    if (error is! PlatformException) {
      return false;
    }
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    return code.contains('permission') ||
        message.contains('permission') ||
        message.contains('denied');
  }

  Future<PermissionStatus> _requestGalleryPermissionStatus() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return PermissionStatus.granted;
    }
    var status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) {
      return status;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return status;
    }
    status = await Permission.photos.request();
    return status;
  }

  Future<bool> _requestGalleryPermissionSafely() async {
    final status = await _requestGalleryPermissionStatus();
    return status.isGranted || status.isLimited;
  }

  Future<void> _handleGalleryPermissionRetry() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      await _loadAlbums();
      return;
    }
    PermissionStatus status;
    try {
      status = await Permission.photos.request();
    } on PlatformException {
      _waitingForSettingsReturn = true;
      await openAppSettings();
      return;
    }
    if (status.isGranted || status.isLimited) {
      await _loadAlbums();
      return;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      _waitingForSettingsReturn = true;
      await openAppSettings();
      return;
    }
    await showAppToast('갤러리 권한을 허용해야 사진을 선택할 수 있습니다.');
    if (!mounted) return;
    setState(() {
      _permissionDenied = true;
      _loading = false;
    });
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _loading = true;
      _permissionDenied = false;
    });
    try {
      final hasPermission = await _requestGalleryPermissionSafely();
      if (!hasPermission) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _permissionDenied = true;
        });
        return;
      }
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          imageOption: const FilterOption(
            sizeConstraint: SizeConstraint(ignoreSize: true),
          ),
        ),
      );
      if (!mounted) return;
      _albums = albums;
      _currentAlbum = albums.isEmpty ? null : albums.first;
      await _loadImages();
    } catch (error) {
      if (!mounted) return;
      if (_isPhotoPermissionError(error)) {
        setState(() {
          _loading = false;
          _permissionDenied = true;
        });
        return;
      }
      rethrow;
    }
  }

  Future<void> _loadImages() async {
    final album = _currentAlbum;
    if (album == null) {
      if (!mounted) return;
      setState(() {
        _mediaList = const <AssetEntity>[];
        _loading = false;
      });
      return;
    }
    try {
      final totalCount = await album.assetCountAsync;
      final media = await album.getAssetListRange(start: 0, end: totalCount);
      if (!mounted) return;
      setState(() {
        _mediaList = media;
        _loading = false;
      });
      await _restoreSelections();
    } catch (error) {
      if (!mounted) return;
      if (_isPhotoPermissionError(error)) {
        setState(() {
          _mediaList = const <AssetEntity>[];
          _loading = false;
          _permissionDenied = true;
        });
        return;
      }
      rethrow;
    }
  }

  Future<void> _restoreSelections() async {
    if (_selectedPaths.isEmpty || _mediaList.isEmpty) {
      _selectedAssetIds.value = <String>[];
      return;
    }
    final restored = <String>[];
    for (final selectedPath in _selectedPaths) {
      final selectedName = selectedPath.split(Platform.pathSeparator).last;
      for (final media in _mediaList) {
        final title = media.title ?? '';
        if (title == selectedName) {
          restored.add(media.id);
          break;
        }
        final file = await media.file;
        if (file != null &&
            (file.path == selectedPath ||
                file.path.split(Platform.pathSeparator).last == selectedName)) {
          restored.add(media.id);
          break;
        }
      }
    }
    _selectedAssetIds.value = restored;
  }

  void _handleAssetTap(AssetEntity media) {
    final next = List<String>.from(_selectedAssetIds.value);
    if (next.contains(media.id)) {
      next.remove(media.id);
    } else {
      next.add(media.id);
    }
    _selectedAssetIds.value = next;
  }

  Future<void> _pickFromCamera() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );
      if (file == null || !mounted) return;
      if (!_selectedPaths.contains(file.path)) {
        _selectedPaths = [..._selectedPaths, file.path];
      }
      Navigator.of(context).pop(_selectedPaths);
    } catch (_) {
      await showAppToast('카메라를 열 수 없습니다.');
    }
  }

  Future<void> _completeSelection() async {
    final selectedIds = _selectedAssetIds.value;
    if (selectedIds.isEmpty) {
      Navigator.of(context).pop(_selectedPaths);
      return;
    }
    final imagePaths = <String>[];
    for (final imageId in selectedIds) {
      final media = _mediaList.cast<AssetEntity?>().firstWhere(
            (item) => item?.id == imageId,
            orElse: () => null,
          );
      if (media == null) continue;
      final file = await media.file;
      if (file != null) {
        imagePaths.add(file.path);
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(imagePaths);
  }

  void _showAlbumSelector() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DEE6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '앨범',
                style: TextStyle(
                  color: Color(0xFF14171C),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ..._albums.map((album) {
                final selected = album == _currentAlbum;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    album.name,
                    style: TextStyle(
                      color: const Color(0xFF14171C),
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_rounded, color: Color(0xFFFF6A5F))
                      : null,
                  onTap: () async {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentAlbum = album;
                      _loading = true;
                    });
                    await _loadImages();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Color(0xFFB7BFCA),
            ),
            const SizedBox(height: 16),
            const Text(
              '갤러리 접근 권한이 필요합니다',
              style: TextStyle(
                color: Color(0xFF14171C),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '사진을 선택하려면 갤러리 접근을 허용해야 합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7B8491),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _handleGalleryPermissionRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A5F),
                minimumSize: const Size.fromHeight(46),
              ),
              child: const Text('권한 확인하기'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                _waitingForSettingsReturn = true;
                await PhotoManager.openSetting();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6A5F),
                minimumSize: const Size.fromHeight(46),
                side: const BorderSide(color: Color(0xFFFF6A5F)),
              ),
              child: const Text('설정에서 권한 허용하기'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: _albums.isEmpty ? null : _showAlbumSelector,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentAlbum?.name ?? '최근항목',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
            ],
          ),
        ),
        actions: [
          ValueListenableBuilder<List<String>>(
            valueListenable: _selectedAssetIds,
            builder: (context, selected, child) {
              return TextButton(
                onPressed: selected.isNotEmpty || _selectedPaths.isNotEmpty
                    ? _completeSelection
                    : null,
                child: Text(
                  '완료',
                  style: TextStyle(
                    color: selected.isNotEmpty || _selectedPaths.isNotEmpty
                        ? const Color(0xFFFF6A5F)
                        : const Color(0xFFB7BFCA),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _permissionDenied
              ? _buildPermissionDeniedView()
              : Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(
                          left: 2,
                          top: 2,
                          right: 2,
                          bottom: 2,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: _mediaList.length,
                        itemBuilder: (context, index) {
                          final media = _mediaList[index];
                          return _WalletKeeperGridImageItem(
                            key: ValueKey(media.id),
                            media: media,
                            selectedAssetIds: _selectedAssetIds,
                            onTap: () => _handleAssetTap(media),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 32,
                              color: Color(0xFF5E6672),
                            ),
                            onPressed: _pickFromCamera,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _WalletKeeperGridImageItem extends StatelessWidget {
  const _WalletKeeperGridImageItem({
    super.key,
    required this.media,
    required this.selectedAssetIds,
    required this.onTap,
  });

  final AssetEntity media;
  final ValueNotifier<List<String>> selectedAssetIds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: selectedAssetIds,
      builder: (context, selected, child) {
        final isSelected = selected.contains(media.id);
        final selectionNumber = isSelected ? selected.indexOf(media.id) + 1 : 0;
        return GestureDetector(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<Uint8List?>(
                future: media.thumbnailDataWithSize(
                  const ThumbnailSize.square(300),
                ),
                builder: (context, snapshot) {
                  final bytes = snapshot.data;
                  if (bytes == null || bytes.isEmpty) {
                    return Container(
                      color: const Color(0xFFF2F4F7),
                    );
                  }
                  return Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  );
                },
              ),
              if (isSelected)
                Container(
                  color: const Color(0x66000000),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF6A5F)
                        : Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFD8DEE6),
                      width: 1.4,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isSelected ? '$selectionNumber' : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsInfoCard extends StatelessWidget {
  const _SettingsInfoCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF14171C),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF5F6772),
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsKeyValueCard extends StatelessWidget {
  const _SettingsKeyValueCard({required this.rows});

  final List<_SettingsKeyValue> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        row.label,
                        style: const TextStyle(
                          color: Color(0xFF7B8491),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: const TextStyle(
                          color: Color(0xFF14171C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SettingsKeyValue {
  const _SettingsKeyValue(this.label, this.value);

  final String label;
  final String value;
}

