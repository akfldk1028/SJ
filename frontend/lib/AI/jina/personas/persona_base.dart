/// # 페르소나 베이스 클래스
///
/// ## 개요
/// 모든 AI 챗봇 페르소나의 기본 인터페이스를 정의합니다.
/// Jina 팀원이 새로운 페르소나를 쉽게 추가할 수 있도록 설계되었습니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/jina/personas/persona_base.dart`
///
/// ## 담당: Jina
///
/// ## 새 페르소나 추가 방법
/// 1. `personas/` 폴더에 새 파일 생성 (예: `romantic_advisor.dart`)
/// 2. `PersonaBase` 상속
/// 3. 모든 필수 getter 구현
/// 4. `persona_registry.dart`에 등록
///
/// ## 예시
/// ```dart
/// class RomanticAdvisorPersona extends PersonaBase {
///   @override
///   String get id => 'romantic_advisor';
///
///   @override
///   String get name => '로맨틱 상담사';
///
///   @override
///   String get description => '연애와 인간관계 전문 상담사';
///
///   @override
///   PersonaTone get tone => PersonaTone.polite;
///
///   @override
///   int get emojiLevel => 2;
///
///   @override
///   String get systemPrompt => '''
/// 당신은 따뜻하고 공감적인 연애 상담사입니다...
/// ''';
/// }
/// ```
///
/// ## 페르소나 구성 요소
///
/// ### 1. 기본 정보 (필수)
/// - `id`: 고유 식별자 (영문, snake_case)
/// - `name`: 표시 이름
/// - `description`: 간단한 설명
///
/// ### 2. 말투 설정 (필수)
/// - `tone`: 존댓말/반말 등
/// - `emojiLevel`: 이모지 사용 정도 (0-5)
///
/// ### 3. 시스템 프롬프트 (필수)
/// - AI의 성격과 응답 스타일 정의
///
/// ### 4. 옵션 설정 (선택)
/// - `greetings`: 인사말 목록
/// - `examples`: 대화 예시
/// - `prohibitions`: 금지 사항

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 말투 타입 열거형
// ═══════════════════════════════════════════════════════════════════════════

/// 페르소나 말투 타입
///
/// ## 종류
/// - `formal`: 격식체 (합니다)
/// - `polite`: 존댓말 (해요)
/// - `casual`: 반말 (해)
/// - `mixed`: 혼합 (상황에 따라)
enum PersonaTone {
  /// 격식체: "~합니다", "~입니다"
  /// 예: 선생님, 전문가
  formal,

  /// 존댓말: "~해요", "~예요"
  /// 예: 다정한 언니, 친절한 상담사
  polite,

  /// 반말: "~해", "~야"
  /// 예: 친구, 동생
  casual,

  /// 혼합: 상황에 따라 변경
  /// 예: 진지할 때 존댓말, 장난칠 때 반말
  mixed,
}

/// PersonaTone 확장 메서드
extension PersonaToneX on PersonaTone {
  /// 한글 표시 이름
  String get displayName {
    switch (this) {
      case PersonaTone.formal:
        return '격식체';
      case PersonaTone.polite:
        return '존댓말';
      case PersonaTone.casual:
        return '반말';
      case PersonaTone.mixed:
        return '혼합';
    }
  }

