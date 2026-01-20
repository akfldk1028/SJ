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

### 2단계: 합충형해파원진 상호작용 분석

⚠️ **중요**: pair_hapchung 데이터가 제공되면 반드시 우선 참조하세요!
이 데이터는 두 사람 사주 간의 직접적인 합충 관계를 미리 계산한 것입니다.

**합(合) - 결합/끌림의 에너지**

1. **육합(六合)** - 가장 중요! (특히 연애/결혼 궁합)
   - 자축합(子丑·土): 안정적인 유대, 신뢰 관계
   - 인해합(寅亥·木): 성장과 발전, 서로 도움
   - 묘술합(卯戌·火): 열정적 끌림, 감정적 교감
   - 진유합(辰酉·金): 실질적 협력, 현실적 파트너
   - 사신합(巳申·水): 지적 교감, 대화가 잘 통함
   - 오미합(午未·土): 따뜻한 정서, 편안한 관계

2. **삼합(三合)** - 팀워크/협업에 유리
   - 인오술(寅午戌·火): 열정과 추진력 공유
   - 해묘미(亥卯未·木): 창의성과 성장 지향
   - 사유축(巳酉丑·金): 계획성과 실행력
   - 신자진(申子辰·水): 지혜와 유연한 대응

3. **반합(半合)** - 삼합의 부분 결합, 강도 차등화 필요!
   **강반합 (생지+왕지, 70-80% 효과)**:
   - 해묘(亥卯), 인오(寅午), 사유(巳酉), 신자(申子)
   **약반합 (왕지+고지, 40-50% 효과)**:
   - 묘미(卯未), 오술(午戌), 유축(酉丑), 자진(子辰)

4. **방합(方合)** - 같은 방향의 결속
   - 인묘진(寅卯辰·東方木): 동방 목국
   - 사오미(巳午未·南方火): 남방 화국
   - 신유술(申酉戌·西方金): 서방 금국
   - 해자축(亥子丑·北方水): 북방 수국
   → 완전 방합은 드물고 2개 조합(부분 방합)이 일반적

5. **천간합** - 두 사람의 천간이 합을 이루면 강한 끌림
   - 갑기합(甲己·土), 을경합(乙庚·金), 병신합(丙辛·水)
   - 정임합(丁壬·木), 무계합(戊癸·火)

**충(沖) - 대립/갈등의 에너지 (가장 강함)**
- 자오충(子午), 축미충(丑未), 인신충(寅申)
- 묘유충(卯酉), 진술충(辰戌), 사해충(巳亥)
- ⚠️ 충이 있다고 무조건 나쁜 것 아님!
- 성숙하면 상호 보완 관계로 발전 가능
- 긴장감이 관계에 활력을 줄 수 있음

**형(刑) - 상처/자극의 에너지**
- 삼형살: 인사신(寅巳申·무은지형), 축술미(丑戌未·무례지형)
- 자형살: 진진(辰辰), 오오(午午), 유유(酉酉), 해해(亥亥)
- 상형: 자묘(子卯·무례지형)
- 관계에서 상처를 주고받을 수 있으나, 성장의 계기가 될 수도 있음

**파(破) - 관계 파괴의 에너지**
- 자유파, 축진파, 인해파, 묘오파, 사신파, 술미파
- 합과 함께 있으면 합을 깨뜨리는 역할

**해(害) - 은밀한 해침의 에너지**
- 자미해, 축오해, 인사해, 묘진해, 신해해, 유술해
- 눈에 보이지 않는 손해, 시기와 질투

**원진(怨嗔) - 원망/질투 관계** ⚠️ 궁합에서 중요!
- 자미(子未), 축오(丑午), 인유(寅酉)
- 묘신(卯申), 진해(辰亥), 사술(巳戌)
- 서로 미워하면서도 끌리는 복잡한 관계
- 연애 궁합에서 특히 주의 필요

