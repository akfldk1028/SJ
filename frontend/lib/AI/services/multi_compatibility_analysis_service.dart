/// # 다중 궁합 분석 서비스
///
/// ## 개요
/// 2~4명의 프로필 간 다중 궁합을 분석합니다.
/// Phase 50 신규 기능으로 기존 2명 궁합 서비스와 별도로 운영됩니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/services/multi_compatibility_analysis_service.dart`
///
/// ## Phase 50 신규 기능
/// - 3~4명 다중 궁합 분석
/// - "나 제외" (includes_owner=false) 지원
/// - compatibility_analyses 테이블에 새 컬럼 활용:
///   - participant_ids (UUID[])
///   - includes_owner (BOOLEAN)
///   - owner_profile_id (UUID)
///   - participant_count (INT GENERATED)
///
/// ## 사용 예시
/// ```dart
/// final service = MultiCompatibilityAnalysisService();
///
/// // 나 포함 3명 궁합
/// final result = await service.analyzeMultiCompatibility(
///   userId: user.id,
///   participantIds: [myId, friend1Id, friend2Id],
///   includesOwner: true,
///   ownerProfileId: myId,
///   relationType: 'friend_close',
/// );
///
/// // 나 제외 4명 궁합 (가족 구성원끼리)
/// final familyResult = await service.analyzeMultiCompatibility(
///   userId: user.id,
///   participantIds: [mom, dad, sister, brother],
///   includesOwner: false,
///   relationType: 'family_sibling',
/// );
/// ```

import 'package:supabase_flutter/supabase_flutter.dart';

import 'multi_compatibility_calculator.dart';

/// 다중 궁합 분석 결과 래퍼
class MultiCompatibilityAnalysisResult {
  final bool success;
  final String? analysisId;
  final MultiCompatibilityResult? data;
  final String? error;
  final int? processingTimeMs;

  const MultiCompatibilityAnalysisResult({
    required this.success,
    this.analysisId,
    this.data,
    this.error,
    this.processingTimeMs,
  });

  factory MultiCompatibilityAnalysisResult.success({
    required String analysisId,
    required MultiCompatibilityResult data,
    int? processingTimeMs,
  }) =>
      MultiCompatibilityAnalysisResult(
        success: true,
        analysisId: analysisId,
        data: data,
        processingTimeMs: processingTimeMs,
      );

  factory MultiCompatibilityAnalysisResult.failure(String error) =>
      MultiCompatibilityAnalysisResult(
        success: false,
        error: error,
      );

  factory MultiCompatibilityAnalysisResult.cached({
    required String analysisId,
    required MultiCompatibilityResult data,
  }) =>
      MultiCompatibilityAnalysisResult(
        success: true,
        analysisId: analysisId,
        data: data,
      );
}

/// 다중 궁합 분석 서비스
class MultiCompatibilityAnalysisService {
  final SupabaseClient _client = Supabase.instance.client;

