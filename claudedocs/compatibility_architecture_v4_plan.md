# 궁합 분석 아키텍처 v4.0 구현 계획

## 개요

### 현재 문제점
1. **Gemini 속도 저하**: 궁합 분석 시 Gemini가 인연의 사주를 계산 + 궁합 분석까지 하면서 느림
2. **정확도 문제**: Gemini가 계산한 사주/궁합이 부정확함
3. **데이터 불일치**: 나의 사주는 `saju_analyses`에 저장, 인연 사주는 `compatibility_analyses`에 저장

### 새 아키텍처
```
[인연 추가 Flow - 변경]
UI 입력 → saju_profiles 저장 → GPT-5.2 사주 계산 → saju_analyses 저장
                                    ↓
                              (나와 동일한 로직)

[궁합 분석 Flow - 변경]
궁합 채팅 시작 → 두 프로필의 saju_analyses 조회 → Dart 궁합 계산 → compatibility_analyses 저장
                                                      ↓
                                              (Gemini 제거, Dart 로직)
```

---

## 구현 단계

### Step 1: 인연 프로필 저장 시 GPT 사주 계산 트리거

**파일**: `frontend/lib/features/profile/presentation/screens/relationship_add_screen.dart`

**변경 내용**:
```dart
// _saveRelationship() 메서드에서
// Step 3: 프로필 저장 후
await repository.save(newProfile);

// 🆕 Step 3.5: GPT-5.2 사주 계산 트리거 (Fire-and-forget)
sajuAnalysisService.analyzeOnProfileSave(
  userId: userId,  // 현재 로그인 사용자
  profileId: newProfileId,
  runInBackground: true,  // 백그라운드 실행
);
```

**필요한 추가 작업**:
1. `SajuAnalysisService`가 인연 프로필도 처리할 수 있도록 확인
2. 인연의 `saju_analyses` 데이터가 나와 동일한 형식으로 저장되는지 확인

---

### Step 2: Dart 궁합 계산기 클래스 생성

**새 파일**: `frontend/lib/AI/services/compatibility_calculator.dart`

#### 2.1 데이터 구조 정의

```dart
/// 천간 (10 Heavenly Stems)
enum Cheongan {
  gap('갑', '甲', '木', '양'),
  eul('을', '乙', '木', '음'),
  byeong('병', '丙', '火', '양'),
  jeong('정', '丁', '火', '음'),
  mu('무', '戊', '土', '양'),
  gi('기', '己', '土', '음'),
  gyeong('경', '庚', '金', '양'),
  sin('신', '辛', '金', '음'),
  im('임', '壬', '水', '양'),
  gye('계', '癸', '水', '음');

  final String korean;
  final String hanja;
  final String oheng;
  final String yinYang;

  const Cheongan(this.korean, this.hanja, this.oheng, this.yinYang);

  /// 한글(한자) 형식에서 파싱 (예: "갑(甲)" → Cheongan.gap)
  static Cheongan? fromKoreanHanja(String? value) {
    if (value == null) return null;
    final korean = value.split('(').first;
    return Cheongan.values.firstWhereOrNull((e) => e.korean == korean);
  }
}

/// 지지 (12 Earthly Branches)
enum Jiji {
  ja('자', '子', '水', '양'),
  chuk('축', '丑', '土', '음'),
  in_('인', '寅', '木', '양'),
  myo('묘', '卯', '木', '음'),
  jin('진', '辰', '土', '양'),
  sa('사', '巳', '火', '음'),
  o('오', '午', '火', '양'),
  mi('미', '未', '土', '음'),
  sin_('신', '申', '金', '양'),
  yu('유', '酉', '金', '음'),
  sul('술', '戌', '土', '양'),
  hae('해', '亥', '水', '음');

  final String korean;
  final String hanja;
  final String oheng;
  final String yinYang;

  const Jiji(this.korean, this.hanja, this.oheng, this.yinYang);

  static Jiji? fromKoreanHanja(String? value) {
    if (value == null) return null;
    final korean = value.split('(').first;
    return Jiji.values.firstWhereOrNull((e) => e.korean == korean);
  }
}
```

#### 2.2 합충형해파 계산 로직

