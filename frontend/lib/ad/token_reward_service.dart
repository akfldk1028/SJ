/// Token Reward Service
/// 광고 보상 토큰 지급을 위한 통합 서비스
///
/// 보상형 광고(Rewarded Ad) 완료 시, 네이티브 광고(Native Ad) 클릭 시
/// Supabase에 토큰 보상을 기록하는 단일 진입점.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TokenRewardService {
  TokenRewardService._();

  /// 보상형 광고 완료 → rewarded_tokens_earned 증가 (RPC)
  ///
  /// [tokens]: 지급할 토큰 수
  /// [screen]: 광고가 표시된 화면 (로깅용, 선택)
  static Future<void> grantRewardedAdTokens(int tokens, {String? screen}) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await Supabase.instance.client.rpc('add_ad_bonus_tokens', params: {
        'p_user_id': userId,
        'p_bonus_tokens': tokens,
      });
      if (kDebugMode) {
        print('[TokenRewardService] rewarded bonus saved: +$tokens tokens (screen: $screen)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[TokenRewardService] rewarded bonus save failed: $e');
      }
    }
  }

  /// 네이티브 광고 클릭 → native_tokens_earned 증가 (RPC)
  ///
  /// [tokens]: 지급할 토큰 수
  static Future<void> grantNativeAdTokens(int tokens) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await Supabase.instance.client.rpc('add_native_bonus_tokens', params: {
        'p_user_id': userId,
        'p_bonus_tokens': tokens,
      });
      if (kDebugMode) {
        print('[TokenRewardService] native bonus saved: +$tokens tokens');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[TokenRewardService] native bonus save failed: $e');
      }
    }
  }
}
