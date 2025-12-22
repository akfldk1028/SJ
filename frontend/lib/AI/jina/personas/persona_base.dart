/// 페르소나 기본 클래스
/// 담당: Jina

// TODO: 구현 예정
// - [ ] 페르소나 인터페이스 정의
// - [ ] 공통 속성 정의

abstract class PersonaBase {
  String get name;
  String get description;
  String get systemPrompt;
  String get toneStyle; // 반말/존댓말
  int get emojiCount; // 이모지 개수 권장
}
