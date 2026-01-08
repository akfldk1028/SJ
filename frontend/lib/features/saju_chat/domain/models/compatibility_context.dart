import '../../../profile/data/models/saju_profile_model.dart';
import '../../../profile/data/relation_schema.dart';
import '../../../saju_chart/data/models/saju_analysis_model.dart';

/// 궁합 분석 컨텍스트
///
/// 두 프로필의 사주 분석 데이터를 담아 AI에게 전달하는 구조체
/// - 나(from)와 상대방(to)의 프로필 및 사주 분석
/// - 관계 유형에 따른 분석 초점 결정
///
/// 사용 예:
/// ```dart
/// final context = CompatibilityContext(
///   fromProfile: myProfile,
///   fromAnalysis: myAnalysis,
///   toProfile: targetProfile,
///   toAnalysis: targetAnalysis,
///   relationType: ProfileRelationType.familyParent,
/// );
///
/// // AI 프롬프트에 전달
/// final prompt = context.toPromptContext();
/// ```
class CompatibilityContext {
  /// 나의 프로필 정보
  final SajuProfileModel fromProfile;

  /// 나의 사주 분석 결과
  final SajuAnalysisModel fromAnalysis;

  /// 상대방의 프로필 정보
  final SajuProfileModel toProfile;

  /// 상대방의 사주 분석 결과
  final SajuAnalysisModel toAnalysis;

  /// 관계 유형 (family_parent, romantic_partner 등)
  final ProfileRelationType relationType;

  /// 관계에서 표시되는 이름 (예: "엄마", "여자친구")
  final String? relationDisplayName;

  /// 캐시된 궁합 분석 ID (있으면 재분석 스킵)
  final String? cachedCompatibilityAnalysisId;

  const CompatibilityContext({
    required this.fromProfile,
    required this.fromAnalysis,
    required this.toProfile,
    required this.toAnalysis,
    required this.relationType,
    this.relationDisplayName,
    this.cachedCompatibilityAnalysisId,
  });

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
    final targetName = relationDisplayName ?? toProfile.displayName;
    return '$targetName님과의 $analysisTypeLabel';
  }

  /// 상대방 이름 (표시용)
  String get targetDisplayName =>
      relationDisplayName ?? toProfile.displayName ?? '상대방';

  /// 나의 이름 (표시용)
  String get myDisplayName => fromProfile.displayName ?? '나';

  /// 캐시된 분석이 있는지
  bool get hasCachedAnalysis => cachedCompatibilityAnalysisId != null;

  /// AI 프롬프트용 컨텍스트 문자열 생성
  ///
  /// 관계 유형에 따라 적절한 분석 초점을 포함
  String toPromptContext() {
    final buffer = StringBuffer();

    // 헤더
    buffer.writeln('## 궁합 분석 요청');
    buffer.writeln('분석 유형: $analysisTypeLabel');
    buffer.writeln('관계: ${relationType.displayName}');
    buffer.writeln();

    // 나의 사주 정보
    buffer.writeln('### ${myDisplayName}의 사주');
    buffer.writeln(_formatSajuInfo(fromProfile, fromAnalysis));
    buffer.writeln();

    // 상대방의 사주 정보
    buffer.writeln('### ${targetDisplayName}의 사주');
    buffer.writeln(_formatSajuInfo(toProfile, toAnalysis));
    buffer.writeln();

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
    if (profile.birthTime != null) {
      buffer.writeln('- 태어난 시간: ${profile.birthTime}');
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
    return switch (analysisType) {
      'family' => '''
- 부모-자녀 / 형제-자매 간의 오행 조화
- 세대 간 소통 패턴과 갈등 요소
- 가족 내 역할과 책임의 균형
- 서로를 이해하고 지지하는 방법
- 가족 유대를 강화하는 활동 제안''',
      'love' => '''
- 연애/결혼 궁합의 핵심 지표
- 일간(일주 천간) 간의 관계 분석
- 성격 궁합과 소통 스타일
- 재성/관성 관계로 본 상대방 운
- 함께하는 미래 전망과 주의점
- 관계 발전을 위한 실질적 조언''',
      'friendship' => '''
- 친구로서의 오행 궁합
- 신뢰와 소통의 패턴
- 함께 성장할 수 있는 영역
- 갈등 발생 시 해결 방법
- 우정을 깊게 하는 활동 제안''',
      'business' => '''
- 업무/사업 파트너로서의 궁합
- 각자의 강점과 역할 분담
- 협업 시 시너지와 주의점
- 재물운의 상호 작용
- 사업 성공을 위한 전략적 조언''',
      _ => '''
- 두 사람의 전반적인 오행 조화
- 성격과 기질의 상호 작용
- 서로에게 미치는 영향
- 관계 발전을 위한 조언''',
    };
  }

  /// 간략한 요약 정보 (UI 표시용)
  Map<String, String> toSummaryMap() {
    return {
      'my_name': myDisplayName,
      'target_name': targetDisplayName,
      'relation': relationType.displayName,
      'analysis_type': analysisTypeLabel,
      'my_day_gan': fromAnalysis.analysis.chart.dayPillar.gan,
      'target_day_gan': toAnalysis.analysis.chart.dayPillar.gan,
    };
  }
}

/// 궁합 분석 캐시 결과
///
/// compatibility_analyses 테이블에 저장되는 데이터
class CompatibilityAnalysisCache {
  final String id;
  final String profile1Id;
  final String profile2Id;
  final String analysisType;

  /// 전체 점수 (0-100)
  final int overallScore;

  /// 사주 분석 결과 (JSONB)
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

  const CompatibilityAnalysisCache({
    required this.id,
    required this.profile1Id,
    required this.profile2Id,
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
  factory CompatibilityAnalysisCache.fromSupabaseMap(Map<String, dynamic> map) {
    return CompatibilityAnalysisCache(
      id: map['id'] as String,
      profile1Id: map['profile1_id'] as String,
      profile2Id: map['profile2_id'] as String,
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
      'profile1_id': profile1Id,
      'profile2_id': profile2Id,
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
    if (overallScore >= 90) return '천생연분';
    if (overallScore >= 80) return '매우 좋음';
    if (overallScore >= 70) return '좋음';
    if (overallScore >= 60) return '보통';
    if (overallScore >= 50) return '노력 필요';
    return '주의 필요';
  }
}
