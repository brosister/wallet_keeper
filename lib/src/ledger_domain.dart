part of '../main.dart';

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

class WalletKeeperFeatureAccess {
  const WalletKeeperFeatureAccess({
    required this.onboardingSeen,
    required this.smsGranted,
    required this.notificationGranted,
  });

  final bool onboardingSeen;
  final bool smsGranted;
  final bool notificationGranted;

  bool get smsAutomationEnabled => smsGranted;
  bool get hasRequiredPermissionAccess => smsGranted && notificationGranted;

  WalletKeeperFeatureAccess copyWith({
    bool? onboardingSeen,
    bool? smsGranted,
    bool? notificationGranted,
  }) {
    return WalletKeeperFeatureAccess(
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      smsGranted: smsGranted ?? this.smsGranted,
      notificationGranted: notificationGranted ?? this.notificationGranted,
    );
  }
}

class WalletKeeperSmsSettings {
  const WalletKeeperSmsSettings({
    required this.smsReceiveEnabled,
    required this.autoInputEnabled,
    required this.showNotification,
    required this.shareHeuristicReports,
    required this.importWindowDays,
  });

  final bool smsReceiveEnabled;
  final bool autoInputEnabled;
  final bool showNotification;
  final bool shareHeuristicReports;
  final int importWindowDays;

  WalletKeeperSmsSettings copyWith({
    bool? smsReceiveEnabled,
    bool? autoInputEnabled,
    bool? showNotification,
    bool? shareHeuristicReports,
    int? importWindowDays,
  }) {
    return WalletKeeperSmsSettings(
      smsReceiveEnabled: smsReceiveEnabled ?? this.smsReceiveEnabled,
      autoInputEnabled: autoInputEnabled ?? this.autoInputEnabled,
      showNotification: showNotification ?? this.showNotification,
      shareHeuristicReports:
          shareHeuristicReports ?? this.shareHeuristicReports,
      importWindowDays: importWindowDays ?? this.importWindowDays,
    );
  }
}

class WalletKeeperSmsSettingsRepository {
  Future<WalletKeeperSmsSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return WalletKeeperSmsSettings(
      smsReceiveEnabled: prefs.getBool(_smsReceiveEnabledKey) ?? true,
      autoInputEnabled: prefs.getBool(_smsAutoInputEnabledKey) ?? false,
      showNotification: prefs.getBool(_smsShowNotificationKey) ?? true,
      shareHeuristicReports:
          prefs.getBool(_smsHeuristicReportEnabledKey) ?? false,
      importWindowDays: prefs.getInt(_smsImportWindowDaysKey) ?? 60,
    );
  }

  Future<void> save(WalletKeeperSmsSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_smsReceiveEnabledKey, settings.smsReceiveEnabled);
    await prefs.setBool(_smsAutoInputEnabledKey, settings.autoInputEnabled);
    await prefs.setBool(_smsShowNotificationKey, settings.showNotification);
    await prefs.setBool(
      _smsHeuristicReportEnabledKey,
      settings.shareHeuristicReports,
    );
    await prefs.setInt(_smsImportWindowDaysKey, settings.importWindowDays);
  }
}

class WalletKeeperSettingsRepository {
  Future<WalletKeeperFeatureAccess> loadFeatureAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen =
        prefs.getBool(_smsOnboardingSeenKey) ?? !Platform.isAndroid;
    final storedNotification =
        prefs.getBool(_notificationPermissionGrantedKey) ?? false;
    final smsGranted = Platform.isAndroid
        ? await Permission.sms.isGranted
        : false;
    final notificationGranted = (Platform.isAndroid || Platform.isIOS)
        ? await _resolveNotificationPermission(storedNotification)
        : false;
    final access = WalletKeeperFeatureAccess(
      onboardingSeen: onboardingSeen,
      smsGranted: smsGranted,
      notificationGranted: notificationGranted,
    );
    await saveFeatureAccess(access);
    return access;
  }

  Future<WalletKeeperFeatureAccess> requestFeatureAccess() async {
    if (Platform.isIOS) {
      final notificationCurrentStatus = await Permission.notification.status;
      final shouldOpenSettingsForNotification =
          notificationCurrentStatus.isPermanentlyDenied ||
          notificationCurrentStatus.isRestricted;
      PermissionStatus notificationStatus;
      try {
        if (shouldOpenSettingsForNotification) {
          notificationStatus = notificationCurrentStatus;
        } else {
          notificationStatus = await Permission.notification.request();
        }
      } on PlatformException catch (error) {
        if (error.code != 'permission_denied') rethrow;
        notificationStatus = PermissionStatus.denied;
      }

      if (shouldOpenSettingsForNotification) {
        await openAppSettings();
      }

      final access = WalletKeeperFeatureAccess(
        onboardingSeen: true,
        smsGranted: false,
        notificationGranted:
            notificationStatus.isGranted || notificationStatus.isLimited,
      );
      await saveFeatureAccess(access);
      return access;
    }

    if (!Platform.isAndroid) {
      const access = WalletKeeperFeatureAccess(
        onboardingSeen: true,
        smsGranted: false,
        notificationGranted: false,
      );
      await saveFeatureAccess(access);
      return access;
    }

    final smsCurrentStatus = await Permission.sms.status;
    final shouldOpenSettingsForSms =
        smsCurrentStatus.isPermanentlyDenied || smsCurrentStatus.isRestricted;
    PermissionStatus smsStatus;
    if (shouldOpenSettingsForSms) {
      smsStatus = smsCurrentStatus;
    } else {
      smsStatus = await Permission.sms.request();
    }
    final smsGranted = smsStatus.isGranted || smsStatus.isLimited;

    final notificationCurrentStatus = await Permission.notification.status;
    final shouldOpenSettingsForNotification =
        notificationCurrentStatus.isPermanentlyDenied ||
        notificationCurrentStatus.isRestricted;
    PermissionStatus notificationStatus;
    try {
      if (shouldOpenSettingsForNotification) {
        notificationStatus = notificationCurrentStatus;
      } else {
        notificationStatus = await Permission.notification.request();
      }
    } on PlatformException catch (error) {
      if (error.code != 'permission_denied') rethrow;
      notificationStatus = PermissionStatus.denied;
    }

    if (shouldOpenSettingsForSms || shouldOpenSettingsForNotification) {
      await openAppSettings();
    }

    final access = WalletKeeperFeatureAccess(
      onboardingSeen:
          smsGranted &&
          (notificationStatus.isGranted || notificationStatus.isLimited),
      smsGranted: smsGranted,
      notificationGranted:
          notificationStatus.isGranted || notificationStatus.isLimited,
    );
    await saveFeatureAccess(access);
    return access;
  }

  Future<WalletKeeperFeatureAccess> skipFeatureAccess() async {
    const access = WalletKeeperFeatureAccess(
      onboardingSeen: true,
      smsGranted: false,
      notificationGranted: false,
    );
    await saveFeatureAccess(access);
    return access;
  }

  Future<void> saveFeatureAccess(WalletKeeperFeatureAccess access) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_smsOnboardingSeenKey, access.onboardingSeen);
    await prefs.setBool(_smsPermissionGrantedKey, access.smsGranted);
    await prefs.setBool(
      _notificationPermissionGrantedKey,
      access.notificationGranted,
    );
  }

  Future<bool> _resolveNotificationPermission(bool fallback) async {
    final status = await Permission.notification.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isDenied || status.isPermanentlyDenied || status.isRestricted) {
      return false;
    }
    return fallback;
  }
}

class WalletKeeperNotificationAccessRepository {
  const WalletKeeperNotificationAccessRepository();

