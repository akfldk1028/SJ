/// # 궁합 분석 프롬프트 (Gemini용)
///
/// ## 개요
/// 두 사람의 사주를 비교하여 궁합을 분석하는 프롬프트입니다.
/// Gemini 모델을 사용하여 빠르고 정확한 궁합 분석을 제공합니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/prompts/compatibility_prompt.dart`
///
/// ## 분석 내용
/// - 오행 상생상극 관계
/// - 합충형해파 상호작용
/// - 용신/희신 호환성
/// - 신살 상호작용
/// - 12운성 조합 해석
/// - 관계 유형별 특화 분석 (연애/가족/사업/우정)
///
/// ## 입력 데이터
/// - 나(from_profile)의 사주 분석 데이터
/// - 상대(to_profile)의 사주 분석 데이터
/// - 관계 유형 (relation_type)
///
/// ## 캐시 정책
/// - 만료 기간: 30일 (두 사람의 사주가 변하지 않으므로)
/// - profile1_id + profile2_id 조합으로 캐시 키

import '../core/ai_constants.dart';
import 'prompt_template.dart';

/// 궁합 분석 프롬프트 (Gemini용)
class CompatibilityPrompt extends PromptTemplate {
  /// 관계 유형
  final String relationType;

  CompatibilityPrompt({required this.relationType});

  @override
  String get summaryType => SummaryType.compatibility;

  @override
  String get modelName => GoogleModels.gemini20Flash; // gemini-2.0-flash

  @override
  int get maxTokens => 4096;

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => const Duration(days: 30);

  /// 관계 유형별 분석 포커스
  String get _relationFocus {
    switch (relationType) {
      case 'family_parent':
      case 'family_child':
      case 'family_sibling':
      case 'family_spouse':
      case 'family_grandparent':
      case 'family_in_law':
      case 'family_other':
        return '''
## 가족 궁합 분석 포커스
- 가족 간 유대감과 소통 방식
- 세대 간 가치관 차이와 조화
- 가정 내 역할과 책임 분담
- 갈등 해결 패턴과 화해 방식
- 장기적인 가족 관계 유지 비결''';

      case 'romantic_partner':
      case 'romantic_crush':
      case 'romantic_ex':
        return '''
## 연애/결혼 궁합 분석 포커스
- 첫 만남의 끌림과 인연
- 연애 스타일과 애정 표현
- 감정적 교감과 정서적 안정감
- 결혼 후 생활 패턴 예측
- 자녀운과 가정 형성
- 위기 극복 능력과 장기 관계 유지''';

      case 'friend_close':
      case 'friend_general':
        return '''
## 우정 궁합 분석 포커스
- 친구로서의 케미와 공감대
- 취미/관심사 공유 가능성
- 서로에게 주는 긍정적 영향
- 신뢰와 비밀 유지 능력
- 위기 시 도움 주고받는 관계''';

      case 'work_colleague':
      case 'work_boss':
      case 'work_subordinate':
      case 'work_client':
      case 'business_partner':
        return '''
## 사업/직장 궁합 분석 포커스
- 업무 스타일 호환성
- 의사결정 방식과 리더십
- 협업 시 시너지와 갈등 요인
- 금전/재물 관계에서의 신뢰
- 장기 파트너십 가능성''';

      case 'mentor':
        return '''
## 멘토-멘티 궁합 분석 포커스
- 가르침과 배움의 조화
- 지식/경험 전수 적합성
- 상호 성장 가능성
- 존경과 신뢰 형성''';

      default:
        return '''
## 일반 궁합 분석 포커스
- 전반적인 인연의 깊이
- 상호 보완적 관계 형성 가능성
- 긍정적/부정적 영향 요인
- 관계 발전 방향 제안''';
    }
  }