```dart
/// 천간합 (5가지)
/// 갑기합토, 을경합금, 병신합수, 정임합목, 무계합화
class CheonganHap {
  static const Map<Set<Cheongan>, String> hapPairs = {
    {Cheongan.gap, Cheongan.gi}: '갑기합토',
    {Cheongan.eul, Cheongan.gyeong}: '을경합금',
    {Cheongan.byeong, Cheongan.sin}: '병신합수',
    {Cheongan.jeong, Cheongan.im}: '정임합목',
    {Cheongan.mu, Cheongan.gye}: '무계합화',
  };

  /// 두 천간이 합인지 확인
  static String? checkHap(Cheongan a, Cheongan b) {
    final pair = {a, b};
    return hapPairs[pair];
  }
}

/// 지지 육합 (6가지)
/// 자축합토, 인해합목, 묘술합화, 진유합금, 사신합수, 오미합화
class JijiYukhap {
  static const Map<Set<Jiji>, String> hapPairs = {
    {Jiji.ja, Jiji.chuk}: '자축합토',
    {Jiji.in_, Jiji.hae}: '인해합목',
    {Jiji.myo, Jiji.sul}: '묘술합화',
    {Jiji.jin, Jiji.yu}: '진유합금',
    {Jiji.sa, Jiji.sin_}: '사신합수',
    {Jiji.o, Jiji.mi}: '오미합화',
  };

  static String? checkHap(Jiji a, Jiji b) {
    final pair = {a, b};
    return hapPairs[pair];
  }
}

/// 지지 삼합 (4가지)
/// 인오술합화, 해묘미합목, 사유축합금, 신자진합수
class JijiSamhap {
  static const Map<Set<Jiji>, String> hapTriples = {
    {Jiji.in_, Jiji.o, Jiji.sul}: '인오술합화',
    {Jiji.hae, Jiji.myo, Jiji.mi}: '해묘미합목',
    {Jiji.sa, Jiji.yu, Jiji.chuk}: '사유축합금',
    {Jiji.sin_, Jiji.ja, Jiji.jin}: '신자진합수',
  };

  /// 두 지지가 반합인지 확인 (삼합의 2개)
  static String? checkBanhap(Jiji a, Jiji b) {
    final pair = {a, b};
    for (final entry in hapTriples.entries) {
      if (entry.key.containsAll(pair)) {
        return '${entry.value.substring(0, entry.value.length - 1)} 반합';
      }
    }
    return null;
  }
}

/// 지지 방합 (4가지)
/// 인묘진합목, 사오미합화, 신유술합금, 해자축합수
class JijiBanghap {
  static const Map<Set<Jiji>, String> hapTriples = {
    {Jiji.in_, Jiji.myo, Jiji.jin}: '인묘진합목',
    {Jiji.sa, Jiji.o, Jiji.mi}: '사오미합화',
    {Jiji.sin_, Jiji.yu, Jiji.sul}: '신유술합금',
    {Jiji.hae, Jiji.ja, Jiji.chuk}: '해자축합수',
  };
}

/// 지지 육충 (6가지)
/// 자오충, 축미충, 인신충, 묘유충, 진술충, 사해충
class JijiChung {
  static const Map<Set<Jiji>, String> chungPairs = {
    {Jiji.ja, Jiji.o}: '자오충',
    {Jiji.chuk, Jiji.mi}: '축미충',
    {Jiji.in_, Jiji.sin_}: '인신충',
    {Jiji.myo, Jiji.yu}: '묘유충',
    {Jiji.jin, Jiji.sul}: '진술충',
    {Jiji.sa, Jiji.hae}: '사해충',
  };

  static String? checkChung(Jiji a, Jiji b) {
    final pair = {a, b};
    return chungPairs[pair];
  }
}

/// 지지 형 (삼형살, 자묘형, 자형)
class JijiHyung {
  // 삼형살
  static const Map<Set<Jiji>, String> samhyung = {
    {Jiji.in_, Jiji.sa, Jiji.sin_}: '인사신 삼형살',
    {Jiji.chuk, Jiji.sul, Jiji.mi}: '축술미 삼형살',
  };

  // 자묘형 (무례지형)
  static const jaMyoHyung = {Jiji.ja, Jiji.myo};

  // 자형 (자기 형벌)
  static const Set<Jiji> jaHyung = {
    Jiji.jin,  // 진진자형
    Jiji.o,    // 오오자형
    Jiji.yu,   // 유유자형
    Jiji.hae,  // 해해자형
  };

  static String? checkHyung(Jiji a, Jiji b) {
    // 자묘형
    if ({a, b} == jaMyoHyung) return '자묘형 (무례지형)';
    // 자형
    if (a == b && jaHyung.contains(a)) return '${a.korean}${a.korean}자형';
    return null;
  }
}

/// 지지 해 (6가지)
/// 술유해, 신해해, 미자해, 축오해, 인사해, 묘진해
class JijiHae {
  static const Map<Set<Jiji>, String> haePairs = {
    {Jiji.sul, Jiji.yu}: '술유해',
    {Jiji.sin_, Jiji.hae}: '신해해',
    {Jiji.mi, Jiji.ja}: '미자해',
    {Jiji.chuk, Jiji.o}: '축오해',
    {Jiji.in_, Jiji.sa}: '인사해',
    {Jiji.myo, Jiji.jin}: '묘진해',
  };

  static String? checkHae(Jiji a, Jiji b) {
    final pair = {a, b};
    return haePairs[pair];
  }
}

/// 지지 파 (6가지)
/// 유자파, 축진파, 인해파, 묘오파, 신사파, 술미파
class JijiPa {
  static const Map<Set<Jiji>, String> paPairs = {
    {Jiji.yu, Jiji.ja}: '유자파',
    {Jiji.chuk, Jiji.jin}: '축진파',
    {Jiji.in_, Jiji.hae}: '인해파',
    {Jiji.myo, Jiji.o}: '묘오파',
    {Jiji.sin_, Jiji.sa}: '신사파',
    {Jiji.sul, Jiji.mi}: '술미파',
  };

  static String? checkPa(Jiji a, Jiji b) {
    final pair = {a, b};
    return paPairs[pair];
  }
}

/// 원진 (12가지)
/// 서로 원수지간
class Wonjin {
  static const Map<Jiji, Jiji> wonjinPairs = {
    Jiji.ja: Jiji.mi,
    Jiji.chuk: Jiji.o,
    Jiji.in_: Jiji.sa,
    Jiji.myo: Jiji.jin,
    Jiji.jin: Jiji.myo,
    Jiji.sa: Jiji.in_,
    Jiji.o: Jiji.chuk,
    Jiji.mi: Jiji.ja,
    Jiji.sin_: Jiji.hae,
    Jiji.yu: Jiji.sul,
    Jiji.sul: Jiji.yu,
    Jiji.hae: Jiji.sin_,
  };

  static bool checkWonjin(Jiji a, Jiji b) {
    return wonjinPairs[a] == b;
  }
}
```