  Future<bool> isFinancialAppNotificationEnabled() async {
    if (!Platform.isAndroid) return false;
    try {
      final enabled = await _notificationAccessChannel.invokeMethod<bool>(
        'isNotificationListenerEnabled',
      );
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openFinancialAppNotificationSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final opened = await _notificationAccessChannel.invokeMethod<bool>(
        'openNotificationListenerSettings',
      );
      return opened ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List?> getApplicationIconBytes(String packageName) async {
    if (!Platform.isAndroid || packageName.trim().isEmpty) return null;
    try {
      final bytes = await _notificationAccessChannel.invokeMethod<Uint8List>(
        'getApplicationIconBytes',
        <String, dynamic>{'packageName': packageName.trim()},
      );
      return bytes;
    } catch (_) {
      return null;
    }
  }
}

class WalletKeeperParsedMessage {
  const WalletKeeperParsedMessage({
    required this.type,
    required this.amount,
    required this.title,
    required this.category,
    required this.content,
    required this.rawBody,
    required this.normalizedBody,
    required this.sourceType,
    required this.institution,
    required this.eventType,
    required this.matchedRule,
    required this.sender,
    required this.date,
    required this.sourceId,
  });

  final EntryType type;
  final int amount;
  final String title;
  final String category;
  final String content;
  final String rawBody;
  final String normalizedBody;
  final String sourceType;
  final String institution;
  final String eventType;
  final String matchedRule;
  final String sender;
  final DateTime date;
  final String sourceId;

  WalletKeeperSmsDraft toDraft() {
    return WalletKeeperSmsDraft(
      id: sourceId,
      title: content.trim().isEmpty ? title : content,
      amount: amount.toDouble(),
      category: category,
      note: '',
      rawBody: rawBody,
      type: type,
      date: date,
      sourceAddress: sender,
      sourceType: sourceType,
      institution: institution,
      eventType: eventType,
      matchedRule: matchedRule,
      sourceAppIconBase64: '',
    );
  }
}

class WalletKeeperSmsDraft {
  const WalletKeeperSmsDraft({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.note,
    required this.rawBody,
    required this.type,
    required this.date,
    required this.sourceAddress,
    required this.sourceType,
    required this.institution,
    required this.eventType,
    required this.matchedRule,
    required this.sourceAppIconBase64,
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final String note;
  final String rawBody;
  final EntryType type;
  final DateTime date;
  final String sourceAddress;
  final String sourceType;
  final String institution;
  final String eventType;
  final String matchedRule;
  final String sourceAppIconBase64;

  WalletKeeperSmsDraft copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? note,
    String? rawBody,
    EntryType? type,
    DateTime? date,
    String? sourceAddress,
    String? sourceType,
    String? institution,
    String? eventType,
    String? matchedRule,
    String? sourceAppIconBase64,
  }) {
    return WalletKeeperSmsDraft(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      rawBody: rawBody ?? this.rawBody,
      type: type ?? this.type,
      date: date ?? this.date,
      sourceAddress: sourceAddress ?? this.sourceAddress,
      sourceType: sourceType ?? this.sourceType,
      institution: institution ?? this.institution,
      eventType: eventType ?? this.eventType,
      matchedRule: matchedRule ?? this.matchedRule,
      sourceAppIconBase64: sourceAppIconBase64 ?? this.sourceAppIconBase64,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'note': note,
    'rawBody': rawBody,
    'type': type.name,
    'date': date.toIso8601String(),
    'sourceAddress': sourceAddress,
    'sourceType': sourceType,
    'institution': institution,
    'eventType': eventType,
    'matchedRule': matchedRule,
    'sourceAppIconBase64': sourceAppIconBase64,
  };

  factory WalletKeeperSmsDraft.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type']?.toString().trim().isNotEmpty ?? false)
        ? json['type'].toString().trim()
        : EntryType.expense.name;
    final rawDate = json['date']?.toString();
    return WalletKeeperSmsDraft(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: json['category']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      rawBody: json['rawBody']?.toString() ?? '',
      type: EntryType.values.byName(rawType),
      date: rawDate == null || rawDate.isEmpty
          ? DateTime.now()
          : DateTime.parse(rawDate),
      sourceAddress: json['sourceAddress']?.toString() ?? '',
      sourceType: json['sourceType']?.toString() ?? 'sms',
      institution: json['institution']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? '',
      matchedRule: json['matchedRule']?.toString() ?? '',
      sourceAppIconBase64: json['sourceAppIconBase64']?.toString() ?? '',
    );
  }

  LedgerEntry toEntry() {
    return LedgerEntry(
      id: id,
      title: title,
      amount: amount,
      category: category,
      note: note,
      attachmentPaths: const [],
      type: type,
      date: date,
      createdAt: DateTime.now(),
    );
  }
}

class WalletKeeperSmsHandledResult {
  const WalletKeeperSmsHandledResult({
    required this.draft,
    required this.savedDirectly,
    required this.analysis,
  });

  final WalletKeeperSmsDraft draft;
  final bool savedDirectly;
  final WalletKeeperParsedMessage analysis;
}

class WalletKeeperSmsAutomationRepository {
  final LedgerRepository _ledgerRepository = LedgerRepository();
  final Telephony _telephony = Telephony.instance;
  final WalletKeeperSmsReportClient _reportClient =
      WalletKeeperSmsReportClient();

  Future<WalletKeeperSmsHandledResult?> handleIncomingMessage(
    SmsMessage message, {
    bool autoSaveToLedger = false,
  }) async {
    final analysis = WalletKeeperSmsParser.parse(message);
    if (analysis == null) return null;
    return _handleIncomingDraftInternal(
      draft: analysis.toDraft(),
      analysis: analysis,
      autoSaveToLedger: autoSaveToLedger,
    );
  }

  Future<WalletKeeperSmsHandledResult?> handleIncomingDraft(
    WalletKeeperSmsDraft draft, {
    bool autoSaveToLedger = false,
  }) async {
    final analysis = WalletKeeperParsedMessage(
      type: draft.type,
      amount: draft.amount.toInt(),
      title: draft.title,
      category: draft.category,
      content: draft.note,
      rawBody: draft.rawBody,
      normalizedBody: draft.rawBody,
      sourceType: draft.sourceType,
      institution: draft.institution,
      eventType: draft.eventType,
      matchedRule: draft.matchedRule,
      sender: draft.sourceAddress,
      date: draft.date,
      sourceId: draft.id,
    );
    return _handleIncomingDraftInternal(
      draft: draft,
      analysis: analysis,
      autoSaveToLedger: autoSaveToLedger,
    );
  }

  Future<WalletKeeperSmsHandledResult?> _handleIncomingDraftInternal({
    required WalletKeeperSmsDraft draft,
    required WalletKeeperParsedMessage analysis,
    required bool autoSaveToLedger,
  }) async {
    if (await _isProcessed(draft.id)) return null;
    if (autoSaveToLedger) {
      final entries = await _ledgerRepository.load();
      if (entries.any(
        (entry) => _entryIdentityKey(entry) == _draftIdentityKey(draft),
      )) {
        await _markProcessed(draft.id);
        return null;
      }
      final nextEntries = [...entries, draft.toEntry()]
        ..sort((a, b) => b.date.compareTo(a.date));
      await _ledgerRepository.save(nextEntries);
      await _markProcessed(draft.id);
      unawaited(_reportClient.reportDetectedMessage(draft));
      return WalletKeeperSmsHandledResult(
        draft: draft,
        savedDirectly: true,
        analysis: analysis,
      );
    }

    final drafts = await loadInboxDrafts();
    if (drafts.any(
      (item) => _draftIdentityKey(item) == _draftIdentityKey(draft),
    )) {
      await _markProcessed(draft.id);
      return null;
    }
    final next = [...drafts, draft]..sort((a, b) => b.date.compareTo(a.date));
    await _saveDrafts(next);
    await _markProcessed(draft.id);
    unawaited(_reportClient.reportDetectedMessage(draft));
    return WalletKeeperSmsHandledResult(
      draft: draft,
      savedDirectly: false,
      analysis: analysis,
    );
  }

  Future<List<WalletKeeperSmsDraft>> loadInboxDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_smsInboxDraftsKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded =
        (jsonDecode(raw) as List)
            .cast<Map<String, dynamic>>()
            .map(WalletKeeperSmsDraft.fromJson)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return decoded;
  }

  Future<List<WalletKeeperSmsDraft>> importRecentMessages({
    int recentDays = 60,
  }) async {
    if (!Platform.isAndroid) return const [];
    final cutoff = DateTime.now().subtract(Duration(days: recentDays));
    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );
    final existing = await loadInboxDrafts();
    final merged = {
      for (final draft in existing) _draftIdentityKey(draft): draft,
    };
    for (final message in messages) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        message.date ?? DateTime.now().millisecondsSinceEpoch,
      );
      if (date.isBefore(cutoff)) continue;
      final analysis = WalletKeeperSmsParser.parse(message);
      if (analysis == null) continue;
      final draft = analysis.toDraft();
      final identityKey = _draftIdentityKey(draft);
      if (merged.containsKey(identityKey)) continue;
      if (await _isProcessed(draft.id)) continue;
      merged[identityKey] = draft;
      await _markProcessed(draft.id);
      unawaited(_reportClient.reportDetectedMessage(draft));
    }
    for (final mms in await _queryRecentMms(recentDays: recentDays)) {
      final identityKey = _draftIdentityKey(mms);
      if (merged.containsKey(identityKey)) continue;
      if (await _isProcessed(mms.id)) continue;
      merged[identityKey] = mms;
      await _markProcessed(mms.id);
      unawaited(_reportClient.reportDetectedMessage(mms));
    }
    final next = merged.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    await _saveDrafts(next);
    return next;
  }

  Future<List<WalletKeeperSmsDraft>> findUnprocessedRecentMessages({
    int recentDays = 7,
    int limit = 20,
  }) async {
    if (!Platform.isAndroid) return const [];
    final cutoff = DateTime.now().subtract(Duration(days: recentDays));
    final messages = await _telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );
    final existing = await loadInboxDrafts();
    final existingKeys = existing.map(_draftIdentityKey).toSet();
    final pending = <WalletKeeperSmsDraft>[];
    for (final message in messages) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        message.date ?? DateTime.now().millisecondsSinceEpoch,
      );
      if (date.isBefore(cutoff)) continue;
      final analysis = WalletKeeperSmsParser.parse(message);
      if (analysis == null) continue;
      final draft = analysis.toDraft();
      final identityKey = _draftIdentityKey(draft);
      if (existingKeys.contains(identityKey)) continue;
      if (await _isProcessed(draft.id)) continue;
      pending.add(draft);
      existingKeys.add(identityKey);
    }
    final mmsDrafts = await _queryRecentMms(
      recentDays: recentDays,
      limit: limit,
    );
    for (final draft in mmsDrafts) {
      final identityKey = _draftIdentityKey(draft);
      if (existingKeys.contains(identityKey)) continue;
      if (await _isProcessed(draft.id)) continue;
      pending.add(draft);
      existingKeys.add(identityKey);
    }
    pending.sort((a, b) => b.date.compareTo(a.date));
    return pending.length <= limit ? pending : pending.take(limit).toList();
  }

  Future<List<WalletKeeperSmsDraft>> saveInboxDrafts(
    List<WalletKeeperSmsDraft> drafts,
  ) async {
    final existing = await loadInboxDrafts();
    final merged = {
      for (final draft in existing) _draftIdentityKey(draft): draft,
    };
    final acceptedDrafts = <WalletKeeperSmsDraft>[];
    for (final draft in drafts) {
      if (await _isProcessed(draft.id)) {
        continue;
      }
      final identityKey = _draftIdentityKey(draft);
      if (merged.containsKey(identityKey)) {
        await _markProcessed(draft.id);
        continue;
      }
      merged[identityKey] = draft;
      acceptedDrafts.add(draft);
    }
    final next = merged.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    await _saveDrafts(next);
    for (final draft in acceptedDrafts) {
      await _markProcessed(draft.id);
      unawaited(_reportClient.reportDetectedMessage(draft));
    }
    return next;
  }

  Future<void> removeDraft(String id) async {
    final drafts = await loadInboxDrafts();
    final next = drafts.where((draft) => draft.id != id).toList();
    await _saveDrafts(next);
  }

  Future<void> clearDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_smsInboxDraftsKey);
  }

  Future<void> _saveDrafts(List<WalletKeeperSmsDraft> drafts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _smsInboxDraftsKey,
      jsonEncode(drafts.map((draft) => draft.toJson()).toList()),
    );
  }

  Future<bool> _isProcessed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_processedSmsIdsKey) ?? const [];
    return ids.contains(id);
  }

  Future<void> _markProcessed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = List<String>.from(
      prefs.getStringList(_processedSmsIdsKey) ?? const <String>[],
    );
    if (!ids.contains(id)) {
      ids.add(id);
    }
    final trimmed = ids.length <= 200 ? ids : ids.sublist(ids.length - 200);
    await prefs.setStringList(_processedSmsIdsKey, trimmed);
  }

  Future<List<WalletKeeperSmsDraft>> _queryRecentMms({
    required int recentDays,
    int limit = 100,
  }) async {
    if (!Platform.isAndroid) return const [];
    final raw = await _mmsReaderChannel.invokeMethod<List<dynamic>>(
      'queryRecentMms',
      {'recentDays': recentDays, 'limit': limit},
    );
    if (raw == null) return const [];
    final drafts = <WalletKeeperSmsDraft>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final body = (item['body'] as String?)?.trim() ?? '';
      if (body.isEmpty) continue;
      final draft = WalletKeeperSmsParser.parseRawMessage(
        body: body,
        sender: (item['address'] as String?)?.trim() ?? '',
        dateMillis:
            (item['dateMillis'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
        sourceId: (item['id'] as String?)?.trim(),
        sourceType: 'mms',
      );
      if (draft != null) {
        drafts.add(draft.toDraft());
      }
    }
    drafts.sort((a, b) => b.date.compareTo(a.date));
    return drafts;
  }

  Future<List<WalletKeeperSmsDraft>> consumePendingMms() async {
    if (!Platform.isAndroid) return const [];
    final raw = await _mmsReaderChannel.invokeMethod<List<dynamic>>(
      'consumePendingMms',
    );
    if (raw == null) return const [];
    final drafts = <WalletKeeperSmsDraft>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final body = (item['body'] as String?)?.trim() ?? '';
      if (body.isEmpty) continue;
      final draft = WalletKeeperSmsParser.parseRawMessage(
        body: body,
        sender: (item['address'] as String?)?.trim() ?? '',
        dateMillis:
            (item['dateMillis'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
        sourceId: (item['id'] as String?)?.trim(),
        sourceType: 'mms',
      );
      if (draft != null) {
        drafts.add(draft.toDraft());
      }
    }
    return drafts;
  }

  Future<List<WalletKeeperSmsDraft>> consumePendingAppNotifications() async {
    if (!Platform.isAndroid) return const [];
    final raw = await _mmsReaderChannel.invokeMethod<List<dynamic>>(
      'consumePendingAppNotifications',
    );
    if (raw == null) return const [];
    final drafts = <WalletKeeperSmsDraft>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final body = (item['body'] as String?)?.trim() ?? '';
      if (body.isEmpty) continue;
      final titleHint = (item['titleHint'] as String?)?.trim() ?? '';
      final textBody = (item['textBody'] as String?)?.trim() ?? '';
      final sourceAddress = (item['address'] as String?)?.trim() ?? '';
      final draft = WalletKeeperSmsParser.parseRawMessage(
        body: textBody.isNotEmpty ? textBody : body,
        sender: sourceAddress,
        dateMillis:
            (item['dateMillis'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
        sourceId: (item['id'] as String?)?.trim(),
        sourceType: 'app_notification',
        titleHint: titleHint,
        rawBodyOverride: body,
      );
      if (draft != null) {
        final iconBytes = await const WalletKeeperNotificationAccessRepository()
            .getApplicationIconBytes(sourceAddress);
        drafts.add(
          draft.toDraft().copyWith(
            sourceAppIconBase64: iconBytes == null || iconBytes.isEmpty
                ? ''
                : base64Encode(iconBytes),
          ),
        );
      }
    }
    return drafts;
  }

  Future<List<WalletKeeperSmsDraft>> findUnprocessedRecentMms({
    int recentMinutes = 30,
    int limit = 12,
  }) async {
    if (!Platform.isAndroid) return const [];
    final recentDays = math.max(1, (recentMinutes / (24 * 60)).ceil());
    final cutoff = DateTime.now().subtract(Duration(minutes: recentMinutes));
    final existing = await loadInboxDrafts();
    final existingKeys = existing.map(_draftIdentityKey).toSet();
    final pending = <WalletKeeperSmsDraft>[];
    for (final draft in await _queryRecentMms(
      recentDays: recentDays,
      limit: limit * 3,
    )) {
      if (draft.date.isBefore(cutoff)) continue;
      final identityKey = _draftIdentityKey(draft);
      if (existingKeys.contains(identityKey)) continue;
      if (await _isProcessed(draft.id)) continue;
      pending.add(draft);
      existingKeys.add(identityKey);
      if (pending.length >= limit) break;
    }
    return pending;
  }

  String _draftIdentityKey(WalletKeeperSmsDraft draft) {
    if (draft.id.trim().isNotEmpty) {
      return draft.id.trim();
    }
    return '${draft.sourceAddress.trim()}|${draft.date.millisecondsSinceEpoch}';
  }

  String _entryIdentityKey(LedgerEntry entry) {
    if (entry.id.trim().isNotEmpty) {
      return entry.id.trim();
    }
    return '|${entry.date.millisecondsSinceEpoch}';
  }
}

class WalletKeeperSmsReportClient {
  Future<void> reportDetectedMessage(WalletKeeperSmsDraft draft) async {
    if (!Platform.isAndroid) return;
    final settings = await WalletKeeperSmsSettingsRepository().load();
    if (!settings.shareHeuristicReports) return;
    if (draft.rawBody.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final installId =
        prefs.getString(_walletKeeperInstallIdKey) ?? _createInstallId();
    if (!prefs.containsKey(_walletKeeperInstallIdKey)) {
      await prefs.setString(_walletKeeperInstallIdKey, installId);
    }

    final client = HttpClient();
    try {
      final request = await client.postUrl(
        Uri.parse(_walletKeeperSmsReportUri),
      );
      request.headers.contentType = ContentType.json;
      request.add(
        utf8.encode(
          jsonEncode({
            'installId': installId,
            'platform': 'android',
            'sourceType': draft.sourceType,
            'sourceId': draft.id,
            'receivedAtSource': draft.date.toIso8601String(),
            'sender': draft.sourceAddress,
            'rawBody': draft.rawBody,
            'parserVersion': _walletKeeperSmsParserVersion,
            'institution': draft.institution,
            'eventType': draft.eventType,
            'entryType': draft.type.name,
            'amount': draft.amount,
            'categoryGuess': draft.category,
            'titleGuess': draft.title,
            'contentGuess': draft.note,
            'matchedRule': draft.matchedRule,
          }),
        ),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 4),
      );
      await response.drain<void>();
    } catch (_) {
      // Reporting must stay non-blocking.
    } finally {
      client.close(force: true);
    }
  }

  String _createInstallId() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}

class WalletKeeperNotificationService {
  static Future<void> showSmsDetectedNotification(
    WalletKeeperSmsHandledResult result,
  ) async {
    final draft = result.draft;
    if (Platform.isAndroid) {
      try {
        await _nativeNotificationChannel
            .invokeMethod('showFinancialNotification', {
              'notificationId': draft.id.hashCode,
              'title': draft.title,
              'amountText': formatCurrency(draft.amount),
              'timestampMillis': draft.date.millisecondsSinceEpoch,
            });
        return;
      } catch (_) {}
    }
    await _localNotifications.show(
      draft.id.hashCode,
      draft.title,
      result.savedDirectly
          ? '${formatCurrency(draft.amount)} 자동 등록됨'
          : '${formatCurrency(draft.amount)} 문자함에 담았어요',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _smsNotificationChannelId,
          _smsNotificationChannelName,
          channelDescription: '금융 문자 감지 알림',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/push_small_icon',
          color: Color(0xFFEB4D4B),
        ),
      ),
      payload: _smsInboxNotificationPayload,
    );
  }
}