  /// 다중 궁합 분석 실행
  ///
  /// ## 파라미터
  /// - `userId`: 요청 사용자 ID (RLS용)
  /// - `participantIds`: 참가자 프로필 ID 목록 (2~4명)
  /// - `includesOwner`: "나" 포함 여부
  /// - `ownerProfileId`: "나"의 프로필 ID (includesOwner=true인 경우 필수)
  /// - `relationType`: 관계 유형
  /// - `forceRefresh`: true면 캐시 무시하고 새로 분석
  Future<MultiCompatibilityAnalysisResult> analyzeMultiCompatibility({
    required String userId,
    required List<String> participantIds,
    required bool includesOwner,
    String? ownerProfileId,
    required String relationType,
    bool forceRefresh = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      print('[MultiCompatibilityService] 다중 궁합 분석 시작');
      print('  - 참가자 수: ${participantIds.length}명');
      print('  - 나 포함: $includesOwner');
      print('  - 관계 유형: $relationType');

      // 유효성 검사
      if (participantIds.length < 2 || participantIds.length > 4) {
        return MultiCompatibilityAnalysisResult.failure(
          '참가자는 2~4명이어야 합니다. 현재: ${participantIds.length}명',
        );
      }

      if (includesOwner && ownerProfileId == null) {
        return MultiCompatibilityAnalysisResult.failure(
          '"나 포함" 모드에서는 ownerProfileId가 필요합니다.',
        );
      }

      if (includesOwner && !participantIds.contains(ownerProfileId)) {
        return MultiCompatibilityAnalysisResult.failure(
          'ownerProfileId가 참가자 목록에 포함되어야 합니다.',
        );
      }

      // 1. 캐시 확인
      if (!forceRefresh) {
        final cached = await _getCachedMultiAnalysis(participantIds, includesOwner);
        if (cached != null) {
          print('[MultiCompatibilityService] 캐시된 분석 사용: ${cached['id']}');
          final cachedData = _parseMultiCompatibilityResult(cached);
          return MultiCompatibilityAnalysisResult.cached(
            analysisId: cached['id'] as String,
            data: cachedData,
          );
        }
      }

      // 2. 모든 참가자의 사주 데이터 조회
      final participants = <ParticipantSaju>[];
      for (final profileId in participantIds) {
        final profileData = await _getProfileWithSaju(profileId);
        if (profileData == null) {
          return MultiCompatibilityAnalysisResult.failure(
            '프로필을 찾을 수 없습니다: $profileId',
          );
        }

        final profile = profileData['profile'] as Map<String, dynamic>;
        final sajuAnalysis = profileData['saju_analysis'] as Map<String, dynamic>?;

        if (sajuAnalysis == null) {
          final name = profile['name'] ?? profile['display_name'] ?? '알 수 없음';
          return MultiCompatibilityAnalysisResult.failure(
            '$name님의 사주 분석이 필요합니다. 해당 프로필로 채팅을 먼저 시작해주세요.',
          );
        }

        participants.add(ParticipantSaju(
          id: profileId,
          name: profile['name'] as String? ??
              profile['display_name'] as String? ??
              '참가자',
          sajuData: sajuAnalysis,
        ));
      }

      print('[MultiCompatibilityService] 모든 참가자 사주 데이터 로드 완료');
      for (final p in participants) {
        print('  - ${p.name}: ${p.sajuString}');
      }

      // 3. 다중 궁합 계산
      final calculationResult = multiCompatibilityCalculator.calculate(
        participants: participants,
        relationType: relationType,
        includesOwner: includesOwner,
        ownerProfileId: ownerProfileId,
      );

      // 4. 결과 저장
      final savedId = await _saveMultiAnalysisResult(
        userId: userId,
        participantIds: participantIds,
        includesOwner: includesOwner,
        ownerProfileId: ownerProfileId,
        relationType: relationType,
        calculationResult: calculationResult,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );

      stopwatch.stop();
      print('[MultiCompatibilityService] 다중 궁합 분석 완료');
      print('  - ID: $savedId');
      print('  - 점수: ${calculationResult.overallScore}점');
      print('  - 소요시간: ${stopwatch.elapsedMilliseconds}ms');

      return MultiCompatibilityAnalysisResult.success(
        analysisId: savedId,
        data: calculationResult,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stack) {
      print('[MultiCompatibilityService] 오류: $e');
      print(stack);
      return MultiCompatibilityAnalysisResult.failure(e.toString());
    }
  }

  /// 캐시된 다중 분석 조회
  ///
  /// participant_ids 배열이 동일한 분석 결과를 찾습니다.
  /// 순서와 관계없이 동일한 참가자 조합이면 캐시 히트
  Future<Map<String, dynamic>?> _getCachedMultiAnalysis(
    List<String> participantIds,
    bool includesOwner,
  ) async {
    try {
      // participant_ids 배열 포함 여부로 조회
      // PostgreSQL의 @> 연산자 사용 (배열 포함)
      final sortedIds = List<String>.from(participantIds)..sort();

      // Supabase에서 배열 비교를 위한 쿼리
      // participant_count와 participant_ids로 필터링
      final response = await _client
          .from('compatibility_analyses')
          .select()
          .eq('participant_count', participantIds.length)
          .eq('includes_owner', includesOwner)
          .order('created_at', ascending: false)
          .limit(10); // 최근 10개에서 매칭

      if (response == null || (response as List).isEmpty) return null;

      // 정렬된 ID 비교로 정확한 매칭 확인
      for (final row in response) {
        final storedIds = List<String>.from(row['participant_ids'] as List? ?? []);
        storedIds.sort();
        if (_listEquals(sortedIds, storedIds)) {
          return row;
        }
      }

      return null;
    } catch (e) {
      print('[MultiCompatibilityService] 캐시 조회 오류: $e');
      return null;
    }
  }

  /// 리스트 동등성 비교
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 프로필 + 사주 분석 데이터 조회
  Future<Map<String, dynamic>?> _getProfileWithSaju(String profileId) async {
    try {
      // 프로필 조회
      final profile = await _client
          .from('saju_profiles')
          .select()
          .eq('id', profileId)
          .maybeSingle();

      if (profile == null) return null;

      // 사주 분석 조회
      final sajuAnalysis = await _client
          .from('saju_analyses')
          .select()
          .eq('profile_id', profileId)
          .maybeSingle();

      return {
        'profile': profile,
        'saju_analysis': sajuAnalysis,
      };
    } catch (e) {
      print('[MultiCompatibilityService] 프로필 조회 오류: $e');
      return null;
    }
  }

  /// 다중 분석 결과 저장
  Future<String> _saveMultiAnalysisResult({
    required String userId,
    required List<String> participantIds,
    required bool includesOwner,
    String? ownerProfileId,
    required String relationType,
    required MultiCompatibilityResult calculationResult,
    required int processingTimeMs,
  }) async {
    print('[MultiCompatibilityService] 다중 궁합 결과 저장');

    // 호환성을 위해 profile1_id, profile2_id도 설정 (첫 2명)
    final profile1Id = participantIds.isNotEmpty ? participantIds[0] : null;
    final profile2Id = participantIds.length > 1 ? participantIds[1] : null;

    final response = await _client.from('compatibility_analyses').insert({
      // 기존 2명 호환 필드
      'profile1_id': profile1Id,
      'profile2_id': profile2Id,

      // Phase 50 신규 필드
      'participant_ids': participantIds,
      'includes_owner': includesOwner,
      'owner_profile_id': ownerProfileId,
      // participant_count는 GENERATED ALWAYS로 자동 계산됨

      // 분석 결과
      'analysis_type': _getAnalysisType(relationType),
      'relation_type': relationType,
      'overall_score': calculationResult.overallScore,
      'category_scores': calculationResult.categoryScores,
      'saju_analysis': {
        'pair_compatibilities':
            calculationResult.pairCompatibilities.map((p) => p.toJson()).toList(),
        'group_harmonies':
            calculationResult.groupHarmonies.map((h) => h.toJson()).toList(),
        'group_oheng_distribution': calculationResult.groupOhengDistribution.toJson(),
      },
      'summary': calculationResult.summary,
      'strengths': calculationResult.groupStrengths,
      'challenges': calculationResult.groupChallenges,
      'advice': null, // 조언은 채팅에서 생성
      'model_provider': 'dart',
      'model_name': 'multi_compatibility_calculator_v1',
      'tokens_used': 0,
      'processing_time_ms': processingTimeMs,
    }).select('id').single();

    return response['id'] as String;
  }

  /// 관계 유형 → 분석 유형 매핑
  String _getAnalysisType(String relationType) {
    if (relationType.startsWith('romantic_')) return 'love';
    if (relationType.startsWith('family_')) return 'family';
    if (relationType.startsWith('work_') || relationType == 'business_partner') {
      return 'business';
    }
    if (relationType.startsWith('friend_')) return 'friendship';
    return 'general';
  }

  /// 캐시된 데이터를 MultiCompatibilityResult로 파싱
  MultiCompatibilityResult _parseMultiCompatibilityResult(Map<String, dynamic> cached) {
    final sajuAnalysis = cached['saju_analysis'] as Map<String, dynamic>? ?? {};
    final pairData = sajuAnalysis['pair_compatibilities'] as List<dynamic>? ?? [];
    final harmonyData = sajuAnalysis['group_harmonies'] as List<dynamic>? ?? [];
    final ohengData =
        sajuAnalysis['group_oheng_distribution'] as Map<String, dynamic>? ?? {};

    return MultiCompatibilityResult(
      overallScore: cached['overall_score'] as int? ?? 50,
      participantCount: cached['participant_count'] as int? ?? 2,
      includesOwner: cached['includes_owner'] as bool? ?? true,
      ownerProfileId: cached['owner_profile_id'] as String?,
      participantIds: List<String>.from(cached['participant_ids'] as List? ?? []),
      participantNames: [], // 캐시에서는 이름 정보 없음
      pairCompatibilities: pairData
          .map((p) => _parsePairCompatibility(p as Map<String, dynamic>))
          .toList(),
      groupHarmonies: harmonyData
          .map((h) => _parseGroupHarmony(h as Map<String, dynamic>))
          .toList(),
      groupOhengDistribution: GroupOhengDistribution(
        mok: ohengData['mok'] as int? ?? 0,
        hwa: ohengData['hwa'] as int? ?? 0,
        to: ohengData['to'] as int? ?? 0,
        geum: ohengData['geum'] as int? ?? 0,
        su: ohengData['su'] as int? ?? 0,
      ),
      groupStrengths: List<String>.from(cached['strengths'] as List? ?? []),
      groupChallenges: List<String>.from(cached['challenges'] as List? ?? []),
      summary: cached['summary'] as String? ?? '',
      categoryScores: Map<String, int>.from(
        cached['category_scores'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  /// 페어 궁합 파싱
  PairCompatibility _parsePairCompatibility(Map<String, dynamic> data) {
    final hapchungData = data['hapchung_details'] as Map<String, dynamic>? ?? {};

    return PairCompatibility(
      participant1Id: data['participant1_id'] as String? ?? '',
      participant1Name: data['participant1_name'] as String? ?? '',
      participant2Id: data['participant2_id'] as String? ?? '',
      participant2Name: data['participant2_name'] as String? ?? '',
      score: data['score'] as int? ?? 50,
      hapchungDetails: HapchungAnalysis(
        hap: List<String>.from(hapchungData['hap'] as List? ?? []),
        chung: List<String>.from(hapchungData['chung'] as List? ?? []),
        hyung: List<String>.from(hapchungData['hyung'] as List? ?? []),
        hae: List<String>.from(hapchungData['hae'] as List? ?? []),
        pa: List<String>.from(hapchungData['pa'] as List? ?? []),
        wonjin: List<String>.from(hapchungData['wonjin'] as List? ?? []),
      ),
      strengths: List<String>.from(data['strengths'] as List? ?? []),
      challenges: List<String>.from(data['challenges'] as List? ?? []),
      hasDayGanHap: data['has_day_gan_hap'] as bool? ?? false,
      hasDayJiHap: data['has_day_ji_hap'] as bool? ?? false,
      hasDayJiChung: data['has_day_ji_chung'] as bool? ?? false,
    );
  }

  /// 그룹 특수 합 파싱
  GroupHarmony _parseGroupHarmony(Map<String, dynamic> data) {
    return GroupHarmony(
      type: data['type'] as String? ?? '',
      name: data['name'] as String? ?? '',
      hanja: data['hanja'] as String? ?? '',
      resultOheng: data['result_oheng'] as String? ?? '',
      participantIds: List<String>.from(data['participant_ids'] as List? ?? []),
      participantNames: List<String>.from(data['participant_names'] as List? ?? []),
      positions: List<String>.from(data['positions'] as List? ?? []),
    );
  }

  /// 다중 궁합 분석 결과 조회 (ID로)
  Future<Map<String, dynamic>?> getMultiAnalysisById(String analysisId) async {
    try {
      return await _client
          .from('compatibility_analyses')
          .select()
          .eq('id', analysisId)
          .maybeSingle();
    } catch (e) {
      print('[MultiCompatibilityService] 분석 조회 오류: $e');
      return null;
    }
  }

  /// 다중 궁합 분석 존재 여부 확인
  Future<bool> hasMultiAnalysis(
    List<String> participantIds,
    bool includesOwner,
  ) async {
    final cached = await _getCachedMultiAnalysis(participantIds, includesOwner);
    return cached != null;
  }

  /// 다중 궁합 분석 결과 삭제
  Future<void> deleteMultiAnalysis(String analysisId) async {
    await _client.from('compatibility_analyses').delete().eq('id', analysisId);
  }

  /// 사용자의 모든 다중 궁합 분석 조회
  Future<List<Map<String, dynamic>>> getUserMultiAnalyses(String userId) async {
    try {
      final response = await _client
          .from('compatibility_analyses')
          .select()
          .gte('participant_count', 3) // 3명 이상만 다중 궁합
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('[MultiCompatibilityService] 다중 분석 목록 조회 오류: $e');
      return [];
    }
  }
}

/// 전역 다중 궁합 서비스 인스턴스
final multiCompatibilityAnalysisService = MultiCompatibilityAnalysisService();