**해석 우선순위**:
- 합: 육합 > 삼합 > 방합 > 반합 > 천간합
- 충/형/해/파/원진: 충 > 형 > 원진 > 해 > 파

**관계 유형별 가중치**:
- 연애/결혼: 육합(×2.0), 원진(×1.5), 도화살 상호작용(×1.5)
- 친구/동료: 삼합/방합(×1.5), 충(×0.8, 덜 치명적)
- 가족: 형(×1.2), 해(×1.2, 가족 간 갈등)

**중복 처리 원칙**:
- 삼합이 있으면 해당 반합 개별 언급 생략 (예: 인오술 삼합 → 인오 반합 생략)
- 육합이 여러 개면 개별적으로 모두 분석
- hap과 banhap 중복 시 banhap 기준으로 통합 (더 상세함)

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

### 🔗 두 사람 간 합충형해파원진 분석 (pair_hapchung)
${data.pairHapchungString}

---

### 상대방 (인연)
- 이름: ${data.targetName}
- 생년월일: ${data.targetBirthDate}
- 태어난 시간: ${data.targetBirthTime ?? '미상'}
- 성별: ${data.targetGender == 'male' ? '남성' : '여성'}
- 관계: ${_getRelationLabel(data.relationType)}

${_buildTargetExistingSajuSection(data)}

---

위 두 사람의 사주 정보를 바탕으로 궁합 분석을 JSON 형식으로 제공해주세요.

반드시 아래 JSON 스키마를 정확히 따라주세요:

```json
{
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
// 궁합 입력 데이터 클래스 (v4.0 리팩토링)
// =============================================================================
// ⚡ 변경사항:
// - 42개 필드 → 15개 필드로 간소화
// - saju_analyses 테이블의 row를 직접 사용 (myAnalysis, targetAnalysis)
// - 불필요한 개별 필드 제거 (mySaju, myOheng... → myAnalysis 하나로 통합)
// =============================================================================

/// 궁합 분석용 입력 데이터 (v4.0)
///
/// ## 사용법
/// ```dart
/// // Supabase에서 saju_analyses row 조회
/// final myRow = await supabase
///     .from('saju_analyses')
///     .select()
///     .eq('profile_id', myProfileId)
///     .single();
///
/// // CompatibilityInputData에 전달
/// final inputData = CompatibilityInputData(
///   myProfileId: myProfileId,
///   myName: '이지나',
///   myBirthDate: '1999-07-27',
///   myGender: 'female',
///   myAnalysis: myRow,  // 👈 전체 row 전달!
///   ...
/// );
/// ```
class CompatibilityInputData {
  // ──────────────────────────────────────────────────────────────────────────
  // 나(분석 요청자) 정보
  // ──────────────────────────────────────────────────────────────────────────
  final String myProfileId;
  final String myName;
  final String myBirthDate;
  final String myGender;

  /// saju_analyses 테이블의 전체 row (JSONB 컬럼 포함)
  /// - year_gan, year_ji, month_gan, month_ji, day_gan, day_ji, hour_gan, hour_ji
  /// - oheng_distribution (JSONB)
  /// - yongsin (JSONB)
  /// - hapchung (JSONB)
  /// - sinsal_list (JSONB)
  /// - twelve_unsung (JSONB)
  final Map<String, dynamic>? myAnalysis;

  // ──────────────────────────────────────────────────────────────────────────
  // 상대방(인연) 정보
  // ──────────────────────────────────────────────────────────────────────────
  final String targetProfileId;
  final String targetName;
  final String targetBirthDate;
  final String? targetBirthTime;
  final String targetGender;
  final bool targetIsLunar;
  final bool targetIsLeapMonth;

  /// saju_analyses 테이블의 전체 row (상대방)
  /// - null이면 Gemini가 직접 사주 계산
  final Map<String, dynamic>? targetAnalysis;

  // ──────────────────────────────────────────────────────────────────────────
  // 관계 정보
  // ──────────────────────────────────────────────────────────────────────────
  final String relationType;