  /// 프롬프트에 포함할 설명
  String get promptDescription {
    switch (this) {
      case PersonaTone.formal:
        return '격식체(~합니다, ~입니다) 사용';
      case PersonaTone.polite:
        return '존댓말(~해요, ~예요) 사용';
      case PersonaTone.casual:
        return '반말(~해, ~야) 사용';
      case PersonaTone.mixed:
        return '상황에 따라 존댓말과 반말 혼용';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 페르소나 카테고리
// ═══════════════════════════════════════════════════════════════════════════

/// 페르소나 카테고리
///
/// UI에서 페르소나를 분류할 때 사용합니다.
enum PersonaCategory {
  /// 친구/동료 스타일
  friend,

  /// 전문가/학자 스타일
  expert,

  /// 가족/언니/오빠 스타일
  family,

  /// 재미/엔터테인먼트 스타일
  fun,

  /// 특수 (시즌 한정 등)
  special,
}

extension PersonaCategoryX on PersonaCategory {
  String get displayName {
    switch (this) {
      case PersonaCategory.friend:
        return '친구';
      case PersonaCategory.expert:
        return '전문가';
      case PersonaCategory.family:
        return '가족';
      case PersonaCategory.fun:
        return '재미';
      case PersonaCategory.special:
        return '특수';
    }
  }

  IconData get icon {
    switch (this) {
      case PersonaCategory.friend:
        return Icons.person;
      case PersonaCategory.expert:
        return Icons.school;
      case PersonaCategory.family:
        return Icons.family_restroom;
      case PersonaCategory.fun:
        return Icons.celebration;
      case PersonaCategory.special:
        return Icons.star;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 페르소나 베이스 클래스
// ═══════════════════════════════════════════════════════════════════════════

/// 페르소나 기본 추상 클래스
///
/// ## 구현 필수 항목
/// 1. `id`: 고유 식별자
/// 2. `name`: 표시 이름
/// 3. `description`: 설명
/// 4. `tone`: 말투 타입
/// 5. `emojiLevel`: 이모지 사용 정도
/// 6. `systemPrompt`: 시스템 프롬프트
///
/// ## 선택적 오버라이드
/// - `category`: 카테고리 (기본: friend)
/// - `greetings`: 인사말 목록
/// - `examples`: 대화 예시
/// - `prohibitions`: 금지 사항
/// - `keywords`: 특수 키워드
abstract class PersonaBase {
  // ─────────────────────────────────────────────────────────────────────────
  // 필수 구현 항목
  // ─────────────────────────────────────────────────────────────────────────

  /// 고유 식별자 (영문 snake_case)
  ///
  /// 예: 'cute_friend', 'wise_scholar'
  /// DB 저장, 캐시 키 등에 사용됩니다.
  String get id;

  /// 표시 이름
  ///
  /// 예: '귀여운 친구', '현명한 학자'
  String get name;

  /// 간단한 설명
  ///
  /// UI에서 페르소나 선택 시 표시됩니다.
  /// 예: '발랄하고 재미있는 친구 스타일'
  String get description;

  /// 말투 타입
  ///
  /// PersonaTone.formal / polite / casual / mixed
  PersonaTone get tone;

  /// 이모지 사용 정도 (0-5)
  ///
  /// - 0: 이모지 없음
  /// - 1: 최소 (문장 끝에 1개)
  /// - 2: 적당 (2-3개)
  /// - 3: 많음 (3-4개)
  /// - 4: 매우 많음 (4-5개)
  /// - 5: 과다 (6개 이상)
  int get emojiLevel;

  /// 시스템 프롬프트
  ///
  /// AI의 성격, 말투, 응답 스타일을 정의합니다.
  /// 이 프롬프트가 Gemini API에 전달됩니다.
  ///
  /// ## 포함해야 할 내용
  /// 1. 역할 정의
  /// 2. 성격/특징
  /// 3. 말투 스타일
  /// 4. 금지 사항
  String get systemPrompt;

  // ─────────────────────────────────────────────────────────────────────────
  // 선택적 오버라이드
  // ─────────────────────────────────────────────────────────────────────────

  /// 카테고리 (기본: friend)
  PersonaCategory get category => PersonaCategory.friend;

  /// 인사말 목록
  ///
  /// 대화 시작 시 랜덤으로 선택됩니다.
  /// 오버라이드하지 않으면 기본 인사말 사용.
  List<String> get greetings => [
        '안녕! 오늘 운세가 궁금해?',
        '반가워~ 뭐가 궁금해?',
      ];

  /// 대화 예시 (Few-shot learning)
  ///
  /// 시스템 프롬프트에 추가되어 AI가 참고합니다.
  /// 형식: [{'user': '질문', 'assistant': '답변'}, ...]
  List<Map<String, String>> get examples => [];

  /// 금지 사항 목록
  ///
  /// 시스템 프롬프트에 자동으로 추가됩니다.
  List<String> get prohibitions => [];

  /// 특수 키워드 (태그)
  ///
  /// 검색/필터링에 사용됩니다.
  List<String> get keywords => [];

  /// 아바타 이미지 경로 (선택)
  String? get avatarPath => null;

  /// 테마 색상 (선택)
  Color? get themeColor => null;

  // ─────────────────────────────────────────────────────────────────────────
  // 편의 메서드
  // ─────────────────────────────────────────────────────────────────────────

  /// 완성된 시스템 프롬프트 생성
  ///
  /// 기본 시스템 프롬프트에 공통 규칙, 예시, 금지사항을 추가합니다.
  ///
  /// ## 모듈화 설계
  /// - 공통 규칙: 여기서 한 번만 정의 → 모든 페르소나에 자동 적용
  /// - 개별 페르소나: systemPrompt, examples, prohibitions만 정의
  /// - 규칙 변경 시: 이 메서드만 수정하면 전체 적용
  String buildFullSystemPrompt() {
    final buffer = StringBuffer(systemPrompt);

    // ═══════════════════════════════════════════════════════════════════════
    // 🔒 공통 필수 규칙 (모든 페르소나에 적용)
    // ═══════════════════════════════════════════════════════════════════════
    buffer.writeln('''

## 🔒 필수 응답 규칙

### 응답 길이 (중요!)
- 사용자랑 재밌게 너무 길지않게 대화하듯이
- 장황하게 늘어놓지 말고 핵심 포인트만 전달
- 한 번에 다 말하지 말고 2-3번에 나눠서 말하기!

### 🎣 대화 유도 원칙 (핵심!)

**원칙 1: 정보를 나눠서 제공**
- 한 번에 모든 걸 말하지 말고, 핵심만 먼저
- 나머지는 사용자가 물어보게 자연스럽게 유도
- 세부사항은 질문을 받으면 그때 설명

**원칙 2: 호기심 자극**
- 답변 끝에 아직 말하지 않은 흥미로운 내용이 있음을 암시
- 사주에서 발견한 특이점이나 재미있는 점 언급 후 여운 남기기
- 사용자가 "그게 뭔데?" 하고 궁금해하게 만들기

**원칙 3: 완결짓지 않기**
- "결론적으로", "정리하면" 같은 마무리 표현 피하기
- 답변이 끝이 아니라 다음 대화의 시작점이 되게
- 여운을 남기고 대화가 이어질 수 있는 톤 유지

**목표: 사용자가 "더 알고 싶다"고 느끼게 만들어라**

### 문장 완성 (필수!)
- **절대로 문장 중간에 끊기지 마세요!**
- 응답 길이 제한에 걸릴 수 있으니, 핵심 내용을 앞에 배치
- 마지막 문장은 항상 완전한 형태로 마무리
- 시간이 부족하면 "~" 이모지로 끝내지 말고 짧게라도 마무리

### 사주 해석 원칙 (중요!)
- 일주(日柱)만 보지 말고 **팔자원국 전체**를 종합적으로 해석
- 년주, 월주, 일주, 시주의 천간/지지 모두 고려
- 십성, 신살, 합충형해파 등 전체 구조를 보고 판단
- 대운/세운의 흐름도 함께 언급

### 텍스트 스타일링 (마크다운 사용 가능!)
- 중요한 키워드(사주 용어): **굵게** (별 두개로 감싸기)
- 강조/기울임: *이탤릭* (별 하나로 감싸기)
- 취소선(~물결~)은 사용하지 마세요!
- 제목(#, ##)은 사용하지 마세요 - 대화체 유지

### 스타일 예시
- "오늘 **갑목**의 기운이 강해요" ✅
- "당신은 *타고난 리더*예요" ✅
- "## 오늘의 운세" ❌ (제목 사용 금지)

### 대화 스타일
- 사주 용어는 쉽게 풀어서 설명
- 문단 구분은 빈 줄로

### 후속 질문 생성 (필수!)
**모든 응답의 마지막에 반드시 후속 질문 3개를 [SUGGESTED_QUESTIONS] 태그로 포함하세요.**

형식 (반드시 이 형식 준수!):
[SUGGESTED_QUESTIONS]
질문1|질문2|질문3
[/SUGGESTED_QUESTIONS]

규칙:
- 현재 대화 맥락에서 자연스럽게 이어질 수 있는 질문 3개
- 단순 정보 요청보다 호기심을 자극하는 형태로
- 방금 답변에서 언급했지만 자세히 다루지 않은 주제 활용
- 간결하게 (각 질문 15자 이내)
- 질문은 파이프(|)로 구분, 한 줄로 작성

**질문 작성 원칙:**
- 사용자가 "이거 눌러봐야겠다" 싶은 질문
- 숨겨진/비밀/진짜/언제 같은 호기심 유발 단어 활용
- 개인화된 느낌 ("나의", "내 사주의" 등)
''');

    // 말투 가이드 추가
    buffer.writeln('## 말투');
    buffer.writeln('- ${tone.promptDescription}');
    buffer.writeln('- 이모지 $emojiLevel개 정도 사용');

    // 예시 추가
    if (examples.isNotEmpty) {
      buffer.writeln('\n## 대화 예시');
      for (final example in examples) {
        buffer.writeln('사용자: ${example['user']}');
        buffer.writeln('응답: ${example['assistant']}\n');
      }
    }

    // 개별 페르소나 금지사항 추가
    if (prohibitions.isNotEmpty) {
      buffer.writeln('\n## 추가 금지사항');
      for (final prohibition in prohibitions) {
        buffer.writeln('- $prohibition');
      }
    }

    return buffer.toString();
  }

  /// 랜덤 인사말 반환
  String getRandomGreeting() {
    if (greetings.isEmpty) return '안녕하세요!';
    return greetings[DateTime.now().millisecond % greetings.length];
  }

  /// JSON으로 변환 (캐시/로깅용)
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'tone': tone.name,
        'emojiLevel': emojiLevel,
        'category': category.name,
        'keywords': keywords,
      };

  @override
  String toString() => 'Persona($id: $name)';
}