  @override
  String get systemPrompt => '''
당신은 한국 전통 사주명리학 분야 30년 경력의 궁합 전문가입니다.
두 사람의 사주를 철저히 비교 분석하여 정확하고 깊이 있는 궁합 해석을 제공합니다.

## 궁합 분석 방법론 (반드시 순서대로)

### 1단계: 오행 상생상극 분석
두 사람의 일간(日干)을 중심으로 오행 관계 분석
- **상생 관계** (木→火→土→金→水): 서로 도움을 주는 좋은 관계
- **상극 관계** (木→土→水→火→金): 한쪽이 다른 쪽을 제압하는 관계
- **비화 관계** (같은 오행): 동질성으로 인한 경쟁 또는 동지 관계

### 2단계: 합충형파해 상호작용 분석

**합(合) - 결합/끌림의 에너지**
- 천간합: 두 사람의 천간이 합을 이루면 강한 끌림
  - 갑기합(土), 을경합(金), 병신합(水), 정임합(木), 무계합(火)
- 지지육합: 깊은 유대감과 정서적 연결
  - 자축합(土), 인해합(木), 묘술합(火), 진유합(金), 사신합(水), 오미합(土)
- 지지삼합: 공동의 목표와 시너지
  - 인오술(火), 해묘미(木), 사유축(金), 신자진(水)

**충(沖) - 대립/갈등의 에너지**
- 자오충, 축미충, 인신충, 묘유충, 진술충, 사해충
- 충이 있으면 초기 갈등이 있으나, 성숙하면 보완 관계로 발전 가능

**형(刑) - 상처/자극의 에너지**
- 삼형살(인사신, 축술미), 상형(자묘), 자형
- 관계에서 상처를 주고받을 수 있으나, 성장의 계기가 될 수도 있음

**파(破)/해(害) - 방해/손해의 에너지**
- 관계 유지에 어려움을 주는 요소

### 3단계: 용신 호환성 분석
- 서로의 용신이 상대방에게 어떤 영향을 주는지
- 용신이 상대의 기신이면 갈등, 희신이면 도움
- 상호 보완적 용신 관계가 이상적

### 4단계: 신살 상호작용 분석
- 도화살 + 도화살: 강한 성적 끌림 (연애에 유리)
- 역마살 + 역마살: 함께 여행/이동이 많은 관계
- 천을귀인/천덕귀인: 서로에게 귀인이 될 수 있는지
- 겁살/재살: 상대로 인한 손실 가능성

### 5단계: 12운성 조합 분석
- 장생/관대/건록/제왕: 에너지가 강한 상태 → 활발한 관계
- 쇠/병/사/묘: 에너지가 약한 상태 → 의존적 관계
- 절/태/양: 새로운 시작의 에너지 → 변화가 많은 관계

$_relationFocus

## 분석 원칙
- **균형 해석**: 좋은 점과 주의할 점을 함께 제시
- **현실적 조언**: 이상적인 관계보다 실질적인 개선 방안 제시
- **상호 존중**: 한쪽에 치우치지 않은 공정한 분석
- **긍정적 방향**: 갈등 요소도 성장의 기회로 해석

## 응답 형식
반드시 JSON 형식으로만 응답하세요. 추가 설명 없이 순수 JSON만 출력하세요.
''';