class WalletKeeperSmsParser {
  static WalletKeeperParsedMessage? parse(SmsMessage message) {
    return parseRawMessage(
      body: (message.body ?? '').trim(),
      sender: (message.address ?? '').trim(),
      dateMillis: message.date ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  static WalletKeeperParsedMessage? parseRawMessage({
    required String body,
    required String sender,
    required int dateMillis,
    String? sourceId,
    String sourceType = 'sms',
    String titleHint = '',
    String? rawBodyOverride,
  }) {
    if (body.isEmpty) return null;
    final normalized = _normalizeForParsing(body);
    final normalizedTitle = _normalizeForParsing(titleHint);
    final institution = _resolveInstitution(
      [normalizedTitle, normalized].where((item) => item.isNotEmpty).join(' '),
      sender,
      sourceType: sourceType,
    );
    final eventType = _resolveEventType(
      normalizedTitle.isNotEmpty ? '$normalizedTitle $normalized' : normalized,
    );
    final type = _resolveType(
      eventType,
      normalizedTitle.isNotEmpty ? '$normalizedTitle $normalized' : normalized,
    );
    if (type == null) return null;
    final amount = _extractAmount(
      normalizedTitle.isNotEmpty ? '$normalizedTitle $normalized' : normalized,
      type,
    );
    if (amount == null) return null;
    final receivedDate = DateTime.fromMillisecondsSinceEpoch(dateMillis);
    final date =
        _extractTransactionDate(
          normalizedTitle.isNotEmpty
              ? '$normalizedTitle $normalized'
              : normalized,
          eventType: eventType,
          fallback: receivedDate,
        ) ??
        receivedDate;
    final target = _extractTarget(
      normalized,
      eventType,
      institution,
      sourceType: sourceType,
      titleHint: normalizedTitle,
    );
    final matchedRule = _buildMatchedRule(
      institution: institution,
      eventType: eventType,
      target: target,
      type: type,
    );
    final title = _resolveTitle(
      normalizedTitle.isNotEmpty ? '$normalizedTitle $normalized' : normalized,
      sender,
      institution,
      eventType,
      target,
      type,
    );
    final category = _resolveCategory(
      normalizedTitle.isNotEmpty ? '$normalizedTitle $normalized' : normalized,
      type,
      institution,
      eventType,
      target,
    );
    final content = _resolveContent(
      normalized,
      institution,
      eventType,
      target,
      type,
      sourceType: sourceType,
      titleHint: normalizedTitle,
    );
    final id =
        sourceId ?? base64Url.encode(utf8.encode('${sender}_$dateMillis'));
    return WalletKeeperParsedMessage(
      type: type,
      amount: amount,
      title: title,
      category: category,
      content: content,
      rawBody: rawBodyOverride ?? body,
      normalizedBody: normalized,
      sourceType: sourceType,
      institution: institution,
      eventType: eventType,
      matchedRule: matchedRule,
      sender: sender,
      date: date,
      sourceId: id,
    );
  }

  static String _normalizeForParsing(String body) {
    return body
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\[Web발신\]\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('\u00A0', ' ')
        .trim();
  }

  static DateTime? _extractTransactionDate(
    String body, {
    required String eventType,
    required DateTime fallback,
  }) {
    final fullDateMatches = <RegExpMatch>[
      ...RegExp(r'(\d{4})[-./](\d{1,2})[-./](\d{1,2})').allMatches(body),
      ...RegExp(r'(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일').allMatches(body),
    ];
    for (final match in fullDateMatches) {
      final year = int.tryParse(match.group(1) ?? '');
      final month = int.tryParse(match.group(2) ?? '');
      final day = int.tryParse(match.group(3) ?? '');
      final date = _safeDate(year, month, day, fallback);
      if (date != null) return date;
    }

    final monthDayPatterns = <RegExp>[
      RegExp(r'(?:카드대금|결제일|납부일|출금예정일?)\s*(\d{1,2})/(\d{1,2})'),
      RegExp(
        r'(\d{1,2})/(\d{1,2})\s*(?:카드대금|결제일|납부일|출금|출금예정|자동이체|입금|환불|카드취소|결제취소|이체)',
      ),
      RegExp(
        r'\]\s*[^\s]+\s+(\d{1,2})/(\d{1,2})\s+(?:입금|출금|승인|결제|자동이체|환불|카드취소|결제취소|이체)',
      ),
      RegExp(r'(\d{1,2})월\s*(\d{1,2})일'),
    ];
    for (final pattern in monthDayPatterns) {
      final match = pattern.firstMatch(body);
      if (match == null) continue;
      final month = int.tryParse(match.group(1) ?? '');
      final day = int.tryParse(match.group(2) ?? '');
      final date = _safeDate(fallback.year, month, day, fallback);
      if (date != null) return _adjustYearIfNeeded(date, fallback, eventType);
    }

    final leadingMonthDay = RegExp(
      r'^\[[^\]]+\]\s*(\d{1,2})/(\d{1,2})\s+\d{1,2}:\d{2}',
    );
    final leadingMatch = leadingMonthDay.firstMatch(body);
    if (leadingMatch != null) {
      final month = int.tryParse(leadingMatch.group(1) ?? '');
      final day = int.tryParse(leadingMatch.group(2) ?? '');
      final date = _safeDate(fallback.year, month, day, fallback);
      if (date != null) return _adjustYearIfNeeded(date, fallback, eventType);
    }

    final leadingDateTime = RegExp(
      r'^(?:[가-힣A-Za-z0-9*]+님?\s+)?(\d{1,2})/(\d{1,2})\s+\d{1,2}:\d{2}',
    );
    final leadingDateTimeMatch = leadingDateTime.firstMatch(body);
    if (leadingDateTimeMatch != null) {
      final month = int.tryParse(leadingDateTimeMatch.group(1) ?? '');
      final day = int.tryParse(leadingDateTimeMatch.group(2) ?? '');
      final date = _safeDate(fallback.year, month, day, fallback);
      if (date != null) return _adjustYearIfNeeded(date, fallback, eventType);
    }

    return null;
  }

  static DateTime? _safeDate(
    int? year,
    int? month,
    int? day,
    DateTime fallback,
  ) {
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    try {
      return DateTime(year, month, day, fallback.hour, fallback.minute);
    } catch (_) {
      return null;
    }
  }

  static DateTime _adjustYearIfNeeded(
    DateTime parsed,
    DateTime fallback,
    String eventType,
  ) {
    if (eventType == '카드대금' || eventType == '납부' || eventType == '자동이체') {
      final futureCandidate = DateTime(
        fallback.year + 1,
        parsed.month,
        parsed.day,
        fallback.hour,
        fallback.minute,
      );
      final pastCandidate = DateTime(
        fallback.year - 1,
        parsed.month,
        parsed.day,
        fallback.hour,
        fallback.minute,
      );
      final currentDiff = parsed.difference(fallback).inDays.abs();
      final futureDiff = futureCandidate.difference(fallback).inDays.abs();
      final pastDiff = pastCandidate.difference(fallback).inDays.abs();
      if (futureDiff < currentDiff && futureDiff <= 200) return futureCandidate;
      if (pastDiff < currentDiff && pastDiff <= 200) return pastCandidate;
    }
    return parsed;
  }

  static String _resolveInstitution(
    String body,
    String sender, {
    String sourceType = 'sms',
  }) {
    final bracketMatch = RegExp(r'^\[([^\]]+)\]').firstMatch(body);
    if (bracketMatch != null) {
      final candidate = bracketMatch.group(1)?.trim() ?? '';
      if (candidate.isNotEmpty) return candidate;
    }
    final haystacks = <String>[body.toLowerCase(), sender.toLowerCase()];
    for (final institution in _knownInstitutions) {
      final needle = institution.toLowerCase();
      if (haystacks.any((text) => text.contains(needle))) {
        return institution;
      }
    }
    if (sourceType == 'app_notification' &&
        _looksLikePackageName(sender.trim())) {
      return '';
    }
    return sender.trim();
  }

  static String _resolveEventType(String body) {
    final orderedRules = <({String eventType, List<String> keywords})>[
      (eventType: '카드대금', keywords: const ['카드대금', '카드 대금', '청구금액', '결제예정금액']),
      (eventType: '자동이체', keywords: const ['자동이체', '자동 출금']),
      (eventType: '납부', keywords: const ['납부', '요금출금']),
      (
        eventType: '환불',
        keywords: const ['환불', '취소완료', '결제취소', '카드취소', '승인취소', '취소'],
      ),
      (eventType: '입금', keywords: const ['입금', '급여', '월급', '환급', '캐시백', '적립']),
      (eventType: '출금', keywords: const ['출금', '인출']),
      (eventType: '승인', keywords: const ['승인', '일시불', '체크승인']),
      (eventType: '결제', keywords: const ['결제', '사용', '구매']),
      (eventType: '이체', keywords: const ['이체', '송금', '계좌이동']),
    ];
    for (final rule in orderedRules) {
      if (_containsAny(body, rule.keywords)) return rule.eventType;
    }
    return '미분류';
  }

  static int? _extractAmount(String body, EntryType type) {
    final normalized = body.replaceAll('\r', '');
    final directAmount = _extractAmountByKeywordPattern(normalized, type);
    if (directAmount != null) return directAmount;
    final matches = RegExp(
      r'([0-9][0-9,]*)\s*원',
    ).allMatches(normalized).toList();
    if (matches.isEmpty) return null;

    final scored = <({int amount, int score, int index})>[];
    for (final match in matches) {
      final raw = match.group(1);
      final amount = int.tryParse(raw?.replaceAll(',', '') ?? '');
      if (amount == null || amount <= 0) continue;
      final start = match.start;
      final end = match.end;
      final contextStart = math.max(0, start - 16);
      final contextEnd = math.min(normalized.length, end + 16);
      final context = normalized.substring(contextStart, contextEnd);

      var score = 0;
      if (_containsAny(context, _typePriorityKeywords(type))) score += 12;
      if (_containsAny(context, _genericTransactionKeywords)) score += 6;
      if (_containsAny(context, _ignoredAmountContextKeywords)) score -= 14;
      if (_looksLikeBalanceContext(normalized, start)) score -= 18;
      if (_looksLikeAccountContext(normalized, start)) score -= 18;
      if (start < normalized.length ~/ 2) score += 2;

      scored.add((amount: amount, score: score, index: start));
    }

    if (scored.isEmpty) return null;
    scored.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      final indexCompare = a.index.compareTo(b.index);
      if (indexCompare != 0) return indexCompare;
      return a.amount.compareTo(b.amount);
    });
    return scored.first.amount;
  }

