/// # 기본 사주 분석 프롬프트 (GPT-5.2용)
///
/// ## 개요
/// 프로필 저장 시 1회 실행되는 평생 사주 분석 프롬프트입니다.
/// GPT-5.2 모델을 사용하여 가장 정확한 분석을 제공합니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/prompts/saju_base_prompt.dart`
///
/// ## 분석 내용
/// - 타고난 성격과 기질
/// - 적성과 재능
/// - 대인관계 특성
/// - 건강 취약점
/// - 재물운 경향
/// - 직업/진로 적합성
/// - 연애/결혼운 특성
///
/// ## 입력 데이터 (SajuInputData)
/// ```dart
/// {
///   'profile_id': 'uuid',
///   'profile_name': '이름',
///   'birth_date': '1990-01-15',
///   'gender': 'male',
///   'saju': {'year_gan': '경', ...},
///   'oheng': {'wood': 2, 'fire': 1, ...},
///   'yongsin': {'yongsin': '금(金)', ...},
///   'day_strength': {'is_singang': true, 'score': 65},
///   'sinsal': [...],
///   'gilseong': [...],
/// }
/// ```
///
/// ## 출력 형식 (JSON)
/// ```json
/// {
///   "summary": "한 문장 요약",
///   "personality": {...},
///   "career": {...},
///   "relationships": {...},
///   "wealth": {...},
///   "health": {...},
///   "overall_advice": "...",
///   "lucky_elements": {...}
/// }
/// ```
///
/// ## 호출 흐름
/// ```
/// profile_provider.dart
///   → _triggerAiAnalysis()
///     → SajuAnalysisService.analyzeOnProfileSave()
///       → _runSajuBaseAnalysis()
///         → SajuBasePrompt.buildMessages()
///           → AiApiService.callOpenAI()
///             → Edge Function (ai-openai)
///               → OpenAI API (GPT-5.2)
/// ```
///
/// ## 캐시 정책
/// - 만료 기간: 무기한 (null)
/// - 프로필이 변경되지 않는 한 재생성 불필요
/// - upsert로 동일 profile_id에 대해 덮어쓰기
///
/// ## 비용 참고 (2025-12 기준)
/// - GPT-5.2: 입력 $1.75/1M, 출력 $14.00/1M, 캐시 90% 할인
/// - 평균 분석 1회: 약 $0.02~0.05

import '../core/ai_constants.dart';
import 'prompt_template.dart';

/// 기본 사주 분석 프롬프트
///
/// ## 사용 예시
/// ```dart
/// final prompt = SajuBasePrompt();
/// final messages = prompt.buildMessages(sajuInputData.toJson());
///
/// final response = await aiApiService.callOpenAI(
///   messages: messages,
///   model: prompt.modelName,          // gpt-5.2
///   maxTokens: prompt.maxTokens,      // 4096
///   temperature: prompt.temperature,  // 0.7
/// );
/// ```
///
/// ## 프롬프트 구조
/// 1. **System Prompt**: 사주명리학 전문가 역할 정의
/// 2. **User Prompt**: 사주 데이터 + JSON 출력 스키마
///
/// ## JSON 출력 필드
/// | 필드 | 설명 |
/// |------|------|
/// | summary | 사주 특성 한 문장 요약 |
/// | personality | 성격 분석 (traits, strengths, weaknesses) |
/// | career | 진로 적합성 (suitable_fields, work_style) |
/// | relationships | 대인관계 (social_style, compatibility_tips) |
/// | wealth | 재물운 (tendency, advice) |
/// | health | 건강 (vulnerable_areas, advice) |
/// | overall_advice | 종합 인생 조언 |
/// | lucky_elements | 행운 요소 (colors, directions, numbers) |
class SajuBasePrompt extends PromptTemplate {
  @override
  String get summaryType => SummaryType.sajuBase;

  @override
  String get modelName => OpenAIModels.sajuAnalysis; // GPT-5.2

  @override
  int get maxTokens => TokenLimits.sajuBaseMaxTokens;

  @override
  double get temperature => 0.7;

  @override
  Duration? get cacheExpiry => CacheExpiry.sajuBase;