#### 2.3 궁합 점수 계산 메인 클래스

```dart
/// 궁합 계산 결과
class CompatibilityResult {
  final int overallScore;
  final Map<String, int> categoryScores;
  final List<String> strengths;
  final List<String> challenges;
  final Map<String, dynamic> hapchungDetails;

  const CompatibilityResult({
    required this.overallScore,
    required this.categoryScores,
    required this.strengths,
    required this.challenges,
    required this.hapchungDetails,
  });
}

/// 궁합 계산기
class CompatibilityCalculator {
  /// 두 사람의 사주로 궁합 계산
  CompatibilityResult calculate({
    required Map<String, dynamic> mySaju,
    required Map<String, dynamic> targetSaju,
    required String relationType,
  }) {
    // 1. 천간 분석
    final cheonganAnalysis = _analyzeCheongan(mySaju, targetSaju);

    // 2. 지지 분석 (합충형해파)
    final jijiAnalysis = _analyzeJiji(mySaju, targetSaju);

    // 3. 오행 상생상극 분석
    final ohengAnalysis = _analyzeOheng(mySaju, targetSaju);

    // 4. 일주 궁합 (일간 기준)
    final ilju = _analyzeIljuCompatibility(mySaju, targetSaju);

    // 5. 점수 계산
    final scores = _calculateScores(
      cheonganAnalysis,
      jijiAnalysis,
      ohengAnalysis,
      ilju,
      relationType,
    );

    return CompatibilityResult(
      overallScore: scores['overall'] ?? 50,
      categoryScores: Map<String, int>.from(scores['categories'] ?? {}),
      strengths: _extractStrengths(cheonganAnalysis, jijiAnalysis),
      challenges: _extractChallenges(cheonganAnalysis, jijiAnalysis),
      hapchungDetails: {
        'cheongan': cheonganAnalysis,
        'jiji': jijiAnalysis,
        'oheng': ohengAnalysis,
      },
    );
  }

  // ... 상세 구현
}
```

