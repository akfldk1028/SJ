import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:purchases_flutter/purchases_flutter.dart';

import 'ad/ad.dart';
import 'ad/token_reward_service.dart';
import 'app.dart';
import 'i18n/multi_file_asset_loader.dart';
import 'purchase/purchase.dart';
import 'core/services/app_update_service.dart';
import 'core/services/posthog_service.dart';
import 'core/services/supabase_service.dart';
import 'AI/core/ai_logger.dart';
import 'features/profile/data/datasources/profile_local_datasource.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/saju_chat/presentation/providers/chat_persona_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Manual 모드: 상태바만 표시, 하단 네비게이션 바 숨김
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // 환경변수 로드
  await dotenv.load(fileName: '.env');

  // Hive 초기화
  await Hive.initFlutter();

  // Hive 박스 열기 - 손상된 데이터 복구 포함
  // 중요: 모든 Datasource에서 Box<Map<dynamic, dynamic>> 타입으로 사용하므로
  // 여기서도 동일한 타입으로 열어야 타입 충돌 방지
  await _openHiveBoxSafely('saju_profiles');   // 사주 프로필
  await _openHiveBoxSafely('chat_sessions');   // 채팅 세션
  await _openHiveBoxSafely('chat_messages');   // 채팅 메시지
  await _openHiveBoxSafely('saju_analyses');   // 사주 분석 결과 캐시
  await _openHiveBoxSafely('saju_sync');       // 사주 분석 동기화 대기 목록
  await _openHiveBoxSafely('message_queue');   // 메시지 큐 (오프라인 재전송용)

  // 테마 설정 Hive Box 열기 (앱 재시작 시 테마 복원용)
  await _openHiveBoxStringSafely('theme_settings');

  // 일일 운세 로컬 캐시 (앱 재시작 시 즉시 표시용)
  await _openHiveBoxStringSafely('daily_fortune_cache');

  // 페르소나 설정 Hive Box 열기 (앱 재시작 시 페르소나 복원용)
  await ChatPersonaBox.ensureBoxOpen();

  // AI 로그 서비스 초기화
  await AiLogger.init();

  // Supabase 초기화 (오프라인 모드 지원)
  await SupabaseService.initialize();

  // PostHog Analytics 초기화
  await PosthogService.initialize();

  // PostHog 유저 식별 (Supabase auth)
  final currentUser = SupabaseService.currentUser;
  if (currentUser != null) {
    PosthogService.identifyUser(currentUser.id);
  }

  // 프로필 클라우드 동기화 (Supabase → Hive)
  await _syncProfilesFromCloud();

  // RevenueCat IAP 초기화 (모바일만, AdService보다 먼저)
  final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  if (isMobile) {
    try {
      await PurchaseService.instance.initialize();
    } catch (e) {
      debugPrint('[PurchaseService] 초기화 실패: $e');
    }
  }

  // AdMob SDK 초기화 (모바일만 - Android/iOS)
  if (isMobile) {
    try {
      await AdService.instance.initialize();
      // 광고 선로딩 (프리미엄이 아닌 경우에만)
      if (!await _isPremiumUser()) {
        await AdService.instance.loadInterstitialAd();
        await AdService.instance.loadRewardedAd();
      } else {
        debugPrint('[main] 프리미엄 유저 → 광고 선로딩 스킵');
      }
    } catch (e) {
      debugPrint('[AdService] 초기화 실패: $e');
    }

    // 실패한 토큰 지급 재시도 (네트워크 에러로 이전에 실패한 건)
    try {
      await TokenRewardService.retryFailedGrants();
    } catch (e) {
      debugPrint('[TokenRewardService] 실패 큐 재시도 오류: $e');
    }
  }

  // Google Play In-App Update 체크 (Android만)
  if (isMobile && Platform.isAndroid) {
    AppUpdateService.instance.checkForUpdate();
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('ja'),
      ],
      path: 'lib/i18n',
      fallbackLocale: const Locale('ko'),
      assetLoader: MultiFileAssetLoader(),
      child: const ProviderScope(
        child: MantokApp(),
      ),
    ),
  );
}