  static int? _extractAmountByKeywordPattern(String body, EntryType type) {
    final patterns = switch (type) {
      EntryType.expense => const [
        r'카드대금\s*([0-9][0-9,]*)\s*원',
        r'청구금액\s*([0-9][0-9,]*)\s*원',
        r'결제예정금액\s*([0-9][0-9,]*)\s*원',
        r'자동이체\s*([0-9][0-9,]*)\s*원',
        r'출금\s*([0-9][0-9,]*)\s*원',
        r'([0-9][0-9,]*)\s*원\s*(?:출금|승인|결제|사용|자동이체|납부|인출|카드대금)',
      ],
      EntryType.income => const [
        r'입금\s*([0-9][0-9,]*)\s*원',
        r'카드취소\s*([0-9][0-9,]*)\s*원',
        r'결제취소\s*([0-9][0-9,]*)\s*원',
        r'([0-9][0-9,]*)\s*원\s*(?:입금|환급|환불|급여|적립|캐시백|카드취소|결제취소|취소)',
      ],
      EntryType.transfer => const [
        r'이체\s*([0-9][0-9,]*)\s*원',
        r'([0-9][0-9,]*)\s*원\s*(?:이체|송금|계좌이동)',
      ],
    };
    for (final pattern in patterns) {
      final match = RegExp(pattern).firstMatch(body);
      if (match == null) continue;
      final raw = match.group(1);
      final amount = int.tryParse(raw?.replaceAll(',', '') ?? '');
      if (amount != null && amount > 0) {
        return amount;
      }
    }
    return null;
  }

