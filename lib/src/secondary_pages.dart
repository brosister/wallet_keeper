part of '../main.dart';

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

class _StatsPageState extends State<StatsPage> {
  late DateTime _selectedMonth;
  int _selectedKind = 1;
  int? _selectedCategoryIndex;
  final ScrollController _categoryScrollController = ScrollController();
  final List<GlobalKey> _categoryRowKeys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _moveMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
      _selectedCategoryIndex = 0;
    });
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
    setState(() {
      _selectedCategoryIndex = clampedIndex;
    });
    if (!shouldScrollList) return;
    final context = _categoryRowKeys[clampedIndex].currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
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

  @override
  Widget build(BuildContext context) {
    final monthEntries = widget.entries
        .where(
          (entry) =>
              entry.date.year == _selectedMonth.year &&
              entry.date.month == _selectedMonth.month,
        )
        .toList();
    final incomeTotal = monthEntries
        .where((entry) => entry.type == EntryType.income)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final expenseTotal = monthEntries
        .where((entry) => entry.type == EntryType.expense)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final targetType = _selectedKind == 0 ? EntryType.income : EntryType.expense;
    final filtered = monthEntries.where((entry) => entry.type == targetType).toList();
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
                    GestureDetector(
                      onTap: () => _moveMonth(-1),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 30,
                        color: Color(0xFF14171C),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('yyyy년 M월', 'ko_KR').format(_selectedMonth),
                      style: const TextStyle(
                        color: Color(0xFF14171C),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 2),
                    GestureDetector(
                      onTap: () => _moveMonth(1),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 30,
                        color: Color(0xFF14171C),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFD9DEE6),
                          width: 1.1,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            '월간',
                            style: TextStyle(
                              color: Color(0xFF14171C),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF14171C),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 18),
              children: [
                Row(
                  children: [
                    _StatsToggleChip(
                      label: '수입',
                      value: formatCurrency(incomeTotal),
                      selected: _selectedKind == 0,
                      onTap: () => _selectKind(0),
                    ),
                    const SizedBox(width: 8),
                    _StatsToggleChip(
                      label: '지출',
                      value: formatCurrency(expenseTotal),
                      selected: _selectedKind == 1,
                      onTap: () => _selectKind(1),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
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
                else ...[
                  _StatsOverviewCard(
                    items: items,
                    total: total,
                    targetType: targetType,
                    selectedIndex: selectedIndex,
                    selectedItem: selectedItem,
                    selectedRatio: selectedRatio,
                    onSegmentTap: (index) => _selectCategory(
                      index,
                      itemCount: items.length,
                      shouldScrollList: true,
                    ),
                    animationKey:
                        '${_selectedMonth.year}-${_selectedMonth.month}-$_selectedKind-${items.length}-${total.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE6EAF0)),
                    ),
                    child: Column(
                      children: items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final ratio = total == 0 ? 0.0 : item.value / total;
                        return _StatsCategoryRow(
                          key: _categoryRowKeys[index],
                          item: item,
                          ratio: ratio,
                          isLast: index == items.length - 1,
                          color: _statsPalette[index % _statsPalette.length],
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
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsToggleChip extends StatelessWidget {
  const _StatsToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.value,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF1EF) : const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFFFFD5D1) : const Color(0xFFE6EAF0),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFF14171C) : const Color(0xFF868A93),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: selected ? const Color(0xFFFF6A5F) : const Color(0xFF14171C),
                  fontSize: 12,
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

class _StatsOverviewCard extends StatelessWidget {
  const _StatsOverviewCard({
    required this.items,
    required this.total,
    required this.targetType,
    required this.animationKey,
    required this.selectedIndex,
    required this.selectedItem,
    required this.selectedRatio,
    required this.onSegmentTap,
  });

  final List<MapEntry<String, double>> items;
  final double total;
  final EntryType targetType;
  final String animationKey;
  final int selectedIndex;
  final MapEntry<String, double>? selectedItem;
  final double selectedRatio;
  final ValueChanged<int> onSegmentTap;

  @override
  Widget build(BuildContext context) {
    final focusItem = selectedItem ?? items.first;
    final focusRatio = selectedItem == null
        ? (total == 0 ? 0.0 : items.first.value / total)
        : selectedRatio;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    targetType == EntryType.income ? '수입 분석' : '지출 분석',
                    style: const TextStyle(
                      color: Color(0xFF14171C),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '총 ${formatCurrency(total)}',
                    style: const TextStyle(
                      color: Color(0xFF7D8591),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1EF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(focusRatio * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFFFF6A5F),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            key: ValueKey(animationKey),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (context, progress, _) {
              return GestureDetector(
                onTapUp: (details) {
                  final index = _StatsDonutPainter.hitTestSegment(
                    size: const Size(220, 220),
                    position: details.localPosition,
                    values: items.map((item) => item.value).toList(),
                  );
                  if (index != null) {
                    onSegmentTap(index);
                  }
                },
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: CustomPaint(
                    painter: _StatsDonutPainter(
                      values: items.map((item) => item.value).toList(),
                      colors: List.generate(
                        items.length,
                        (index) =>
                            _statsPalette[index % _statsPalette.length],
                      ),
                      progress: progress,
                      selectedIndex: selectedIndex,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        child: Column(
                          key: ValueKey('${focusItem.key}-${focusItem.value}'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_categoryEmoji(focusItem.key)} ${focusItem.key}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF14171C),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatCurrency(focusItem.value),
                              style: const TextStyle(
                                color: Color(0xFF14171C),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '전체의 ${(focusRatio * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Color(0xFF7D8591),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
          ),
        ],
      ),
    );
  }
}

class _StatsCategoryRow extends StatelessWidget {
  const _StatsCategoryRow({
    super.key,
    required this.item,
    required this.ratio,
    required this.isLast,
    required this.color,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final MapEntry<String, double> item;
  final double ratio;
  final bool isLast;
  final Color color;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final row = AnimatedScale(
      scale: selected ? 1.02 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF7F6) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : const Color(0xFFE6EAF0),
            ),
                          ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_categoryEmoji(item.key)} ${item.key}',
                    style: const TextStyle(
                      color: Color(0xFF14171C),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0).toDouble(),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F3F7),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(item.value),
                  style: const TextStyle(
                    color: Color(0xFF14171C),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(ratio * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF8B93A0),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                          ),
                        ),
              ],
            ),
          ],
        ),
      ),
    );
      return InkWell(
        onTap: onTap,
        child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: dimmed ? 0.42 : 1,
        child: ImageFiltered(
          imageFilter: dimmed
              ? ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8)
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
  });

  final List<double> values;
  final List<Color> colors;
  final double progress;
  final int selectedIndex;

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
    final outerRadius = size.width / 2 - 26;
    const maxStroke = 34.0;
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
    const baseStrokeWidth = 26.0;
    const selectedStrokeWidth = 34.0;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - selectedStrokeWidth,
    );
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = baseStrokeWidth
      ..color = const Color(0xFFF1F3F7);
    canvas.drawArc(rect, 0, math.pi * 2, false, backgroundPaint);
    var startAngle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final normalizedSweep = (values[i] / total) * math.pi * 2;
      final sweepAngle = normalizedSweep * progress;
      final isSelected = i == selectedIndex;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = isSelected ? selectedStrokeWidth : baseStrokeWidth
        ..color = isSelected ? colors[i] : colors[i].withValues(alpha: 0.24);
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += normalizedSweep;
    }
  }

  @override
  bool shouldRepaint(covariant _StatsDonutPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.colors != colors ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

const List<Color> _statsPalette = [
  Color(0xFFFF6A5F),
  Color(0xFFFFA26B),
  Color(0xFFFFD166),
  Color(0xFF7AD3A8),
  Color(0xFF6EC5FF),
  Color(0xFF9C8CFF),
];

String _categoryEmoji(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('교') || lower.contains('차')) return '🚕';
  if (lower.contains('식')) return '🍜';
  if (lower.contains('쇼')) return '🛍️';
  if (lower.contains('생')) return '🧴';
  return '💳';
}

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
    return InkWell(
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
    required this.onPasteMessage,
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
  final Future<void> Function() onPasteMessage;
  final Future<void> Function(Set<String> ids) onDeleteSelected;

  @override
  State<SmsInboxPage> createState() => _SmsInboxPageState();
}

