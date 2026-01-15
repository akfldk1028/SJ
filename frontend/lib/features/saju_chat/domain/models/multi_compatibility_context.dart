/// # 다중 궁합 분석 컨텍스트
///
/// ## 개요
/// 2~4명의 프로필 사주 분석 데이터를 담아 AI에게 전달하는 구조체
/// Phase 50 신규 기능으로 기존 2명 궁합 컨텍스트와 별도로 운영됩니다.
///
/// ## 파일 위치
/// `frontend/lib/features/saju_chat/domain/models/multi_compatibility_context.dart`
///
/// ## Phase 50 신규 기능
/// - 3~4명 다중 궁합 컨텍스트
/// - "나 제외" (includes_owner=false) 지원
/// - AI 프롬프트용 상세 포맷팅
///
/// ## 사용 예시
/// ```dart
/// final context = MultiCompatibilityContext(
///   participants: [profile1, profile2, profile3],
///   participantAnalyses: [analysis1, analysis2, analysis3],
///   relationType: ProfileRelationType.friendClose,
///   includesOwner: true,
///   ownerProfileId: myProfileId,
/// );
///
/// // AI 프롬프트에 전달
/// final prompt = context.toPromptContext();
/// ```

import '../../../profile/data/models/saju_profile_model.dart';
import '../../../profile/data/relation_schema.dart';
import '../../../saju_chart/data/models/saju_analysis_model.dart';

/// 다중 궁합 분석 컨텍스트
class MultiCompatibilityContext {
  /// 참가자 프로필 목록 (2~4명)
  final List<SajuProfileModel> participants;

  /// 참가자별 사주 분석 결과
  final List<SajuAnalysisModel> participantAnalyses;

  /// 관계 유형 (family_parent, friend_close 등)
  final ProfileRelationType relationType;

  /// "나" 포함 여부
  final bool includesOwner;

  /// "나"의 프로필 ID (includesOwner=true인 경우)
  final String? ownerProfileId;

  /// 각 참가자의 관계 표시명 (예: ["엄마", "아빠", "동생"])
  final List<String>? relationDisplayNames;

  /// 캐시된 다중 궁합 분석 ID
  final String? cachedMultiAnalysisId;

  const MultiCompatibilityContext({
    required this.participants,
    required this.participantAnalyses,
    required this.relationType,
    required this.includesOwner,
    this.ownerProfileId,
    this.relationDisplayNames,
    this.cachedMultiAnalysisId,
  });

  /// 참가자 수
  int get participantCount => participants.length;

  /// 분석 유형 (family, love, friendship, business, general)
  String get analysisType => relationType.compatibilityType;

  /// 분석 유형 한글 라벨
  String get analysisTypeLabel {
    return switch (analysisType) {
      'family' => '가족 궁합',
      'love' => '연애/결혼 궁합',
      'friendship' => '우정 궁합',
      'business' => '사업/직장 궁합',
      _ => '일반 궁합',
    };
  }

  /// 채팅 타이틀
  String get chatTitle {
    final names = _getDisplayNames();
    if (names.length <= 2) {
      return '${names.join("님, ")}님의 $analysisTypeLabel';
    } else {
      return '${names.take(2).join("님, ")}님 외 ${names.length - 2}명의 $analysisTypeLabel';
    }
  }

  /// "나"의 프로필 인덱스 (-1이면 없음)
  int get ownerIndex {
    if (!includesOwner || ownerProfileId == null) return -1;
    return participants.indexWhere((p) => p.id == ownerProfileId);
  }

  /// "나"의 프로필 (없으면 null)
  SajuProfileModel? get ownerProfile {
    final idx = ownerIndex;
    return idx >= 0 ? participants[idx] : null;
  }

  /// "나"의 사주 분석 (없으면 null)
  SajuAnalysisModel? get ownerAnalysis {
    final idx = ownerIndex;
    return idx >= 0 ? participantAnalyses[idx] : null;
  }

  /// 캐시된 분석이 있는지
  bool get hasCachedAnalysis => cachedMultiAnalysisId != null;

  /// 표시용 이름 목록
  List<String> _getDisplayNames() {
    final names = <String>[];
    for (int i = 0; i < participants.length; i++) {
      if (relationDisplayNames != null && i < relationDisplayNames!.length) {
        names.add(relationDisplayNames![i]);
      } else {
        names.add(participants[i].displayName ?? '참가자 ${i + 1}');
      }
    }
    return names;
  }

  /// 참가자별 표시 이름 가져오기
  String getParticipantDisplayName(int index) {
    if (index < 0 || index >= participants.length) return '알 수 없음';

    if (relationDisplayNames != null && index < relationDisplayNames!.length) {
      return relationDisplayNames![index];
    }
    return participants[index].displayName ?? '참가자 ${index + 1}';
  }

