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

  // Hive 박스 열기 (채팅 세션용)
  await Hive.openBox('chat_sessions');
  await Hive.openBox('chat_messages');
  await Hive.openBox('saju_analyses'); // 사주 분석 결과 캐시

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
