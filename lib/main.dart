import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:another_telephony/telephony.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

part 'src/ledger_home_page.dart';
part 'src/overview_page.dart';
part 'src/secondary_pages.dart';
part 'src/shared_widgets.dart';
part 'src/ledger_domain.dart';

const _storageKey = 'wallet_keeper_entries_v1';
const _memoStorageKey = 'wallet_keeper_memos_v1';
const _budgetStorageKey = 'wallet_keeper_budgets_v1';
const _walletKeeperBottomNavSectionHeight = 112.0;
const _walletKeeperAdSettingsUri =
    'https://app-master.officialsite.kr/api/wallet-keeper/ad-settings';
const _walletKeeperSmsReportUri =
    'https://app-master.officialsite.kr/api/wallet-keeper/sms-reports';
const _walletKeeperAuthBaseUri =
    'https://app-master.officialsite.kr/api/wallet-keeper';
const _smsOnboardingSeenKey = 'wallet_keeper_sms_onboarding_seen_v1';
const _smsPermissionGrantedKey = 'wallet_keeper_sms_permission_granted_v1';
const _notificationPermissionGrantedKey =
    'wallet_keeper_notification_permission_granted_v1';
const _iosNotificationAutoPromptedKey =
    'wallet_keeper_ios_notification_auto_prompted_v1';
const _processedSmsIdsKey = 'wallet_keeper_processed_sms_ids_v1';
const _smsInboxDraftsKey = 'wallet_keeper_sms_inbox_drafts_v1';
const _smsReceiveEnabledKey = 'wallet_keeper_sms_receive_enabled_v1';
const _smsAutoInputEnabledKey = 'wallet_keeper_sms_auto_input_enabled_v1';
const _smsShowNotificationKey = 'wallet_keeper_sms_show_notification_v1';
const _smsHeuristicReportEnabledKey =
    'wallet_keeper_sms_heuristic_report_enabled_v1';
const _smsImportWindowDaysKey = 'wallet_keeper_sms_import_window_days_v1';
const _walletKeeperInstallIdKey = 'wallet_keeper_install_id_v1';
const _walletKeeperSessionKey = 'wallet_keeper_session_v1';
const _walletKeeperGuestSerialKey = 'wallet_keeper_guest_serial_v1';
const _smsNotificationChannelId = 'wallet_keeper_sms_channel';
const _smsNotificationChannelName = '지갑지켜 문자 알림';
const _walletKeeperSmsParserVersion = '2026.05.07-r1';
const _walletKeeperKakaoNativeKey = 'e0888b88d12ae3a234b022db1d2c723e';
const _walletKeeperGoogleServerClientId =
    '136302078709-pn1u0n5rrvrbn6feu41h4eg85i45j00t.apps.googleusercontent.com';
const _walletKeeperNaverClientId = '';
const _walletKeeperNaverClientSecret = '';
const _walletKeeperNaverClientName = '지갑지켜';
const _mmsReaderChannel = MethodChannel('wallet_keeper/mms_reader');
const _mmsRouteChannel = MethodChannel('wallet_keeper/mms_route');
const _nativeNotificationChannel = MethodChannel(
  'wallet_keeper/native_notifications',
);
const _notificationAccessChannel = MethodChannel(
  'wallet_keeper/notification_access',
);
const _smsInboxNotificationPayload = 'sms_inbox';
const _admobAndroidTestBannerUnitId = 'ca-app-pub-3940256099942544/6300978111';
const _admobIosTestBannerUnitId = 'ca-app-pub-3940256099942544/2934735716';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();
final StreamController<String> _notificationRouteController =
    StreamController<String>.broadcast();
bool _pendingNotificationLaunchToSmsInbox = false;
WalletKeeperAdSettings? _walletKeeperAdSettingsCache;
Future<void>? _walletKeeperCoreServicesFuture;

Future<void> _ensureWalletKeeperCoreServicesInitialized() {
  return _walletKeeperCoreServicesFuture ??= _initializeWalletKeeperCoreServices();
}

