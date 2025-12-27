import '../../../features/profile/data/models/saju_profile_model.dart';
import '../../../features/saju_chart/data/models/saju_analysis_db_model.dart';
import '../../../features/saju_chat/data/models/chat_message_model.dart';

/// AI 컨텍스트
///
/// AI 분석/대화에 필요한 모든 데이터를 하나로 묶은 컨테이너
/// JH_AI, Jina 팀원이 이 객체 하나로 필요한 데이터에 접근
///
/// ```dart
/// // AI 모듈에서 사용 예시
/// final context = await ref.read(aiContextProvider.future);
///
/// // 프로필 정보
/// final name = context.profile.displayName;
/// final gender = context.profile.gender;
///
/// // 사주 분석 데이터
/// final dayGan = context.analysis.dayGan;  // 일간
/// final yongsin = context.analysis.yongsin;  // 용신
///
/// // 최근 대화 (컨텍스트용)
/// final recentChats = context.recentMessages;
/// ```
class AIContext {
  /// 사용자 프로필
  final SajuProfileModel profile;

  /// 사주 분석 결과
  final SajuAnalysisDbModel analysis;

  /// 최근 대화 메시지 (AI 컨텍스트 전달용)
  final List<ChatMessageModel>? recentMessages;

  /// 현재 채팅 세션 ID
  final String? currentSessionId;

  /// 추가 메타데이터
  final Map<String, dynamic>? metadata;

  const AIContext({
    required this.profile,
    required this.analysis,
    this.recentMessages,
    this.currentSessionId,
    this.metadata,
  });

  // ============================================================================
  // 프로필 관련 Getter
  // ============================================================================

  /// 프로필 ID
  String get profileId => profile.id;

  /// 표시 이름
  String get displayName => profile.displayName;

  /// 성별 (male/female)
  String get gender => profile.gender;

  /// 생년월일
  DateTime get birthDate => profile.birthDate;

  /// 음력 여부
  bool get isLunar => profile.isLunar;

  /// 출생 시간 (분)
  int? get birthTimeMinutes => profile.birthTimeMinutes;

  /// 출생 도시
  String get birthCity => profile.birthCity;

  // ============================================================================
  // 사주 분석 Getter
  // ============================================================================

  /// 사주팔자 (년월일시)
  String get sajuPalza {
    final year = '${analysis.yearGan}${analysis.yearJi}';
    final month = '${analysis.monthGan}${analysis.monthJi}';
    final day = '${analysis.dayGan}${analysis.dayJi}';
    final hour = (analysis.hourGan != null && analysis.hourJi != null)
        ? '${analysis.hourGan}${analysis.hourJi}'
        : '';
    return '$year $month $day $hour'.trim();
  }

  /// 일간 (日干) - 나를 나타내는 글자
  String get dayGan => analysis.dayGan;

  /// 오행 분포
  Map<String, dynamic>? get ohengDistribution => analysis.ohengDistribution;

  /// 일간 강약 (신강/신약)
  Map<String, dynamic>? get dayStrength => analysis.dayStrength;

  /// 신강 여부
  bool get isSingang => analysis.dayStrength?['is_singang'] ?? false;

  /// 용신 정보
  Map<String, dynamic>? get yongsin => analysis.yongsin;

  /// 용신 오행 (예: "수(水)")
  String? get yongsinOheng => analysis.yongsin?['yongsin'] as String?;

  /// 희신 오행
  String? get huisinOheng => analysis.yongsin?['huisin'] as String?;

  /// 격국 정보
  Map<String, dynamic>? get gyeokguk => analysis.gyeokguk;

  /// 십신 정보
  Map<String, dynamic>? get sipsinInfo => analysis.sipsinInfo;

  /// 대운 정보
  Map<String, dynamic>? get daeun => analysis.daeun;

  /// 현재 세운
  Map<String, dynamic>? get currentSeun => analysis.currentSeun;

  // ============================================================================
  // 대화 컨텍스트
  // ============================================================================

  /// 최근 대화 메시지 수
  int get recentMessageCount => recentMessages?.length ?? 0;

  /// 최근 대화 요약 (AI 프롬프트용)
  String get conversationSummary {
    if (recentMessages == null || recentMessages!.isEmpty) {
      return '대화 기록 없음';
    }

    final buffer = StringBuffer();
    for (final msg in recentMessages!) {
      final role = msg.role == 'user' ? '사용자' : 'AI';
      final content = msg.content.length > 100
          ? '${msg.content.substring(0, 100)}...'
          : msg.content;
      buffer.writeln('$role: $content');
    }
    return buffer.toString();
  }

  // ============================================================================
  // AI 프롬프트 헬퍼
  // ============================================================================

  /// 기본 사주 정보 문자열 (프롬프트용)
  String get basicInfoForPrompt {
    final buffer = StringBuffer();
    buffer.writeln('이름: $displayName');
    buffer.writeln('성별: ${gender == 'male' ? '남성' : '여성'}');
    buffer.writeln('생년월일: ${birthDate.year}년 ${birthDate.month}월 ${birthDate.day}일 (${isLunar ? '음력' : '양력'})');
    if (birthTimeMinutes != null) {
      final hours = birthTimeMinutes! ~/ 60;
      final minutes = birthTimeMinutes! % 60;
      buffer.writeln('출생시간: $hours시 $minutes분');
    }
    buffer.writeln('사주팔자: $sajuPalza');
    buffer.writeln('일간: $dayGan (${isSingang ? '신강' : '신약'})');
    if (yongsinOheng != null) {
      buffer.writeln('용신: $yongsinOheng');
    }
    return buffer.toString();
  }

  /// 상세 분석 정보 문자열 (프롬프트용)
  String get detailedInfoForPrompt {
    final buffer = StringBuffer();
    buffer.writeln(basicInfoForPrompt);
    buffer.writeln();

    // 오행 분포
    if (ohengDistribution != null) {
      buffer.writeln('오행 분포:');
      ohengDistribution!.forEach((key, value) {
        buffer.writeln('  - $key: $value');
      });
    }

    // 격국
    if (gyeokguk != null) {
      buffer.writeln('격국: ${gyeokguk!['name'] ?? '미정'}');
    }

    return buffer.toString();
  }

  // ============================================================================
  // Utility
  // ============================================================================

  /// 복사본 생성
  AIContext copyWith({
    SajuProfileModel? profile,
    SajuAnalysisDbModel? analysis,
    List<ChatMessageModel>? recentMessages,
    String? currentSessionId,
    Map<String, dynamic>? metadata,
  }) {
    return AIContext(
      profile: profile ?? this.profile,
      analysis: analysis ?? this.analysis,
      recentMessages: recentMessages ?? this.recentMessages,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'AIContext(profile: $displayName, saju: $sajuPalza, messages: $recentMessageCount)';
  }
}
