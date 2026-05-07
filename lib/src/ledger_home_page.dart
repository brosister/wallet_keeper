part of '../main.dart';

enum _ShellRouteKind {
  root,
  smsInbox,
  smsSettings,
  settingsData,
  settingsPrivacy,
  editor,
  memoEditor,
}

class _ShellRoute {
  const _ShellRoute.root()
      : kind = _ShellRouteKind.root,
        existing = null,
        smsDraft = null,
        memo = null,
        month = null;
  const _ShellRoute.smsInbox()
      : kind = _ShellRouteKind.smsInbox,
        existing = null,
        smsDraft = null,
        memo = null,
        month = null;
  const _ShellRoute.smsSettings()
      : kind = _ShellRouteKind.smsSettings,
        existing = null,
        smsDraft = null,
        memo = null,
        month = null;
  const _ShellRoute.settingsData()
      : kind = _ShellRouteKind.settingsData,
        existing = null,
        smsDraft = null,
        memo = null,
        month = null;
  const _ShellRoute.settingsPrivacy()
      : kind = _ShellRouteKind.settingsPrivacy,
        existing = null,
        smsDraft = null,
        memo = null,
        month = null;
  const _ShellRoute.memoEditor({this.memo, this.month})
      : kind = _ShellRouteKind.memoEditor,
        existing = null,
        smsDraft = null;
  const _ShellRoute.editor({this.existing, this.smsDraft})
      : kind = _ShellRouteKind.editor,
        memo = null,
        month = null;

  final _ShellRouteKind kind;
  final LedgerEntry? existing;
  final WalletKeeperSmsDraft? smsDraft;
  final WalletKeeperMemo? memo;
  final DateTime? month;
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
  final WalletKeeperAccountRepository _accountRepository = WalletKeeperAccountRepository();
  final WalletKeeperCloudSyncRepository _cloudSyncRepository = WalletKeeperCloudSyncRepository();

  List<LedgerEntry> _entries = const [];
  List<WalletKeeperMemo> _memos = const [];
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
  final List<_ShellRoute> _routeStack = [const _ShellRoute.root()];
  final GlobalKey<_EntryEditorPageState> _editorPageKey = GlobalKey<_EntryEditorPageState>();
  DateTime? _lastBackPressedAt;

