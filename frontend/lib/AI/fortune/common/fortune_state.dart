/// # Fortune State 정의
///
/// ## 개요
/// 운세 분석의 상태를 나타내는 열거형
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/common/fortune_state.dart`

/// 운세 분석 상태
///
/// ## 상태 흐름
/// ```
/// initial → waitingForSajuBase → ready → analyzing → completed
///                                   ↓
///                                 error
/// ```
enum FortuneState {
  /// 초기 상태
  /// - 아직 아무 작업도 시작되지 않음
  initial,

  /// saju_base 분석 대기 중
  /// - saju_base가 없거나 분석 중일 때
  /// - UI: 스켈레톤 로딩 + "평생 운세 분석 중..." 메시지
  waitingForSajuBase,

  /// saju_base 준비 완료, 운세 분석 가능
  /// - 운세 캐시 확인 후 분석 실행
  ready,

  /// 운세 분석 진행 중
  /// - GPT-5-mini API 호출 중
  /// - UI: 프로그레스 바
  analyzing,

  /// 분석 완료
  /// - 결과 표시 가능
  completed,

  /// 에러 발생
  /// - 에러 메시지 표시
  error,
}

/// FortuneState 확장 메서드
extension FortuneStateExtension on FortuneState {
  /// 로딩 상태인지 확인
  bool get isLoading =>
      this == FortuneState.waitingForSajuBase ||
      this == FortuneState.analyzing;

  /// 완료 상태인지 확인
  bool get isCompleted => this == FortuneState.completed;

  /// 에러 상태인지 확인
  bool get isError => this == FortuneState.error;

  /// 분석 가능 상태인지 확인
  bool get canAnalyze => this == FortuneState.ready;

  /// 상태별 UI 메시지
  String get displayMessage {
    switch (this) {
      case FortuneState.initial:
        return '준비 중...';
      case FortuneState.waitingForSajuBase:
        return '평생 운세 분석 중...';
      case FortuneState.ready:
        return '분석 준비 완료';
      case FortuneState.analyzing:
        return '운세 분석 중...';
      case FortuneState.completed:
        return '분석 완료';
      case FortuneState.error:
        return '오류 발생';
    }
  }
}