  @override
  String buildUserPrompt(Map<String, dynamic> input) {
    final data = CompatibilityInputData.fromJson(input);

    return '''
## 궁합 분석 대상

### 나 (분석 요청자)
- 이름: ${data.myName}
- 생년월일: ${data.myBirthDate}
- 성별: ${data.myGender == 'male' ? '남성' : '여성'}

#### 사주 팔자
${data.mySajuString}

#### 오행 분포
${data.myOhengString}

#### 용신 정보
${data.myYongsinString}

#### 합충형해파
${data.myHapchungString}

#### 신살
${data.mySinsalString}

#### 12운성
${data.myUnsungString}

---

### 상대방 (인연)
- 이름: ${data.targetName}
- 생년월일: ${data.targetBirthDate}
- 태어난 시간: ${data.targetBirthTime ?? '미상'}
- 성별: ${data.targetGender == 'male' ? '남성' : '여성'}
- 관계: ${_getRelationLabel(data.relationType)}

${data.hasTargetSaju ? _buildTargetExistingSajuSection(data) : _buildTargetCalculationInstructions(data)}

---

위 두 사람의 사주 정보를 바탕으로 궁합 분석을 JSON 형식으로 제공해주세요.

반드시 아래 JSON 스키마를 정확히 따라주세요:

**중요**: 상대방의 사주를 직접 계산한 경우, "target_calculated_saju" 필드에 계산 결과를 담아주세요.
상대방의 기존 사주 데이터가 있었다면 이 필드는 null로 두세요.

```json
{
  "target_calculated_saju": {
    "_comment": "상대방 사주를 직접 계산한 경우에만 채움. 기존 데이터 있으면 null",
    "saju": {
      "year": {"gan": "갑", "ji": "자"},
      "month": {"gan": "병", "ji": "인"},
      "day": {"gan": "무", "ji": "술"},
      "hour": {"gan": "계", "ji": "해"}
    },
    "oheng": {"wood": 2, "fire": 1, "earth": 2, "metal": 1, "water": 2},
    "day_master": "일간 오행 (예: 土)",
    "hapchung": {
      "cheongan_haps": ["천간합 목록"],
      "cheongan_chungs": ["천간충 목록"],
      "jiji_yukhaps": ["지지육합 목록"],
      "jiji_samhaps": ["삼합 목록"],
      "jiji_chungs": ["지지충 목록"],
      "jiji_hyungs": ["지지형 목록"],
      "jiji_pas": ["지지파 목록"],
      "jiji_haes": ["지지해 목록"]
    },
    "sinsal": [
      {"name": "신살명", "pillar": "위치", "type": "길/흉"}
    ],
    "twelve_unsung": [
      {"pillar": "년주", "unsung": "운성명"}
    ]
  },

  "overall_score": 85,
  "overall_grade": "좋음",
  "summary": "두 사람의 궁합에 대한 한 문장 핵심 요약",

  "category_scores": {
    "oheng_harmony": {
      "score": 80,
      "grade": "좋음",
      "description": "오행 상생상극 분석 결과 설명"
    },
    "hapchung_interaction": {
      "score": 75,
      "grade": "양호",
      "description": "합충형해파 상호작용 분석 결과"
    },
    "yongsin_compatibility": {
      "score": 90,
      "grade": "매우 좋음",
      "description": "용신 호환성 분석 결과"
    },
    "sinsal_synergy": {
      "score": 70,
      "grade": "보통",
      "description": "신살 상호작용 분석 결과"
    },
    "energy_balance": {
      "score": 85,
      "grade": "좋음",
      "description": "12운성 에너지 조합 분석 결과"
    }
  },

  "detailed_analysis": {
    "oheng": {
      "my_day_master": "나의 일간 오행",
      "target_day_master": "상대 일간 오행",
      "relationship": "상생/상극/비화",
      "interpretation": "오행 관계 해석"
    },
    "hapchung": {
      "haps": ["두 사람 사이의 합 관계 목록"],
      "chungs": ["두 사람 사이의 충 관계 목록"],
      "others": ["형/파/해 관계 목록"],
      "interpretation": "합충형해파 종합 해석"
    },
    "yongsin": {
      "my_yongsin_effect": "나의 용신이 상대에게 미치는 영향",
      "target_yongsin_effect": "상대의 용신이 나에게 미치는 영향",
      "synergy": "용신 시너지 효과"
    },
    "sinsal": {
      "positive_interactions": ["긍정적 신살 상호작용"],
      "negative_interactions": ["부정적 신살 상호작용"],
      "special_notes": "특이사항 (도화살 궁합 등)"
    }
  },

  "strengths": [
    "이 관계의 장점 1",
    "이 관계의 장점 2",
    "이 관계의 장점 3"
  ],

  "challenges": [
    "이 관계에서 주의할 점 1",
    "이 관계에서 주의할 점 2"
  ],

  "advice": {
    "for_requester": "나에게 드리는 조언",
    "for_target": "상대방에게 드리는 조언",
    "together": "두 사람이 함께 노력할 점"
  },

  "destiny_keywords": ["인연", "키워드", "3-5개"],

  "best_activities": [
    "함께 하면 좋은 활동 1",
    "함께 하면 좋은 활동 2"
  ],

  "caution_periods": "갈등이 생기기 쉬운 시기/상황"
}
```

**점수 기준:**
- 90-100: 천생연분/최고의 궁합
- 80-89: 매우 좋은 궁합
- 70-79: 좋은 궁합
- 60-69: 보통 궁합
- 50-59: 노력이 필요한 궁합
- 50 미만: 어려운 궁합 (개선 방안 제시 필요)
''';
  }

