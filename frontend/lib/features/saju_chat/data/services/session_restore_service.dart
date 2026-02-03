import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../AI/services/compatibility_analysis_service.dart';
import '../../../../core/repositories/saju_analysis_repository.dart';
import '../../../../core/repositories/saju_profile_repository.dart';
import '../../../../core/services/ai_summary_service.dart';
import '../../../../core/services/prompt_loader.dart';
import '../../../profile/domain/entities/saju_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../saju_chart/domain/entities/saju_analysis.dart';
import '../../../saju_chart/presentation/providers/saju_chart_provider.dart';
import '../../domain/models/chat_type.dart';
import '../services/system_prompt_builder.dart';
import '../../presentation/providers/chat_persona_provider.dart';
import '../../presentation/providers/chat_session_provider.dart';

/// 세션 복원용 시스템 프롬프트 빌드 서비스
///
/// v7.1: 앱 백그라운드 → 포그라운드 복귀 시 사주 정보 포함
/// - 프로필 + 사주 분석 + AI Summary 로드하여 완전한 프롬프트 생성
/// v7.2: 궁합 모드 지원 추가
/// - 세션의 targetProfileId로 상대방 프로필/사주 복원
/// - chat_mentions에서 participantIds 복원 → 궁합 분석 결과 로드
class SessionRestoreService {
  /// 양방향 관계 유형 조회 헬퍼
  /// profile_relations에서 from→to, to→from 양방향으로 검색
  static Future<String?> findRelationType(String profileId1, String profileId2) async {
    var result = await Supabase.instance.client
        .from('profile_relations')
        .select('relation_type')
        .eq('from_profile_id', profileId1)
        .eq('to_profile_id', profileId2)
        .maybeSingle();

    result ??= await Supabase.instance.client
        .from('profile_relations')
        .select('relation_type')
        .eq('from_profile_id', profileId2)
        .eq('to_profile_id', profileId1)
        .maybeSingle();

    return result?['relation_type'] as String?;
  }

  /// ChatType → 프롬프트 파일명 매핑
  static String _getPromptFileName(ChatType chatType) {
    switch (chatType) {
      case ChatType.dailyFortune:
        return 'daily_fortune';
      case ChatType.sajuAnalysis:
        return 'saju_analysis';
      case ChatType.compatibility:
        return 'compatibility';
      default:
        return 'general';
    }
  }

  /// 시스템 프롬프트 로드 (MD 파일에서)
  static Future<String> _loadSystemPrompt(ChatType chatType) async {
    final fileName = _getPromptFileName(chatType);
    return PromptLoader.load(fileName);
  }

