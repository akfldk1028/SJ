import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../AI/services/saju_analysis_service.dart' as ai_saju;
import '../../../../core/repositories/saju_analysis_repository.dart';
import '../../../../core/repositories/saju_profile_repository.dart';
import '../../../profile/domain/entities/saju_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../saju_chart/domain/entities/saju_analysis.dart';
import '../../../saju_chart/presentation/providers/saju_chart_provider.dart';

/// 궁합/프로필 데이터 로드 결과
class CompatibilityData {
  /// 첫 번째 사람 (궁합) 또는 owner (일반)
  final SajuProfile? activeProfile;

  /// 첫 번째 사람의 사주
  final SajuAnalysis? sajuAnalysis;

  /// 두 번째 사람 (궁합 시에만)
  final SajuProfile? targetProfile;

  /// 두 번째 사람의 사주
  final SajuAnalysis? targetSajuAnalysis;

  /// v10.0: 3번째 이후 참가자
  final List<({SajuProfile profile, SajuAnalysis? sajuAnalysis})> additionalParticipants;

  /// "나 제외" 모드 여부
  final bool isThirdPartyCompatibility;

  /// v8.1: 관계 유형 (family_parent, romantic_partner 등)
  final String? relationType;

  const CompatibilityData({
    this.activeProfile,
    this.sajuAnalysis,
    this.targetProfile,
    this.targetSajuAnalysis,
    this.additionalParticipants = const [],
    this.isThirdPartyCompatibility = false,
    this.relationType,
  });
}