  static EntryType? _resolveType(String eventType, String body) {
    switch (eventType) {
      case '입금':
      case '환불':
        return EntryType.income;
      case '이체':
        return EntryType.transfer;
      case '자동이체':
      case '카드대금':
      case '출금':
      case '승인':
      case '결제':
      case '납부':
        return EntryType.expense;
    }
    final text = body.toLowerCase();
    if (_containsAny(text, const ['입금', '급여', '환급', '캐시백', '적립'])) {
      return EntryType.income;
    }
    if (_containsAny(text, const ['이체', '송금', '계좌이동'])) {
      return EntryType.transfer;
    }
    if (_containsAny(text, const [
      '승인',
      '결제',
      '사용',
      '출금',
      '납부',
      '자동이체',
      '인출',
      '카드대금',
      '청구금액',
    ])) {
      return EntryType.expense;
    }
    return null;
  }

  static const List<String> _genericTransactionKeywords = [
    '입금',
    '출금',
    '승인',
    '결제',
    '사용',
    '이체',
    '자동이체',
    '인출',
    '환불',
    '환급',
    '취소',
    '카드취소',
    '결제취소',
    '납부',
    '카드대금',
    '청구금액',
  ];

  static const List<String> _ignoredAmountContextKeywords = [
    '잔액',
    '잔여',
    '남은',
    '한도',
    '가능',
    '누적',
    '승인번호',
    '계좌번호',
    '문의',
    '고객센터',
  ];

  static List<String> _typePriorityKeywords(EntryType type) {
    switch (type) {
      case EntryType.expense:
        return const ['출금', '승인', '결제', '사용', '자동이체', '납부', '인출'];
      case EntryType.income:
        return const [
          '입금',
          '환급',
          '환불',
          '급여',
          '적립',
          '캐시백',
          '취소',
          '카드취소',
          '결제취소',
        ];
      case EntryType.transfer:
        return const ['이체', '송금', '계좌이동'];
    }
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  static bool _looksLikeBalanceContext(String body, int amountStart) {
    final left = body.substring(math.max(0, amountStart - 6), amountStart);
    return left.contains('잔액') || left.contains('잔여') || left.contains('남은');
  }

  static bool _looksLikeAccountContext(String body, int amountStart) {
    final left = body.substring(math.max(0, amountStart - 10), amountStart);
    return left.contains('계좌') || left.contains('번호');
  }

  static String _extractTarget(
    String body,
    String eventType,
    String institution, {
    String sourceType = 'sms',
    String titleHint = '',
  }) {
    if (eventType == '카드대금') {
      return '카드대금';
    }

    final combined = titleHint.isNotEmpty ? '$titleHint $body' : body;

    if (sourceType == 'app_notification') {
      final pipeSegments = combined
          .split('|')
          .map(_cleanTargetCandidate)
          .map(_stripPaymentInstrumentNoise)
          .where((item) => item.isNotEmpty)
          .where((item) => item != institution)
          .where((item) => !_looksLikePackageName(item))
          .where((item) => !_looksLikePaymentInstrument(item))
          .toList();
      if (pipeSegments.isNotEmpty) {
        return pipeSegments.last;
      }
    }

    final slashMatch = RegExp(r'/\s*([^/]+)$').firstMatch(body);
    final slashTarget = _cleanTargetCandidate(slashMatch?.group(1) ?? '');
    if (slashTarget.isNotEmpty) {
      return slashTarget;
    }

    final merchantAfterAmount = RegExp(
      r'(?:승인|결제|사용)\s*(?:[0-9][0-9,]{2,}\s*원)?\s*([가-힣A-Za-z0-9&().\- ]{2,32})$',
    ).firstMatch(body);
    final merchantCandidate = _cleanTargetCandidate(
      merchantAfterAmount?.group(1) ?? '',
    );
    if (merchantCandidate.isNotEmpty) {
      return merchantCandidate;
    }

    final cardApprovalPattern = RegExp(
      r'\]\s*(?:\d{2}/\d{2}\s+\d{1,2}:\d{2}\s+)?(.+?)\s+[0-9][0-9,]{2,}\s*원\s*(?:승인|결제|사용)',
    ).firstMatch(body);
    final cardApprovalTarget = _cleanTargetCandidate(
      cardApprovalPattern?.group(1) ?? '',
    );
    if (cardApprovalTarget.isNotEmpty) {
      return cardApprovalTarget;
    }

    final depositorPattern = RegExp(
      r'(?:\]\s*)?(?:[가-힣A-Za-z0-9*]+\s+)?(?:\d{2}/\d{2}\s+\d{1,2}:\d{2}\s+)?([가-힣A-Za-z0-9 ]{2,20}?)(?:님)?\s+[0-9][0-9,]{2,}\s*원?\s*입금',
    ).firstMatch(body);
    final depositor = _cleanTargetCandidate(depositorPattern?.group(1) ?? '');
    if (depositor.isNotEmpty) {
      return depositor;
    }

    if (eventType == '입금' || eventType == '환불') {
      final trailingIncome = RegExp(
        r'(?:입금|환불|카드취소|결제취소)\s*[0-9][0-9,]{2,}\s*원?(?:\s*\([^)]*\))?\s*(.+)$',
      ).firstMatch(combined);
      final trailingIncomeTarget = _cleanTargetCandidate(
        trailingIncome?.group(1) ?? '',
      );
      if (trailingIncomeTarget.isNotEmpty) {
        return trailingIncomeTarget;
      }
    }

    if (eventType == '자동이체' || eventType == '납부') {
      final trailing = RegExp(
        r'(?:자동이체|납부|출금)\s*[0-9][0-9,]{2,}\s*원?(?:\s*(?:출금|납부))?\s*(.+)$',
      ).firstMatch(combined);
      final trailingTarget = _cleanTargetCandidate(trailing?.group(1) ?? '');
      if (trailingTarget.isNotEmpty) {
        return trailingTarget;
      }
    }

    if (eventType == '출금') {
      final trailingExpense = RegExp(
        r'(?:출금|오픈뱅킹출금)\s*[0-9][0-9,]{2,}\s*원?(?:\s*잔액[0-9,]+)?\s*(.+)$',
      ).firstMatch(combined);
      final trailingExpenseTarget = _cleanTargetCandidate(
        trailingExpense?.group(1) ?? '',
      );
      if (trailingExpenseTarget.isNotEmpty) {
        return trailingExpenseTarget;
      }
    }

    if (sourceType == 'app_notification' &&
        (_containsAny(combined, const ['오픈뱅킹', '잔액']) ||
            RegExp(r'\d{2,}-\*{2,}-\*{2,}\d+').hasMatch(combined))) {
      return '';
    }

    if (institution.isNotEmpty &&
        institution != body &&
        !(sourceType == 'app_notification' &&
            _looksLikePackageName(institution))) {
      return institution;
    }
    return '';
  }

  static String _resolveTitle(
    String body,
    String sender,
    String institution,
    String eventType,
    String target,
    EntryType type,
  ) {
    if (target.isNotEmpty && target != institution) {
      return target;
    }
    if (institution.isNotEmpty) return institution;
    if (sender.isNotEmpty && !_looksLikePackageName(sender)) return sender;
    switch (type) {
      case EntryType.expense:
        return eventType == '자동이체' ? '자동이체' : '문자 지출';
      case EntryType.income:
        return '문자 수입';
      case EntryType.transfer:
        return '문자 이체';
    }
  }

  static String _resolveCategory(
    String body,
    EntryType type,
    String institution,
    String eventType,
    String target,
  ) {
    if (type == EntryType.income) {
      if (_containsAny(body, const ['급여', '월급'])) return '급여';
      if (_containsAny(body, const ['환불', '환급'])) return '환급';
      if (_containsAny(body, const ['캐시백', '적립'])) return '혜택';
      if (target.isNotEmpty) return '입금';
      return '문자 수입';
    }
    if (type == EntryType.transfer) {
      return '이체';
    }
    if (eventType == '카드대금') {
      return '카드값';
    }
    if (eventType == '자동이체' || eventType == '납부') {
      if (_containsAny('$body $target', const ['통신', '휴대폰', '요금'])) {
        return '통신';
      }
      if (_containsAny('$body $target', const ['보험'])) return '보험';
      if (_containsAny('$body $target', const ['관리비', '월세', '전세'])) {
        return '주거';
      }
      if (_containsAny('$body $target', const ['가스', '전기', '수도'])) {
        return '공과금';
      }
      return '고정비';
    }
    const categoryMap = <String, String>{
      '스타벅스': '식비',
      '카페': '식비',
      '커피': '식비',
      '편의점': '생활',
      '마트': '생활',
      '배달': '식비',
      '치킨': '식비',
      '피자': '식비',
      '버거': '식비',
      '지하철': '교통',
      '버스': '교통',
      '택시': '교통',
      '주유': '교통',
      '교통': '교통',
      '쿠팡': '쇼핑',
      '네이버': '쇼핑',
      '쇼핑': '쇼핑',
      '통신': '통신',
      '휴대폰': '통신',
      '병원': '의료',
      '약국': '의료',
      '관리비': '주거',
      '보험': '보험',
      '넷플릭스': '구독',
      '유튜브': '구독',
      '애플': '구독',
      '구글': '구독',
    };
    final searchText = '$body $target $institution';
    for (final entry in categoryMap.entries) {
      if (searchText.contains(entry.key)) return entry.value;
    }
    switch (type) {
      case EntryType.expense:
        return eventType == '자동이체' || eventType == '납부' ? '고정비' : '지출';
      case EntryType.income:
        return '수입';
      case EntryType.transfer:
        return '이체';
    }
  }

  static String _resolveContent(
    String body,
    String institution,
    String eventType,
    String target,
    EntryType type, {
    String sourceType = 'sms',
    String titleHint = '',
  }) {
    final cleanTarget = target.trim();
    final combined = titleHint.isNotEmpty ? '$titleHint $body' : body;
    final appNotificationShouldSimplify =
        sourceType == 'app_notification' &&
        (_containsAny(combined, const ['오픈뱅킹', '잔액']) ||
            RegExp(r'\d{2,}-\*{2,}-\*{2,}\d+').hasMatch(combined));
    if (eventType == '카드대금') {
      if (institution.isNotEmpty) {
        return '$institution 카드대금';
      }
      return '카드대금 납부';
    }
    if (eventType == '자동이체' || eventType == '납부') {
      if (cleanTarget.isNotEmpty && cleanTarget != institution) {
        return '$cleanTarget 납부';
      }
      return '자동이체 납부';
    }
    if (eventType == '입금') {
      if (cleanTarget.isNotEmpty && cleanTarget != institution) {
        return '$cleanTarget 입금';
      }
      return '${institution.isNotEmpty ? institution : '계좌'} 입금';
    }
    if (eventType == '환불') {
      if (cleanTarget.isNotEmpty && cleanTarget != institution) {
        return '$cleanTarget 환불';
      }
      return '결제 환불';
    }
    if (eventType == '승인' || eventType == '결제') {
      if (cleanTarget.isNotEmpty && cleanTarget != institution) {
        return '$cleanTarget 결제';
      }
      return '${institution.isNotEmpty ? institution : '카드'} 결제';
    }
    if (eventType == '출금') {
      if (appNotificationShouldSimplify) {
        return '출금';
      }
      if (cleanTarget.isNotEmpty && cleanTarget != institution) {
        return '$cleanTarget 출금';
      }
      return '${institution.isNotEmpty ? institution : '계좌'} 출금';
    }
    if (eventType == '이체') {
      if (appNotificationShouldSimplify) {
        return '이체';
      }
      if (cleanTarget.isNotEmpty && cleanTarget != institution) {
        return '$cleanTarget 이체';
      }
      return '계좌 이체';
    }
    if (type == EntryType.expense) return '지출 내역';
    if (type == EntryType.income) return '수입 내역';
    return '이체 내역';
  }

  static String _buildMatchedRule({
    required String institution,
    required String eventType,
    required String target,
    required EntryType type,
  }) {
    final parts = <String>[
      if (institution.isNotEmpty) institution,
      eventType,
      if (target.isNotEmpty) 'target',
      type.name,
    ];
    return parts.join(':');
  }

  static String _cleanTargetCandidate(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'^\[.*?\]\s*'), '')
        .replaceAll(RegExp(r'https?://\S+'), '')
        .replaceAll(RegExp(r'\(\d{2}/\d{2}기준\)'), '')
        .replaceAll(RegExp(r'\(\d{4}[-./]\d{1,2}[-./]\d{1,2}기준\)'), '')
        .replaceAll(RegExp(r'\b\d{1,2}[:.]\d{2}\b'), '')
        .replaceAll(RegExp(r'\b\d{2}/\d{2}\b'), '')
        .replaceAll(RegExp(r'\b\d{1,2}\b(?=\s+\d{2,}-\*{2,}-\*{2,}\d+)'), '')
        .replaceAll(RegExp(r'\b\d{2,}-\*{2,}-\*{2,}\d+\b'), '')
        .replaceAll(RegExp(r'\b잔액\s*[0-9,]+\b'), '')
        .replaceAll(RegExp(r'\b[0-9][0-9,]{2,}\s*원\b'), '')
        .replaceAll(
          RegExp(r'\b(승인|결제|사용|출금|입금|자동이체|오픈뱅킹출금|납부|잔액|환불|카드대금|청구금액)\b'),
          '',
        )
        .replaceAll(RegExp(r'[()]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll(RegExp(r'^[\/:\-]+|[\/:\-]+$'), '')
        .trim();
    if (cleaned.isEmpty) return '';
    if (cleaned.length <= 1) return '';
    if (RegExp(r'^\d+$').hasMatch(cleaned)) return '';
    if (RegExp(r'.*\*{2,}.*').hasMatch(cleaned)) return '';
    if (_containsAny(cleaned, const ['잔액', '오픈뱅킹'])) return '';
    return cleaned;
  }

  static String _stripPaymentInstrumentNoise(String value) {
    return value
        .replaceAll(
          RegExp(
            r'\b(?:KB국민|국민|신한|우리|하나|현대|삼성|롯데|농협|NH농협|카카오|토스|IBK|기업|씨티|BC)[가-힣A-Za-z]*(?:체크|카드)\b',
          ),
          '',
        )
        .replaceAll(RegExp(r'\b(?:체크카드|신용카드|일시불|할부)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _looksLikePaymentInstrument(String value) {
    return RegExp(r'(체크|카드|계좌|은행|일시불|할부)').hasMatch(value);
  }

  static bool _looksLikePackageName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (!trimmed.contains('.')) return false;
    return RegExp(r'^[a-z0-9._]+$').hasMatch(trimmed);
  }

  static const List<String> _knownInstitutions = [
    '우리은행',
    '신한은행',
    '국민은행',
    'KB국민은행',
    '카카오뱅크',
    '토스뱅크',
    '케이뱅크',
    '하나은행',
    'NH농협은행',
    '농협은행',
    '기업은행',
    'IBK기업은행',
    'SC제일은행',
    '수협은행',
    '새마을금고',
    '우체국',
    '부산은행',
    '대구은행',
    '광주은행',
    '경남은행',
    '전북은행',
    '제주은행',
    '우리카드',
    '신한카드',
    'KB국민카드',
    '국민카드',
    '삼성카드',
    '현대카드',
    '롯데카드',
    '하나카드',
    '농협카드',
    'BC카드',
    '카카오페이',
    '토스',
    '네이버페이',
    '페이코',
  ];
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
    required this.attachmentPaths,
    required this.type,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final String note;
  final List<String> attachmentPaths;
  final EntryType type;
  final DateTime date;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category,
    'note': note,
    'attachmentPaths': attachmentPaths,
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
    attachmentPaths: ((json['attachmentPaths'] as List?) ?? const [])
        .map((item) => item.toString())
        .toList(),
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

class WalletKeeperMemoRepository {
  Future<List<WalletKeeperMemo>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_memoStorageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return decoded.map(WalletKeeperMemo.fromJson).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> save(List<WalletKeeperMemo> memos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _memoStorageKey,
      jsonEncode(memos.map((memo) => memo.toJson()).toList()),
    );
  }
}

class WalletKeeperBudgetRepository {
  Future<List<WalletKeeperBudgetSetting>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_budgetStorageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return decoded.map(WalletKeeperBudgetSetting.fromJson).toList()
      ..sort((a, b) {
        final monthCompare = b.monthKey.compareTo(a.monthKey);
        if (monthCompare != 0) return monthCompare;
        return a.category.compareTo(b.category);
      });
  }

  Future<void> save(List<WalletKeeperBudgetSetting> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _budgetStorageKey,
      jsonEncode(budgets.map((budget) => budget.toJson()).toList()),
    );
  }
}

