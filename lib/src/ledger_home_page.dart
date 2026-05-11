part of '../main.dart';

enum _ShellRouteKind {
  root,
  smsInbox,
  smsSettings,
  settingsProfile,
  settingsInquiryList,
  settingsInquiryDetail,
  settingsInquiryCompose,
  settingsTerms,
  assetUpcomingHistory,
  assetFlowHistory,
  editor,
}

enum _WalletKeeperCloudConflictAction {
  startFresh,
  loadRemote,
}

class _ShellRoute {
  const _ShellRoute.root()
      : kind = _ShellRouteKind.root,
        existing = null,
        smsDraft = null,
        inquiry = null;
  const _ShellRoute.smsInbox()
      : kind = _ShellRouteKind.smsInbox,
        existing = null,
        smsDraft = null,
        inquiry = null;
  const _ShellRoute.smsSettings()
      : kind = _ShellRouteKind.smsSettings,
        existing = null,
        smsDraft = null,
        inquiry = null;
  const _ShellRoute.settingsProfile()
      : kind = _ShellRouteKind.settingsProfile,
        existing = null,
        smsDraft = null,
        inquiry = null;
  const _ShellRoute.settingsInquiryList()
      : kind = _ShellRouteKind.settingsInquiryList,
        existing = null,
        smsDraft = null,
        inquiry = null;
  const _ShellRoute.settingsInquiryDetail({required this.inquiry})
      : kind = _ShellRouteKind.settingsInquiryDetail,
        existing = null,
        smsDraft = null;
  const _ShellRoute.settingsInquiryCompose()
      : kind = _ShellRouteKind.settingsInquiryCompose,
        existing = null,
        smsDraft = null,
        inquiry = null;
  const _ShellRoute.settingsTerms()
      : kind = _ShellRouteKind.settingsTerms,
        existing = null,
        smsDraft = null,
        inquiry = null;
  const _ShellRoute.assetUpcomingHistory()
      : kind = _ShellRouteKind.assetUpcomingHistory,
        existing = null,
        smsDraft = null,
        inquiry = null;
  const _ShellRoute.assetFlowHistory()
      : kind = _ShellRouteKind.assetFlowHistory,
        existing = null,
        smsDraft = null,
        inquiry = null;
  const _ShellRoute.editor({this.existing, this.smsDraft})
      : kind = _ShellRouteKind.editor,
        inquiry = null;

  final _ShellRouteKind kind;
  final LedgerEntry? existing;
  final WalletKeeperSmsDraft? smsDraft;
  final WalletKeeperInquiry? inquiry;
}

class LedgerHomePage extends StatefulWidget {
  const LedgerHomePage({
    super.key,
    required this.featureAccess,
    required this.onRequestFeatureAccess,
    required this.onRequireFeatureOnboarding,
  });

  final WalletKeeperFeatureAccess featureAccess;
  final Future<void> Function() onRequestFeatureAccess;
  final VoidCallback onRequireFeatureOnboarding;

  @override
  State<LedgerHomePage> createState() => _LedgerHomePageState();
}

class _LedgerHomePageState extends State<LedgerHomePage> with WidgetsBindingObserver {
  final LedgerRepository _repository = LedgerRepository();
  final WalletKeeperSmsAutomationRepository _smsAutomationRepository =
      WalletKeeperSmsAutomationRepository();
  final Telephony _telephony = Telephony.instance;
  final WalletKeeperSmsSettingsRepository _smsSettingsRepository =
      WalletKeeperSmsSettingsRepository();
  final WalletKeeperNotificationAccessRepository _notificationAccessRepository =
      const WalletKeeperNotificationAccessRepository();
  final WalletKeeperMemoRepository _memoRepository = WalletKeeperMemoRepository();
  final WalletKeeperBudgetRepository _budgetRepository =
      WalletKeeperBudgetRepository();
  final WalletKeeperInquiryRepository _inquiryRepository =
      WalletKeeperInquiryRepository();
  final WalletKeeperAccountRepository _accountRepository = WalletKeeperAccountRepository();
  final WalletKeeperCloudSyncRepository _cloudSyncRepository = WalletKeeperCloudSyncRepository();
  final WalletKeeperPushRepository _pushRepository = WalletKeeperPushRepository();