/// 궁합/프로필 데이터 로드 서비스
///
/// sendMessage()에서 프로필/사주 로드 로직을 분리
/// v6.0 (Phase 57): 프로필/사주 로드 로직 단순화
/// - 궁합 모드: person1, person2 둘 다 동일하게 처리
/// - 일반 채팅: owner의 프로필/사주 사용
class CompatibilityDataLoader {
  /// 프로필 및 사주 데이터 로드
  ///
  /// [ref]: Riverpod Ref (프로바이더 접근용)
  /// [sessionId]: 현재 세션 ID
  /// [person1Id]: 첫 번째 사람 프로필 ID (궁합 모드)
  /// [person2Id]: 두 번째 사람 프로필 ID (궁합 또는 단일 멘션)
  /// [extraMentionIds]: v10.0 chat_mentions에서 복원된 3번째 이후 참가자 ID
  /// [effectiveParticipantIds]: 궁합 참가자 ID 목록
  /// [userId]: 현재 로그인 사용자 ID
  /// [isCompatibilityMode]: 궁합 모드 여부
  static Future<CompatibilityData> loadProfiles({
    required Ref ref,
    required String sessionId,
    String? person1Id,
    String? person2Id,
    List<String> extraMentionIds = const [],
    List<String>? effectiveParticipantIds,
    String? userId,
    required bool isCompatibilityMode,
    bool? includesOwner,  // v12.1: "나 포함/제외" 명시적 전달
  }) async {
    SajuProfile? activeProfile;    // 첫 번째 사람 (궁합) 또는 owner (일반)
    SajuAnalysis? sajuAnalysis;    // 첫 번째 사람의 사주
    SajuProfile? targetProfile;    // 두 번째 사람 (궁합 시에만)
    SajuAnalysis? targetSajuAnalysis;  // 두 번째 사람의 사주
    List<({SajuProfile profile, SajuAnalysis? sajuAnalysis})> additionalParticipants = [];  // v10.0: 3번째 이후

    final profileRepo = SajuProfileRepository();
    final analysisRepo = SajuAnalysisRepository();

    if (isCompatibilityMode && (person1Id != null || person2Id != null)) {
      // ═══════════════════════════════════════════════════════════════════
      // 궁합 모드: person1, person2 둘 다 프로필/사주 로드
      // v14.0: person1Id가 null이면 owner(activeProfile)를 person1으로 사용
      // ═══════════════════════════════════════════════════════════════════
      if (person1Id == null) {
        // owner를 person1으로 자동 채움
        final ownerProfile = await ref.read(activeProfileProvider.future);
        person1Id = ownerProfile?.id;
        if (kDebugMode) {
          print('   🔄 v14.0: person1Id null → owner 자동 채움: $person1Id (${ownerProfile?.displayName})');
        }
      }

      if (kDebugMode) {
        print('   🎯 궁합 모드: 두 사람 프로필/사주 조회...');
      }

      // Person 1 로드 (person1Id가 여전히 null이면 owner Provider fallback)
      if (person1Id != null) {
        activeProfile = await profileRepo.getById(person1Id);
      }
      if (activeProfile == null) {
        // activeProfileProvider fallback (DB 직접 조회 실패 시)
        activeProfile = await ref.read(activeProfileProvider.future);
        person1Id = activeProfile?.id;
      }
      if (activeProfile != null && person1Id != null) {
        sajuAnalysis = await analysisRepo.getByProfileId(person1Id);

        // v6.0: 첫 번째 사람도 사주 자동생성
        if (sajuAnalysis == null && userId != null) {
          if (kDebugMode) {
            print('   ⚠️ Person1 사주 분석 없음 → GPT-5.2 자동 분석 시작');
          }
          try {
            final aiAnalysisService = ai_saju.SajuAnalysisService();
            final result = await aiAnalysisService.ensureSajuBaseAnalysis(
              userId: userId,
              profileId: person1Id,
              runInBackground: false,
            );
            if (result.success) {
              sajuAnalysis = await analysisRepo.getByProfileId(person1Id);
              if (kDebugMode) {
                print('   ✅ Person1 사주 분석 자동 생성 완료');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('   ❌ Person1 사주 분석 생성 중 오류: $e');
            }
          }
        }

        if (kDebugMode) {
          print('   ✅ Person1 프로필: ${activeProfile.displayName}');
          print('   ✅ Person1 사주: ${sajuAnalysis != null ? '있음' : '없음'}');
        }
      }

      // Person 2 로드
      if (person2Id != null) {
        targetProfile = await profileRepo.getById(person2Id);
        if (targetProfile != null) {
          targetSajuAnalysis = await analysisRepo.getByProfileId(person2Id);

          // v6.0: 두 번째 사람도 사주 자동생성
          if (targetSajuAnalysis == null && userId != null) {
            if (kDebugMode) {
              print('   ⚠️ Person2 사주 분석 없음 → GPT-5.2 자동 분석 시작');
            }
            try {
              final aiAnalysisService = ai_saju.SajuAnalysisService();
              final result = await aiAnalysisService.ensureSajuBaseAnalysis(
                userId: userId,
                profileId: person2Id,
                runInBackground: false,
              );
              if (result.success) {
                targetSajuAnalysis = await analysisRepo.getByProfileId(person2Id);
                if (kDebugMode) {
                  print('   ✅ Person2 사주 분석 자동 생성 완료');
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('   ❌ Person2 사주 분석 생성 중 오류: $e');
              }
            }
          }

          if (kDebugMode) {
            print('   ✅ Person2 프로필: ${targetProfile.displayName}');
            print('   ✅ Person2 사주: ${targetSajuAnalysis != null ? '있음' : '없음'}');
          }
        }
      }

      // v14.0: 궁합 모드에서 세션 메타 + chat_mentions 저장
      // (기존엔 하위 호환 분기에서만 저장했으나, 단일 멘션→궁합 승격 시 누락됨)
      if (person2Id != null) {
        try {
          await Supabase.instance.client
              .from('chat_sessions')
              .update({'target_profile_id': person2Id})
              .eq('id', sessionId);
          // chat_mentions 저장 (이미 ParticipantResolver에서 저장된 경우 중복 방지)
          final mentionCheck = await Supabase.instance.client
              .from('chat_mentions')
              .select('id')
              .eq('session_id', sessionId)
              .limit(1);
          if (mentionCheck is List && mentionCheck.isEmpty && person1Id != null) {
            final ids = [person1Id, if (person2Id != null) person2Id!, ...extraMentionIds];
            await _saveChatMentions(sessionId, ids);
          }
        } catch (e) {
          if (kDebugMode) {
            print('   ⚠️ v14.0: 세션 메타/chat_mentions 저장 실패: $e');
          }
        }
      }

      // v10.0: 추가 참가자 로드 (3번째 이후)
      // effectiveParticipantIds에서 또는 chat_mentions 복원된 extraMentionIds에서 로드
      final extraIds = (effectiveParticipantIds != null && effectiveParticipantIds.length > 2)
          ? effectiveParticipantIds.sublist(2)
          : extraMentionIds;
      if (extraIds.isNotEmpty) {
        for (int i = 0; i < extraIds.length; i++) {
          final pid = extraIds[i];
          final p = await profileRepo.getById(pid);
          if (p != null) {
            var saju = await analysisRepo.getByProfileId(pid);
            // 사주 없으면 자동 생성
            if (saju == null && userId != null) {
              try {
                final aiService = ai_saju.SajuAnalysisService();
                final result = await aiService.ensureSajuBaseAnalysis(
                  userId: userId,
                  profileId: pid,
                  runInBackground: false,
                );
                if (result.success) {
                  saju = await analysisRepo.getByProfileId(pid);
                }
              } catch (e) {
                if (kDebugMode) {
                  print('   ❌ Person${i + 3} 사주 자동생성 실패: $e');
                }
              }
            }
            additionalParticipants.add((profile: p, sajuAnalysis: saju));
            if (kDebugMode) {
              print('   ✅ Person${i + 3} 프로필: ${p.displayName}, 사주: ${saju != null ? '있음' : '없음'}');
            }
          }
        }
      }
    } else if (person2Id != null) {
      // ═══════════════════════════════════════════════════════════════════
      // 하위 호환: owner + target 방식 (단일 targetProfileId만 있는 경우)
      // ═══════════════════════════════════════════════════════════════════
      if (kDebugMode) {
        print('   🎯 하위 호환 모드: owner + target');
      }

      // Owner (나) 로드
      sajuAnalysis = await ref.read(currentSajuAnalysisProvider.future);
      activeProfile = await ref.read(activeProfileProvider.future);

      // Target 로드
      targetProfile = await profileRepo.getById(person2Id);
      if (targetProfile != null) {
        targetSajuAnalysis = await analysisRepo.getByProfileId(person2Id);

        if (targetSajuAnalysis == null && userId != null) {
          if (kDebugMode) {
            print('   ⚠️ 상대방 사주 분석 없음 → GPT-5.2 자동 분석 시작');
          }
          try {
            final aiAnalysisService = ai_saju.SajuAnalysisService();
            final result = await aiAnalysisService.ensureSajuBaseAnalysis(
              userId: userId,
              profileId: person2Id,
              runInBackground: false,
            );
            if (result.success) {
              targetSajuAnalysis = await analysisRepo.getByProfileId(person2Id);
            }
          } catch (e) {
            if (kDebugMode) {
              print('   ❌ 상대방 사주 분석 생성 중 오류: $e');
            }
          }
        }
      }

      // v9.0: 단일 멘션 시 세션에 target_profile_id 저장 (앱 재시작 복원용)
      if (targetProfile != null) {
        try {
          await Supabase.instance.client
              .from('chat_sessions')
              .update({'target_profile_id': person2Id})
              .eq('id', sessionId);
          // chat_mentions에도 저장 (owner + target)
          final ownerId = (await ref.read(activeProfileProvider.future))?.id;
          if (ownerId != null) {
            await _saveChatMentions(sessionId, [ownerId, person2Id!]);
          }
          if (kDebugMode) {
            print('   ✅ 세션에 target_profile_id 저장: $person2Id');
          }
        } catch (e) {
          if (kDebugMode) {
            print('   ⚠️ 세션 target_profile_id 저장 실패: $e');
          }
        }
      }
    } else {
      // ═══════════════════════════════════════════════════════════════════
      // 일반 채팅: owner의 프로필/사주 사용
      // ═══════════════════════════════════════════════════════════════════
      sajuAnalysis = await ref.read(currentSajuAnalysisProvider.future);
      activeProfile = await ref.read(activeProfileProvider.future);
      if (kDebugMode) {
        print('   🎯 일반 채팅 모드: owner 프로필/사주 사용');
        print('   ✅ 프로필: ${activeProfile?.displayName}');
        print('   ✅ 사주: ${sajuAnalysis != null ? '있음' : '없음'}');
      }
    }

    // v12.1: "나 제외" 모드 판단 (includesOwner 명시적 전달 우선)
    // - includesOwner가 명시적으로 false이면 무조건 "나 제외" 모드
    // - includesOwner가 null이면 기존 로직 (참가자에 owner 포함 여부 체크)
    bool isThirdPartyCompatibility = false;
    if (isCompatibilityMode && person1Id != null) {
      if (includesOwner == false) {
        // v12.1: MentionSendHandler에서 "[나 제외]" 감지 → 명시적 나 제외
        isThirdPartyCompatibility = true;
        if (kDebugMode) {
          print('   📌 v12.1: includesOwner=false → 나 제외 모드 (명시적)');
        }
      } else if (includesOwner == null) {
        // 기존 로직: owner가 참가자에 포함되어 있는지 자동 판단
        final ownerProfile = await ref.read(activeProfileProvider.future);
        final ownerId = ownerProfile?.id;
        final ownerIncluded = (ownerId == person1Id) || (ownerId == person2Id) ||
            (ownerId != null && extraMentionIds.contains(ownerId));
        isThirdPartyCompatibility = !ownerIncluded;
        if (kDebugMode) {
          print('   📌 includesOwner=null → 자동 판단: ownerId=$ownerId, ownerIncluded=$ownerIncluded');
        }
      }
      // includesOwner == true → isThirdPartyCompatibility = false (기본값)
      if (kDebugMode) {
        print('   📌 isThirdPartyCompatibility=$isThirdPartyCompatibility');
        if (isThirdPartyCompatibility) {
          print('   📌 나 제외 모드: person1=${activeProfile?.displayName}, person2=${targetProfile?.displayName}');
        }
      }
    }

    return CompatibilityData(
      activeProfile: activeProfile,
      sajuAnalysis: sajuAnalysis,
      targetProfile: targetProfile,
      targetSajuAnalysis: targetSajuAnalysis,
      additionalParticipants: additionalParticipants,
      isThirdPartyCompatibility: isThirdPartyCompatibility,
      relationType: null,  // relationType은 sendMessage에서 별도로 조회
    );
  }

  /// chat_mentions 테이블에 참가자 저장
  static Future<void> _saveChatMentions(String sessionId, List<String> participantIds) async {
    try {
      if (kDebugMode) {
        print('   📝 chat_mentions 저장 시작 (${participantIds.length}명)...');
      }

      // 기존 멘션 삭제 (세션 재분석 시 중복 방지)
      await Supabase.instance.client
          .from('chat_mentions')
          .delete()
          .eq('session_id', sessionId);

      // 새 멘션 저장
      final mentionRows = participantIds.asMap().entries.map((entry) => {
        'session_id': sessionId,
        'target_profile_id': entry.value,
        'mention_order': entry.key,
      }).toList();

      await Supabase.instance.client
          .from('chat_mentions')
          .insert(mentionRows);

      if (kDebugMode) {
        print('   ✅ chat_mentions 저장 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('   ⚠️ chat_mentions 저장 실패: $e');
      }
    }
  }
}
