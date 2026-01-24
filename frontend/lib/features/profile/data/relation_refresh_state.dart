/// 관계 데이터 갱신 상태 holder (Provider 아님!)
///
/// Provider를 사용하면 값 변경 시 모든 listener에게 notify되어
/// navigation 중 defunct widget 에러가 발생함.
/// static 변수는 notify하지 않으므로 안전함.
class RelationRefreshState {
  /// 갱신이 필요한지 여부
  static bool needsRefresh = false;

  /// 갱신 플래그 설정 (화면 이동 전 호출)
  static void markNeedsRefresh() {
    needsRefresh = true;
  }

  /// 갱신 플래그 확인 및 클리어 (새 화면에서 호출)
  static bool checkAndClear() {
    if (needsRefresh) {
      needsRefresh = false;
      return true;
    }
    return false;
  }
}
