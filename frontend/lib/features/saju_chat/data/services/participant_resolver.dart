import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 참가자 결정 결과
class ParticipantResolution {
  final bool isCompatibilityMode;
  final String? person1Id;
  final String? person2Id;
  final List<String> extraMentionIds;

  const ParticipantResolution({
    required this.isCompatibilityMode,
    this.person1Id,
    this.person2Id,
    this.extraMentionIds = const [],
  });
}

/// sendMessage()에서 참가자 결정 로직을 분리
///
/// 궁합 참가자 결정 우선순위:
/// 1. [compatibilityParticipantIds] (UI에서 직접 전달)
/// 2. [targetProfileId] + chat_mentions 조회 (하위 호환)
/// 3. chat_mentions 자동 복원 (두 번째 이후 메시지)
/// 4. 단일 멘션 처리 (effectiveParticipantIds.length == 1)
class ParticipantResolver {
  /// 참가자 결정
  ///
  /// [sessionId]: 현재 세션 ID
  /// [compatibilityParticipantIds]: UI에서 전달된 궁합 참가자 IDs
  /// [multiParticipantIds]: deprecated 파라미터 (하위 호환)
  /// [targetProfileId]: 단일 타겟 프로필 ID
  static Future<ParticipantResolution> resolve({
    required String sessionId,
    List<String>? compatibilityParticipantIds,
    List<String>? multiParticipantIds,
    String? targetProfileId,
  }) async {
    // 궁합 참가자 결정 (우선순위: compatibilityParticipantIds > multiParticipantIds)
    final effectiveParticipantIds = compatibilityParticipantIds ?? multiParticipantIds;

    // 궁합 모드: 2명의 참가자가 있는 경우
    var isCompatibilityMode = effectiveParticipantIds != null && effectiveParticipantIds.length >= 2;

    // 궁합 모드에서 참가자 ID 추출
    String? person1Id;  // 첫 번째 사람 (기존 activeProfile 역할)
    String? person2Id;  // 두 번째 사람 (기존 targetProfile 역할)
    List<String> extraMentionIds = [];  // v10.0: chat_mentions에서 복원된 3번째 이후 참가자 ID

    if (isCompatibilityMode) {
      person1Id = effectiveParticipantIds[0];
      person2Id = effectiveParticipantIds[1];
      if (kDebugMode) {
        print('   ✅ 궁합 모드 활성화: person1Id=$person1Id, person2Id=$person2Id');
      }
    } else if (targetProfileId != null) {
      // 하위 호환: 단일 targetProfileId만 있는 경우
      // chat_mentions에서 실제 participantIds를 복원하여 정확한 person1/person2 결정
      person2Id = targetProfileId;
      try {
        final mentions = await Supabase.instance.client
            .from('chat_mentions')
            .select('target_profile_id, mention_order')
            .eq('session_id', sessionId)
            .order('mention_order');
        if (mentions is List && mentions.length >= 2) {
          person1Id = mentions[0]['target_profile_id'] as String?;
          person2Id = mentions[1]['target_profile_id'] as String?;
          // v10.0: 3번째 이후 참가자 ID 수집
          for (int i = 2; i < mentions.length; i++) {
            final pid = mentions[i]['target_profile_id'] as String?;
            if (pid != null) extraMentionIds.add(pid);
          }
          if (kDebugMode) {
            print('   ✅ chat_mentions에서 복원: person1=$person1Id, person2=$person2Id, extra=${extraMentionIds.length}명');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('   ⚠️ chat_mentions 조회 실패: $e');
        }
      }
      // chat_mentions에서 person1Id를 복원했으면 궁합 모드로 전환
      if (person1Id != null) {
        isCompatibilityMode = true;
      }
      if (kDebugMode) {
        print('   📌 하위 호환 모드: person1=$person1Id, person2=$person2Id, isCompatibilityMode=$isCompatibilityMode');
      }
    } else {
      // v8.0: 명시적 ID가 없어도 chat_mentions에서 궁합 복원 시도
      // (두 번째 이후 메시지에서 UI가 participantIds를 전달하지 못하는 문제 대응)
      try {
        final mentions = await Supabase.instance.client
            .from('chat_mentions')
            .select('target_profile_id, mention_order')
            .eq('session_id', sessionId)
            .order('mention_order');
        if (mentions is List && mentions.length >= 2) {
          person1Id = mentions[0]['target_profile_id'] as String?;
          person2Id = mentions[1]['target_profile_id'] as String?;
          if (person1Id != null && person2Id != null) {
            isCompatibilityMode = true;
            // v10.0: 3번째 이후 참가자 ID 수집
            for (int i = 2; i < mentions.length; i++) {
              final pid = mentions[i]['target_profile_id'] as String?;
              if (pid != null) extraMentionIds.add(pid);
            }
            if (kDebugMode) {
              print('   ✅ chat_mentions에서 궁합 자동 복원: person1=$person1Id, person2=$person2Id, extra=${extraMentionIds.length}명');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('   ⚠️ chat_mentions 자동 복원 실패: $e');
        }
      }

      if (!isCompatibilityMode && kDebugMode) {
        print('   📝 일반 채팅 모드 (궁합 아님)');
        print('      effectiveParticipantIds: $effectiveParticipantIds');
        print('      compatibilityParticipantIds: $compatibilityParticipantIds');
        print('      multiParticipantIds: $multiParticipantIds');
      }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // v9.0: 단일 멘션 처리 (@친구/종환 이사람사주머게)
    // - participantIds에 1명만 있으면 해당 인물의 사주 데이터 로드 필요
    // - person2Id를 설정하여 "하위 호환: owner + target" 분기로 진입
    // ═══════════════════════════════════════════════════════════════════════════
    if (!isCompatibilityMode && person2Id == null &&
        effectiveParticipantIds != null && effectiveParticipantIds.length == 1) {
      person2Id = effectiveParticipantIds[0];
      if (kDebugMode) {
        print('   📌 단일 멘션 모드: target=$person2Id (상대방 사주 데이터 로드)');
      }
    }

    return ParticipantResolution(
      isCompatibilityMode: isCompatibilityMode,
      person1Id: person1Id,
      person2Id: person2Id,
      extraMentionIds: extraMentionIds,
    );
  }
}