Future<void> _initializeWalletKeeperCoreServices() async {
  try {
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));
    }
  } catch (error, stackTrace) {
    debugPrint('Failed to initialize Firebase: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  try {
    KakaoSdk.init(nativeAppKey: _walletKeeperKakaoNativeKey);
  } catch (error, stackTrace) {
    debugPrint('Failed to initialize Kakao SDK: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  if (_walletKeeperNaverClientId.isNotEmpty &&
      _walletKeeperNaverClientSecret.isNotEmpty &&
      (Platform.isAndroid || Platform.isIOS)) {
    try {
      NaverLoginSDK.initialize(
        urlScheme: Platform.isIOS
            ? 'com.brosister.walletkeeper'
            : 'com.brosister.walletkeeper',
        clientId: _walletKeeperNaverClientId,
        clientSecret: _walletKeeperNaverClientSecret,
        clientName: _walletKeeperNaverClientName,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to initialize Naver SDK: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
  try {
    await _initializeLocalNotifications().timeout(const Duration(seconds: 5));
  } catch (error, stackTrace) {
    debugPrint('Failed to initialize local notifications: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initializeLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: android);
  await _localNotifications.initialize(
    settings,
    onDidReceiveNotificationResponse: (response) {
      if (response.payload == _smsInboxNotificationPayload) {
        _notificationRouteController.add(_smsInboxNotificationPayload);
      }
    },
  );
  final launchDetails = await _localNotifications
      .getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp == true &&
      launchDetails?.notificationResponse?.payload ==
          _smsInboxNotificationPayload) {
    _pendingNotificationLaunchToSmsInbox = true;
  }
  final androidPlugin = _localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await androidPlugin?.createNotificationChannel(
    const AndroidNotificationChannel(
      _smsNotificationChannelId,
      _smsNotificationChannelName,
      description: '금융 문자 감지 알림',
      importance: Importance.high,
    ),
  );
}

@pragma('vm:entry-point')
Future<void> walletKeeperBackgroundMessageHandler(SmsMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isAndroid) return;
  final access = await WalletKeeperSettingsRepository().loadFeatureAccess();
  final settings = await WalletKeeperSmsSettingsRepository().load();
  if (!access.smsGranted || !settings.smsReceiveEnabled) return;
  await _initializeLocalNotifications();
  final result = await WalletKeeperSmsAutomationRepository()
      .handleIncomingMessage(
        message,
        autoSaveToLedger: settings.autoInputEnabled,
      );
  if (result == null || !settings.showNotification) return;
  await WalletKeeperNotificationService.showSmsDetectedNotification(result);
}

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
  unawaited(_ensureWalletKeeperCoreServicesInitialized());
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
        textTheme: Typography.material2021().black.apply(
          fontFamily: 'Pretendard',
        ),
        primaryTextTheme: Typography.material2021().white.apply(
          fontFamily: 'Pretendard',
        ),
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
      home: const WalletKeeperStartupShell(),
    );
  }
}

class WalletKeeperAdSettings {
  const WalletKeeperAdSettings({
    required this.useTestAds,
    required this.androidBannerAdId,
    required this.iosBannerAdId,
    required this.testAndroidBannerAdId,
    required this.testIosBannerAdId,
  });

  final bool useTestAds;
  final String androidBannerAdId;
  final String iosBannerAdId;
  final String testAndroidBannerAdId;
  final String testIosBannerAdId;

  String bannerAdUnitIdForCurrentPlatform() {
    if (Platform.isAndroid) {
      if (useTestAds) {
        return testAndroidBannerAdId.isNotEmpty
            ? testAndroidBannerAdId
            : _admobAndroidTestBannerUnitId;
      }
      return androidBannerAdId.isNotEmpty
          ? androidBannerAdId
          : _admobAndroidTestBannerUnitId;
    }
    if (Platform.isIOS) {
      if (useTestAds) {
        return testIosBannerAdId.isNotEmpty
            ? testIosBannerAdId
            : _admobIosTestBannerUnitId;
      }
      return iosBannerAdId.isNotEmpty
          ? iosBannerAdId
          : _admobIosTestBannerUnitId;
    }
    return '';
  }
}

const _fallbackWalletKeeperAdSettings = WalletKeeperAdSettings(
  useTestAds: true,
  androidBannerAdId: '',
  iosBannerAdId: '',
  testAndroidBannerAdId: _admobAndroidTestBannerUnitId,
  testIosBannerAdId: _admobIosTestBannerUnitId,
);

Future<WalletKeeperAdSettings> _fetchWalletKeeperAdSettings() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final request = await client.getUrl(Uri.parse(_walletKeeperAdSettingsUri));
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return _fallbackWalletKeeperAdSettings;
    }
    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final data = (decoded['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final androidBanner = (data['android_banner_ad_id'] as String? ?? '')
        .trim();
    final iosBanner = (data['ios_banner_ad_id'] as String? ?? '').trim();
    final testAndroidBanner =
        (data['test_android_banner_ad_id'] as String? ?? '').trim();
    final testIosBanner = (data['test_ios_banner_ad_id'] as String? ?? '')
        .trim();
    final useTestAds =
        data['use_test_ads'] == true ||
        androidBanner == _admobAndroidTestBannerUnitId ||
        iosBanner == _admobIosTestBannerUnitId;
    return WalletKeeperAdSettings(
      useTestAds: useTestAds,
      androidBannerAdId: androidBanner,
      iosBannerAdId: iosBanner,
      testAndroidBannerAdId: testAndroidBanner,
      testIosBannerAdId: testIosBanner,
    );
  } catch (_) {
    return _fallbackWalletKeeperAdSettings;
  } finally {
    client.close(force: true);
  }
}

