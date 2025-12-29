/// # 프롬프트 템플릿 베이스
///
/// ## 개요
/// 모든 AI 프롬프트의 기본 인터페이스와 공통 데이터 모델을 정의합니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/prompts/prompt_template.dart`
///
/// ## 핵심 클래스
/// - `PromptTemplate`: 프롬프트 템플릿 추상 클래스
/// - `SajuInputData`: GPT에 전달할 사주 정보 데이터 클래스
///
/// ## 상속 구조
/// ```
/// PromptTemplate (추상)
///   ├── SajuBasePrompt      (평생 사주 - GPT-4o)
///   ├── DailyFortunePrompt  (일운 - Gemini)
///   ├── MonthlyFortunePrompt
///   └── QuestionAnswerPrompt
/// ```
///
/// ## 데이터 흐름
/// ```
/// saju_analyses (DB)
///       ↓
/// AiQueries.convertToInputData()
///       ↓
/// SajuInputData
///       ↓
/// PromptTemplate.buildUserPrompt()
///       ↓
/// GPT/Gemini API 호출
/// ```
///
/// ## 사용 예시
/// ```dart
/// // 1. 프롬프트 생성
/// final prompt = SajuBasePrompt();
///
/// // 2. 메시지 빌드
/// final messages = prompt.buildMessages(sajuInputData.toJson());
///
/// // 3. API 호출
/// final response = await apiService.callOpenAI(
///   messages: messages,
///   model: prompt.modelName,
///   maxTokens: prompt.maxTokens,
/// );
/// ```

// ═══════════════════════════════════════════════════════════════════════════
// 프롬프트 템플릿 추상 클래스
// ═══════════════════════════════════════════════════════════════════════════

/// 프롬프트 템플릿 기본 클래스
///
/// ## 구현 필수 항목
/// - `summaryType`: 분석 유형 (DB 저장용)
/// - `modelName`: 사용할 AI 모델
/// - `systemPrompt`: 시스템 프롬프트
/// - `buildUserPrompt()`: 사용자 프롬프트 생성
/// - `maxTokens`: 최대 응답 토큰
/// - `cacheExpiry`: 캐시 만료 시간
///
/// ## 선택적 오버라이드
/// - `temperature`: 창의성 수준 (기본 0.7)
abstract class PromptTemplate {
  /// 분석 유형 (SummaryType 상수 값)
  ///
  /// DB의 `ai_summaries.summary_type` 컬럼에 저장됩니다.
  /// 예: 'saju_base', 'daily_fortune'
  String get summaryType;

  /// 사용할 AI 모델 ID
  ///
  /// OpenAI: 'gpt-4o', 'gpt-4o-mini'
  /// Google: 'gemini-2.0-flash', 'gemini-1.5-pro'
  String get modelName;

  /// 시스템 프롬프트
  ///
  /// AI의 역할과 응답 형식을 정의합니다.
  /// 예: "당신은 한국 전통 사주명리학 전문가입니다..."
  String get systemPrompt;

  /// 사용자 프롬프트 생성
  ///
  /// [input] SajuInputData.toJson()의 결과
  /// 반환: 완성된 사용자 프롬프트 문자열
  String buildUserPrompt(Map<String, dynamic> input);

  /// 최대 응답 토큰 수
  ///
  /// 응답 길이를 제한합니다.
  /// 너무 작으면 응답이 잘리고, 너무 크면 비용이 증가합니다.
  int get maxTokens;

  /// Temperature (창의성/무작위성)
  ///
  /// - 0.0: 결정적, 일관된 응답
  /// - 1.0: 창의적, 다양한 응답
  /// - 2.0: 매우 무작위적
  ///
  /// 사주 분석은 0.7 정도가 적당 (정확성 + 약간의 창의성)
  double get temperature => 0.7;

  /// 캐시 만료 시간
  ///
  /// - `null`: 무기한 캐시
  /// - `Duration(hours: 24)`: 24시간 후 만료
  Duration? get cacheExpiry;