  // ──────────────────────────────────────────────────────────────────────────
  // 두 사람 간 합충형해파원진 (pair_hapchung from compatibility_analyses)
  // ──────────────────────────────────────────────────────────────────────────
  /// 두 사람 사주 간 직접적인 합충 관계 (Supabase compatibility_analyses.pair_hapchung)
  /// 구조:
  /// - hap, samhap, banhap, yukhap, banghap, cheongan_hap (긍정)
  /// - chung, hyung, pa, hae, wonjin (부정)
  /// - overall_score, positive_count, negative_count
  final Map<String, dynamic>? pairHapchung;

  CompatibilityInputData({
    required this.myProfileId,
    required this.myName,
    required this.myBirthDate,
    required this.myGender,
    this.myAnalysis,
    required this.targetProfileId,
    required this.targetName,
    required this.targetBirthDate,
    this.targetBirthTime,
    required this.targetGender,
    this.targetIsLunar = false,
    this.targetIsLeapMonth = false,
    this.targetAnalysis,
    required this.relationType,
    this.pairHapchung,
  });

  /// 상대방 사주 데이터 존재 여부
  bool get hasTargetSaju => targetAnalysis != null && targetAnalysis!.isNotEmpty;

  // ──────────────────────────────────────────────────────────────────────────
  // JSON 변환
  // ──────────────────────────────────────────────────────────────────────────
  factory CompatibilityInputData.fromJson(Map<String, dynamic> json) {
    return CompatibilityInputData(
      myProfileId: json['my_profile_id'] ?? '',
      myName: json['my_name'] ?? '나',
      myBirthDate: json['my_birth_date'] ?? '',
      myGender: json['my_gender'] ?? 'male',
      myAnalysis: json['my_analysis'] as Map<String, dynamic>?,
      targetProfileId: json['target_profile_id'] ?? '',
      targetName: json['target_name'] ?? '상대방',
      targetBirthDate: json['target_birth_date'] ?? '',
      targetBirthTime: json['target_birth_time'] as String?,
      targetGender: json['target_gender'] ?? 'male',
      targetIsLunar: json['target_is_lunar'] as bool? ?? false,
      targetIsLeapMonth: json['target_is_leap_month'] as bool? ?? false,
      targetAnalysis: json['target_analysis'] as Map<String, dynamic>?,
      relationType: json['relation_type'] ?? 'other',
      pairHapchung: json['pair_hapchung'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'my_profile_id': myProfileId,
        'my_name': myName,
        'my_birth_date': myBirthDate,
        'my_gender': myGender,
        'my_analysis': myAnalysis,
        'target_profile_id': targetProfileId,
        'target_name': targetName,
        'target_birth_date': targetBirthDate,
        'target_birth_time': targetBirthTime,
        'target_gender': targetGender,
        'target_is_lunar': targetIsLunar,
        'target_is_leap_month': targetIsLeapMonth,
        'target_analysis': targetAnalysis,
        'relation_type': relationType,
        'pair_hapchung': pairHapchung,
      };

  // ──────────────────────────────────────────────────────────────────────────
  // 프롬프트용 문자열 변환 (간소화)
  // ──────────────────────────────────────────────────────────────────────────

  // 사주 팔자 문자열
  String get mySajuString => _formatSaju(myAnalysis);
  String get targetSajuString => _formatSaju(targetAnalysis);

  // 오행 분포 문자열
  String get myOhengString => _formatOheng(myAnalysis?['oheng_distribution']);
  String get targetOhengString => _formatOheng(targetAnalysis?['oheng_distribution']);

  // 용신 정보 문자열
  String get myYongsinString => _formatYongsin(myAnalysis?['yongsin']);
  String get targetYongsinString => _formatYongsin(targetAnalysis?['yongsin']);

  // 합충형해파 문자열
  String get myHapchungString => _formatHapchung(myAnalysis?['hapchung']);
  String get targetHapchungString => _formatHapchung(targetAnalysis?['hapchung']);

  // 신살 문자열
  String get mySinsalString => _formatSinsal(myAnalysis?['sinsal_list']);
  String get targetSinsalString => _formatSinsal(targetAnalysis?['sinsal_list']);

  // 12운성 문자열
  String get myUnsungString => _formatUnsung(myAnalysis?['twelve_unsung']);
  String get targetUnsungString => _formatUnsung(targetAnalysis?['twelve_unsung']);

  // 두 사람 간 합충형해파원진 문자열 (pair_hapchung)
  String get pairHapchungString => _formatPairHapchung(pairHapchung);

  // ──────────────────────────────────────────────────────────────────────────
  // 포맷 헬퍼 (간소화)
  // ──────────────────────────────────────────────────────────────────────────

  /// 사주 팔자 포맷 (saju_analyses row에서 직접 추출)
  String _formatSaju(Map<String, dynamic>? analysis) {
    if (analysis == null) return '(사주 정보 없음)';

    final year = '${analysis['year_gan'] ?? '?'}${analysis['year_ji'] ?? '?'}';
    final month = '${analysis['month_gan'] ?? '?'}${analysis['month_ji'] ?? '?'}';
    final day = '${analysis['day_gan'] ?? '?'}${analysis['day_ji'] ?? '?'}';
    final hour = analysis['hour_gan'] != null && analysis['hour_ji'] != null
        ? '${analysis['hour_gan']}${analysis['hour_ji']}'
        : '(시주 미상)';

    return '''
| 년주 | 월주 | 일주 | 시주 |
|------|------|------|------|
| $year | $month | $day | $hour |''';
  }

  /// 오행 분포 포맷
  String _formatOheng(dynamic oheng) {
    if (oheng == null) return '(오행 정보 없음)';
    final o = oheng as Map<String, dynamic>;
    return '목${o['wood'] ?? 0} 화${o['fire'] ?? 0} 토${o['earth'] ?? 0} 금${o['metal'] ?? 0} 수${o['water'] ?? 0}';
  }

  /// 용신 정보 포맷
  String _formatYongsin(dynamic yongsin) {
    if (yongsin == null) return '(용신 정보 없음)';
    final y = yongsin as Map<String, dynamic>;
    return '용신: ${y['yongsin'] ?? '?'} / 희신: ${y['heesin'] ?? y['huisin'] ?? '?'} / 기신: ${y['gisin'] ?? '?'}';
  }

  /// 합충형해파 포맷 (간소화 - JSONB 구조 그대로 활용)
  String _formatHapchung(dynamic hapchung) {
    if (hapchung == null) return '(합충 정보 없음)';
    final h = hapchung as Map<String, dynamic>;
    final parts = <String>[];

    // 각 항목이 있으면 추가 (간단한 리스트 형식)
    void addIfNotEmpty(String label, dynamic list) {
      if (list is List && list.isNotEmpty) {
        final items = list.map((e) => e is Map ? (e['description'] ?? e.toString()) : e.toString()).join(', ');
        parts.add('$label: $items');
      }
    }

    addIfNotEmpty('천간합', h['cheongan_haps']);
    addIfNotEmpty('천간충', h['cheongan_chungs']);
    addIfNotEmpty('지지육합', h['jiji_yukhaps']);
    addIfNotEmpty('지지삼합', h['jiji_samhaps']);
    addIfNotEmpty('지지충', h['jiji_chungs']);
    addIfNotEmpty('지지형', h['jiji_hyungs']);
    addIfNotEmpty('지지파', h['jiji_pas']);
    addIfNotEmpty('지지해', h['jiji_haes']);

    return parts.isEmpty ? '(합충 없음)' : parts.join('\n');
  }

  /// 신살 포맷
  String _formatSinsal(dynamic sinsal) {
    if (sinsal == null) return '(신살 정보 없음)';
    final list = sinsal as List;
    if (list.isEmpty) return '(신살 없음)';

    return list.map((e) {
      if (e is Map) {
        return '${e['name'] ?? '?'}(${e['type'] ?? ''})';
      }
      return e.toString();
    }).join(', ');
  }

  /// 12운성 포맷
  String _formatUnsung(dynamic unsung) {
    if (unsung == null) return '(12운성 정보 없음)';
    final list = unsung as List;
    if (list.isEmpty) return '(12운성 없음)';

    return list.map((e) {
      if (e is Map) {
        return '${e['pillar'] ?? '?'}: ${e['unsung'] ?? '?'}';
      }
      return e.toString();
    }).join(', ');
  }

  /// 두 사람 간 합충형해파원진 포맷 (pair_hapchung from compatibility_analyses)
  /// Supabase pair_hapchung JSONB 구조:
  /// - hap, samhap, banhap, yukhap, banghap, cheongan_hap (긍정)
  /// - chung, hyung, pa, hae, wonjin (부정)
  /// - overall_score, positive_count, negative_count
  String _formatPairHapchung(Map<String, dynamic>? pairHapchung) {
    if (pairHapchung == null || pairHapchung.isEmpty) {
      return '(두 사람 간 합충 분석 데이터 없음 - 직접 분석 필요)';
    }

    final parts = <String>[];

    // 점수 요약
    final overallScore = pairHapchung['overall_score'] ?? 0;
    final positiveCount = pairHapchung['positive_count'] ?? 0;
    final negativeCount = pairHapchung['negative_count'] ?? 0;

    parts.add('**분석 요약**: 기본 점수 $overallScore점 (긍정 $positiveCount개 / 부정 $negativeCount개)');
    parts.add('');

    // 긍정적 요소 (합)
    final positiveSection = <String>[];

    void addPositiveIfNotEmpty(String label, String emoji, dynamic list) {
      if (list is List && list.isNotEmpty) {
        positiveSection.add('$emoji **$label**: ${list.join(', ')}');
      }
    }

    addPositiveIfNotEmpty('육합', '💕', pairHapchung['yukhap']);
    addPositiveIfNotEmpty('삼합', '🔺', pairHapchung['samhap']);
    addPositiveIfNotEmpty('반합', '◐', pairHapchung['banhap']);
    addPositiveIfNotEmpty('방합', '🧭', pairHapchung['banghap']);
    addPositiveIfNotEmpty('천간합', '☯️', pairHapchung['cheongan_hap']);
    // hap 필드는 종합이므로 위 개별 항목과 중복될 수 있어 생략

    if (positiveSection.isNotEmpty) {
      parts.add('**[긍정적 관계 - 합(合)]**');
      parts.addAll(positiveSection);
      parts.add('');
    }

    // 부정적 요소 (충형파해원진)
    final negativeSection = <String>[];

    void addNegativeIfNotEmpty(String label, String emoji, dynamic list) {
      if (list is List && list.isNotEmpty) {
        negativeSection.add('$emoji **$label**: ${list.join(', ')}');
      }
    }

    addNegativeIfNotEmpty('충', '⚡', pairHapchung['chung']);
    addNegativeIfNotEmpty('형', '🔥', pairHapchung['hyung']);
    addNegativeIfNotEmpty('파', '💔', pairHapchung['pa']);
    addNegativeIfNotEmpty('해', '🌀', pairHapchung['hae']);
    addNegativeIfNotEmpty('원진', '😤', pairHapchung['wonjin']);

    if (negativeSection.isNotEmpty) {
      parts.add('**[부정적 관계 - 충형파해원진]**');
      parts.addAll(negativeSection);
      parts.add('');
    }

    // 아무것도 없으면
    if (positiveSection.isEmpty && negativeSection.isEmpty) {
      parts.add('(특별한 합충 관계 없음 - 평범한 관계)');
    }

    return parts.join('\n');
  }
}