/// 프로필 클라우드 동기화 (Supabase → Hive)
/// 앱 시작 시 다른 기기에서 저장한 프로필을 로컬로 가져옴
Future<void> _syncProfilesFromCloud() async {
  try {
    final datasource = ProfileLocalDatasource();
    final repository = ProfileRepositoryImpl(datasource);
    await repository.syncFromCloud();
    if (kDebugMode) {
      print('[Main] 프로필 클라우드 동기화 완료');
    }
  } catch (e) {
    if (kDebugMode) {
      print('[Main] 프로필 클라우드 동기화 실패 (오프라인 모드 계속): $e');
    }
    // 동기화 실패해도 앱은 계속 동작 (오프라인 모드)
  }
}

/// Hive Box<String> 안전하게 열기 (테마 설정 등 String 타입 Box용)
Future<void> _openHiveBoxStringSafely(String boxName) async {
  try {
    await Hive.openBox<String>(boxName);
  } catch (e) {
    if (kDebugMode) {
      print('[Hive] String Box 열기 실패 ($boxName): $e, 데이터 초기화 시도');
    }
    await Hive.deleteBoxFromDisk(boxName);
    await Hive.openBox<String>(boxName);
  }
}

/// Hive Box 안전하게 열기
/// 손상된 데이터가 있으면 클리어하고 다시 열기
///
/// 중요: 모든 Datasource에서 Box<Map<dynamic, dynamic>> 타입으로 사용하므로
/// 여기서도 동일한 타입으로 열어야 타입 충돌 방지
Future<void> _openHiveBoxSafely(String boxName) async {
  try {
    // 모든 Datasource와 동일한 타입으로 열어야 타입 충돌 방지
    final box = await Hive.openBox<Map<dynamic, dynamic>>(boxName);

    // 손상된 데이터 검증 및 정리
    final keysToDelete = <dynamic>[];
    for (var i = 0; i < box.length; i++) {
      try {
        final raw = box.getAt(i);
        if (raw == null) {
          // null 데이터는 손상된 것으로 간주
          keysToDelete.add(box.keyAt(i));
          if (kDebugMode) {
            print('[Hive] 손상된 데이터 발견 ($boxName): index=$i, null value');
          }
        }
      } catch (e) {
        keysToDelete.add(box.keyAt(i));
        if (kDebugMode) {
          print('[Hive] 손상된 데이터 발견 ($boxName): index=$i, error=$e');
        }
      }
    }

    // 손상된 데이터 삭제
    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
      if (kDebugMode) {
        print('[Hive] 손상된 데이터 ${keysToDelete.length}개 삭제 ($boxName)');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('[Hive] Box 열기 실패 ($boxName): $e, 데이터 초기화 시도');
    }
    // Box를 완전히 삭제하고 다시 열기
    await Hive.deleteBoxFromDisk(boxName);
    await Hive.openBox<Map<dynamic, dynamic>>(boxName);
  }
}

/// 프리미엄 유저 빠른 체크 (main 전용)
/// PurchaseService 초기화 후 호출. Provider 없이 직접 확인.
/// ⚠️ purchase_provider.dart의 isPremium 로직과 동일하게 유지할 것
Future<bool> _isPremiumUser() async {
  if (!PurchaseService.instance.isAvailable) return false;
  try {
    final info = await Purchases.getCustomerInfo();

    // 1차: entitlement (구독 상품만 신뢰)
    // ⚠️ day_pass/week_pass는 RevenueCat이 만료 추적 못함 → isActive 영원히 true
    final entitlement = info.entitlements.all[PurchaseConfig.entitlementPremium];
    if (entitlement?.isActive == true) {
      final pid = entitlement!.productIdentifier;
      final isTimeLimited = pid == PurchaseConfig.productDayPass ||
          pid == PurchaseConfig.productWeekPass;
      if (!isTimeLimited) return true; // 월간 구독 → 신뢰
    }

    // 2차: 활성 구독
    if (info.activeSubscriptions.contains(PurchaseConfig.productMonthly)) return true;

    // 3차: 시간제 상품 — 구매일+기간으로 직접 체크
    final now = DateTime.now();
    for (final tx in info.nonSubscriptionTransactions) {
      Duration? duration;
      if (tx.productIdentifier == PurchaseConfig.productDayPass) {
        duration = const Duration(hours: 24);
      } else if (tx.productIdentifier == PurchaseConfig.productWeekPass) {
        duration = const Duration(days: 7);
      }
      if (duration != null) {
        final purchaseDate = DateTime.tryParse(tx.purchaseDate);
        if (purchaseDate != null && now.isBefore(purchaseDate.add(duration))) {
          return true;
        }
      }
    }
    return false;
  } catch (e) {
    debugPrint('[main] 프리미엄 체크 실패: $e');
    return false;
  }
}
