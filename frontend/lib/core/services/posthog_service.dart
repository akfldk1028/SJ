import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// PostHog Analytics 서비스 (싱글톤)
///
/// 이벤트 추적, 화면 추적, 유저 식별을 위한 래퍼.
/// main.dart에서 초기화 후 사용.
class PosthogService {
  PosthogService._();

  static bool _initialized = false;

  /// PostHog SDK 초기화
  static Future<void> initialize() async {
    const apiKey = String.fromEnvironment('POSTHOG_API_KEY');
    const host = String.fromEnvironment('POSTHOG_HOST');

    if (apiKey.isEmpty) {
      debugPrint('[PostHog] API key not configured. Skipping init.');
      return;
    }

    try {
      final config = PostHogConfig(apiKey);
      config.host = host.isNotEmpty ? host : 'https://us.i.posthog.com';
      config.debug = kDebugMode;
      config.captureApplicationLifecycleEvents = true;

      await Posthog().setup(config);
      _initialized = true;
      debugPrint('[PostHog] Initialized (host: ${config.host})');
    } catch (e) {
      debugPrint('[PostHog] Init failed: $e');
    }
  }

  /// 커스텀 이벤트 전송
  static void trackEvent(String eventName, [Map<String, Object>? properties]) {
    if (!_initialized) return;
    Posthog().capture(eventName: eventName, properties: properties);
  }

  /// 화면 조회 이벤트
  static void trackScreen(String screenName, [Map<String, Object>? properties]) {
    if (!_initialized) return;
    Posthog().screen(screenName: screenName, properties: properties);
  }

  /// 유저 식별 (Supabase auth ID)
  static void identifyUser(String userId, [Map<String, Object>? properties]) {
    if (!_initialized) return;
    Posthog().identify(userId: userId, userProperties: properties);
  }

  /// 로그아웃 시 유저 초기화
  static Future<void> reset() async {
    if (!_initialized) return;
    await Posthog().reset();
  }
}