  /// 완성된 메시지 배열 생성
  ///
  /// OpenAI/Gemini API에 전달할 메시지 형식으로 변환합니다.
  ///
  /// [input] SajuInputData.toJson() 결과
  /// 반환: [{'role': 'system', 'content': ...}, {'role': 'user', 'content': ...}]
  List<Map<String, String>> buildMessages(Map<String, dynamic> input) {
    return [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': buildUserPrompt(input)},
    ];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 사주 입력 데이터 클래스
// ═══════════════════════════════════════════════════════════════════════════

/// 사주 정보 입력 데이터
///
/// ## 개요
/// saju_analyses 테이블의 데이터를 GPT 프롬프트에 전달하기 위한 형식으로 변환합니다.
///
/// ## 필드 설명
///
/// ### 기본 정보
/// - `profileId`: 프로필 고유 ID (UUID)
/// - `profileName`: 표시 이름 (예: "홍길동")
/// - `birthDate`: 생년월일
/// - `birthTime`: 생시 (HH:mm 형식, 선택적)
/// - `gender`: 성별 ('male' 또는 'female')
///
/// ### 사주 팔자 (`saju` Map)
/// ```dart
/// {
///   'year_gan': '갑',   // 년간
///   'year_ji': '자',    // 년지
///   'month_gan': '을',  // 월간
///   'month_ji': '축',   // 월지
///   'day_gan': '병',    // 일간 (나를 대표)
///   'day_ji': '인',     // 일지
///   'hour_gan': '정',   // 시간 (선택적)
///   'hour_ji': '묘',    // 시지 (선택적)
/// }
/// ```
///
/// ### 오행 분포 (`oheng` Map)
/// ```dart
/// {
///   'wood': 2,   // 목
///   'fire': 1,   // 화
///   'earth': 3,  // 토
///   'metal': 1,  // 금
///   'water': 1,  // 수
/// }
/// ```
///
/// ### 용신 정보 (`yongsin` Map, 선택적)
/// ```dart
/// {
///   'yongsin': '금(金)',  // 용신
///   'huisin': '토(土)',   // 희신
///   'gisin': '화(火)',    // 기신
///   'gusin': '수(水)',    // 구신
/// }
/// ```
///
/// ### 신강/신약 (`dayStrength` Map, 선택적)
/// ```dart
/// {
///   'is_singang': true,  // 신강 여부
///   'score': 65,         // 점수 (0-100)
/// }
/// ```
///
/// ### 신살 (`sinsal` List, 선택적)
/// ```dart
/// [
///   {'name': '역마살', 'pillar': 'year', 'meaning': '...'},
///   {'name': '도화살', 'pillar': 'day', 'meaning': '...'},
/// ]
/// ```
///
/// ### 길성 (`gilseong` List, 선택적)
/// ```dart
/// [
///   {'name': '천을귀인', 'pillar': 'year', 'meaning': '...'},
/// ]
/// ```
///
/// ### 12운성 (`twelveUnsung` Map, 선택적)
/// ```dart
/// {
///   'year': '장생',
///   'month': '목욕',
///   'day': '관대',
///   'hour': '건록',
/// }
/// ```
class SajuInputData {
  // ─────────────────────────────────────────────────────────────────────────
  // 기본 정보
  // ─────────────────────────────────────────────────────────────────────────

  /// 프로필 고유 ID (UUID)
  final String profileId;

  /// 표시 이름
  final String profileName;

  /// 생년월일
  final DateTime birthDate;

  /// 생시 (HH:mm 형식, 예: "14:30")
  /// null이면 시간 미상
  final String? birthTime;

  /// 성별 ('male' 또는 'female')
  final String gender;

  // ─────────────────────────────────────────────────────────────────────────
  // 사주 정보
  // ─────────────────────────────────────────────────────────────────────────

  /// 사주 팔자
  /// Keys: year_gan, year_ji, month_gan, month_ji, day_gan, day_ji, [hour_gan, hour_ji]
  final Map<String, String> saju;

  /// 오행 분포
  /// Keys: wood, fire, earth, metal, water
  final Map<String, int> oheng;

  /// 용신 정보 (선택적)
  final Map<String, dynamic>? yongsin;

  /// 신강/신약 정보 (선택적)
  final Map<String, dynamic>? dayStrength;

  /// 신살 목록 (선택적)
  final List<Map<String, dynamic>>? sinsal;

  /// 길성 목록 (선택적)
  final List<Map<String, dynamic>>? gilseong;

  /// 12운성 (선택적)
  final List<dynamic>? twelveUnsung;

  // ─────────────────────────────────────────────────────────────────────────
  // 추가 사주 분석 데이터 (AI 프롬프트용)
  // ─────────────────────────────────────────────────────────────────────────

  /// 십신 정보 (선택적)
  /// ```dart
  /// {
  ///   'year': {'gan': '편관', 'ji': '정재'},
  ///   'month': {'gan': '정인', 'ji': '편재'},
  ///   ...
  /// }
  /// ```
  final Map<String, dynamic>? sipsinInfo;

  /// 지장간 정보 (선택적)
  /// ```dart
  /// {
  ///   'year': ['정화', '기토'],
  ///   'month': ['갑목', '을목', '계수'],
  ///   ...
  /// }
  /// ```
  final Map<String, dynamic>? jijangganInfo;

  /// 격국 정보 (선택적)
  /// ```dart
  /// {
  ///   'name': '정관격',
  ///   'description': '...',
  /// }
  /// ```
  final Map<String, dynamic>? gyeokguk;

  /// 12신살 (선택적) - 년지 기준 12지지별 신살
  /// ```dart
  /// [
  ///   {"jiji":"술","pillar":"년지","sinsal":"화개(華蓋)","fortuneType":"길흉혼합"},
  ///   {"jiji":"해","pillar":"월지","sinsal":"겁살(劫煞)","fortuneType":"흉"},
  /// ]
  /// ```
  final List<dynamic>? twelveSinsal;

  /// 대운 정보 (선택적)
  /// ```dart
  /// {
  ///   'start_age': 5,
  ///   'current': {'gan': '갑', 'ji': '자', 'start_year': 1995, 'end_year': 2005},
  ///   'list': [...]
  /// }
  /// ```
  final Map<String, dynamic>? daeun;

  /// 합충형파해 정보 (선택적) - 천간/지지 간 관계
  /// ```dart
  /// {
  ///   'cheongan_haps': [{'gan1': '갑', 'gan2': '기', 'pillar1': '년', 'pillar2': '월', 'description': '갑기합화토'}],
  ///   'cheongan_chungs': [...],
  ///   'jiji_yukhaps': [...],
  ///   'jiji_samhaps': [{'jijis': ['인', '오', '술'], 'pillars': ['년', '일', '시'], 'result_oheng': '화', 'is_full': true}],
  ///   'jiji_banghaps': [...],
  ///   'jiji_chungs': [...],
  ///   'jiji_hyungs': [...],
  ///   'jiji_pas': [...],
  ///   'jiji_haes': [...],
  ///   'wonjins': [...],
  /// }
  /// ```
  final Map<String, dynamic>? hapchung;

  // ─────────────────────────────────────────────────────────────────────────
  // 생성자
  // ─────────────────────────────────────────────────────────────────────────

  const SajuInputData({
    required this.profileId,
    required this.profileName,
    required this.birthDate,
    this.birthTime,
    required this.gender,
    required this.saju,
    required this.oheng,
    this.yongsin,
    this.dayStrength,
    this.sinsal,
    this.gilseong,
    this.twelveUnsung,
    this.sipsinInfo,
    this.jijangganInfo,
    this.gyeokguk,
    this.twelveSinsal,
    this.daeun,
    this.hapchung,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // JSON 직렬화
  // ─────────────────────────────────────────────────────────────────────────

  /// JSON으로 변환
  ///
  /// API 호출 및 DB 저장 시 사용됩니다.
  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'profile_name': profileName,
        'birth_date': birthDate.toIso8601String().split('T').first,
        'birth_time': birthTime,
        'gender': gender,
        'saju': saju,
        'oheng': oheng,
        if (yongsin != null) 'yongsin': yongsin,
        if (dayStrength != null) 'day_strength': dayStrength,
        if (sinsal != null) 'sinsal': sinsal,
        if (gilseong != null) 'gilseong': gilseong,
        if (twelveUnsung != null) 'twelve_unsung': twelveUnsung,
        if (sipsinInfo != null) 'sipsin_info': sipsinInfo,
        if (jijangganInfo != null) 'jijanggan_info': jijangganInfo,
        if (gyeokguk != null) 'gyeokguk': gyeokguk,
        if (twelveSinsal != null) 'twelve_sinsal': twelveSinsal,
        if (daeun != null) 'daeun': daeun,
        if (hapchung != null) 'hapchung': hapchung,
      };

  /// JSON에서 생성
  ///
  /// DB 조회 결과나 캐시된 데이터에서 복원합니다.
  factory SajuInputData.fromJson(Map<String, dynamic> json) {
    return SajuInputData(
      profileId: json['profile_id'] as String,
      profileName: json['profile_name'] as String,
      birthDate: DateTime.parse(json['birth_date'] as String),
      birthTime: json['birth_time'] as String?,
      gender: json['gender'] as String,
      saju: Map<String, String>.from(json['saju'] as Map),
      oheng: Map<String, int>.from(json['oheng'] as Map),
      yongsin: json['yongsin'] as Map<String, dynamic>?,
      dayStrength: json['day_strength'] as Map<String, dynamic>?,
      sinsal: (json['sinsal'] as List?)?.cast<Map<String, dynamic>>(),
      gilseong: (json['gilseong'] as List?)?.cast<Map<String, dynamic>>(),
      twelveUnsung: json['twelve_unsung'] as List<dynamic>?,
      sipsinInfo: json['sipsin_info'] as Map<String, dynamic>?,
      jijangganInfo: json['jijanggan_info'] as Map<String, dynamic>?,
      gyeokguk: json['gyeokguk'] as Map<String, dynamic>?,
      twelveSinsal: json['twelve_sinsal'] as List<dynamic>?,
      daeun: json['daeun'] as Map<String, dynamic>?,
      hapchung: json['hapchung'] as Map<String, dynamic>?,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 편의 Getter
  // ─────────────────────────────────────────────────────────────────────────

  /// 사주 팔자 문자열
  ///
  /// 예: "갑자 을축 병인 정묘" 또는 "갑자 을축 병인 (시주 미상)"
  String get sajuString {
    final yearGan = saju['year_gan'] ?? '';
    final yearJi = saju['year_ji'] ?? '';
    final monthGan = saju['month_gan'] ?? '';
    final monthJi = saju['month_ji'] ?? '';
    final dayGan = saju['day_gan'] ?? '';
    final dayJi = saju['day_ji'] ?? '';
    final hourGan = saju['hour_gan'] ?? '';
    final hourJi = saju['hour_ji'] ?? '';

    if (hourGan.isEmpty) {
      return '$yearGan$yearJi $monthGan$monthJi $dayGan$dayJi (시주 미상)';
    }
    return '$yearGan$yearJi $monthGan$monthJi $dayGan$dayJi $hourGan$hourJi';
  }

  /// 오행 분포 문자열
  ///
  /// 예: "목2 화1 토3 금1 수1"
  String get ohengString {
    return '목${oheng['wood'] ?? 0} 화${oheng['fire'] ?? 0} 토${oheng['earth'] ?? 0} 금${oheng['metal'] ?? 0} 수${oheng['water'] ?? 0}';
  }

  /// 일간 (일주 천간) - 나를 대표하는 오행
  ///
  /// 예: "병" (병화일간)
  String get dayMaster => saju['day_gan'] ?? '';
}
