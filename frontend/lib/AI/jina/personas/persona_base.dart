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
  /// 기본 시스템 프롬프트에 예시와 금지사항을 추가합니다.
  String buildFullSystemPrompt() {
    final buffer = StringBuffer(systemPrompt);

    // 말투 가이드 추가
    buffer.writeln('\n\n## 말투');
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

    // 금지사항 추가
    if (prohibitions.isNotEmpty) {
      buffer.writeln('\n## 금지사항');
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