  _ShellRoute get _currentRoute => _routeStack.last;

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
      _consumePendingMmsOnly();
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
    final loadedDrafts = await _smsAutomationRepository.loadInboxDrafts();
    final loadedSettings = await _smsSettingsRepository.load();
    final financialNotificationEnabled =
        await _notificationAccessRepository.isFinancialAppNotificationEnabled();
    final session = await _accountRepository.bootstrapGuest();
    final remoteBundle = await _cloudSyncRepository.loadRemote();
    if (!mounted) return;
    setState(() {
      _entries = remoteBundle != null && loadedEntries.isEmpty ? remoteBundle.entries : loadedEntries;
      _memos = remoteBundle != null && loadedMemos.isEmpty ? remoteBundle.memos : loadedMemos;
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
    if (remoteBundle != null) {
      await _smsSettingsRepository.save(remoteBundle.smsSettings);
    }
    _startPendingMmsTimerIfNeeded();
    await _consumePendingMmsOnly();
    await _consumeLaunchRoute();
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
        smsSettings: _smsSettings,
      );
    } catch (_) {}
  }

  Future<void> _saveEntry(LedgerEntry entry, {String? consumedDraftId}) async {
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
      _popToSmsInboxOrRoot();
    });
    await _syncCloud();
    await showAppToast('내역을 저장했습니다.');
  }

  Future<void> _deleteEntry(LedgerEntry entry) async {
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
    if (confirmed != true) return;
    final next = _entries.where((item) => item.id != entry.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    await _repository.save(next);
    if (!mounted) return;
    setState(() => _entries = next);
    await _syncCloud();
    await showAppToast('내역을 삭제했습니다.');
  }

  void _openMemoComposer({WalletKeeperMemo? existing, required DateTime month}) {
    setState(() {
      _routeStack.add(_ShellRoute.memoEditor(memo: existing, month: month));
    });
  }

  Future<void> _saveMemo(WalletKeeperMemo memo) async {
    final next = [..._memos];
    final index = next.indexWhere((item) => item.id == memo.id);
    if (index >= 0) {
      next[index] = memo;
    } else {
      next.add(memo);
    }
    next.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _memoRepository.save(next);
    if (!mounted) return;
    setState(() {
      _memos = next;
      _routeStack.removeLast();
    });
    await _syncCloud();
    await showAppToast('메모를 저장했습니다.');
  }

  Future<void> _deleteMemo(WalletKeeperMemo memo) async {
    final next = _memos.where((item) => item.id != memo.id).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _memoRepository.save(next);
    if (!mounted) return;
    setState(() => _memos = next);
    await _syncCloud();
    await showAppToast('메모를 삭제했습니다.');
  }

  Future<void> _runGuarded(
    Future<WalletKeeperUserSession> Function() action,
    String successMessage,
  ) async {
    try {
      final session = await action();
      if (!mounted) return;
      setState(() => _session = session);
      await _syncCloud();
      await showAppToast(successMessage);
    } catch (error) {
      await showAppToast(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _syncCloudManually() async {
    try {
      await _syncCloud();
      await showAppToast('서버 동기화를 완료했습니다.');
    } catch (error) {
      await showAppToast('서버 동기화에 실패했습니다.');
    }
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
    setState(() {
      _routeStack.add(_ShellRoute.editor(existing: existing, smsDraft: smsDraft));
    });
  }

  void _openSmsPage() {
    if (!widget.featureAccess.hasRequiredPermissionAccess) {
      widget.onRequireFeatureOnboarding();
      return;
    }
    _consumePendingMmsOnly();
    setState(() => _routeStack.add(const _ShellRoute.smsInbox()));
  }

  Future<void> _openSmsPageFromNotification() async {
    if (!mounted) return;
    if (!widget.featureAccess.hasRequiredPermissionAccess) {
      widget.onRequireFeatureOnboarding();
      return;
    }
    await _consumePendingMmsOnly();
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
      _consumePendingMmsOnly();
    });
  }

  Future<void> _consumePendingMmsOnly() async {
    if (!Platform.isAndroid ||
        !widget.featureAccess.smsAutomationEnabled ||
        !_smsSettings.smsReceiveEnabled) {
      return;
    }
    final pendingMms = await _smsAutomationRepository.consumePendingMms();
    if (pendingMms.isEmpty) return;
    if (_smsSettings.autoInputEnabled) {
      var draftsChanged = false;
      var entriesChanged = false;
      for (final draft in pendingMms) {
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
    final merged = await _smsAutomationRepository.saveInboxDrafts(pendingMms);
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
    setState(() => _routeStack.removeLast());
    return false;
  }

  Future<void> _closeEditorAndSelectTab(int index) async {
    if (_currentRoute.kind == _ShellRouteKind.editor) {
      final canLeave = await _editorPageKey.currentState?.confirmDiscardIfNeeded() ?? true;
      if (!canLeave) return;
      if (!mounted) return;
      setState(() {
        if (_routeStack.isNotEmpty) {
          _routeStack.removeLast();
        }
        _selectedTab = index;
      });
      return;
    }
    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final summary = LedgerSummary.fromEntries(_entries);
    final showBottomBar =
        _currentRoute.kind == _ShellRouteKind.root ||
        _currentRoute.kind == _ShellRouteKind.editor;
    final bottomOverlayHeight = showBottomBar
        ? _walletKeeperBottomNavSectionHeight + MediaQuery.paddingOf(context).bottom
        : 0.0;

    Widget page;
    switch (_currentRoute.kind) {
      case _ShellRouteKind.root:
        page = [
          OverviewPage(
            summary: summary,
            entries: _entries,
            memos: _memos,
            smsDraftCount: _smsDrafts.length,
            onEdit: ({existing}) => _openComposer(existing: existing),
            onOpenMemoComposer: ({memo, required month}) =>
                _openMemoComposer(existing: memo, month: month),
            onOpenSmsPage: _openSmsPage,
            onDelete: _deleteEntry,
            onDeleteMemo: _deleteMemo,
          ),
          StatsPage(
            entries: _entries,
          ),
          AssetPage(
            entries: _entries,
            session: _session,
          ),
          SettingsPage(
            session: _session,
            smsSettings: _smsSettings,
            onOpenSmsSettings: () => setState(() => _routeStack.add(const _ShellRoute.smsSettings())),
            onOpenDataSettings: () => setState(() => _routeStack.add(const _ShellRoute.settingsData())),
            onOpenPrivacyInfo: () => setState(() => _routeStack.add(const _ShellRoute.settingsPrivacy())),
            onSignInWithKakao: () => _runGuarded(_accountRepository.signInWithKakao, '카카오 연동을 완료했습니다.'),
            onSignInWithGoogle: () => _runGuarded(_accountRepository.signInWithGoogle, '구글 연동을 완료했습니다.'),
            onSignInWithNaver: () => _runGuarded(_accountRepository.signInWithNaver, '네이버 연동을 완료했습니다.'),
            onSignInWithApple: () => _runGuarded(_accountRepository.signInWithApple, '애플 연동을 완료했습니다.'),
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
          onPasteMessage: () => showAppToast('문자 복사붙여넣기는 다음 디자인에서 연결합니다.'),
          onDeleteSelected: _deleteSelectedSmsDrafts,
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
      case _ShellRouteKind.settingsData:
        page = DataSettingsPage(
          session: _session,
          onBack: () => setState(() => _routeStack.removeLast()),
          onSyncNow: _syncCloudManually,
        );
        break;
      case _ShellRouteKind.settingsPrivacy:
        page = PrivacyInfoPage(
          onBack: () => setState(() => _routeStack.removeLast()),
        );
        break;
      case _ShellRouteKind.editor:
        page = EntryEditorPage(
          key: _editorPageKey,
          existing: _currentRoute.existing,
          smsDraft: _currentRoute.smsDraft,
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
          onSave: (entry) => _saveEntry(
            entry,
            consumedDraftId: _currentRoute.smsDraft?.id,
          ),
        );
        break;
      case _ShellRouteKind.memoEditor:
        page = MemoEditorPage(
          existing: _currentRoute.memo,
          month: _currentRoute.month ?? DateTime.now(),
          onBack: () => setState(() => _routeStack.removeLast()),
          onSave: _saveMemo,
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