  @override
  String get systemPrompt => '''
당신은 한국 전통 사주명리학 전문가입니다. 수십 년간의 연구와 실전 경험을 바탕으로 정확하고 통찰력 있는 사주 분석을 제공합니다.

## 분석 원칙
1. **정확성**: 명리학 원리에 충실하되 현대적 해석을 가미
2. **균형**: 긍정적/부정적 측면을 균형 있게 분석
3. **실용성**: 실생활에 적용 가능한 조언 제공
4. **존중**: 개인의 선택과 노력을 존중하는 관점 유지

## 분석 영역
- 타고난 성격과 기질
- 적성과 재능
- 대인관계 특성
- 건강 취약점
- 재물운 경향
- 직업/진로 적합성
- 연애/결혼운 특성
- 주의해야 할 점

## 응답 형식
JSON 형식으로 구조화된 분석 결과를 반환하세요.
''';

  @override
  String buildUserPrompt(Map<String, dynamic> input) {
    final data = SajuInputData.fromJson(input);

    return '''
## 분석 대상
- 이름: ${data.profileName}
- 생년월일: ${_formatBirthDate(data.birthDate)}
- 성별: ${data.gender == 'male' ? '남성' : '여성'}
- 태어난 시간: ${data.birthTime ?? '미상'}

## 사주 팔자
${data.sajuString}

## 오행 분포
${data.ohengString}

## 일간 (나를 대표하는 오행)
${data.dayMaster}

${_buildYongsinSection(data.yongsin)}
${_buildDayStrengthSection(data.dayStrength)}
${_buildGyeokgukSection(data.gyeokguk)}
${_buildSipsinSection(data.sipsinInfo)}
${_buildJijangganSection(data.jijangganInfo)}
${_buildSinsalSection(data.sinsal)}
${_buildGilseongSection(data.gilseong)}
${_buildUnsungSection(data.twelveUnsung)}
${_buildTwelveSinsalSection(data.twelveSinsal)}
${_buildDaeunSection(data.daeun)}
${_buildHapchungSection(data.hapchung)}

---

위 사주 정보를 바탕으로 종합적인 사주 분석을 JSON 형식으로 제공해주세요.

반드시 아래 JSON 스키마를 따라주세요:

```json
{
  "summary": "한 문장으로 요약한 사주 특성",
  "personality": {
    "core_traits": ["핵심 성격 특성 3-5개"],
    "strengths": ["장점 3-5개"],
    "weaknesses": ["약점/주의점 2-3개"],
    "description": "성격에 대한 2-3문장 설명"
  },
  "career": {
    "suitable_fields": ["적합한 분야 3-5개"],
    "unsuitable_fields": ["피해야 할 분야 1-2개"],
    "work_style": "업무 스타일 설명",
    "advice": "진로 관련 조언"
  },
  "relationships": {
    "social_style": "대인관계 스타일",
    "compatibility_tips": "인연/궁합 관련 조언",
    "cautions": ["주의점 1-2개"]
  },
  "wealth": {
    "tendency": "재물운 경향",
    "strengths": ["재물 관련 강점"],
    "advice": "재물 관련 조언"
  },
  "health": {
    "vulnerable_areas": ["건강 취약 부위 1-3개"],
    "advice": "건강 관련 조언"
  },
  "overall_advice": "종합적인 인생 조언 2-3문장",
  "lucky_elements": {
    "colors": ["행운의 색 1-2개"],
    "directions": ["좋은 방향 1-2개"],
    "numbers": [행운의 숫자 1-2개]
  }
}
```
''';
  }

  String _formatBirthDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String _buildYongsinSection(Map<String, dynamic>? yongsin) {
    if (yongsin == null || yongsin.isEmpty) return '';

    final buffer = StringBuffer('\n## 용신 정보\n');

    if (yongsin['yongsin'] != null) {
      buffer.writeln('- 용신(用神): ${yongsin['yongsin']}');
    }
    if (yongsin['huisin'] != null) {
      buffer.writeln('- 희신(喜神): ${yongsin['huisin']}');
    }
    if (yongsin['gisin'] != null) {
      buffer.writeln('- 기신(忌神): ${yongsin['gisin']}');
    }
    if (yongsin['gusin'] != null) {
      buffer.writeln('- 구신(仇神): ${yongsin['gusin']}');
    }

    return buffer.toString();
  }