class _SmsInboxPageState extends State<SmsInboxPage> {
  bool _importing = false;
  bool _deleteMode = false;
  final Set<String> _selectedIds = <String>{};

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
    final allSelected = widget.drafts.isNotEmpty && _selectedIds.length == widget.drafts.length;
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
              title: '문자함 (${widget.drafts.length})',
              onBack: _handleBackPressed,
              trailing: [
                _CompactHeaderButton(
                  icon: _deleteMode ? Icons.close_rounded : Icons.delete_outline_rounded,
                  onTap: widget.drafts.isEmpty
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
                    '휴대폰에 수신된 금융 문자가 자동 저장됩니다.\n문자 가져오기로 휴대폰에 저장된 문자를 가져올 수 있습니다. 설정 > 문자설정 > 문자 자동 입력 기능 On 으로 설정하시면 문자함을 거치지 않고 바로 등록할 수 있습니다.',
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
                            ..addAll(widget.drafts.map((draft) => draft.id));
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
                                      ..addAll(widget.drafts.map((draft) => draft.id));
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
                if (widget.drafts.isEmpty)
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
                  ...widget.drafts.map(
                    (draft) => InkWell(
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
                                        draft.note.replaceFirst(
                                          RegExp(r'^SMS 자동 감지\n발신:.*\n\n'),
                                          '',
                                        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            width: 44,
            height: 24,
            child: FittedBox(
              fit: BoxFit.fill,
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

  bool get hasUnsavedChanges {
    if (_saving) return false;
    final source = widget.existing;
    final draft = widget.smsDraft;
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
      _categoryController.text = draft.category;
      _noteController.text = cleanedNote;
      _type = draft.type;
      _date = draft.date;
      return;
    }
    _titleController.text = existing?.title ?? '';
    _setAmountText(existing?.amount.toStringAsFixed(0) ?? '');
    _categoryController.text = existing?.category ?? '';
    _noteController.text = existing?.note ?? '';
    _attachmentPaths = List<String>.from(existing?.attachmentPaths ?? const []);
    _type = existing?.type ?? EntryType.expense;
    _date = existing?.date ?? DateTime.now();
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
    final bottomOverlayHeight = bottomOverlayHeightOf(context);
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
                          onTap: () => setState(() => _type = type),
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
                          IconButton(
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
                if (_fromSmsDraft) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      '문자분석 개선이 필요하신가요?',
                      style: TextStyle(
                        color: const Color(0xFF9CA3AF).withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + bottomOverlayHeight),
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
                          child: OutlinedButton.icon(
                onPressed: () => widget.onCancel(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF343A44),
                              side: const BorderSide(color: Color(0xFFD4DAE3)),
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            label: const Text('건너뛰기'),
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
                            child: Text(_saving ? '저장 중' : '저장 (1/1)'),
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
              const SizedBox(width: 2),
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
  });

  final List<LedgerEntry> entries;
  final WalletKeeperUserSession? session;

  @override
  Widget build(BuildContext context) {
    final bottomInset = bottomOverlayHeightOf(context);
    final summary = LedgerSummary.fromEntries(entries);
    final thisMonthEntries = entries
        .where(
          (entry) =>
              entry.date.year == DateTime.now().year &&
              entry.date.month == DateTime.now().month,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final topCategories = summary.topCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          const _RootTabHeader(title: '자산'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 24),
              children: [
                Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE6EAF0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFFFECE9),
                  backgroundImage: session?.profileImage.isNotEmpty == true
                      ? NetworkImage(session!.profileImage)
                      : null,
                  child: session?.profileImage.isNotEmpty == true
                      ? null
                      : const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 26,
                          color: Color(0xFFFF6A5F),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session == null || session!.isGuest
                            ? '비회원 자산 요약'
                            : '${session!.providerLabel} 연동 자산 요약',
                        style: const TextStyle(
                          color: Color(0xFF14171C),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session?.email.isNotEmpty == true
                            ? session!.email
                            : '현재는 가계부 내역 기준으로 자금 흐름을 보여줍니다.',
                        style: const TextStyle(
                          color: Color(0xFF727B86),
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
                const SizedBox(height: 14),
                Row(
            children: [
              Expanded(
                child: _AssetMetricCard(
                  label: '이번 달 수입',
                  value: formatCurrency(summary.monthIncome),
                  valueColor: const Color(0xFF2F6BFF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AssetMetricCard(
                  label: '이번 달 지출',
                  value: formatCurrency(summary.monthExpense),
                  valueColor: const Color(0xFFFF6A5F),
                ),
              ),
            ],
          ),
                const SizedBox(height: 10),
                Row(
            children: [
              Expanded(
                child: _AssetMetricCard(
                  label: '순흐름',
                  value: formatCurrency(summary.balance),
                  valueColor: summary.balance >= 0
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD92D20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AssetMetricCard(
                  label: '이체 / 고정비',
                  value:
                      '${formatCurrency(summary.transferAmount)} / ${formatCurrency(summary.fixedExpense)}',
                  valueColor: const Color(0xFF14171C),
                ),
              ),
            ],
          ),
                const SizedBox(height: 18),
                _SettingsMenuSection(
            title: '상위 지출 카테고리',
            children: topCategories.isEmpty
                ? [
                    const _AssetEmptyTile(
                      title: '아직 지출 데이터가 없습니다.',
                      subtitle: '기록이 쌓이면 자산 흐름과 지출 비중을 여기서 확인할 수 있습니다.',
                    ),
                  ]
                : topCategories.take(5).map((entry) {
                    return _AssetCategoryTile(
                      title: entry.key,
                      amount: formatCurrency(entry.value),
                    );
                  }).toList(),
          ),
                const SizedBox(height: 18),
                _SettingsMenuSection(
            title: '최근 자금 흐름',
            children: thisMonthEntries.isEmpty
                ? [
                    const _AssetEmptyTile(
                      title: '이번 달 기록이 없습니다.',
                      subtitle: '내역을 추가하면 최근 흐름을 자산 탭에서도 바로 볼 수 있습니다.',
                    ),
                  ]
                : thisMonthEntries.take(5).map((entry) {
                    return _AssetLedgerTile(entry: entry);
                  }).toList(),
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

class _AssetMetricCard extends StatelessWidget {
  const _AssetMetricCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7B8491),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetCategoryTile extends StatelessWidget {
  const _AssetCategoryTile({
    required this.title,
    required this.amount,
  });

  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
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
          Text(
            amount,
            style: const TextStyle(
              color: Color(0xFFFF6A5F),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetLedgerTile extends StatelessWidget {
  const _AssetLedgerTile({
    required this.entry,
  });

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE6EAF0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    color: Color(0xFF14171C),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('M.d HH:mm').format(entry.date)} · ${entry.category}',
                  style: const TextStyle(
                    color: Color(0xFF7B8491),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(entry.amount),
            style: TextStyle(
              color: entry.type == EntryType.income
                  ? const Color(0xFF2F6BFF)
                  : const Color(0xFFFF6A5F),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetEmptyTile extends StatelessWidget {
  const _AssetEmptyTile({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF7B8491),
              fontSize: 11,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
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
    extends State<WalletKeeperPhotoPickerPage> {
  final ImagePicker _picker = ImagePicker();
  late List<String> _selectedPaths;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedPaths = List<String>.from(widget.initialPaths);
  }

  Future<void> _pickFromGallery() async {
    setState(() => _loading = true);
    try {
      final files = await _picker.pickMultiImage(
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );
      if (files.isEmpty || !mounted) return;
      final next = List<String>.from(_selectedPaths);
      for (final file in files) {
        if (!next.contains(file.path)) {
          next.add(file.path);
        }
      }
      setState(() {
        _selectedPaths = next;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFromCamera() async {
    setState(() => _loading = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );
      if (file == null || !mounted) return;
      setState(() {
        if (!_selectedPaths.contains(file.path)) {
          _selectedPaths = [..._selectedPaths, file.path];
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: Column(
        children: [
          _CompactPageHeader(
            title: '사진 추가',
            onBack: () => Navigator.of(context).pop(),
            trailing: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(_selectedPaths),
                child: const Text(
                  '완료',
                  style: TextStyle(
                    color: Color(0xFFFF6A5F),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PhotoPickerActionTile(
                        icon: Icons.photo_library_outlined,
                        title: '갤러리',
                        subtitle: '여러 장 선택',
                        onTap: _loading ? null : _pickFromGallery,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PhotoPickerActionTile(
                        icon: Icons.photo_camera_outlined,
                        title: '카메라',
                        subtitle: '즉시 촬영',
                        onTap: _loading ? null : _pickFromCamera,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE6EAF0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '선택된 사진 ${_selectedPaths.length}장',
                        style: const TextStyle(
                          color: Color(0xFF14171C),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_selectedPaths.isEmpty)
                        const Text(
                          '아직 선택된 사진이 없습니다.',
                          style: TextStyle(
                            color: Color(0xFF8D95A1),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _selectedPaths.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final path = _selectedPaths[index];
                            return Container(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(path),
                                      width: 62,
                                      height: 62,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 62,
                                        height: 62,
                                        color: const Color(0xFFE9EEF4),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.broken_image_outlined,
                                          color: Color(0xFF9AA3B2),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      path.split(Platform.pathSeparator).last,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF14171C),
                                        fontSize: 12,
                                        height: 1.35,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedPaths =
                                            List<String>.from(_selectedPaths)
                                              ..removeAt(index);
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Color(0xFF9AA3B2),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

class _PhotoPickerActionTile extends StatelessWidget {
  const _PhotoPickerActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6EAF0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: const Color(0xFFFF6A5F)),
            const SizedBox(height: 10),
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