---

### Step 3: CompatibilityAnalysisService 수정

**파일**: `frontend/lib/AI/services/compatibility_analysis_service.dart`

**변경 내용**:
1. Gemini 호출 제거
2. Dart 궁합 계산기 사용
3. 두 프로필 모두 `saju_analyses`에서 조회

```dart
/// 궁합 분석 실행 (변경)
Future<CompatibilityAnalysisResult> analyzeCompatibility({...}) async {
  // 1. 캐시 확인 (동일)

  // 2. 두 프로필의 saju_analyses 조회 (변경)
  // - 나: saju_analyses 조회
  // - 인연: saju_analyses 조회 (없으면 에러)
  final myData = await _getProfileWithSaju(fromProfileId);
  final targetData = await _getProfileWithSaju(toProfileId);  // 🆕 인연도 동일 로직

  if (myData == null || myData['saju_analysis'] == null) {
    return CompatibilityAnalysisResult.failure('나의 사주 분석이 필요합니다');
  }
  if (targetData == null || targetData['saju_analysis'] == null) {
    return CompatibilityAnalysisResult.failure('인연의 사주 분석이 필요합니다. 잠시 후 다시 시도해주세요.');
  }

  // 3. Dart 궁합 계산 (변경 - Gemini 제거)
  final calculator = CompatibilityCalculator();
  final result = calculator.calculate(
    mySaju: myData['saju_analysis'],
    targetSaju: targetData['saju_analysis'],
    relationType: relationType,
  );

  // 4. 결과 저장 (변경)
  final savedId = await _saveAnalysisResult(
    userId: userId,
    fromProfileId: fromProfileId,
    toProfileId: toProfileId,
    relationType: relationType,
    calculationResult: result,  // Dart 계산 결과
  );

  // ...
}
```

---

### Step 4: 테스트 및 검증

#### 4.1 사주 데이터 검증
- 인연 추가 후 `saju_analyses` 테이블에 데이터 저장 확인
- 한글(한자) 형식 확인 (예: `갑(甲)`, `자(子)`)

#### 4.2 궁합 계산 검증
- 천간합 계산 정확성
- 지지 육합/삼합/방합 정확성
- 충/형/해/파 계산 정확성
- 오행 상생상극 분석

#### 4.3 성능 검증
- Gemini 제거로 인한 응답 속도 개선 확인
- 목표: < 1초 (Dart 계산)

---

## 파일 변경 목록

| 파일 | 변경 유형 | 설명 |
|------|----------|------|
| `relationship_add_screen.dart` | 수정 | 인연 저장 시 GPT 사주 계산 트리거 |
| `compatibility_calculator.dart` | 신규 | Dart 궁합 계산 로직 |
| `compatibility_analysis_service.dart` | 수정 | Gemini → Dart 계산으로 변경 |
| `compatibility_prompt.dart` | 삭제 가능 | Gemini 프롬프트 (더 이상 사용 안 함) |

---

## 일정

| 단계 | 작업 | 예상 |
|------|------|------|
| Step 1 | 인연 GPT 사주 계산 트리거 | 30분 |
| Step 2 | Dart 궁합 계산기 구현 | 2-3시간 |
| Step 3 | Service 수정 | 1시간 |
| Step 4 | 테스트 및 검증 | 1시간 |

---

## 참고: 합충형해파 완전 정리

