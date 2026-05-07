part of '../main.dart';

class _BottomOverlayScope extends InheritedWidget {
  const _BottomOverlayScope({
    required this.overlayHeight,
    required super.child,
  });

  final double overlayHeight;

  @override
  bool updateShouldNotify(covariant _BottomOverlayScope oldWidget) {
    return oldWidget.overlayHeight != overlayHeight;
  }

  static double maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_BottomOverlayScope>()?.overlayHeight ?? 0;
  }
}

double bottomOverlayHeightOf(BuildContext context) {
  return _BottomOverlayScope.maybeOf(context);
}

class WalletKeeperPanel extends StatelessWidget {
  const WalletKeeperPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9EDF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class WalletKeeperHeaderAction extends StatelessWidget {
  const WalletKeeperHeaderAction({
    super.key,
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
      child: Ink(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7EBF2)),
        ),
        child: Icon(icon, color: const Color(0xFF1F2937), size: 16),
      ),
    );
  }
}

class WalletKeeperTopSection extends StatelessWidget {
  const WalletKeeperTopSection({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    this.trailing,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Row(
              children: [
                GestureDetector(
                  onTap: onPrevious,
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 24,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 1),
                Text(
                  DateFormat('yyyy년 M월', 'ko_KR').format(month),
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 1),
                GestureDetector(
                  onTap: onNext,
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                trailing ?? const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WalletKeeperSegmentTabs extends StatelessWidget {
  const WalletKeeperSegmentTabs({
    super.key,
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
      height: 52,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      labels[i],
                      style: TextStyle(
                        color: selectedIndex == i
                            ? const Color(0xFF111827)
                            : const Color(0xFF9AA3B2),
                        fontSize: 16,
                        fontWeight: selectedIndex == i
                            ? FontWeight.w800
                            : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 3,
                      width: double.infinity,
                      color: selectedIndex == i
                          ? const Color(0xFFFF695D)
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

class WalletKeeperSummaryStrip extends StatelessWidget {
  const WalletKeeperSummaryStrip({
    super.key,
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
          top: BorderSide(color: Color(0xFFE5EAF1)),
          bottom: BorderSide(color: Color(0xFFE5EAF1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(
              label: '수입',
              value: formatCurrency(income),
              color: const Color(0xFF2F80ED),
            ),
          ),
          Expanded(
            child: _SummaryCell(
              label: '지출',
              value: formatCurrency(expense),
              color: const Color(0xFFFF695D),
            ),
          ),
          Expanded(
            child: _SummaryCell(
              label: '합계',
              value: total <= 0 ? '-${formatCurrency(total.abs())}' : formatCurrency(total),
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
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
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF556070),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
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

class WalletKeeperSectionLabel extends StatelessWidget {
  const WalletKeeperSectionLabel({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing case final Widget trailingWidget) trailingWidget,
      ],
    );
  }
}

class WalletKeeperEmptyState extends StatelessWidget {
  const WalletKeeperEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.plain = false,
  });

  final String message;
  final IconData icon;
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1EF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: const Color(0xFFFF695D), size: 26),
        ),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
            height: 1.55,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    if (plain) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        child: content,
      );
    }
    return WalletKeeperPanel(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      child: content,
    );
  }
}