class WalletKeeperStartupShell extends StatefulWidget {
  const WalletKeeperStartupShell({super.key});

  @override
  State<WalletKeeperStartupShell> createState() =>
      _WalletKeeperStartupShellState();
}

class _WalletKeeperStartupBundle {
  const _WalletKeeperStartupBundle({
    required this.featureAccess,
    required this.versionCheck,
  });

  final WalletKeeperFeatureAccess featureAccess;
  final WalletKeeperVersionCheckResult? versionCheck;
}

WalletKeeperFeatureAccess _fallbackFeatureAccess() {
  return WalletKeeperFeatureAccess(
    onboardingSeen: !Platform.isAndroid,
    smsGranted: false,
    notificationGranted: false,
  );
}

class _WalletKeeperStartupShellState extends State<WalletKeeperStartupShell> {
  final WalletKeeperSettingsRepository _settingsRepository =
      WalletKeeperSettingsRepository();
  final WalletKeeperVersionRepository _versionRepository =
      WalletKeeperVersionRepository();
  late final Future<_WalletKeeperStartupBundle> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _initializeStartup();
  }

  Future<_WalletKeeperStartupBundle> _initializeStartup() async {
    try {
      await _ensureWalletKeeperCoreServicesInitialized().timeout(
        const Duration(seconds: 6),
      );
    } catch (_) {}
    try {
      _walletKeeperAdSettingsCache = await _fetchWalletKeeperAdSettings()
          .timeout(const Duration(seconds: 6));
    } catch (_) {
      _walletKeeperAdSettingsCache = _fallbackWalletKeeperAdSettings;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await MobileAds.instance.initialize().timeout(
          const Duration(seconds: 5),
        );
      } catch (_) {}
    }
    WalletKeeperFeatureAccess featureAccess;
    try {
      featureAccess = await _settingsRepository.loadFeatureAccess().timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {
      featureAccess = _fallbackFeatureAccess();
    }
    WalletKeeperVersionCheckResult? versionCheck;
    try {
      versionCheck = await _versionRepository.checkCurrentVersion().timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {}
    return _WalletKeeperStartupBundle(
      featureAccess: featureAccess,
      versionCheck: versionCheck,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_WalletKeeperStartupBundle>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const WalletKeeperCustomSplashScreen();
        }
        if (snapshot.hasError) {
          return WalletKeeperBootstrap(
            initialFeatureAccess: _fallbackFeatureAccess(),
            versionCheck: null,
          );
        }
        final bundle = snapshot.data;
        if (bundle == null) {
          return WalletKeeperBootstrap(
            initialFeatureAccess: _fallbackFeatureAccess(),
            versionCheck: null,
          );
        }
        return WalletKeeperBootstrap(
          initialFeatureAccess: bundle.featureAccess,
          versionCheck: bundle.versionCheck,
        );
      },
    );
  }
}