class WalletKeeperInquiryRepository {
  static const _baseUrl = _walletKeeperAuthBaseUri;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<List<WalletKeeperInquiry>> fetchList(
    WalletKeeperUserSession session,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/inquiries/${session.userId}'),
      headers: _headers(session),
    );
    final payload =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode != 200 || payload['success'] != true) {
      throw Exception(payload['message'] ?? '문의 목록을 불러오지 못했습니다.');
    }
    return (((payload['data'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(WalletKeeperInquiry.fromServerJson)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> submit({
    required WalletKeeperUserSession session,
    required String title,
    required String content,
    required String replyEmail,
    String? appVersion,
  }) async {
    final package = await PackageInfo.fromPlatform();
    final response = await http.post(
      Uri.parse('$_baseUrl/inquiry'),
      headers: _headers(session),
      body: jsonEncode({
        'user_id': session.userId,
        'inquiry_type': 'inquiry',
        'subject': title,
        'content': content,
        'user_email': replyEmail.trim().isEmpty ? null : replyEmail.trim(),
        'user_name': session.name.trim().isEmpty ? null : session.name.trim(),
        'device_info': await _buildDeviceInfoLabel(),
        'app_version':
            appVersion ?? '${package.version}+${package.buildNumber}',
      }),
    );
    final payload =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode != 200 || payload['success'] != true) {
      throw Exception(payload['message'] ?? '문의 등록에 실패했습니다.');
    }
  }

  Map<String, String> _headers(WalletKeeperUserSession session) => {
    'Content-Type': 'application/json',
    if (session.token.isNotEmpty) 'Authorization': 'Bearer ${session.token}',
  };

  Future<String> _buildDeviceInfoLabel() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return 'Android ${info.version.release} (${info.model})';
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return 'iOS ${info.systemVersion} (${info.model})';
      }
    } catch (_) {}
    return Platform.operatingSystem;
  }
}