  /// AI 프롬프트용 컨텍스트 문자열 생성
  ///
  /// 관계 유형에 따라 적절한 분석 초점을 포함
  String toPromptContext() {
    final buffer = StringBuffer();

    // 헤더
    buffer.writeln('## 다중 궁합 분석 요청');
    buffer.writeln('분석 유형: $analysisTypeLabel');
    buffer.writeln('참가자 수: $participantCount명');
    buffer.writeln('나 포함: ${includesOwner ? "예" : "아니오"}');
    buffer.writeln('관계: ${relationType.displayName}');
    buffer.writeln();

    // 각 참가자의 사주 정보
    for (int i = 0; i < participants.length; i++) {
      final name = getParticipantDisplayName(i);
      final isOwner = includesOwner && participants[i].id == ownerProfileId;
      final ownerMark = isOwner ? ' (나)' : '';

      buffer.writeln('### ${i + 1}. $name$ownerMark의 사주');
      buffer.writeln(_formatSajuInfo(participants[i], participantAnalyses[i]));
      buffer.writeln();
    }

    // 분석 초점 안내
    buffer.writeln('### 분석 초점');
    buffer.writeln(_getAnalysisFocus());

    return buffer.toString();
  }

  /// 사주 정보 포맷팅
  String _formatSajuInfo(SajuProfileModel profile, SajuAnalysisModel analysis) {
    final chart = analysis.analysis.chart;
    final buffer = StringBuffer();

    // 기본 정보
    buffer.writeln('- 이름: ${profile.displayName ?? "미입력"}');
    buffer.writeln('- 성별: ${profile.gender == 'male' ? '남성' : '여성'}');
    buffer.writeln(
        '- 생년월일: ${profile.birthDate.year}년 ${profile.birthDate.month}월 ${profile.birthDate.day}일');
    if (profile.birthTimeMinutes != null) {
      final hours = profile.birthTimeMinutes! ~/ 60;
      final minutes = profile.birthTimeMinutes! % 60;
      buffer.writeln(
          '- 태어난 시간: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}');
    }

    // 사주 4주
    buffer.writeln('- 사주팔자:');
    buffer.writeln(
        '  - 년주: ${chart.yearPillar.gan}${chart.yearPillar.ji} (${_getGanJiMeaning(chart.yearPillar.gan, chart.yearPillar.ji)})');
    buffer.writeln(
        '  - 월주: ${chart.monthPillar.gan}${chart.monthPillar.ji} (${_getGanJiMeaning(chart.monthPillar.gan, chart.monthPillar.ji)})');
    buffer.writeln(
        '  - 일주: ${chart.dayPillar.gan}${chart.dayPillar.ji} (${_getGanJiMeaning(chart.dayPillar.gan, chart.dayPillar.ji)})');
    if (chart.hourPillar != null) {
      buffer.writeln(
          '  - 시주: ${chart.hourPillar!.gan}${chart.hourPillar!.ji} (${_getGanJiMeaning(chart.hourPillar!.gan, chart.hourPillar!.ji)})');
    }

    // 오행 분포
    final oheng = analysis.analysis.ohengDistribution;
    buffer.writeln('- 오행 분포:');
    buffer.writeln('  - 목(木): ${oheng.mok}');
    buffer.writeln('  - 화(火): ${oheng.hwa}');
    buffer.writeln('  - 토(土): ${oheng.to}');
    buffer.writeln('  - 금(金): ${oheng.geum}');
    buffer.writeln('  - 수(水): ${oheng.su}');

    // 일간 강약
    final dayStrength = analysis.analysis.dayStrength;
    buffer.writeln('- 신강/신약: ${dayStrength.level.name} (점수: ${dayStrength.score})');

    // 용신
    final yongsin = analysis.analysis.yongsin;
    buffer.writeln('- 용신: ${yongsin.yongsin.name}');
    buffer.writeln('- 희신: ${yongsin.heesin.name}');

    return buffer.toString();
  }

  /// 천간/지지 의미 반환
  String _getGanJiMeaning(String gan, String ji) {
    // 천간 오행
    final ganOheng = switch (gan) {
      '갑' || '을' => '목',
      '병' || '정' => '화',
      '무' || '기' => '토',
      '경' || '신' => '금',
      '임' || '계' => '수',
      _ => '',
    };

    // 지지 띠
    final jiAnimal = switch (ji) {
      '자' => '쥐',
      '축' => '소',
      '인' => '호랑이',
      '묘' => '토끼',
      '진' => '용',
      '사' => '뱀',
      '오' => '말',
      '미' => '양',
      '신' => '원숭이',
      '유' => '닭',
      '술' => '개',
      '해' => '돼지',
      _ => '',
    };

    return '$ganOheng/$jiAnimal';
  }

