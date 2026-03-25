import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 참가자 결정 결과
class ParticipantResolution {
  final bool isCompatibilityMode;
  final String? person1Id;
  final String? person2Id;
  final List<String> extraMentionIds;
  final bool? includesOwner; // v12.1: "나 포함/제외" 전달

  const ParticipantResolution({
    required this.isCompatibilityMode,
    this.person1Id,
    this.person2Id,
    this.extraMentionIds = const [],
    this.includesOwner,
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
    bool? includesOwner,  // v12.1: "나 포함/제외" (MentionSendHandler에서 전달)
  }) async {
    // 궁합 참가자 결정 (우선순위: compatibilityParticipantIds > multiParticipantIds)
    final effectiveParticipantIds = compatibilityParticipantIds ?? multiParticipantIds;

    // 궁합 모드: 2명의 참가자가 있는 경우
    var isCompatibilityMode = effectiveParticipantIds != null && effectiveParticipantIds.length >= 2;

    // 궁합 모드에서 참가자 ID 추출
    String? person1Id;  // 첫 번째 사람 (기존 activeProfile 역할)
    String? person2Id;  // 두 번째 사람 (기존 targetProfile 역할)
    List<String> extraMentionIds = [];  // v10.0: chat_mentions에서 복원된 3번째 이후 참가자 ID
    bool alreadySaved = false;  // Phase 59: 첫 분기에서 저장 완료 시 병합 블록 스킵

    if (isCompatibilityMode) {
      // ═══════════════════════════════════════════════════════════════════
      // v12.1: 새 멘션 우선 병합 (신규 = primary pair, 기존 = extra)
      // - 새 멘션이 person1/person2가 되어 궁합 분석 대상이 됨
      // - 기존 참가자는 extra로 이동하여 AI가 동등하게 참조 가능
      // - chat_mentions 순서: [신규..., 기존 중 신규에 없는 것...]
      // ═══════════════════════════════════════════════════════════════════
      List<String> mergedIds = List<String>.from(effectiveParticipantIds);

      try {
        final existingMentions = await Supabase.instance.client
            .from('chat_mentions')
            .select('target_profile_id, mention_order')
            .eq('session_id', sessionId)
            .order('mention_order');

        if (existingMentions is List && existingMentions.isNotEmpty) {
          final existingIds = existingMentions
              .map((m) => m['target_profile_id'] as String?)
              .where((id) => id != null)
              .cast<String>()
              .toList();

          // 기존 참가자 중 새 멘션에 없는 사람만 뒤에 추가
          final oldExtras = existingIds
              .where((id) => !effectiveParticipantIds.contains(id))
              .toList();

          if (oldExtras.isNotEmpty) {
            mergedIds = [...effectiveParticipantIds, ...oldExtras];
            if (kDebugMode) {
              print('   🔄 v12.1 병합: 신규 ${effectiveParticipantIds.length}명(primary) + 기존 ${oldExtras.length}명(extra) = 총 ${mergedIds.length}명');
              print('      신규(primary): $effectiveParticipantIds');
              print('      기존(extra): $oldExtras');
            }
          } else if (existingIds.length > effectiveParticipantIds.length) {
            // 새 참가자가 모두 기존에 있지만 기존이 더 많으면 → 기존 중 신규 외 나머지 유지
            mergedIds = [...effectiveParticipantIds, ...existingIds.where((id) => !effectiveParticipantIds.contains(id))];
          }
          // 새 참가자 == 기존이면 그대로 (mergedIds = effectiveParticipantIds)
        }
      } catch (e) {
        if (kDebugMode) {
          print('   ⚠️ 기존 chat_mentions 조회 실패 (첫 메시지일 수 있음): $e');
        }
      }

      // 신규 멘션이 primary pair (person1/person2)
      person1Id = mergedIds[0];
      person2Id = mergedIds.length > 1 ? mergedIds[1] : null;
      if (mergedIds.length > 2) {
        extraMentionIds = mergedIds.sublist(2);
      }

      if (kDebugMode) {
        print('   ✅ 궁합 모드 활성화: person1=$person1Id, person2=$person2Id, extra=${extraMentionIds.length}명 (총 ${mergedIds.length}명)');
      }

      // 병합된 전체 참가자를 chat_mentions에 저장 (신규 우선 순서)
      await _saveMergedParticipants(sessionId, mergedIds);
      alreadySaved = true;
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
    } else if (effectiveParticipantIds != null && effectiveParticipantIds.length == 1) {
      // ═══════════════════════════════════════════════════════════════════
      // v13.0: 단일 멘션 포커스 전환
      //
      // 기존 궁합 세션에서 새 인물 1명 멘션 시:
      //   유저 의도: "이 사람에 대해 봐줘" (포커스 전환)
      //   기존 동작(버그): 새 멘션을 extra(3번째+)에 추가 → AI가 무시
      //   수정: 새 멘션을 person2(주 분석 대상)로 승격,
      //         기존 person2는 extras로 이동
      //
      // 새 세션(chat_mentions 없음)이면: v9.0 단일 멘션 모드
      // ═══════════════════════════════════════════════════════════════════
      final newMentionId = effectiveParticipantIds[0];

      try {
        final existingMentions = await Supabase.instance.client
            .from('chat_mentions')
            .select('target_profile_id, mention_order')
            .eq('session_id', sessionId)
            .order('mention_order');

        if (existingMentions is List && existingMentions.length >= 2) {
          final existingIds = existingMentions
              .map((m) => m['target_profile_id'] as String?)
              .where((id) => id != null)
              .cast<String>()
              .toList();

          // 기존 person1 유지 (보통 owner/본인)
          person1Id = existingIds[0];
          isCompatibilityMode = true;

          if (newMentionId == existingIds[0] || newMentionId == existingIds[1]) {
            // 기존 person1 또는 person2 재멘션 → 기존 순서 유지
            person2Id = existingIds[1];
            extraMentionIds = existingIds.length > 2
                ? existingIds.sublist(2)
                : [];
            if (kDebugMode) {
              print('   📌 v13.0: 기존 참가자 재멘션 → 순서 유지: person1=$person1Id, person2=$person2Id');
            }
          } else {
            // 새 인물 또는 기존 extra에서 승격 → person2로 포커스 전환
            person2Id = newMentionId;
            // 기존 참가자 중 person1과 새 멘션 제외 → extras
            extraMentionIds = existingIds
                .where((id) => id != person1Id && id != newMentionId)
                .toList();

            // chat_mentions 업데이트: [person1, 새멘션, 기존 나머지...]
            final mergedIds = [person1Id!, person2Id!, ...extraMentionIds];
            await _saveMergedParticipants(sessionId, mergedIds);
            alreadySaved = true;

            if (kDebugMode) {
              print('   🔄 v13.0 포커스 전환: person2=$newMentionId (이전: ${existingIds[1]})');
              print('      새 순서: $mergedIds');
            }
          }
        } else {
          // 기존 chat_mentions 없거나 1명뿐 → 단일 멘션 모드 (v9.0 동일)
          person2Id = newMentionId;
          if (kDebugMode) {
            print('   📌 v13.0: 단일 멘션 모드 (새 세션): target=$newMentionId');
          }
        }
      } catch (e) {
        // 조회 실패 시 단일 멘션 fallback
        person2Id = newMentionId;
        if (kDebugMode) {
          print('   ⚠️ v13.0: chat_mentions 조회 실패 → 단일 멘션 fallback: $e');
        }
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

    // ═══════════════════════════════════════════════════════════════════════════
    // Phase 59: 참가자 추가 모드 (기존 궁합 세션에 1명씩 추가)
    // - 새 멘션(effectiveParticipantIds)이 있고, 기존 chat_mentions가 있으면 병합
    // - 예: 첫 메시지 2명 → 두 번째 메시지에서 1명 추가 → 총 3명
    // ═══════════════════════════════════════════════════════════════════════════
    if (!alreadySaved && effectiveParticipantIds != null && effectiveParticipantIds.isNotEmpty) {
      try {
        final existingMentions = await Supabase.instance.client
            .from('chat_mentions')
            .select('target_profile_id, mention_order')
            .eq('session_id', sessionId)
            .order('mention_order');

        if (existingMentions is List && existingMentions.isNotEmpty) {
          // 기존 참가자 ID 목록
          final existingIds = existingMentions
              .map((m) => m['target_profile_id'] as String?)
              .where((id) => id != null)
              .cast<String>()
              .toList();

          // 새 멘션 중 기존에 없는 것만 추가
          final newIds = effectiveParticipantIds
              .where((id) => !existingIds.contains(id))
              .toList();

          if (newIds.isNotEmpty) {
            // 기존 + 새로운 참가자 병합
            final mergedIds = [...existingIds, ...newIds];

            if (kDebugMode) {
              print('   🔄 Phase 59: 참가자 추가 모드');
              print('      기존: $existingIds (${existingIds.length}명)');
              print('      추가: $newIds (${newIds.length}명)');
              print('      병합: $mergedIds (${mergedIds.length}명)');
            }

            // 병합된 참가자로 재설정
            if (mergedIds.length >= 2) {
              person1Id = mergedIds[0];
              person2Id = mergedIds[1];
              isCompatibilityMode = true;

              // 3명째 이후는 extraMentionIds에 추가
              extraMentionIds = mergedIds.length > 2
                  ? mergedIds.sublist(2)
                  : [];

              if (kDebugMode) {
                print('   ✅ 병합 완료: person1=$person1Id, person2=$person2Id, extra=${extraMentionIds.length}명');
              }

              // Phase 59: 병합된 참가자를 chat_mentions에 저장
              await _saveMergedParticipants(sessionId, mergedIds);
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('   ⚠️ Phase 59: 참가자 병합 중 오류: $e');
        }
      }
    }

    return ParticipantResolution(
      isCompatibilityMode: isCompatibilityMode,
      person1Id: person1Id,
      person2Id: person2Id,
      extraMentionIds: extraMentionIds,
      includesOwner: includesOwner,
    );
  }

  /// Phase 59: 병합된 참가자를 chat_mentions에 저장
  ///
  /// 기존 chat_mentions 삭제 후 병합된 전체 목록 저장
  static Future<void> _saveMergedParticipants(
    String sessionId,
    List<String> participantIds,
  ) async {
    try {
      // 기존 멘션 삭제
      await Supabase.instance.client
          .from('chat_mentions')
          .delete()
          .eq('session_id', sessionId);

      // 새 멘션 저장 (순서 유지)
      final mentionRows = participantIds.asMap().entries.map((entry) => {
            'session_id': sessionId,
            'target_profile_id': entry.value,
            'mention_order': entry.key,
          }).toList();

      await Supabase.instance.client.from('chat_mentions').insert(mentionRows);

      if (kDebugMode) {
        print('   ✅ Phase 59: chat_mentions 저장 완료 (${participantIds.length}명)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('   ⚠️ Phase 59: chat_mentions 저장 실패: $e');
      }
    }
  }
}