  /// 상대방(인연) 기존 사주 정보 섹션 (사주가 있는 경우)
  String _buildTargetExistingSajuSection(CompatibilityInputData data) {
    return '''
#### 사주 팔자
${data.targetSajuString}

#### 오행 분포
${data.targetOhengString}

#### 용신 정보
${data.targetYongsinString}

#### 합충형해파
${data.targetHapchungString}

#### 신살
${data.targetSinsalString}

#### 12운성
${data.targetUnsungString}''';
  }

  /// 상대방(인연) 사주 계산 지시 (사주가 없는 경우 - Gemini가 직접 계산)
  String _buildTargetCalculationInstructions(CompatibilityInputData data) {
    // v3.7.1 (Phase 47 Fix): 음력/양력 정보 명시
    final calendarType = data.targetIsLunar ? '음력 (陰曆)' : '양력 (陽曆)';
    final leapMonthInfo = data.targetIsLeapMonth ? ' [윤달]' : '';

    // 음력인 경우 양력 변환 주의사항 추가
    final lunarConversionNote = data.targetIsLunar
        ? '''

🚨 **중요: 음력 → 양력 변환 필수** 🚨
입력된 생년월일 **${data.targetBirthDate}는 음력 날짜**입니다.
${data.targetIsLeapMonth ? '⚠️ 윤달(閏月)입니다. 윤달 여부를 반드시 고려하세요.' : ''}

**반드시 다음 순서로 계산하세요:**
1. 음력 ${data.targetBirthDate}${leapMonthInfo}를 양력으로 변환
2. 변환된 양력 날짜로 만세력 사주팔자 계산
3. 입춘(立春) 기준으로 년월 구분

**예시**: 음력 1994-11-28 → 양력 1994-12-30
(실제 변환 결과는 만세력 표를 참고하세요)'''
        : '';

    return '''
#### ⭐ 상대방 사주 직접 계산 지시 ⭐

**중요**: 상대방의 사주 분석 데이터가 없습니다.
아래 생년월일/시간 정보를 바탕으로 **당신이 직접 만세력 사주팔자를 계산**해주세요.

**계산 대상 정보**:
- 생년월일: ${data.targetBirthDate}
- **달력 종류: $calendarType$leapMonthInfo**
- 태어난 시간: ${data.targetBirthTime ?? '미상 (시주 생략 가능)'}
- 성별: ${data.targetGender == 'male' ? '남성' : '여성'}
$lunarConversionNote

**필수 계산 항목**:
1. **사주팔자 (四柱八字)**:
   - 년주(年柱): 년간 + 년지
   - 월주(月柱): 월간 + 월지
   - 일주(日柱): 일간 + 일지
   - 시주(時柱): 시간 + 시지 (시간 미상이면 생략)

2. **오행 분포 (五行分布)**:
   - 사주 8자 중 목(木), 화(火), 토(土), 금(金), 수(水) 각각 개수

3. **합충형해파 분석**:
   - 천간합/충
   - 지지육합/삼합/방합
   - 지지충/형/파/해

4. **주요 신살 (神殺)**:
   - 도화살, 역마살, 천을귀인, 문창귀인 등 주요 신살만 확인

5. **12운성 (十二運星)**:
   - 각 지지에서 일간의 12운성 상태

**계산 시 주의사항**:
- 만세력 계산법 사용 (대한민국 표준시 기준)
- 입춘(立春) 기준 년월 구분
- 자시(子時) 구분: 23:00~00:59
${data.targetIsLunar ? '- **⚠️ 음력 날짜를 반드시 양력으로 변환 후 계산**' : ''}

계산 결과는 응답 JSON의 "target_calculated_saju" 필드에 담아주세요.''';
  }

  /// 관계 유형 라벨
  String _getRelationLabel(String relationType) {
    const labels = {
      'family_parent': '부모님',
      'family_child': '자녀',
      'family_sibling': '형제자매',
      'family_spouse': '배우자',
      'family_grandparent': '조부모님',
      'family_in_law': '인척',
      'family_other': '기타 가족',
      'romantic_partner': '연인',
      'romantic_crush': '짝사랑 상대',
      'romantic_ex': '전 연인',
      'friend_close': '절친한 친구',
      'friend_general': '친구',
      'work_colleague': '직장 동료',
      'work_boss': '상사',
      'work_subordinate': '부하직원',
      'work_client': '거래처/고객',
      'business_partner': '사업 파트너',
      'mentor': '멘토',
      'other': '기타',
    };
    return labels[relationType] ?? '기타';
  }
}