  String _buildDayStrengthSection(Map<String, dynamic>? dayStrength) {
    if (dayStrength == null || dayStrength.isEmpty) return '';

    final buffer = StringBuffer('\n## 신강/신약\n');

    final isSingang = dayStrength['is_singang'] as bool? ?? false;
    final score = dayStrength['score'] as int? ?? 50;

    buffer.writeln('- 판정: ${isSingang ? '신강(身强)' : '신약(身弱)'}');
    buffer.writeln('- 점수: $score/100');

    return buffer.toString();
  }

  String _buildSinsalSection(List<Map<String, dynamic>>? sinsal) {
    if (sinsal == null || sinsal.isEmpty) return '';

    final buffer = StringBuffer('\n## 신살 정보\n');

    for (final s in sinsal) {
      final name = s['name'] ?? '';
      final pillar = s['pillar'] ?? '';
      final meaning = s['meaning'] ?? '';
      buffer.writeln('- $name ($pillar): $meaning');
    }

    return buffer.toString();
  }

  String _buildGilseongSection(List<Map<String, dynamic>>? gilseong) {
    if (gilseong == null || gilseong.isEmpty) return '';

    final buffer = StringBuffer('\n## 길성 정보\n');

    for (final g in gilseong) {
      final name = g['name'] ?? '';
      final pillar = g['pillar'] ?? '';
      final meaning = g['meaning'] ?? '';
      buffer.writeln('- $name ($pillar): $meaning');
    }

    return buffer.toString();
  }

  String _buildUnsungSection(List<dynamic>? unsung) {
    if (unsung == null || unsung.isEmpty) return '';

    final buffer = StringBuffer('\n## 12운성\n');

    for (final item in unsung) {
      if (item is Map) {
        final pillar = item['pillar'] ?? '';
        final unsungName = item['unsung'] ?? '';
        final fortuneType = item['fortuneType'] ?? '';
        if (unsungName.toString().isNotEmpty) {
          buffer.writeln('- $pillar: $unsungName ($fortuneType)');
        }
      }
    }

    return buffer.toString();
  }

  /// 격국 섹션 빌드
  String _buildGyeokgukSection(Map<String, dynamic>? gyeokguk) {
    if (gyeokguk == null || gyeokguk.isEmpty) return '';

    final buffer = StringBuffer('\n## 격국\n');

    final name = gyeokguk['name'] ?? gyeokguk['type'] ?? '';
    final description = gyeokguk['description'] ?? '';

    if (name.toString().isNotEmpty) {
      buffer.writeln('- 격국: $name');
    }
    if (description.toString().isNotEmpty) {
      buffer.writeln('- 설명: $description');
    }

    return buffer.toString();
  }

  /// 십신 섹션 빌드
  String _buildSipsinSection(Map<String, dynamic>? sipsin) {
    if (sipsin == null || sipsin.isEmpty) return '';

    final buffer = StringBuffer('\n## 십신 (十神)\n');

    final pillars = ['year', 'month', 'day', 'hour'];
    final pillarNames = {'year': '년주', 'month': '월주', 'day': '일주', 'hour': '시주'};

    for (final pillar in pillars) {
      final data = sipsin[pillar];
      if (data != null && data is Map) {
        final gan = data['gan'] ?? '';
        final ji = data['ji'] ?? '';
        if (gan.toString().isNotEmpty || ji.toString().isNotEmpty) {
          buffer.writeln('- ${pillarNames[pillar]}: 천간=$gan, 지지=$ji');
        }
      }
    }

    return buffer.toString();
  }

  /// 지장간 섹션 빌드
  String _buildJijangganSection(Map<String, dynamic>? jijanggan) {
    if (jijanggan == null || jijanggan.isEmpty) return '';

    final buffer = StringBuffer('\n## 지장간 (地藏干)\n');

    final pillars = ['year', 'month', 'day', 'hour'];
    final pillarNames = {'year': '년지', 'month': '월지', 'day': '일지', 'hour': '시지'};

    for (final pillar in pillars) {
      final data = jijanggan[pillar];
      if (data != null) {
        if (data is List) {
          buffer.writeln('- ${pillarNames[pillar]}: ${data.join(', ')}');
        } else {
          buffer.writeln('- ${pillarNames[pillar]}: $data');
        }
      }
    }

    return buffer.toString();
  }