  /// 관계 유형별 분석 초점
  String _getAnalysisFocus() {
    final countText = '$participantCount명';
    final ownerText = includesOwner ? '(나 포함)' : '(나 제외)';

    return switch (analysisType) {
      'family' => '''
- $countText$ownerText 가족 구성원 간의 오행 조화
- 각 구성원의 역할과 상호작용 패턴
- 세대/관계 간 갈등 요소와 해결 방안
- 가족 전체의 시너지와 보완점
- 함께하는 활동과 소통 방법 제안''',
      'love' => '''
- $countText$ownerText 구성원 간의 연애/결혼 궁합
- 삼각관계 또는 다자관계 역학
- 각 쌍별 상성과 전체 조화
- 잠재적 갈등 요소와 주의점
- 관계 발전을 위한 조언''',
      'friendship' => '''
- $countText$ownerText 친구 그룹의 오행 궁합
- 그룹 내 역할 분담과 케미
- 소통 스타일과 신뢰 패턴
- 함께 성장할 수 있는 영역
- 우정을 깊게 하는 활동 제안''',
      'business' => '''
- $countText$ownerText 업무/사업 파트너 궁합
- 각자의 강점과 역할 분담
- 팀워크와 시너지 분석
- 협업 시 주의점과 갈등 해결법
- 성공적인 협업을 위한 전략''',
      _ => '''
- $countText$ownerText 구성원의 전반적인 오행 조화
- 각 쌍별 성격과 기질 상호작용
- 그룹 전체의 균형과 역학
- 관계 발전을 위한 조언''',
    };
  }

  /// 간략한 요약 정보 (UI 표시용)
  Map<String, dynamic> toSummaryMap() {
    final names = _getDisplayNames();
    final dayGans =
        participantAnalyses.map((a) => a.analysis.chart.dayPillar.gan).toList();

    return {
      'participant_count': participantCount,
      'participant_names': names,
      'includes_owner': includesOwner,
      'relation_type': relationType.name,
      'analysis_type': analysisTypeLabel,
      'day_gans': dayGans,
    };
  }
}

/// 다중 궁합 분석 캐시 결과
///
/// compatibility_analyses 테이블에 저장되는 데이터 (Phase 50 확장)
class MultiCompatibilityAnalysisCache {
  final String id;
  final List<String> participantIds;
  final int participantCount;
  final bool includesOwner;
  final String? ownerProfileId;
  final String analysisType;

  /// 전체 점수 (0-100)
  final int overallScore;

  /// 사주 분석 결과 (JSONB) - 페어별 분석 + 그룹 분석
  final Map<String, dynamic> sajuAnalysis;

  /// 강점 목록
  final List<String> strengths;

  /// 도전 과제 목록
  final List<String> challenges;

  /// 조언
  final String? advice;

  /// 분석 일시
  final DateTime analyzedAt;

  /// 만료 예정일
  final DateTime? expiresAt;

  const MultiCompatibilityAnalysisCache({
    required this.id,
    required this.participantIds,
    required this.participantCount,
    required this.includesOwner,
    this.ownerProfileId,
    required this.analysisType,
    required this.overallScore,
    required this.sajuAnalysis,
    this.strengths = const [],
    this.challenges = const [],
    this.advice,
    required this.analyzedAt,
    this.expiresAt,
  });

  /// Supabase Map에서 생성
  factory MultiCompatibilityAnalysisCache.fromSupabaseMap(Map<String, dynamic> map) {
    return MultiCompatibilityAnalysisCache(
      id: map['id'] as String,
      participantIds: List<String>.from(map['participant_ids'] as List? ?? []),
      participantCount: map['participant_count'] as int? ?? 2,
      includesOwner: map['includes_owner'] as bool? ?? true,
      ownerProfileId: map['owner_profile_id'] as String?,
      analysisType: map['analysis_type'] as String,
      overallScore: map['overall_score'] as int? ?? 0,
      sajuAnalysis: map['saju_analysis'] as Map<String, dynamic>? ?? {},
      strengths: (map['strengths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      challenges: (map['challenges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      advice: map['advice'] as String?,
      analyzedAt: DateTime.parse(map['analyzed_at'] as String),
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
    );
  }

  /// Supabase INSERT용 Map
  Map<String, dynamic> toSupabaseInsert() {
    return {
      'participant_ids': participantIds,
      'includes_owner': includesOwner,
      'owner_profile_id': ownerProfileId,
      'analysis_type': analysisType,
      'overall_score': overallScore,
      'saju_analysis': sajuAnalysis,
      'strengths': strengths,
      'challenges': challenges,
      'advice': advice,
      'analyzed_at': analyzedAt.toUtc().toIso8601String(),
      'expires_at': expiresAt?.toUtc().toIso8601String(),
    };
  }

  /// 만료 여부
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// 점수 등급
  String get scoreGrade {
    if (overallScore >= 90) return '최고의 조합';
    if (overallScore >= 80) return '매우 좋음';
    if (overallScore >= 70) return '좋음';
    if (overallScore >= 60) return '보통';
    if (overallScore >= 50) return '노력 필요';
    return '주의 필요';
  }
}