### 천간합 (5가지)
| 합 | 천간 조합 | 변화 오행 |
|----|----------|----------|
| 갑기합 | 갑(甲) + 기(己) | 土 |
| 을경합 | 을(乙) + 경(庚) | 金 |
| 병신합 | 병(丙) + 신(辛) | 水 |
| 정임합 | 정(丁) + 임(壬) | 木 |
| 무계합 | 무(戊) + 계(癸) | 火 |

### 지지 육합 (6가지)
| 합 | 지지 조합 | 변화 오행 |
|----|----------|----------|
| 자축합 | 자(子) + 축(丑) | 土 |
| 인해합 | 인(寅) + 해(亥) | 木 |
| 묘술합 | 묘(卯) + 술(戌) | 火 |
| 진유합 | 진(辰) + 유(酉) | 金 |
| 사신합 | 사(巳) + 신(申) | 水 |
| 오미합 | 오(午) + 미(未) | 火/土 |

### 지지 삼합 (4가지)
| 합 | 지지 조합 | 변화 오행 |
|----|----------|----------|
| 인오술 | 인(寅) + 오(午) + 술(戌) | 火 |
| 해묘미 | 해(亥) + 묘(卯) + 미(未) | 木 |
| 사유축 | 사(巳) + 유(酉) + 축(丑) | 金 |
| 신자진 | 신(申) + 자(子) + 진(辰) | 水 |

### 지지 방합 (4가지)
| 합 | 지지 조합 | 변화 오행 |
|----|----------|----------|
| 인묘진 | 인(寅) + 묘(卯) + 진(辰) | 木 |
| 사오미 | 사(巳) + 오(午) + 미(未) | 火 |
| 신유술 | 신(申) + 유(酉) + 술(戌) | 金 |
| 해자축 | 해(亥) + 자(子) + 축(丑) | 水 |

### 지지 육충 (6가지)
| 충 | 지지 조합 | 의미 |
|----|----------|------|
| 자오충 | 자(子) ↔ 오(午) | 水火 충돌 |
| 축미충 | 축(丑) ↔ 미(未) | 土土 충돌 |
| 인신충 | 인(寅) ↔ 신(申) | 木金 충돌 |
| 묘유충 | 묘(卯) ↔ 유(酉) | 木金 충돌 |
| 진술충 | 진(辰) ↔ 술(戌) | 土土 충돌 |
| 사해충 | 사(巳) ↔ 해(亥) | 火水 충돌 |

### 지지 형
| 형 | 지지 조합 | 유형 |
|----|----------|------|
| 인사신 | 인(寅) + 사(巳) + 신(申) | 삼형살 (무은지형) |
| 축술미 | 축(丑) + 술(戌) + 미(未) | 삼형살 (지세지형) |
| 자묘형 | 자(子) + 묘(卯) | 무례지형 |
| 진진자형 | 진(辰) + 진(辰) | 자형 |
| 오오자형 | 오(午) + 오(午) | 자형 |
| 유유자형 | 유(酉) + 유(酉) | 자형 |
| 해해자형 | 해(亥) + 해(亥) | 자형 |

### 지지 해 (6가지)
| 해 | 지지 조합 |
|----|----------|
| 술유해 | 술(戌) + 유(酉) |
| 신해해 | 신(申) + 해(亥) |
| 미자해 | 미(未) + 자(子) |
| 축오해 | 축(丑) + 오(午) |
| 인사해 | 인(寅) + 사(巳) |
| 묘진해 | 묘(卯) + 진(辰) |

### 지지 파 (6가지)
| 파 | 지지 조합 |
|----|----------|
| 유자파 | 유(酉) + 자(子) |
| 축진파 | 축(丑) + 진(辰) |
| 인해파 | 인(寅) + 해(亥) |
| 묘오파 | 묘(卯) + 오(午) |
| 신사파 | 신(申) + 사(巳) |
| 술미파 | 술(戌) + 미(未) |

### 원진 (12가지)
| 원진 | 지지 조합 |
|------|----------|
| 자미 | 자(子) ↔ 미(未) |
| 축오 | 축(丑) ↔ 오(午) |
| 인사 | 인(寅) ↔ 사(巳) |
| 묘진 | 묘(卯) ↔ 진(辰) |
| 신해 | 신(申) ↔ 해(亥) |
| 유술 | 유(酉) ↔ 술(戌) |