  /// 12신살 섹션 빌드
  String _buildTwelveSinsalSection(List<dynamic>? twelveSinsal) {
    if (twelveSinsal == null || twelveSinsal.isEmpty) return '';

    final buffer = StringBuffer('\n## 12신살 (十二神殺)\n');

    for (final item in twelveSinsal) {
      if (item is Map) {
        final pillar = item['pillar'] ?? '';
        final sinsal = item['sinsal'] ?? '';
        final fortuneType = item['fortuneType'] ?? '';
        if (sinsal.toString().isNotEmpty) {
          buffer.writeln('- $pillar: $sinsal ($fortuneType)');
        }
      }
    }

    return buffer.toString();
  }

  /// 대운 섹션 빌드
  String _buildDaeunSection(Map<String, dynamic>? daeun) {
    if (daeun == null || daeun.isEmpty) return '';

    final buffer = StringBuffer('\n## 대운 (大運)\n');

    // 대운 시작 나이
    final startAge = daeun['start_age'];
    if (startAge != null) {
      buffer.writeln('- 대운 시작: $startAge세');
    }

    // 현재 대운
    final current = daeun['current'];
    if (current != null && current is Map) {
      final gan = current['gan'] ?? '';
      final ji = current['ji'] ?? '';
      final startYear = current['start_year'];
      final endYear = current['end_year'];

      buffer.write('- 현재 대운: $gan$ji');
      if (startYear != null && endYear != null) {
        buffer.writeln(' ($startYear~$endYear)');
      } else {
        buffer.writeln('');
      }
    }

    // 대운 목록 (간략히)
    final list = daeun['list'];
    if (list != null && list is List && list.isNotEmpty) {
      final limitedList = list.take(5);
      buffer.writeln('- 대운 흐름: ${limitedList.map((d) {
        if (d is Map) return '${d['gan'] ?? ''}${d['ji'] ?? ''}';
        return d.toString();
      }).join(' → ')}...');
    }

    return buffer.toString();
  }

  /// 합충형파해 섹션 빌드
  ///
  /// 천간/지지 간의 합충형파해 관계를 프롬프트에 포함합니다.
  /// - 합: 천간합, 지지육합, 삼합, 방합 (길한 관계)
  /// - 충: 천간충, 지지충 (충돌 관계)
  /// - 형: 지지형 (갈등 관계)
  /// - 파: 지지파 (손상 관계)
  /// - 해: 지지해 (방해 관계)
  /// - 원진: 미움 관계
  String _buildHapchungSection(Map<String, dynamic>? hapchung) {
    if (hapchung == null) return '';

    final hasRelations = hapchung['has_relations'] as bool? ?? false;
    if (!hasRelations) return '';

    final buffer = StringBuffer('\n## 합충형파해 (合沖刑破害)\n');

    // 집계 정보
    final totalHaps = hapchung['total_haps'] as int? ?? 0;
    final totalChungs = hapchung['total_chungs'] as int? ?? 0;
    final totalNegatives = hapchung['total_negatives'] as int? ?? 0;

    buffer.writeln('> 합 ${totalHaps}개, 충 ${totalChungs}개, 형/파/해/원진 ${totalNegatives}개');
    buffer.writeln('');

    // 천간합
    final cheonganHaps = hapchung['cheongan_haps'] as List? ?? [];
    if (cheonganHaps.isNotEmpty) {
      buffer.writeln('### 천간합 (天干合)');
      for (final h in cheonganHaps) {
        final desc = h['description'] ?? '${h['gan1']}${h['gan2']}합';
        buffer.writeln('- ${h['pillar1']}주-${h['pillar2']}주: $desc');
      }
      buffer.writeln('');
    }

    // 천간충
    final cheonganChungs = hapchung['cheongan_chungs'] as List? ?? [];
    if (cheonganChungs.isNotEmpty) {
      buffer.writeln('### 천간충 (天干沖)');
      for (final c in cheonganChungs) {
        buffer.writeln('- ${c['pillar1']}주-${c['pillar2']}주: ${c['gan1']}${c['gan2']}충');
      }
      buffer.writeln('');
    }

    // 지지육합
    final jijiYukhaps = hapchung['jiji_yukhaps'] as List? ?? [];
    if (jijiYukhaps.isNotEmpty) {
      buffer.writeln('### 지지육합 (地支六合)');
      for (final y in jijiYukhaps) {
        final desc = y['description'] ?? '${y['ji1']}${y['ji2']}합';
        buffer.writeln('- ${y['pillar1']}주-${y['pillar2']}주: $desc');
      }
      buffer.writeln('');
    }

    // 삼합
    final jijiSamhaps = hapchung['jiji_samhaps'] as List? ?? [];
    if (jijiSamhaps.isNotEmpty) {
      buffer.writeln('### 삼합 (三合)');
      for (final s in jijiSamhaps) {
        final jijis = (s['jijis'] as List?)?.join('') ?? '';
        final pillars = (s['pillars'] as List?)?.join(',') ?? '';
        final isFull = s['is_full'] as bool? ?? true;
        final label = isFull ? '삼합' : '반합';
        buffer.writeln('- ${pillars}주: $jijis $label (${s['result_oheng']}국)');
      }
      buffer.writeln('');
    }

    // 방합
    final jijiBanghaps = hapchung['jiji_banghaps'] as List? ?? [];
    if (jijiBanghaps.isNotEmpty) {
      buffer.writeln('### 방합 (方合)');
      for (final b in jijiBanghaps) {
        final jijis = (b['jijis'] as List?)?.join('') ?? '';
        final pillars = (b['pillars'] as List?)?.join(',') ?? '';
        buffer.writeln('- ${pillars}주: $jijis 방합 (${b['season']}, ${b['direction']}방)');
      }
      buffer.writeln('');
    }

    // 지지충
    final jijiChungs = hapchung['jiji_chungs'] as List? ?? [];
    if (jijiChungs.isNotEmpty) {
      buffer.writeln('### 지지충 (地支沖)');
      for (final c in jijiChungs) {
        buffer.writeln('- ${c['pillar1']}주-${c['pillar2']}주: ${c['ji1']}${c['ji2']}충');
      }
      buffer.writeln('');
    }

    // 지지형
    final jijiHyungs = hapchung['jiji_hyungs'] as List? ?? [];
    if (jijiHyungs.isNotEmpty) {
      buffer.writeln('### 지지형 (地支刑)');
      for (final h in jijiHyungs) {
        final desc = h['description'] ?? '${h['ji1']}${h['ji2']}형';
        buffer.writeln('- ${h['pillar1']}주-${h['pillar2']}주: $desc');
      }
      buffer.writeln('');
    }

    // 지지파
    final jijiPas = hapchung['jiji_pas'] as List? ?? [];
    if (jijiPas.isNotEmpty) {
      buffer.writeln('### 지지파 (地支破)');
      for (final p in jijiPas) {
        buffer.writeln('- ${p['pillar1']}주-${p['pillar2']}주: ${p['ji1']}${p['ji2']}파');
      }
      buffer.writeln('');
    }

    // 지지해
    final jijiHaes = hapchung['jiji_haes'] as List? ?? [];
    if (jijiHaes.isNotEmpty) {
      buffer.writeln('### 지지해 (地支害)');
      for (final h in jijiHaes) {
        buffer.writeln('- ${h['pillar1']}주-${h['pillar2']}주: ${h['ji1']}${h['ji2']}해');
      }
      buffer.writeln('');
    }

    // 원진
    final wonjins = hapchung['wonjins'] as List? ?? [];
    if (wonjins.isNotEmpty) {
      buffer.writeln('### 원진 (怨嗔)');
      for (final w in wonjins) {
        buffer.writeln('- ${w['pillar1']}주-${w['pillar2']}주: ${w['ji1']}${w['ji2']}원진');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }
}