  /// 세션 복원용 시스템 프롬프트 빌드
  ///
  /// [ref]: Riverpod Ref (프로바이더 접근용)
  /// [sessionId]: 현재 세션 ID
  /// [cachedAiSummary]: 캐시된 AI Summary (새로 생성하지 않음)
  static Future<String> buildRestoreSystemPrompt({
    required Ref ref,
    required String sessionId,
    AiSummary? cachedAiSummary,
  }) async {
    try {
      // 1. 페르소나 프롬프트 (기본)
      final personaPrompt = ref.read(finalSystemPromptProvider);

      // 2. 프로필 로드
      final activeProfile = await ref.read(activeProfileProvider.future);
      if (activeProfile == null) {
        if (kDebugMode) {
          print('[ChatProvider] 세션 복원: 프로필 없음 - 페르소나 프롬프트만 사용');
        }
        return personaPrompt;
      }

      // 3. 사주 분석 로드
      final sajuAnalysis = await ref.read(currentSajuAnalysisProvider.future);

      // 4. AI Summary (캐시된 것만 사용 - 새로 생성하지 않음!)
      // 세션 복원 시 Edge Function 호출하면 비용 발생하므로 캐시만 확인
      final aiSummary = cachedAiSummary;

      // 5. 궁합 모드 확인 및 상대방 데이터 복원 (v7.2)
      SajuProfile? person1Profile = activeProfile;
      SajuAnalysis? person1SajuAnalysis = sajuAnalysis;
      SajuProfile? targetProfile;
      SajuAnalysis? targetSajuAnalysis;
      Map<String, dynamic>? compatibilityAnalysis;
      bool isThirdPartyCompatibility = false;
      String? relationType;  // v8.1: 관계 유형
      List<({SajuProfile profile, SajuAnalysis? sajuAnalysis})> additionalParticipants = [];  // v10.0

      final sessionRepository = ref.read(chatSessionRepositoryProvider);
      final currentSession = await sessionRepository.getSession(sessionId);
      final targetProfileId = currentSession?.targetProfileId;

      if (targetProfileId != null) {
        // 궁합 세션! 상대방 데이터 복원
        final profileRepo = SajuProfileRepository();
        final analysisRepo = SajuAnalysisRepository();

        targetProfile = await profileRepo.getById(targetProfileId);
        if (targetProfile != null) {
          targetSajuAnalysis = await analysisRepo.getByProfileId(targetProfileId);
        }

        // chat_mentions에서 참가자 ID 복원 → person1, person2, 추가 참가자 결정
        String? person1Id;
        String? person2Id;
        List<String> extraParticipantIds = [];  // v10.0: 3번째 이후 ID
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
              if (pid != null) extraParticipantIds.add(pid);
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('[ChatProvider] 세션 복원: chat_mentions 조회 실패: $e');
          }
        }

        // fallback: person1 = activeProfile, person2 = targetProfile
        person1Id ??= activeProfile.id;
        person2Id ??= targetProfileId;

        // "나 제외" 모드 판단
        isThirdPartyCompatibility = activeProfile.id != person1Id;

        // v7.2: 나 제외 모드에서는 person1의 프로필/사주를 별도 로드
        if (isThirdPartyCompatibility && person1Id != null) {
          person1Profile = await profileRepo.getById(person1Id);
          if (person1Profile != null) {
            person1SajuAnalysis = await analysisRepo.getByProfileId(person1Id);
          }
          // person2도 별도 로드 (targetProfileId와 다를 수 있음)
          if (person2Id != null && person2Id != targetProfileId) {
            targetProfile = await profileRepo.getById(person2Id);
            if (targetProfile != null) {
              targetSajuAnalysis = await analysisRepo.getByProfileId(person2Id);
            }
          }
        }

        // v10.0: 추가 참가자 프로필/사주 로드 (3번째 이후)
        if (extraParticipantIds.isNotEmpty) {
          for (final pid in extraParticipantIds) {
            final p = await profileRepo.getById(pid);
            if (p != null) {
              final saju = await analysisRepo.getByProfileId(pid);
              additionalParticipants.add((profile: p, sajuAnalysis: saju));
            }
          }
          if (kDebugMode) {
            print('[ChatProvider] 세션 복원: 추가 참가자 ${additionalParticipants.length}명 로드');
          }
        }

        // v8.1: 관계 유형 조회 (양방향 검색)
        if (person1Id != null && person2Id != null) {
          try {
            relationType = await findRelationType(person1Id, person2Id);
          } catch (e) {
            if (kDebugMode) {
              print('[ChatProvider] 세션 복원: 관계 유형 조회 실패: $e');
            }
          }
        }

        // 궁합 분석 결과 로드 (캐시)
        if (person1Id != null && person2Id != null) {
          try {
            final compatService = CompatibilityAnalysisService();
            final cached = await compatService.getAnalysisByProfiles(person1Id, person2Id);
            if (cached != null) {
              compatibilityAnalysis = Map<String, dynamic>.from(cached);
            }
          } catch (e) {
            if (kDebugMode) {
              print('[ChatProvider] 세션 복원: 궁합 분석 로드 실패: $e');
            }
          }
        }

        // v7.1: 두 사람의 8글자를 궁합 분석 결과에 추가 (프롬프트용)
        if (compatibilityAnalysis != null) {
          if (person1SajuAnalysis != null) {
            final c = person1SajuAnalysis.chart;
            compatibilityAnalysis!['_person1_chars'] = {
              'year_gan': c.yearPillar.gan, 'year_ji': c.yearPillar.ji,
              'month_gan': c.monthPillar.gan, 'month_ji': c.monthPillar.ji,
              'day_gan': c.dayPillar.gan, 'day_ji': c.dayPillar.ji,
              'hour_gan': c.hourPillar?.gan, 'hour_ji': c.hourPillar?.ji,
            };
          }
          if (targetSajuAnalysis != null) {
            final c = targetSajuAnalysis.chart;
            compatibilityAnalysis!['_person2_chars'] = {
              'year_gan': c.yearPillar.gan, 'year_ji': c.yearPillar.ji,
              'month_gan': c.monthPillar.gan, 'month_ji': c.monthPillar.ji,
              'day_gan': c.dayPillar.gan, 'day_ji': c.dayPillar.ji,
              'hour_gan': c.hourPillar?.gan, 'hour_ji': c.hourPillar?.ji,
            };
          }
        }

        if (kDebugMode) {
          print('[ChatProvider] 세션 복원: 궁합 모드');
          print('   상대방: ${targetProfile?.displayName ?? "?"}');
          print('   상대방 사주: ${targetSajuAnalysis != null ? "있음" : "없음"}');
          print('   궁합 분석: ${compatibilityAnalysis != null ? "있음" : "없음"}');
          print('   나 제외 모드: $isThirdPartyCompatibility');
        }
      }