class WalletKeeperCustomSplashScreen extends StatelessWidget {
  const WalletKeeperCustomSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEA4D4A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 108,
              height: 108,
              child: Image(
                image: AssetImage('assets/branding/wallet_keeper_logo.png'),
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 18),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletKeeperBootstrap extends StatefulWidget {
  const WalletKeeperBootstrap({
    super.key,
    required this.initialFeatureAccess,
    required this.versionCheck,
  });

  final WalletKeeperFeatureAccess initialFeatureAccess;
  final WalletKeeperVersionCheckResult? versionCheck;

  @override
  State<WalletKeeperBootstrap> createState() => _WalletKeeperBootstrapState();
}

class _WalletKeeperBootstrapState extends State<WalletKeeperBootstrap> {
  final WalletKeeperSettingsRepository _settingsRepository =
      WalletKeeperSettingsRepository();
  final WalletKeeperNotificationAccessRepository _notificationAccessRepository =
      const WalletKeeperNotificationAccessRepository();
  late WalletKeeperFeatureAccess _featureAccess;
  bool _requestingPermissions = false;
  bool _versionNoticeShown = false;

  @override
  void initState() {
    super.initState();
    _featureAccess = widget.initialFeatureAccess;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestIosNotificationPermissionOnFirstLaunchIfNeeded();
      await _showVersionNoticeIfNeeded();
    });
  }

  Future<void> _requestIosNotificationPermissionOnFirstLaunchIfNeeded() async {
    if (!Platform.isIOS) return;
    final prefs = await SharedPreferences.getInstance();
    final alreadyPrompted =
        prefs.getBool(_iosNotificationAutoPromptedKey) ?? false;
    if (alreadyPrompted) return;
    await prefs.setBool(_iosNotificationAutoPromptedKey, true);
    try {
      final access = await _settingsRepository.requestFeatureAccess();
      if (!mounted) return;
      setState(() => _featureAccess = access);
    } catch (error, stackTrace) {
      debugPrint('Failed to auto request iOS notification permission: $error');
      debugPrintStack(stackTrace: stackTrace);
      final access = await _settingsRepository.loadFeatureAccess();
      if (!mounted) return;
      setState(() => _featureAccess = access);
    }
  }

  Future<void> _showVersionNoticeIfNeeded() async {
    if (!mounted || _versionNoticeShown) return;
    final versionCheck = widget.versionCheck;
    if (versionCheck == null || !versionCheck.shouldUpdate) return;
    _versionNoticeShown = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: !versionCheck.forceUpdate,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            versionCheck.title,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),
          content: Text(
            versionCheck.message,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5E6B85),
              height: 1.5,
            ),
          ),
          actions: [
            if (!versionCheck.forceUpdate)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('나중에'),
              ),
            FilledButton(
              onPressed: () async {
                final storeUrl = versionCheck.storeUrl.trim().isNotEmpty
                    ? versionCheck.storeUrl.trim()
                    : (Platform.isIOS
                          ? versionCheck.iosStoreUrl.trim()
                          : versionCheck.androidStoreUrl.trim());
                if (storeUrl.isNotEmpty) {
                  final uri = Uri.tryParse(storeUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
                if (!versionCheck.forceUpdate && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE76158),
                foregroundColor: Colors.white,
              ),
              child: Text(versionCheck.forceUpdate ? '업데이트' : '지금 업데이트'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _agreeAndRequestPermissions() async {
    if (_requestingPermissions) return;
    setState(() => _requestingPermissions = true);
    try {
      final access = await _settingsRepository.requestFeatureAccess();
      if (!mounted) return;
      setState(() => _featureAccess = access);
      if (!access.hasRequiredPermissionAccess) {
        await showAppToast('권한 허용이 필요해요.');
      }
      if (Platform.isAndroid) {
        final opened = await _notificationAccessRepository
            .openFinancialAppNotificationSettings();
        if (!mounted) return;
        await showAppToast(
          opened ? '금융 앱 알림 감지를 위해 알림 접근을 허용해주세요.' : '알림 접근 설정을 열 수 없습니다.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to request feature access: $error');
      debugPrintStack(stackTrace: stackTrace);
      final access = await _settingsRepository.loadFeatureAccess();
      if (!mounted) return;
      setState(() => _featureAccess = access);
    } finally {
      if (mounted) {
        setState(() => _requestingPermissions = false);
      }
    }
  }

  Future<void> _skipPermissions() async {
    final access = await _settingsRepository.skipFeatureAccess();
    if (!mounted) return;
    setState(() => _featureAccess = access);
  }

  Future<void> _requestPermissionsAgain() async {
    try {
      final access = await _settingsRepository.requestFeatureAccess();
      if (!mounted) return;
      setState(() => _featureAccess = access);
      if (!access.hasRequiredPermissionAccess) {
        await showAppToast('권한 허용이 필요해요.');
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to request feature access again: $error');
      debugPrintStack(stackTrace: stackTrace);
      final access = await _settingsRepository.loadFeatureAccess();
      if (!mounted) return;
      setState(() => _featureAccess = access);
    }
  }

  void _reopenFeatureOnboarding() {
    setState(() {
      _featureAccess = _featureAccess.copyWith(onboardingSeen: false);
      _requestingPermissions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final featureAccess = _featureAccess;
    if (Platform.isAndroid && !featureAccess.onboardingSeen) {
      return WalletKeeperSmsConsentScreen(
        requestingPermissions: _requestingPermissions,
        onDecline: _skipPermissions,
        onAgree: _agreeAndRequestPermissions,
      );
    }

    return LedgerHomePage(
      featureAccess: featureAccess,
      onRequestFeatureAccess: _requestPermissionsAgain,
      onRequireFeatureOnboarding: _reopenFeatureOnboarding,
    );
  }
}

class WalletKeeperSmsConsentScreen extends StatelessWidget {
  const WalletKeeperSmsConsentScreen({
    super.key,
    required this.requestingPermissions,
    required this.onDecline,
    required this.onAgree,
  });

  final bool requestingPermissions;
  final Future<void> Function() onDecline;
  final Future<void> Function() onAgree;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final modalWidth = math.min(constraints.maxWidth - 72, 980.0);
          return Stack(
            children: [
              Positioned.fill(child: Container(color: const Color(0xFFF4F5F7))),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints.tightFor(width: modalWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '안전한 지갑지켜 이용을 위해\n다음 권한 허용이 필요합니다.',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 17,
                            height: 1.28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 34),
                        const Text(
                          'SMS 권한',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '지갑지켜는 카드 사용, 입금, 출금 문자를 감지해\n가계부 내역을 더 빠르게 기록할 수 있도록 SMS 내용을 확인합니다.\n수집된 정보는 문자 분류와 내역 입력에만 사용됩니다.',
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 12,
                            height: 1.42,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          '권한에 동의하지 않아도 지갑지켜의 기본 기능은 사용할 수 있습니다.\n다만 문자 자동 입력과 같은 일부 편의 기능은 비활성화됩니다.',
                          style: TextStyle(
                            color: Color(0xFF7C8798),
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: requestingPermissions
                                    ? null
                                    : onDecline,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  padding: EdgeInsets.zero,
                                  side: const BorderSide(
                                    color: Color(0xFFD7DEE8),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  backgroundColor: const Color(0xFFFFFFFF),
                                  overlayColor: const Color(0x08111827),
                                ),
                                child: const Text(
                                  '동의안함',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: requestingPermissions
                                    ? null
                                    : onAgree,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  padding: EdgeInsets.zero,
                                  backgroundColor: const Color(0xFFE85D53),
                                  disabledBackgroundColor: const Color(
                                    0xFFF2B9B5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  requestingPermissions ? '권한 요청중' : '동의함',
                                  style: const TextStyle(
                                    color: Color(0xFFFFFFFF),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