// =============================================================================
// 궁합 입력 데이터 클래스
// =============================================================================

/// 궁합 분석용 입력 데이터
class CompatibilityInputData {
  // 나(분석 요청자) 정보
  final String myProfileId;
  final String myName;
  final String myBirthDate;
  final String myGender;
  final Map<String, dynamic>? mySaju;
  final Map<String, dynamic>? myOheng;
  final Map<String, dynamic>? myYongsin;
  final Map<String, dynamic>? myHapchung;
  final List<dynamic>? mySinsal;
  final List<dynamic>? myUnsung;

  // 상대방 정보
  final String targetProfileId;
  final String targetName;
  final String targetBirthDate;
  final String? targetBirthTime; // 태어난 시간 (HH:mm 또는 null)
  final String targetGender;
  // v3.7.1 (Phase 47 Fix): 음력/양력 정보 추가
  final bool targetIsLunar; // 음력 여부
  final bool targetIsLeapMonth; // 윤달 여부
  final Map<String, dynamic>? targetSaju;
  final Map<String, dynamic>? targetOheng;
  final Map<String, dynamic>? targetYongsin;
  final Map<String, dynamic>? targetHapchung;
  final List<dynamic>? targetSinsal;
  final List<dynamic>? targetUnsung;

  // 관계 정보
  final String relationType;

  CompatibilityInputData({
    required this.myProfileId,
    required this.myName,
    required this.myBirthDate,
    required this.myGender,
    this.mySaju,
    this.myOheng,
    this.myYongsin,
    this.myHapchung,
    this.mySinsal,
    this.myUnsung,
    required this.targetProfileId,
    required this.targetName,
    required this.targetBirthDate,
    this.targetBirthTime,
    required this.targetGender,
    this.targetIsLunar = false, // v3.7.1: 기본값 양력
    this.targetIsLeapMonth = false, // v3.7.1: 기본값 윤달 아님
    this.targetSaju,
    this.targetOheng,
    this.targetYongsin,
    this.targetHapchung,
    this.targetSinsal,
    this.targetUnsung,
    required this.relationType,
  });

  /// 상대방(인연)의 사주 데이터가 있는지 확인
  /// - GPT가 분석한 사주가 있으면 true
  /// - 없으면 Gemini가 직접 계산해야 함
  bool get hasTargetSaju => targetSaju != null && targetSaju!.isNotEmpty;

  factory CompatibilityInputData.fromJson(Map<String, dynamic> json) {
    return CompatibilityInputData(
      myProfileId: json['my_profile_id'] ?? '',
      myName: json['my_name'] ?? '나',
      myBirthDate: json['my_birth_date'] ?? '',
      myGender: json['my_gender'] ?? 'male',
      mySaju: json['my_saju'] as Map<String, dynamic>?,
      myOheng: json['my_oheng'] as Map<String, dynamic>?,
      myYongsin: json['my_yongsin'] as Map<String, dynamic>?,
      myHapchung: json['my_hapchung'] as Map<String, dynamic>?,
      mySinsal: json['my_sinsal'] as List<dynamic>?,
      myUnsung: json['my_unsung'] as List<dynamic>?,
      targetProfileId: json['target_profile_id'] ?? '',
      targetName: json['target_name'] ?? '상대방',
      targetBirthDate: json['target_birth_date'] ?? '',
      targetBirthTime: json['target_birth_time'] as String?,
      targetGender: json['target_gender'] ?? 'male',
      // v3.7.1 (Phase 47 Fix): 음력/양력 정보
      targetIsLunar: json['target_is_lunar'] as bool? ?? false,
      targetIsLeapMonth: json['target_is_leap_month'] as bool? ?? false,
      targetSaju: json['target_saju'] as Map<String, dynamic>?,
      targetOheng: json['target_oheng'] as Map<String, dynamic>?,
      targetYongsin: json['target_yongsin'] as Map<String, dynamic>?,
      targetHapchung: json['target_hapchung'] as Map<String, dynamic>?,
      targetSinsal: json['target_sinsal'] as List<dynamic>?,
      targetUnsung: json['target_unsung'] as List<dynamic>?,
      relationType: json['relation_type'] ?? 'other',
    );
  }