class WalletKeeperBudgetSetting {
  const WalletKeeperBudgetSetting({
    required this.id,
    required this.category,
    required this.amount,
    required this.monthKey,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String category;
  final double amount;
  final String monthKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'amount': amount,
    'monthKey': monthKey,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory WalletKeeperBudgetSetting.fromJson(Map<String, dynamic> json) =>
      WalletKeeperBudgetSetting(
        id: json['id'] as String,
        category: json['category'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        monthKey: json['monthKey'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class WalletKeeperMemo {
  const WalletKeeperMemo({
    required this.id,
    required this.title,
    required this.content,
    required this.monthKey,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final String monthKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'monthKey': monthKey,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory WalletKeeperMemo.fromJson(Map<String, dynamic> json) =>
      WalletKeeperMemo(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        monthKey: json['monthKey'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class WalletKeeperInquiry {
  const WalletKeeperInquiry({
    required this.id,
    required this.inquiryType,
    required this.title,
    required this.content,
    required this.status,
    required this.adminReply,
    required this.createdAt,
    required this.updatedAt,
    this.repliedAt,
  });

  final String id;
  final String inquiryType;
  final String title;
  final String content;
  final String status;
  final String adminReply;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? repliedAt;

  bool get hasReply => adminReply.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'inquiryType': inquiryType,
    'title': title,
    'content': content,
    'status': status,
    'adminReply': adminReply,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'repliedAt': repliedAt?.toIso8601String(),
  };

  factory WalletKeeperInquiry.fromJson(Map<String, dynamic> json) =>
      WalletKeeperInquiry(
        id: json['id'] as String,
        inquiryType: json['inquiryType'] as String? ?? 'inquiry',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        adminReply: json['adminReply'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(
          (json['updatedAt'] ?? json['createdAt']) as String,
        ),
        repliedAt: json['repliedAt'] == null
            ? null
            : DateTime.tryParse(json['repliedAt'] as String),
      );

  factory WalletKeeperInquiry.fromServerJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now();
    final repliedAt = DateTime.tryParse(json['replied_at']?.toString() ?? '');
    return WalletKeeperInquiry(
      id: json['id']?.toString() ?? const Uuid().v4(),
      inquiryType: json['inquiry_type']?.toString() ?? 'inquiry',
      title: json['subject']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      adminReply: json['admin_reply']?.toString() ?? '',
      createdAt: createdAt,
      updatedAt: repliedAt ?? createdAt,
      repliedAt: repliedAt,
    );
  }
}

class WalletKeeperUserSession {
  const WalletKeeperUserSession({
    required this.userId,
    required this.socialId,
    required this.loginType,
    required this.name,
    required this.email,
    required this.profileImage,
    required this.token,
    required this.sessionId,
    required this.deviceSerial,
  });

  final String userId;
  final String socialId;
  final String loginType;
  final String name;
  final String email;
  final String profileImage;
  final String token;
  final String sessionId;
  final String deviceSerial;

  bool get isGuest => loginType == 'device';

  String get providerLabel {
    switch (loginType) {
      case 'kakao':
        return '카카오';
      case 'google':
        return '구글';
      case 'naver':
        return '네이버';
      case 'apple':
        return '애플';
      default:
        return '비회원';
    }
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'socialId': socialId,
    'loginType': loginType,
    'name': name,
    'email': email,
    'profileImage': profileImage,
    'token': token,
    'sessionId': sessionId,
    'deviceSerial': deviceSerial,
  };

  factory WalletKeeperUserSession.fromJson(Map<String, dynamic> json) =>
      WalletKeeperUserSession(
        userId: json['userId'] as String,
        socialId: json['socialId'] as String? ?? '',
        loginType: json['loginType'] as String? ?? 'device',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        profileImage: json['profileImage'] as String? ?? '',
        token: json['token'] as String? ?? '',
        sessionId: json['sessionId'] as String? ?? '',
        deviceSerial: json['deviceSerial'] as String? ?? '',
      );
}

class WalletKeeperVersionCheckResult {
  const WalletKeeperVersionCheckResult({
    required this.shouldUpdate,
    required this.forceUpdate,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.updateMode,
    required this.title,
    required this.message,
    required this.storeUrl,
    required this.androidStoreUrl,
    required this.iosStoreUrl,
  });

  final bool shouldUpdate;
  final bool forceUpdate;
  final String latestVersion;
  final String minSupportedVersion;
  final String updateMode;
  final String title;
  final String message;
  final String storeUrl;
  final String androidStoreUrl;
  final String iosStoreUrl;

  bool get hasStoreUrl => storeUrl.trim().isNotEmpty;

  factory WalletKeeperVersionCheckResult.fromJson(Map<String, dynamic> json) {
    return WalletKeeperVersionCheckResult(
      shouldUpdate: json['shouldUpdate'] == true,
      forceUpdate: json['forceUpdate'] == true,
      latestVersion: json['latestVersion'] as String? ?? '',
      minSupportedVersion: json['minSupportedVersion'] as String? ?? '',
      updateMode: json['updateMode'] as String? ?? 'recommended',
      title: json['title'] as String? ?? '새 버전이 있어요',
      message: json['message'] as String? ?? '더 안정적인 사용을 위해 최신 버전으로 업데이트해 주세요.',
      storeUrl: json['storeUrl'] as String? ?? '',
      androidStoreUrl: json['androidStoreUrl'] as String? ?? '',
      iosStoreUrl: json['iosStoreUrl'] as String? ?? '',
    );
  }
}

class WalletKeeperPolicyDocument {
  const WalletKeeperPolicyDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.version,
    required this.effectiveDate,
    required this.languageCode,
    required this.requestedLanguage,
    required this.resolvedLanguage,
  });

  final int id;
  final String title;
  final String content;
  final String type;
  final String version;
  final DateTime effectiveDate;
  final String languageCode;
  final String requestedLanguage;
  final String resolvedLanguage;

  factory WalletKeeperPolicyDocument.fromJson(Map<String, dynamic> json) {
    final effectiveDateRaw = (json['effectiveDate'] ?? '').toString().trim();
    final parsedDate =
        DateTime.tryParse(effectiveDateRaw) ??
        DateTime.tryParse('${effectiveDateRaw}T00:00:00') ??
        DateTime.now();
    return WalletKeeperPolicyDocument(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString().trim(),
      content: (json['content'] ?? '').toString().trim(),
      type: (json['type'] ?? '').toString().trim(),
      version: (json['version'] ?? '').toString().trim(),
      effectiveDate: parsedDate,
      languageCode: (json['languageCode'] ?? '').toString().trim(),
      requestedLanguage: (json['requestedLanguage'] ?? '').toString().trim(),
      resolvedLanguage: (json['resolvedLanguage'] ?? '').toString().trim(),
    );
  }
}

class WalletKeeperSyncBundle {
  const WalletKeeperSyncBundle({
    required this.entries,
    required this.memos,
    required this.budgets,
    required this.smsSettings,
  });

  final List<LedgerEntry> entries;
  final List<WalletKeeperMemo> memos;
  final List<WalletKeeperBudgetSetting> budgets;
  final WalletKeeperSmsSettings smsSettings;

  bool get hasMeaningfulData =>
      entries.isNotEmpty || memos.isNotEmpty || budgets.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'entries': entries.map((entry) => entry.toJson()).toList(),
    'memos': memos.map((memo) => memo.toJson()).toList(),
    'budgets': budgets.map((budget) => budget.toJson()).toList(),
    'smsSettings': smsSettings.toJson(),
  };

  factory WalletKeeperSyncBundle.fromJson(Map<String, dynamic> json) {
    final entries = ((json['entries'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(LedgerEntry.fromJson)
        .toList();
    final memos = ((json['memos'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(WalletKeeperMemo.fromJson)
        .toList();
    final budgets = ((json['budgets'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(WalletKeeperBudgetSetting.fromJson)
        .toList();
    return WalletKeeperSyncBundle(
      entries: entries,
      memos: memos,
      budgets: budgets,
      smsSettings: walletKeeperSmsSettingsFromJson(
        (json['smsSettings'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}

extension WalletKeeperSmsSettingsCodec on WalletKeeperSmsSettings {
  Map<String, dynamic> toJson() => {
    'smsReceiveEnabled': smsReceiveEnabled,
    'autoInputEnabled': autoInputEnabled,
    'showNotification': showNotification,
    'shareHeuristicReports': shareHeuristicReports,
    'importWindowDays': importWindowDays,
  };
}

WalletKeeperSmsSettings walletKeeperSmsSettingsFromJson(
  Map<String, dynamic> json,
) => WalletKeeperSmsSettings(
  smsReceiveEnabled: json['smsReceiveEnabled'] as bool? ?? true,
  autoInputEnabled: json['autoInputEnabled'] as bool? ?? false,
  showNotification: json['showNotification'] as bool? ?? true,
  shareHeuristicReports: json['shareHeuristicReports'] as bool? ?? false,
  importWindowDays: (json['importWindowDays'] as num?)?.toInt() ?? 60,
);

class WalletKeeperAccountRepository {
  static const _baseUrl = _walletKeeperAuthBaseUri;

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _walletKeeperGoogleServerClientId,
  );
  firebase_auth.FirebaseAuth get _firebaseAuth =>
      firebase_auth.FirebaseAuth.instance;

  Future<String> getOrCreateGuestSerial() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_walletKeeperGuestSerialKey);
    if (cached != null && cached.isNotEmpty && !cached.startsWith('android_')) {
      return cached;
    }

    String prefix = 'WK';
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        prefix = 'A_${info.model.replaceAll(' ', '_')}';
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        prefix = 'I_${info.model.replaceAll(' ', '_')}';
      }
    } catch (_) {}

    final serial = '${prefix}_${const Uuid().v4()}';
    await prefs.setString(_walletKeeperGuestSerialKey, serial);
    return serial;
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': info.model,
          'manufacturer': info.manufacturer,
          'version': info.version.release,
          'sdkInt': info.version.sdkInt,
        };
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': info.model,
          'systemName': info.systemName,
          'systemVersion': info.systemVersion,
          'name': info.name,
        };
      }
    } catch (_) {}
    return {'platform': Platform.operatingSystem};
  }

  Future<WalletKeeperUserSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_walletKeeperSessionKey);
    if (raw == null || raw.isEmpty) return null;
    final session = WalletKeeperUserSession.fromJson(
      (jsonDecode(raw) as Map).cast<String, dynamic>(),
    );
    if (session.isGuest && session.deviceSerial.startsWith('android_')) {
      await prefs.remove(_walletKeeperSessionKey);
      await prefs.remove(_walletKeeperGuestSerialKey);
      return null;
    }
    return session;
  }

  Future<WalletKeeperUserSession> loadOrBootstrapSession() async {
    return await loadSession() ?? await bootstrapGuest();
  }

  Future<void> saveSession(WalletKeeperUserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _walletKeeperSessionKey,
      jsonEncode(session.toJson()),
    );
  }

  Future<WalletKeeperUserSession> bootstrapGuest() async {
    final serial = await getOrCreateGuestSerial();
    final deviceInfo = await getDeviceInfo();
    final response = await http.post(
      Uri.parse('$_baseUrl/guest/bootstrap'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'guestSerial': serial, 'deviceInfo': deviceInfo}),
    );
    final payload =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode != 200 || payload['success'] != true) {
      throw Exception(payload['message'] ?? '게스트 사용자 생성에 실패했습니다.');
    }
    final data = (payload['data'] as Map).cast<String, dynamic>();
    final session = WalletKeeperUserSession(
      userId: data['user']['id'] as String,
      socialId: data['user']['socialId'] as String? ?? serial,
      loginType: data['user']['loginType'] as String? ?? 'device',
      name: data['user']['name'] as String? ?? '비회원',
      email: data['user']['email'] as String? ?? '',
      profileImage: data['user']['profileImage'] as String? ?? '',
      token: data['token'] as String? ?? '',
      sessionId: data['sessionId'] as String? ?? '',
      deviceSerial: serial,
    );
    await saveSession(session);
    return session;
  }

  Future<WalletKeeperUserSession> signInWithKakao() async {
    OAuthToken token;
    if (await isKakaoTalkInstalled()) {
      token = await UserApi.instance.loginWithKakaoTalk();
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }
    return _linkSocialAccount(
      provider: 'kakao',
      body: {'accessToken': token.accessToken},
    );
  }

  Future<WalletKeeperUserSession> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('구글 로그인을 취소했습니다.');
    }
    final auth = await account.authentication;
    if (auth.idToken == null) {
      throw Exception('구글 ID 토큰이 없습니다.');
    }
    final credential = firebase_auth.GoogleAuthProvider.credential(
      idToken: auth.idToken,
      accessToken: auth.accessToken,
    );
    await _firebaseAuth.signInWithCredential(credential);
    return _linkSocialAccount(
      provider: 'google',
      body: {'idToken': auth.idToken},
    );
  }

  Future<WalletKeeperUserSession> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    if (credential.identityToken == null) {
      throw Exception('애플 로그인 토큰이 없습니다.');
    }
    return _linkSocialAccount(
      provider: 'apple',
      body: {
        'identityToken': credential.identityToken,
        'authorizationCode': credential.authorizationCode,
        'user': {
          'name': '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
              .trim(),
          'email': credential.email,
        },
      },
    );
  }

  Future<WalletKeeperUserSession> signInWithNaver() async {
    if (_walletKeeperNaverClientId.isEmpty ||
        _walletKeeperNaverClientSecret.isEmpty) {
      throw Exception('네이버 로그인 키가 아직 설정되지 않았습니다.');
    }
    final completer = Completer<WalletKeeperUserSession>();
    final success = await NaverLoginSDK.login(
      callback: OAuthLoginCallback(
        onSuccess: () async {
          try {
            final accessToken = await NaverLoginSDK.getAccessToken();
            if (accessToken.isEmpty) {
              throw Exception('네이버 액세스 토큰이 없습니다.');
            }
            completer.complete(
              await _linkSocialAccount(
                provider: 'naver',
                body: {'accessToken': accessToken},
              ),
            );
          } catch (error) {
            if (!completer.isCompleted) completer.completeError(error);
          }
        },
        onFailure: (_, message) {
          if (!completer.isCompleted) {
            completer.completeError(Exception(message));
          }
        },
        onError: (_, message) {
          if (!completer.isCompleted) {
            completer.completeError(Exception(message));
          }
        },
      ),
    );
    if (!success && !completer.isCompleted) {
      throw Exception('네이버 로그인을 완료하지 못했습니다.');
    }
    return completer.future;
  }

  Future<WalletKeeperUserSession> _linkSocialAccount({
    required String provider,
    required Map<String, dynamic> body,
  }) async {
    final session = await loadSession() ?? await bootstrapGuest();
    final deviceInfo = await getDeviceInfo();
    final response = await http.post(
      Uri.parse('$_baseUrl/social/$provider/callback'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'guestSerial': session.deviceSerial,
        'deviceInfo': deviceInfo,
        ...body,
      }),
    );
    final payload =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode != 200 || payload['success'] != true) {
      throw Exception(payload['message'] ?? '$provider 로그인에 실패했습니다.');
    }
    final data = (payload['data'] as Map).cast<String, dynamic>();
    final linked = WalletKeeperUserSession(
      userId: data['user']['id'] as String,
      socialId: data['user']['socialId'] as String? ?? '',
      loginType: data['user']['loginType'] as String? ?? provider,
      name: data['user']['name'] as String? ?? '',
      email: data['user']['email'] as String? ?? '',
      profileImage: data['user']['profileImage'] as String? ?? '',
      token: data['token'] as String? ?? '',
      sessionId: data['sessionId'] as String? ?? '',
      deviceSerial: session.deviceSerial,
    );
    await saveSession(linked);
    return linked;
  }

  Future<WalletKeeperUserSession> signOutToGuest() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    try {
      await UserApi.instance.logout();
    } catch (_) {}
    try {
      await NaverLoginSDK.logout();
    } catch (_) {}
    return bootstrapGuest();
  }
}

class WalletKeeperPushRepository {
  static const _baseUrl = _walletKeeperAuthBaseUri;