      // 6. 완전한 시스템 프롬프트 생성 (궁합 데이터 포함)
      // 궁합 모드면 compatibility.md 로드, 아니면 general.md
      final restoreBasePrompt = targetProfile != null
          ? await _loadSystemPrompt(ChatType.compatibility)
          : await _loadSystemPrompt(ChatType.general);
      final builder = SystemPromptBuilder();
      final fullPrompt = builder.build(
        basePrompt: restoreBasePrompt,
        aiSummary: aiSummary,
        sajuAnalysis: person1SajuAnalysis,  // v7.2: 나 제외 모드 시 person1의 사주
        profile: person1Profile,  // v7.2: 나 제외 모드 시 person1의 프로필
        personaPrompt: personaPrompt,
        isFirstMessage: true,  // 복원 후 첫 메시지로 취급
        targetProfile: targetProfile,
        targetSajuAnalysis: targetSajuAnalysis,
        compatibilityAnalysis: compatibilityAnalysis,
        isThirdPartyCompatibility: isThirdPartyCompatibility,
        relationType: relationType,  // v8.1: 관계 유형
        additionalParticipants: additionalParticipants.isNotEmpty ? additionalParticipants : null,  // v10.0
      );

      if (kDebugMode) {
        print('[ChatProvider] 세션 복원: 프롬프트 생성 완료');
        print('   Person1 프로필: ${person1Profile?.displayName}');
        print('   Person1 사주: ${person1SajuAnalysis != null ? "있음" : "없음"}');
        print('   Person2 프로필: ${targetProfile?.displayName}');
        print('   Person2 사주: ${targetSajuAnalysis != null ? "있음" : "없음"}');
        print('   AI Summary: ${aiSummary != null ? "있음" : "없음"}');
        print('   궁합 모드: ${targetProfile != null}');
        print('   나 제외 모드: $isThirdPartyCompatibility');
        if (additionalParticipants.isNotEmpty) {
          print('   추가 참가자: ${additionalParticipants.length}명');
        }
      }

      return fullPrompt;
    } catch (e) {
      if (kDebugMode) {
        print('[ChatProvider] 세션 복원 프롬프트 오류: $e - 페르소나 프롬프트만 사용');
      }
      return ref.read(finalSystemPromptProvider);
    }
  }
}