  Map<String, dynamic> toJson() => {
        'my_profile_id': myProfileId,
        'my_name': myName,
        'my_birth_date': myBirthDate,
        'my_gender': myGender,
        'my_saju': mySaju,
        'my_oheng': myOheng,
        'my_yongsin': myYongsin,
        'my_hapchung': myHapchung,
        'my_sinsal': mySinsal,
        'my_unsung': myUnsung,
        'target_profile_id': targetProfileId,
        'target_name': targetName,
        'target_birth_date': targetBirthDate,
        'target_birth_time': targetBirthTime,
        'target_gender': targetGender,
        // v3.7.1 (Phase 47 Fix): 음력/양력 정보
        'target_is_lunar': targetIsLunar,
        'target_is_leap_month': targetIsLeapMonth,
        'target_saju': targetSaju,
        'target_oheng': targetOheng,
        'target_yongsin': targetYongsin,
        'target_hapchung': targetHapchung,
        'target_sinsal': targetSinsal,
        'target_unsung': targetUnsung,
        'relation_type': relationType,
      };

  // ─────────────────────────────────────────────────────────────────────────
  // 문자열 변환 헬퍼 (프롬프트용)
  // ─────────────────────────────────────────────────────────────────────────

  String get mySajuString => _formatSaju(mySaju);
  String get targetSajuString => _formatSaju(targetSaju);

  String get myOhengString => _formatOheng(myOheng);
  String get targetOhengString => _formatOheng(targetOheng);

  String get myYongsinString => _formatYongsin(myYongsin);
  String get targetYongsinString => _formatYongsin(targetYongsin);

  String get myHapchungString => _formatHapchung(myHapchung);
  String get targetHapchungString => _formatHapchung(targetHapchung);

  String get mySinsalString => _formatSinsal(mySinsal);
  String get targetSinsalString => _formatSinsal(targetSinsal);

  String get myUnsungString => _formatUnsung(myUnsung);
  String get targetUnsungString => _formatUnsung(targetUnsung);

  String _formatSaju(Map<String, dynamic>? saju) {
    if (saju == null) return '(사주 정보 없음)';

    final year = '${saju['year_gan'] ?? '?'}${saju['year_ji'] ?? '?'}';
    final month = '${saju['month_gan'] ?? '?'}${saju['month_ji'] ?? '?'}';
    final day = '${saju['day_gan'] ?? '?'}${saju['day_ji'] ?? '?'}';
    final hour = saju['hour_gan'] != null && saju['hour_ji'] != null
        ? '${saju['hour_gan']}${saju['hour_ji']}'
        : '(시주 미상)';

    return '''
| 년주 | 월주 | 일주 | 시주 |
|------|------|------|------|
| $year | $month | $day | $hour |''';
  }

  String _formatOheng(Map<String, dynamic>? oheng) {
    if (oheng == null) return '(오행 정보 없음)';

    return '''
- 목(木): ${oheng['wood'] ?? 0}개
- 화(火): ${oheng['fire'] ?? 0}개
- 토(土): ${oheng['earth'] ?? 0}개
- 금(金): ${oheng['metal'] ?? 0}개
- 수(水): ${oheng['water'] ?? 0}개''';
  }

  String _formatYongsin(Map<String, dynamic>? yongsin) {
    if (yongsin == null) return '(용신 정보 없음)';

    return '''
- 용신: ${yongsin['yongsin'] ?? '미정'}
- 희신: ${yongsin['heesin'] ?? yongsin['huisin'] ?? '미정'}
- 기신: ${yongsin['gisin'] ?? '미정'}
- 구신: ${yongsin['gusin'] ?? '미정'}
- 한신: ${yongsin['hansin'] ?? '미정'}
- 분석법: ${yongsin['method'] ?? '미정'}''';
  }