  final WalletKeeperAccountRepository _accountRepository =
      WalletKeeperAccountRepository();

  Future<void> registerCurrentDeviceToken() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;

    final session = await _accountRepository.loadOrBootstrapSession();
    final deviceInfo = await _accountRepository.getDeviceInfo();
    final package = await PackageInfo.fromPlatform();
    final messaging = FirebaseMessaging.instance;

    if (Platform.isIOS) {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
    }

    final token = await messaging.getToken();
    if (token == null || token.trim().isEmpty) return;

    await http.post(
      Uri.parse('$_baseUrl/fcm/register'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.token}',
      },
      body: jsonEncode({
        'fcmToken': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'appVersion': '${package.version}+${package.buildNumber}',
        'deviceInfo': {
          ...deviceInfo,
          'deviceModel': deviceInfo['model'] ?? '',
          'osVersion':
              deviceInfo['version'] ?? deviceInfo['systemVersion'] ?? '',
        },
      }),
    );
  }
}

class WalletKeeperVersionRepository {
  static const _baseUrl = _walletKeeperAuthBaseUri;

  Future<WalletKeeperVersionCheckResult?> checkCurrentVersion() async {
    final package = await PackageInfo.fromPlatform();
    final currentVersion = '${package.version}+${package.buildNumber}';
    final lang = Platform.localeName;
    final uri = Uri.parse('$_baseUrl/app-version/check').replace(
      queryParameters: {
        'currentVersion': currentVersion,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'lang': lang,
      },
    );
    final response = await http.get(uri);
    final payload =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode != 200 || payload['success'] != true) {
      return null;
    }
    final data = (payload['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    return WalletKeeperVersionCheckResult.fromJson(data);
  }
}

class WalletKeeperPolicyRepository {
  static const _baseUrl = _walletKeeperAuthBaseUri;

  Future<WalletKeeperPolicyDocument> fetchPolicy({
    required String type,
    required String localeTag,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/policies',
    ).replace(queryParameters: {'type': type, 'lang': localeTag});
    final response = await http.get(uri);
    final payload =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode != 200 || payload['success'] != true) {
      throw Exception(payload['message'] ?? '정책 문서를 불러오지 못했습니다.');
    }
    final data = (payload['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    return WalletKeeperPolicyDocument.fromJson(data);
  }
}

class WalletKeeperCloudSyncRepository {
  static const _baseUrl = _walletKeeperAuthBaseUri;

  final WalletKeeperAccountRepository _accountRepository =
      WalletKeeperAccountRepository();

  Future<WalletKeeperSyncBundle?> loadRemote() async {
    final session =
        await _accountRepository.loadSession() ??
        await _accountRepository.bootstrapGuest();
    return loadRemoteForSession(session);
  }

  Future<WalletKeeperSyncBundle?> loadRemoteForSession(
    WalletKeeperUserSession session,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/save'),
      headers: {'Authorization': 'Bearer ${session.token}'},
    );
    final payload =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode != 200 || payload['success'] != true) {
      return null;
    }
    final data = (payload['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final savePayload = (data['payload'] as Map?)?.cast<String, dynamic>();
    if (savePayload == null) return null;
    return WalletKeeperSyncBundle.fromJson(savePayload);
  }

  Future<void> sync({
    required List<LedgerEntry> entries,
    required List<WalletKeeperMemo> memos,
    required List<WalletKeeperBudgetSetting> budgets,
    required WalletKeeperSmsSettings smsSettings,
  }) async {
    final session =
        await _accountRepository.loadSession() ??
        await _accountRepository.bootstrapGuest();
    await syncForSession(
      session: session,
      entries: entries,
      memos: memos,
      budgets: budgets,
      smsSettings: smsSettings,
    );
  }

  Future<void> syncForSession({
    required WalletKeeperUserSession session,
    required List<LedgerEntry> entries,
    required List<WalletKeeperMemo> memos,
    required List<WalletKeeperBudgetSetting> budgets,
    required WalletKeeperSmsSettings smsSettings,
  }) async {
    final deviceInfo = await _accountRepository.getDeviceInfo();
    final response = await http.post(
      Uri.parse('$_baseUrl/save'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.token}',
      },
      body: jsonEncode({
        'guestSerial': session.deviceSerial,
        'deviceInfo': deviceInfo,
        'payload': WalletKeeperSyncBundle(
          entries: entries,
          memos: memos,
          budgets: budgets,
          smsSettings: smsSettings,
        ).toJson(),
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('서버 동기화에 실패했습니다.');
    }
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

String formatCompactCurrency(double amount) {
  final value = amount.abs();
  if (value >= 1000) {
    final compact = value / 1000;
    final digits = compact >= 100 ? 0 : 1;
    return '₩${compact.toStringAsFixed(digits).replaceAll('.0', '')}k';
  }
  return formatCurrency(amount);
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
