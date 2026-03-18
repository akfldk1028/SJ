/// Token Reward Service
/// 광고 보상 토큰 지급을 위한 통합 서비스
///
/// 보상형 광고(Rewarded Ad) 완료 시, 네이티브 광고(Native Ad) 클릭 시
/// Supabase에 토큰 보상을 기록하는 단일 진입점.
///
/// RPC 실패 시 최대 2회 재시도 + 실패 큐(Hive) 저장 → 다음 앱 시작 시 재시도.
library;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TokenRewardService {
  TokenRewardService._();

  static const _failedGrantsBoxName = 'failed_token_grants';

  /// 보상형 광고 완료 → bonus_tokens 증가 (RPC)
  ///
  /// [tokens]: 지급할 토큰 수
  /// [screen]: 광고가 표시된 화면 (로깅용, 선택)
  /// [isFallback]: true면 광고 로드 실패 fallback → ads_watched 미증가
  /// 반환: true = 서버 저장 성공, false = 실패 (큐에 저장됨)
  static Future<bool> grantRewardedAdTokens(int tokens, {String? screen, bool isFallback = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        await Supabase.instance.client.rpc('add_ad_bonus_tokens', params: {
          'p_user_id': userId,
          'p_bonus_tokens': tokens,
          'p_is_fallback': isFallback,
        });
        debugPrint('[TokenRewardService] rewarded bonus saved: +$tokens tokens (screen: $screen, fallback: $isFallback)');
        return true;
      } catch (e) {
        debugPrint('[TokenRewardService] attempt ${attempt + 1}/3 failed: $e');
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }

    // 3회 실패 → 큐에 저장 (다음 앱 시작 시 재시도)
    await _queueFailedGrant(userId, tokens, 'add_ad_bonus_tokens', screen, isFallback: isFallback);
    return false;
  }

  /// 네이티브 광고 클릭 → native_tokens_earned 증가 (RPC)
  ///
  /// [tokens]: 지급할 토큰 수
  static Future<bool> grantNativeAdTokens(int tokens) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        await Supabase.instance.client.rpc('add_native_bonus_tokens', params: {
          'p_user_id': userId,
          'p_bonus_tokens': tokens,
        });
        debugPrint('[TokenRewardService] native bonus saved: +$tokens tokens');
        return true;
      } catch (e) {
        debugPrint('[TokenRewardService] native attempt ${attempt + 1}/3 failed: $e');
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }

    await _queueFailedGrant(userId, tokens, 'add_native_bonus_tokens', null);
    return false;
  }

  /// 실패한 토큰 지급을 Hive에 저장
  static Future<void> _queueFailedGrant(
    String userId,
    int tokens,
    String rpcName,
    String? screen, {
    bool isFallback = false,
  }) async {
    try {
      final box = await Hive.openBox(_failedGrantsBoxName);
      await box.add({
        'userId': userId,
        'tokens': tokens,
        'rpcName': rpcName,
        'screen': screen,
        'isFallback': isFallback,
        'createdAt': DateTime.now().toIso8601String(),
      });
      debugPrint('[TokenRewardService] queued failed grant: +$tokens ($rpcName, fallback: $isFallback)');
    } catch (e) {
      debugPrint('[TokenRewardService] queue save failed: $e');
    }
  }

  /// 앱 시작 시 실패 큐 재시도 (main.dart에서 호출)
  static Future<void> retryFailedGrants() async {
    try {
      final box = await Hive.openBox(_failedGrantsBoxName);
      if (box.isEmpty) return;

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      debugPrint('[TokenRewardService] retrying ${box.length} failed grants...');

      final keysToDelete = <dynamic>[];
      for (final key in box.keys) {
        final grant = box.get(key) as Map?;
        if (grant == null) continue;

        // 본인 것만 재시도
        if (grant['userId'] != userId) continue;

        try {
          final params = <String, dynamic>{
            'p_user_id': userId,
            'p_bonus_tokens': grant['tokens'] as int,
          };
          // add_ad_bonus_tokens RPC: fallback 여부 전달
          if (grant['rpcName'] == 'add_ad_bonus_tokens') {
            params['p_is_fallback'] = grant['isFallback'] as bool? ?? false;
          }
          await Supabase.instance.client.rpc(grant['rpcName'] as String, params: params);
          keysToDelete.add(key);
          debugPrint('[TokenRewardService] retry success: +${grant['tokens']} (${grant['rpcName']})');
        } catch (e) {
          debugPrint('[TokenRewardService] retry failed: $e');
          // 7일 이상 된 건 삭제
          final createdAt = DateTime.tryParse(grant['createdAt'] as String? ?? '');
          if (createdAt != null && DateTime.now().difference(createdAt).inDays > 7) {
            keysToDelete.add(key);
            debugPrint('[TokenRewardService] expired grant removed (>7 days)');
          }
        }
      }

      await box.deleteAll(keysToDelete);
    } catch (e) {
      debugPrint('[TokenRewardService] retryFailedGrants error: $e');
    }
  }
}