  String _formatHapchung(Map<String, dynamic>? hapchung) {
    if (hapchung == null) return '(합충형해파 정보 없음)';

    final buffer = StringBuffer();

    // 천간합
    final cheonganHaps = hapchung['cheongan_haps'] as List?;
    if (cheonganHaps != null && cheonganHaps.isNotEmpty) {
      buffer.writeln('**천간합:**');
      for (final hap in cheonganHaps) {
        buffer.writeln('- ${hap['description'] ?? hap}');
      }
    }

    // 천간충
    final cheonganChungs = hapchung['cheongan_chungs'] as List?;
    if (cheonganChungs != null && cheonganChungs.isNotEmpty) {
      buffer.writeln('**천간충:**');
      for (final chung in cheonganChungs) {
        buffer.writeln('- ${chung['description'] ?? chung}');
      }
    }

    // 지지육합
    final jijiYukhaps = hapchung['jiji_yukhaps'] as List?;
    if (jijiYukhaps != null && jijiYukhaps.isNotEmpty) {
      buffer.writeln('**지지육합:**');
      for (final hap in jijiYukhaps) {
        buffer.writeln('- ${hap['description'] ?? hap}');
      }
    }

    // 지지삼합
    final jijiSamhaps = hapchung['jiji_samhaps'] as List?;
    if (jijiSamhaps != null && jijiSamhaps.isNotEmpty) {
      buffer.writeln('**지지삼합:**');
      for (final hap in jijiSamhaps) {
        buffer.writeln('- ${hap['description'] ?? hap}');
      }
    }

    // 지지방합
    final jijiBanghaps = hapchung['jiji_banghaps'] as List?;
    if (jijiBanghaps != null && jijiBanghaps.isNotEmpty) {
      buffer.writeln('**지지방합:**');
      for (final hap in jijiBanghaps) {
        buffer.writeln('- ${hap['description'] ?? hap}');
      }
    }

    // 지지충
    final jijiChungs = hapchung['jiji_chungs'] as List?;
    if (jijiChungs != null && jijiChungs.isNotEmpty) {
      buffer.writeln('**지지충:**');
      for (final chung in jijiChungs) {
        buffer.writeln('- ${chung['description'] ?? chung}');
      }
    }

    // 지지형
    final jijiHyungs = hapchung['jiji_hyungs'] as List?;
    if (jijiHyungs != null && jijiHyungs.isNotEmpty) {
      buffer.writeln('**지지형:**');
      for (final hyung in jijiHyungs) {
        buffer.writeln('- ${hyung['description'] ?? hyung}');
      }
    }

    // 지지파
    final jijiPas = hapchung['jiji_pas'] as List?;
    if (jijiPas != null && jijiPas.isNotEmpty) {
      buffer.writeln('**지지파:**');
      for (final pa in jijiPas) {
        buffer.writeln('- ${pa['description'] ?? pa}');
      }
    }

    // 지지해
    final jijiHaes = hapchung['jiji_haes'] as List?;
    if (jijiHaes != null && jijiHaes.isNotEmpty) {
      buffer.writeln('**지지해:**');
      for (final hae in jijiHaes) {
        buffer.writeln('- ${hae['description'] ?? hae}');
      }
    }

    // 원진
    final wonjins = hapchung['wonjins'] as List?;
    if (wonjins != null && wonjins.isNotEmpty) {
      buffer.writeln('**원진:**');
      for (final wonjin in wonjins) {
        buffer.writeln('- ${wonjin['description'] ?? wonjin}');
      }
    }

    return buffer.isEmpty ? '(합충형해파 없음)' : buffer.toString();
  }

  String _formatSinsal(List<dynamic>? sinsal) {
    if (sinsal == null || sinsal.isEmpty) return '(신살 정보 없음)';

    final buffer = StringBuffer();
    for (final item in sinsal) {
      if (item is Map) {
        final name = item['name'] ?? '미상';
        final type = item['type'] ?? '';
        final location = item['location'] ?? '';
        buffer.writeln('- $name ($type) - $location');
      } else {
        buffer.writeln('- $item');
      }
    }
    return buffer.toString();
  }

  String _formatUnsung(List<dynamic>? unsung) {
    if (unsung == null || unsung.isEmpty) return '(12운성 정보 없음)';

    final buffer = StringBuffer();
    for (final item in unsung) {
      if (item is Map) {
        final pillar = item['pillar'] ?? '';
        final unsungName = item['unsung'] ?? '';
        final strength = item['strength'] ?? 0;
        buffer.writeln('- $pillar: $unsungName (강도: $strength)');
      } else {
        buffer.writeln('- $item');
      }
    }
    return buffer.toString();
  }
}
