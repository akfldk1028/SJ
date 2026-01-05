import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'ad/ad.dart';
import 'app.dart';
import 'core/services/supabase_service.dart';
import 'AI/core/ai_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경변수 로드
  await dotenv.load(fileName: '.env');

  // Hive 초기화
  await Hive.initFlutter();

  // Hive 박스 열기 (채팅 세션용) - 손상된 데이터 복구 포함
  await _openHiveBoxSafely('chat_sessions');
  await _openHiveBoxSafely('chat_messages');
  await _openHiveBoxSafely('saju_analyses'); // 사주 분석 결과 캐시

  // AI 로그 서비스 초기화
  await AiLogger.init();

  // Supabase 초기화 (오프라인 모드 지원)
  await SupabaseService.initialize();

  // AdMob SDK 초기화 (Web 제외)
  if (!kIsWeb) {
    await AdService.instance.initialize();
    // 광고 사전 로드
    await AdService.instance.loadInterstitialAd();
    await AdService.instance.loadRewardedAd();
  }

  runApp(
    const ProviderScope(
      child: MantokApp(),
    ),
  );
}

/// Hive Box 안전하게 열기
/// 손상된 데이터가 있으면 클리어하고 다시 열기
Future<void> _openHiveBoxSafely(String boxName) async {
  try {
    final box = await Hive.openBox(boxName);

    // 손상된 데이터 검증 및 정리
    final keysToDelete = <dynamic>[];
    for (var i = 0; i < box.length; i++) {
      try {
        final raw = box.getAt(i);
        if (raw != null && raw is! Map) {
          // Map이 아닌 데이터는 손상된 것으로 간주
          keysToDelete.add(box.keyAt(i));
          if (kDebugMode) {
            print('[Hive] 손상된 데이터 발견 ($boxName): index=$i, type=${raw.runtimeType}');
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
    await Hive.openBox(boxName);
  }
}
