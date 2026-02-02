import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'ad/ad.dart';
import 'app.dart';
import 'purchase/purchase.dart';
import 'core/services/app_update_service.dart';
import 'core/services/supabase_service.dart';
import 'AI/core/ai_logger.dart';
import 'features/profile/data/datasources/profile_local_datasource.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/saju_chat/presentation/providers/chat_persona_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // 페르소나 설정 Hive Box 열기 (앱 재시작 시 페르소나 복원용)
  await ChatPersonaBox.ensureBoxOpen();

  // AI 로그 서비스 초기화
  await AiLogger.init();

  // Supabase 초기화 (오프라인 모드 지원)
  await SupabaseService.initialize();

  // 프로필 클라우드 동기화 (Supabase → Hive)
  await _syncProfilesFromCloud();

  // AdMob SDK 초기화 (모바일만 - Android/iOS)
  final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  if (isMobile) {
    try {
      await AdService.instance.initialize();
      await AdService.instance.loadInterstitialAd();
      await AdService.instance.loadRewardedAd();
    } catch (e) {
      debugPrint('[AdService] 초기화 실패: $e');
    }
  }

  // RevenueCat IAP 초기화 (모바일만)
  if (isMobile) {
    try {
      await PurchaseService.instance.initialize();
    } catch (e) {
      debugPrint('[PurchaseService] 초기화 실패: $e');
    }
  }

  // Google Play In-App Update 체크 (Android만)
  if (isMobile && Platform.isAndroid) {
    AppUpdateService.instance.checkForUpdate();
  }

  runApp(
    const ProviderScope(
      child: MantokApp(),
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