  List<LedgerEntry> _entries = const [];
  List<WalletKeeperMemo> _memos = const [];
  List<WalletKeeperBudgetSetting> _budgets = const [];
  List<WalletKeeperInquiry> _inquiries = const [];
  List<WalletKeeperSmsDraft> _smsDrafts = const [];
  WalletKeeperUserSession? _session;
  WalletKeeperSmsSettings _smsSettings = const WalletKeeperSmsSettings(
    smsReceiveEnabled: true,
    autoInputEnabled: false,
    showNotification: true,
    shareHeuristicReports: false,
    importWindowDays: 60,
  );
  Timer? _pendingMmsTimer;
  StreamSubscription<String>? _notificationRouteSubscription;
  int _selectedTab = 0;
  bool _smsListenerAttached = false;
  bool _financialAppNotificationEnabled = false;
  int _selectedOverviewTab = 0;
  int _overviewResetNonce = 0;
  final List<_ShellRoute> _routeStack = [const _ShellRoute.root()];
  final GlobalKey<_EntryEditorPageState> _editorPageKey = GlobalKey<_EntryEditorPageState>();
  final GlobalKey<_InquiryComposePageState> _inquiryComposePageKey =
      GlobalKey<_InquiryComposePageState>();
  DateTime? _lastBackPressedAt;

  _ShellRoute get _currentRoute =>
      _routeStack.isEmpty ? const _ShellRoute.root() : _routeStack.last;

  List<String> get _categorySuggestions {
    final values = <String>{};
    for (final entry in _entries) {
      final trimmed = entry.category.trim();
      if (trimmed.isNotEmpty) {
        values.add(trimmed);
      }
    }
    final list = values.toList()..sort();
    return list;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _bindSmsListenerIfNeeded();
    _startPendingMmsTimerIfNeeded();
    _notificationRouteSubscription = _notificationRouteController.stream.listen(
      (route) async {
        if (route != _smsInboxNotificationPayload) return;
        await _openSmsPageFromNotification();
      },
    );
  }

  @override
  void dispose() {
    _pendingMmsTimer?.cancel();
    _notificationRouteSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshFinancialAppNotificationAccess();
      _startPendingMmsTimerIfNeeded();
      _consumePendingRealtimeMessages();
      _consumeLaunchRoute();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _pendingMmsTimer?.cancel();
      _pendingMmsTimer = null;
    }
  }

  @override
  void didUpdateWidget(covariant LedgerHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.featureAccess.smsGranted != widget.featureAccess.smsGranted) {
      _bindSmsListenerIfNeeded();
      _startPendingMmsTimerIfNeeded();
    }
  }

  Future<void> _load() async {
    final loadedEntries = await _repository.load();
    final loadedMemos = await _memoRepository.load();
    final loadedBudgets = await _budgetRepository.load();
    final loadedDrafts = await _smsAutomationRepository.loadInboxDrafts();
    final loadedSettings = await _smsSettingsRepository.load();
    final financialNotificationEnabled =
        await _notificationAccessRepository.isFinancialAppNotificationEnabled();
    final session = await _accountRepository.bootstrapGuest();
    final remoteBundle = await _cloudSyncRepository.loadRemote();
    final loadedInquiries = await _loadInquiriesForSession(session);
    if (!mounted) return;
    setState(() {
      _entries = remoteBundle != null && loadedEntries.isEmpty ? remoteBundle.entries : loadedEntries;
      _memos = remoteBundle != null && loadedMemos.isEmpty ? remoteBundle.memos : loadedMemos;
      _budgets = remoteBundle != null && loadedBudgets.isEmpty ? remoteBundle.budgets : loadedBudgets;
      _inquiries = loadedInquiries;
      _smsDrafts = loadedDrafts;
      _smsSettings = remoteBundle?.smsSettings ?? loadedSettings;
      _financialAppNotificationEnabled = financialNotificationEnabled;
      _session = session;
    });
    if (remoteBundle != null && loadedEntries.isEmpty) {
      await _repository.save(remoteBundle.entries);
    }
    if (remoteBundle != null && loadedMemos.isEmpty) {
      await _memoRepository.save(remoteBundle.memos);
    }
    if (remoteBundle != null && loadedBudgets.isEmpty) {
      await _budgetRepository.save(remoteBundle.budgets);
    }
    if (remoteBundle != null) {
      await _smsSettingsRepository.save(remoteBundle.smsSettings);
    }
    unawaited(_registerPushTokenSilently());
    _startPendingMmsTimerIfNeeded();
    await _consumePendingRealtimeMessages();
    await _consumeLaunchRoute();
  }

  Future<void> _registerPushTokenSilently() async {
    try {
      await _pushRepository.registerCurrentDeviceToken();
    } catch (error, stackTrace) {
      debugPrint('Wallet Keeper FCM register failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _refreshFinancialAppNotificationAccess() async {
    final enabled =
        await _notificationAccessRepository.isFinancialAppNotificationEnabled();
    if (!mounted) return;
    if (_financialAppNotificationEnabled == enabled) return;
    setState(() {
      _financialAppNotificationEnabled = enabled;
    });
  }

  Future<void> _openFinancialAppNotificationSettings() async {
    final opened =
        await _notificationAccessRepository.openFinancialAppNotificationSettings();
    if (!opened && mounted) {
      await showAppToast('알림 접근 설정을 열 수 없습니다.');
      return;
    }
    if (mounted) {
      await showAppToast('금융 앱 알림 감지를 위해 알림 접근을 허용해주세요.');
    }
  }

  Future<void> _syncCloud() async {
    try {
      await _cloudSyncRepository.sync(
        entries: _entries,
        memos: _memos,
        budgets: _budgets,
        smsSettings: _smsSettings,
      );
    } catch (_) {}
  }

  WalletKeeperSyncBundle _currentLocalBundle() {
    return WalletKeeperSyncBundle(
      entries: _entries,
      memos: _memos,
      budgets: _budgets,
      smsSettings: _smsSettings,
    );
  }

  Future<void> _applyRemoteBundle(
    WalletKeeperUserSession session,
    WalletKeeperSyncBundle bundle,
    List<WalletKeeperInquiry> inquiries,
  ) async {
    final sortedEntries = [...bundle.entries]
      ..sort((a, b) => b.date.compareTo(a.date));
    final sortedBudgets = [...bundle.budgets]
      ..sort((a, b) {
        final monthCompare = b.monthKey.compareTo(a.monthKey);
        if (monthCompare != 0) return monthCompare;
        return a.category.compareTo(b.category);
      });
    await _repository.save(sortedEntries);
    await _memoRepository.save(bundle.memos);
    await _budgetRepository.save(sortedBudgets);
    await _smsSettingsRepository.save(bundle.smsSettings);
    if (!mounted) return;
    setState(() {
      _session = session;
      _inquiries = inquiries;
      _entries = sortedEntries;
      _memos = bundle.memos;
      _budgets = sortedBudgets;
      _smsSettings = bundle.smsSettings;
    });
  }

  Future<void> _preserveLocalAndSyncToSession(
    WalletKeeperUserSession session,
    List<WalletKeeperInquiry> inquiries,
  ) async {
    final localBundle = _currentLocalBundle();
    await _cloudSyncRepository.syncForSession(
      session: session,
      entries: localBundle.entries,
      memos: localBundle.memos,
      budgets: localBundle.budgets,
      smsSettings: localBundle.smsSettings,
    );
    if (!mounted) return;
    setState(() {
      _session = session;
      _inquiries = inquiries;
    });
  }

  Future<_WalletKeeperCloudConflictAction> _showCloudConflictDialog() async {
    final action = await showDialog<_WalletKeeperCloudConflictAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text('서버에 이미 저장된 데이터가 있어요!'),
            content: const Text(
              '이 계정에는 다른 기기에서 저장한 데이터가 있습니다. 새로 작성하거나 서버 데이터를 불러올 수 있습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(_WalletKeeperCloudConflictAction.startFresh),
                child: const Text('새로작성'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop(_WalletKeeperCloudConflictAction.loadRemote),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A5F),
                ),
                child: const Text('불러오기'),
              ),
            ],
          ),
        );
      },
    );
    return action ?? _WalletKeeperCloudConflictAction.loadRemote;
  }

  Future<bool> _showStartFreshWarningDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('새로작성'),
          content: const Text(
            '새로작성하면 이미 저장된 데이터가 소멸되는데도 새로작성할까요?',
          ),
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
              child: const Text('새로작성'),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Future<void> _saveEntry(
    LedgerEntry entry, {
    String? consumedDraftId,
    bool stayOnCurrentRoute = false,
  }) async {
    final next = [..._entries];
    final index = next.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      next[index] = entry;
    } else {
      next.add(entry);
    }
    next.sort((a, b) => b.date.compareTo(a.date));
    await _repository.save(next);
    if (consumedDraftId != null) {
      await _smsAutomationRepository.removeDraft(consumedDraftId);
    }
    if (!mounted) return;
    setState(() {
      _entries = next;
      if (consumedDraftId != null) {
        _smsDrafts = _smsDrafts.where((draft) => draft.id != consumedDraftId).toList();
      }
      if (!stayOnCurrentRoute) {
        _popToSmsInboxOrRoot();
      }
    });
    await _syncCloud();
    await showAppToast('내역을 저장했습니다.');
  }

  Future<bool> _deleteEntry(LedgerEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('내역 삭제'),
          content: Text('`${entry.title}` 내역을 삭제할까요?'),
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
        );
      },
    );
    if (confirmed != true) return false;
    final next = _entries.where((item) => item.id != entry.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    await _repository.save(next);
    if (!mounted) return false;
    setState(() => _entries = next);
    await _syncCloud();
    await showAppToast('내역을 삭제했습니다.');
    return true;
  }

  Future<void> _saveBudgetsForMonth(
    DateTime month,
    List<WalletKeeperBudgetSetting> monthBudgets,
  ) async {
    final monthKey = DateFormat('yyyy-MM').format(month);
    final retained = _budgets.where((budget) => budget.monthKey != monthKey).toList();
    final next = [...retained, ...monthBudgets]
      ..sort((a, b) {
        final monthCompare = b.monthKey.compareTo(a.monthKey);
        if (monthCompare != 0) return monthCompare;
        return a.category.compareTo(b.category);
      });
    await _budgetRepository.save(next);
    if (!mounted) return;
    setState(() => _budgets = next);
    await _syncCloud();
    await showAppToast('예산을 저장했습니다.');
  }

  Future<void> _saveInquiry({
    required String title,
    required String content,
    required String replyEmail,
  }) async {
    if (_session == null) {
      await showAppToast('계정 정보를 확인할 수 없습니다.');
      return;
    }
    await _inquiryRepository.submit(
      session: _session!,
      title: title,
      content: content,
      replyEmail: replyEmail,
    );
    final next = await _loadInquiriesForSession(_session!);
    if (!mounted) return;
    setState(() {
      _inquiries = next;
      if (_currentRoute.kind == _ShellRouteKind.settingsInquiryCompose) {
        _routeStack.removeLast();
      }
    });
    await showAppToast('문의를 등록했습니다.');
  }

  Future<void> _runSocialSignIn(
    Future<WalletKeeperUserSession> Function() action,
    String successMessage,
  ) async {
    try {
      final previousSession = _session ?? await _accountRepository.loadSession();
      final session = await action();
      final inquiries = await _loadInquiriesForSession(session);
      final switchedUser =
          previousSession != null && previousSession.userId != session.userId;
      final remoteBundle = await _cloudSyncRepository.loadRemoteForSession(session);
      final remoteHasData = remoteBundle?.hasMeaningfulData == true;
      if (switchedUser && remoteHasData) {
        while (true) {
          final conflictAction = await _showCloudConflictDialog();
          if (conflictAction == _WalletKeeperCloudConflictAction.loadRemote) {
            await _applyRemoteBundle(session, remoteBundle!, inquiries);
            break;
          }
          final confirmed = await _showStartFreshWarningDialog();
          if (!confirmed) {
            continue;
          }
          await _preserveLocalAndSyncToSession(session, inquiries);
          break;
        }
      } else {
        await _preserveLocalAndSyncToSession(session, inquiries);
      }
      if (!mounted) return;
      unawaited(_registerPushTokenSilently());
      await showAppToast(successMessage);
    } catch (error) {
      await showAppToast(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _logoutToGuest() async {
    try {
      final session = await _accountRepository.signOutToGuest();
      final inquiries = await _loadInquiriesForSession(session);
      await _preserveLocalAndSyncToSession(session, inquiries);
      unawaited(_registerPushTokenSilently());
      await showAppToast('로그아웃되었습니다.');
    } catch (error) {
      await showAppToast(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<List<WalletKeeperInquiry>> _loadInquiriesForSession(
    WalletKeeperUserSession? session, {
    bool showErrorToast = false,
  }) async {
    if (session == null) return const [];
    try {
      return await _inquiryRepository.fetchList(session);
    } catch (error) {
      if (showErrorToast) {
        await showAppToast(
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
      return const [];
    }
  }

  Future<void> _refreshInquiries({bool showErrorToast = false}) async {
    final next = await _loadInquiriesForSession(
      _session,
      showErrorToast: showErrorToast,
    );
    if (!mounted) return;
    setState(() => _inquiries = next);
  }


  void _popToSmsInboxOrRoot() {
    if (_routeStack.length > 1 && _routeStack[_routeStack.length - 2].kind == _ShellRouteKind.smsInbox) {
      _routeStack
        ..removeLast()
        ..removeLast()
        ..add(const _ShellRoute.smsInbox());
      return;
    }
    _routeStack
      ..clear()
      ..add(const _ShellRoute.root());
  }

  void _openComposer({LedgerEntry? existing, WalletKeeperSmsDraft? smsDraft}) {
    if (_currentRoute.kind == _ShellRouteKind.editor) {
      return;
    }
    setState(() {
      _routeStack.add(_ShellRoute.editor(existing: existing, smsDraft: smsDraft));
    });
  }

  Future<void> _showEntryEditorSheet({LedgerEntry? existing}) async {
    final editorKey = GlobalKey<_EntryEditorPageState>();
    Future<void> attemptClose(BuildContext sheetContext) async {
      final canLeave =
          await editorKey.currentState?.confirmDiscardIfNeeded() ?? true;
      if (!canLeave || !sheetContext.mounted) return;
      Navigator.of(sheetContext).pop();
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        final keyboardInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await attemptClose(sheetContext);
          },
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(bottom: keyboardInset),
            child: FractionallySizedBox(
              heightFactor: 0.93,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Material(
                  color: Colors.white,
                  child: EntryEditorPage(
                    key: editorKey,
                    existing: existing,
                    categorySuggestions: _categorySuggestions,
                    featureAccess: widget.featureAccess,
                    onRequestSmsAccess: widget.onRequestFeatureAccess,
                    onCancel: () => attemptClose(sheetContext),
                    onDeleteEntry: existing == null
                        ? null
                        : () async {
                            final deleted = await _deleteEntry(existing);
                            if (!deleted || !sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop();
                          },
                    onSave: (entry) async {
                      await _saveEntry(
                        entry,
                        stayOnCurrentRoute: true,
                      );
                      if (!sheetContext.mounted) return;
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBudgetSettingsSheet({
    required DateTime month,
  }) async {
    final monthKey = DateFormat('yyyy-MM').format(month);
    final monthBudgets = _budgets
        .where((budget) => budget.monthKey == monthKey)
        .toList()
      ..sort((a, b) => a.category.compareTo(b.category));
    final categorySuggestions = _entries
        .where((entry) => entry.type != EntryType.transfer)
        .map((entry) => entry.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Material(
              color: Colors.white,
              child: BudgetSettingsSheet(
                month: month,
                initialBudgets: monthBudgets,
                categorySuggestions: categorySuggestions,
                onSave: (budgets) => _saveBudgetsForMonth(month, budgets),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openSmsPage() {
    if (!widget.featureAccess.hasRequiredPermissionAccess) {
      widget.onRequireFeatureOnboarding();
      return;
    }
    _consumePendingRealtimeMessages();
    setState(() => _routeStack.add(const _ShellRoute.smsInbox()));
  }

  Future<void> _openSmsPageFromNotification() async {
    if (!mounted) return;
    if (!widget.featureAccess.hasRequiredPermissionAccess) {
      widget.onRequireFeatureOnboarding();
      return;
    }
    await _consumePendingRealtimeMessages();
    if (!mounted) return;
    setState(() {
      if (_currentRoute.kind == _ShellRouteKind.smsInbox) return;
      _routeStack.add(const _ShellRoute.smsInbox());
    });
  }

  Future<void> _importRecentSms(int days) async {
    final drafts = await _smsAutomationRepository.importRecentMessages(recentDays: days);
    if (!mounted) return;
    setState(() => _smsDrafts = drafts);
  }

  Future<void> _deleteSelectedSmsDrafts(Set<String> ids) async {
    for (final id in ids) {
      await _smsAutomationRepository.removeDraft(id);
    }
    if (!mounted) return;
    setState(() {
      _smsDrafts = _smsDrafts.where((draft) => !ids.contains(draft.id)).toList();
    });
  }

  Future<void> _quickAutoInputDraft(WalletKeeperSmsDraft draft) async {
    await _saveEntry(
      draft.toEntry(),
      consumedDraftId: draft.id,
      stayOnCurrentRoute: true,
    );
  }

  Future<void> _pasteSmsFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final body = data?.text?.trim() ?? '';
    if (body.isEmpty) {
      await showAppToast('금융문자가 아닌것같아요!');
      return;
    }
    final parsed = WalletKeeperSmsParser.parseRawMessage(
      body: body,
      sender: 'clipboard',
      dateMillis: DateTime.now().millisecondsSinceEpoch,
      sourceType: 'sms',
    );
    if (parsed == null) {
      await showAppToast('금융문자가 아닌것같아요!');
      return;
    }
    final merged = await _smsAutomationRepository.saveInboxDrafts([parsed.toDraft()]);
    if (!mounted) return;
    setState(() => _smsDrafts = merged);
    await showAppToast('문자함에 추가했습니다.');
  }

  Future<void> _saveSmsSettings(WalletKeeperSmsSettings settings) async {
    await _smsSettingsRepository.save(settings);
    if (!mounted) return;
    setState(() => _smsSettings = settings);
    await _syncCloud();
  }

  Future<void> _removeSmsDraft(String id) async {
    await _smsAutomationRepository.removeDraft(id);
    if (!mounted) return;
    setState(() => _smsDrafts = _smsDrafts.where((draft) => draft.id != id).toList());
  }

  Future<void> _bindSmsListenerIfNeeded() async {
    if (!Platform.isAndroid ||
        !widget.featureAccess.smsAutomationEnabled ||
        !_smsSettings.smsReceiveEnabled ||
        _smsListenerAttached) {
      return;
    }
    _telephony.listenIncomingSms(
      onNewMessage: _handleForegroundSms,
      onBackgroundMessage: walletKeeperBackgroundMessageHandler,
      listenInBackground: true,
    );
    _smsListenerAttached = true;
  }

  void _startPendingMmsTimerIfNeeded() {
    if (!Platform.isAndroid ||
        !widget.featureAccess.smsAutomationEnabled ||
        !_smsSettings.smsReceiveEnabled) {
      _pendingMmsTimer?.cancel();
      _pendingMmsTimer = null;
      return;
    }
    if (_pendingMmsTimer != null) return;
    _pendingMmsTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      _consumePendingRealtimeMessages();
    });
  }

  Future<void> _consumePendingRealtimeMessages() async {
    if (!Platform.isAndroid ||
        !widget.featureAccess.smsAutomationEnabled ||
        !_smsSettings.smsReceiveEnabled) {
      return;
    }
    final pendingMms = await _smsAutomationRepository.consumePendingMms();
    final pendingNotifications =
        _financialAppNotificationEnabled
            ? await _smsAutomationRepository.consumePendingAppNotifications()
            : const <WalletKeeperSmsDraft>[];
    final pendingMessages = [...pendingMms, ...pendingNotifications]
      ..sort((a, b) => b.date.compareTo(a.date));
    if (pendingMessages.isEmpty) return;
    if (_smsSettings.autoInputEnabled) {
      var draftsChanged = false;
      var entriesChanged = false;
      for (final draft in pendingMessages) {
        final result = await _smsAutomationRepository.handleIncomingDraft(
          draft,
          autoSaveToLedger: true,
        );
        if (result == null) continue;
        entriesChanged = entriesChanged || result.savedDirectly;
        if (!result.savedDirectly) {
          draftsChanged = true;
        }
      }
      if (!mounted) return;
      if (entriesChanged) {
        final loadedEntries = await _repository.load();
        if (!mounted) return;
        setState(() => _entries = loadedEntries);
      }
      if (draftsChanged) {
        final drafts = await _smsAutomationRepository.loadInboxDrafts();
        if (!mounted) return;
        setState(() => _smsDrafts = drafts);
      }
      return;
    }
    final merged = await _smsAutomationRepository.saveInboxDrafts(pendingMessages);
    if (!mounted) return;
    setState(() => _smsDrafts = merged);
  }

  Future<void> _consumeLaunchRoute() async {
    if (_pendingNotificationLaunchToSmsInbox) {
      _pendingNotificationLaunchToSmsInbox = false;
      await _openSmsPageFromNotification();
      return;
    }
    if (!Platform.isAndroid) return;
    try {
      final route = await _mmsRouteChannel.invokeMethod<String>('consumeLaunchRoute');
      if (route == _smsInboxNotificationPayload) {
        await _openSmsPageFromNotification();
      }
    } catch (_) {}
  }

  Future<void> _handleForegroundSms(SmsMessage message) async {
    final result = await _smsAutomationRepository.handleIncomingMessage(
      message,
      autoSaveToLedger: _smsSettings.autoInputEnabled,
    );
    if (!mounted || result == null) return;
    if (result.savedDirectly) {
      final loadedEntries = await _repository.load();
      if (!mounted) return;
      setState(() => _entries = loadedEntries);
    } else {
      setState(() {
        _smsDrafts = [result.draft, ..._smsDrafts.where((item) => item.id != result.draft.id)]
          ..sort((a, b) => b.date.compareTo(a.date));
      });
    }
    if (_smsSettings.showNotification) {
      await WalletKeeperNotificationService.showSmsDetectedNotification(result);
    }
    await showAppToast(
      result.savedDirectly ? '금융 문자를 감지해 바로 등록했습니다.' : '금융 문자를 감지해 문자함에 담았습니다.',
    );
  }

  Future<bool> _handleBack() async {
    if (_currentRoute.kind == _ShellRouteKind.root) {
      final now = DateTime.now();
      final shouldExit = _lastBackPressedAt != null &&
          now.difference(_lastBackPressedAt!) <= const Duration(seconds: 2);
      if (shouldExit) {
        return true;
      }
      _lastBackPressedAt = now;
      await showAppToast('한 번 더 누르면 앱이 종료됩니다.');
      return false;
    }
    if (_currentRoute.kind == _ShellRouteKind.editor) {
      final canLeave = await _editorPageKey.currentState?.confirmDiscardIfNeeded() ?? true;
      if (!canLeave) return false;
    }
    if (_currentRoute.kind == _ShellRouteKind.settingsInquiryCompose) {
      final canLeave =
          await _inquiryComposePageKey.currentState?.confirmDiscardIfNeeded() ??
              true;
      if (!canLeave) return false;
    }
    setState(() => _routeStack.removeLast());
    return false;
  }

  Future<void> _closeEditorAndSelectTab(int index) async {
    final shouldResetOverview = index == 0 && _selectedTab == 0;
    if (_currentRoute.kind == _ShellRouteKind.editor) {
      final canLeave = await _editorPageKey.currentState?.confirmDiscardIfNeeded() ?? true;
      if (!canLeave) return;
      if (!mounted) return;
      setState(() {
        if (_routeStack.isNotEmpty) {
          _routeStack
            ..clear()
            ..add(const _ShellRoute.root());
        }
        _selectedTab = index;
        if (shouldResetOverview) {
          _selectedOverviewTab = 0;
          _overviewResetNonce++;
        }
      });
      return;
    }
    if (_currentRoute.kind == _ShellRouteKind.settingsInquiryCompose) {
      final canLeave =
          await _inquiryComposePageKey.currentState?.confirmDiscardIfNeeded() ??
              true;
      if (!canLeave) return;
      if (!mounted) return;
      setState(() {
        if (_routeStack.isNotEmpty) {
          _routeStack
            ..clear()
            ..add(const _ShellRoute.root());
        }
        _selectedTab = index;
        if (shouldResetOverview) {
          _selectedOverviewTab = 0;
          _overviewResetNonce++;
        }
      });
      return;
    }
    setState(() {
      if (_routeStack.isNotEmpty) {
        _routeStack
          ..clear()
          ..add(const _ShellRoute.root());
      }
      _selectedTab = index;
      if (shouldResetOverview) {
        _selectedOverviewTab = 0;
        _overviewResetNonce++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = LedgerSummary.fromEntries(_entries);
    final showBottomBar =
        _currentRoute.kind == _ShellRouteKind.root ||
        _currentRoute.kind == _ShellRouteKind.smsInbox ||
        _currentRoute.kind == _ShellRouteKind.editor ||
        _currentRoute.kind == _ShellRouteKind.smsSettings ||
        _currentRoute.kind == _ShellRouteKind.settingsProfile ||
        _currentRoute.kind == _ShellRouteKind.settingsInquiryList ||
        _currentRoute.kind == _ShellRouteKind.settingsInquiryDetail ||
        _currentRoute.kind == _ShellRouteKind.settingsInquiryCompose ||
        _currentRoute.kind == _ShellRouteKind.settingsTerms ||
        _currentRoute.kind == _ShellRouteKind.assetUpcomingHistory ||
        _currentRoute.kind == _ShellRouteKind.assetFlowHistory;
    final bottomOverlayHeight = showBottomBar
        ? _walletKeeperBottomNavSectionHeight + MediaQuery.paddingOf(context).bottom
        : 0.0;

    Widget page;
    switch (_currentRoute.kind) {
      case _ShellRouteKind.root:
        page = [
          OverviewPage(
            key: ValueKey('overview-$_overviewResetNonce'),
            summary: summary,
            entries: _entries,
            budgets: _budgets,
            smsDraftCount: _smsDrafts.length,
            selectedTab: _selectedOverviewTab,
            onSelectedTabChanged: (index) => setState(() => _selectedOverviewTab = index),
            onEdit: ({existing}) => _showEntryEditorSheet(existing: existing),
            onOpenBudgetSettings: ({required month}) =>
                _showBudgetSettingsSheet(month: month),
            onOpenSmsPage: _openSmsPage,
            onDelete: (entry) async {
              await _deleteEntry(entry);
            },
          ),
          StatsPage(
            entries: _entries,
          ),
          AssetPage(
            entries: _entries,
            session: _session,
            onOpenUpcomingExpenses: () => setState(() => _routeStack.add(const _ShellRoute.assetUpcomingHistory())),
            onOpenFlowHistory: () => setState(() => _routeStack.add(const _ShellRoute.assetFlowHistory())),
          ),
          SettingsPage(
            session: _session,
            smsSettings: _smsSettings,
            onOpenSmsSettings: () => setState(() => _routeStack.add(const _ShellRoute.smsSettings())),
            onOpenProfileInfo: () => setState(() => _routeStack.add(const _ShellRoute.settingsProfile())),
            onOpenInquiryList: () {
              _refreshInquiries();
              setState(() => _routeStack.add(const _ShellRoute.settingsInquiryList()));
            },
            onOpenTermsInfo: () => setState(() => _routeStack.add(const _ShellRoute.settingsTerms())),
            onLogout: _logoutToGuest,
            onSignInWithKakao: () => _runSocialSignIn(_accountRepository.signInWithKakao, '로그인되었습니다.'),
            onSignInWithGoogle: () => _runSocialSignIn(_accountRepository.signInWithGoogle, '로그인되었습니다.'),
            onSignInWithNaver: () => _runSocialSignIn(_accountRepository.signInWithNaver, '로그인되었습니다.'),
            onSignInWithApple: () => _runSocialSignIn(_accountRepository.signInWithApple, '로그인되었습니다.'),
          ),
        ][_selectedTab];
        break;
      case _ShellRouteKind.smsInbox:
        page = SmsInboxPage(
          drafts: _smsDrafts,
          featureAccess: widget.featureAccess,
          settings: _smsSettings,
          onBack: () => setState(() => _routeStack.removeLast()),
          onOpenSettingsPage: () => setState(() => _routeStack.add(const _ShellRoute.smsSettings())),
          onImportRecent: _importRecentSms,
          onOpenDraft: (draft) => _openComposer(smsDraft: draft),
          onRequestSmsAccess: widget.onRequestFeatureAccess,
          onQuickAutoInput: _quickAutoInputDraft,
          onDeleteSelected: _deleteSelectedSmsDrafts,
          onPasteFromClipboard: _pasteSmsFromClipboard,
        );
        break;
      case _ShellRouteKind.smsSettings:
        page = SmsSettingsPage(
          featureAccess: widget.featureAccess,
          settings: _smsSettings,
          financialAppNotificationEnabled: _financialAppNotificationEnabled,
          onBack: () => setState(() => _routeStack.removeLast()),
          onOpenFinancialAppNotificationSettings:
              _openFinancialAppNotificationSettings,
          onChanged: _saveSmsSettings,
        );
        break;
      case _ShellRouteKind.settingsProfile:
        page = ProfileInfoPage(
          session: _session,
          onBack: () => setState(() => _routeStack.removeLast()),
        );
        break;
      case _ShellRouteKind.settingsInquiryList:
        page = InquiryListPage(
          inquiries: _inquiries,
          onBack: () => setState(() => _routeStack.removeLast()),
          onRefresh: () => _refreshInquiries(showErrorToast: true),
          onOpenDetail: (inquiry) =>
              setState(() => _routeStack.add(_ShellRoute.settingsInquiryDetail(inquiry: inquiry))),
          onOpenCompose: () =>
              setState(() => _routeStack.add(const _ShellRoute.settingsInquiryCompose())),
        );
        break;
      case _ShellRouteKind.settingsInquiryDetail:
        page = InquiryDetailPage(
          inquiry: _currentRoute.inquiry!,
          onBack: () => setState(() => _routeStack.removeLast()),
        );
        break;
      case _ShellRouteKind.settingsInquiryCompose:
        page = InquiryComposePage(
          key: _inquiryComposePageKey,
          session: _session,
          onBack: () async {
            final canLeave =
                await _inquiryComposePageKey.currentState?.confirmDiscardIfNeeded() ??
                    true;
            if (!canLeave || !mounted) return;
            setState(() => _routeStack.removeLast());
          },
          onSave: _saveInquiry,
        );
        break;
      case _ShellRouteKind.settingsTerms:
        page = TermsInfoPage(
          onBack: () => setState(() => _routeStack.removeLast()),
        );
        break;
      case _ShellRouteKind.assetUpcomingHistory:
        page = AssetUpcomingExpensesPage(
          entries: _entries,
          onBack: () => setState(() => _routeStack.removeLast()),
        );
        break;
      case _ShellRouteKind.assetFlowHistory:
        page = AssetFlowHistoryPage(
          entries: _entries,
          onBack: () => setState(() => _routeStack.removeLast()),
        );
        break;
      case _ShellRouteKind.editor:
        page = EntryEditorPage(
          key: _editorPageKey,
          existing: _currentRoute.existing,
          smsDraft: _currentRoute.smsDraft,
          categorySuggestions: _categorySuggestions,
          featureAccess: widget.featureAccess,
          onRequestSmsAccess: widget.onRequestFeatureAccess,
          onCancel: () async {
            final canLeave = await _editorPageKey.currentState?.confirmDiscardIfNeeded() ?? true;
            if (!canLeave || !mounted) return;
            setState(() => _routeStack.removeLast());
          },
          onDeleteDraft: _currentRoute.smsDraft == null
              ? null
              : () async {
                  await _removeSmsDraft(_currentRoute.smsDraft!.id);
                  if (!mounted) return;
                  setState(() => _routeStack.removeLast());
                },
          onDeleteEntry: _currentRoute.existing == null
              ? null
              : () async {
                  final deleted = await _deleteEntry(_currentRoute.existing!);
                  if (!deleted || !mounted) return;
                  setState(() => _routeStack.removeLast());
                },
          onSave: (entry) => _saveEntry(
            entry,
            consumedDraftId: _currentRoute.smsDraft?.id,
          ),
        );
        break;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handleBack();
        if (shouldPop && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: _BottomOverlayScope(
          overlayHeight: bottomOverlayHeight,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                page,
                if (showBottomBar)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      top: false,
                      child: Material(
                        color: Colors.transparent,
                        child: WalletKeeperBottomBar(
                          selectedIndex: _selectedTab,
                          onAdd: () => _openComposer(),
                          onSelected: _closeEditorAndSelectTab,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
