/// 광고 전략 설정
/// 사주 앱 비즈니스 맞춤 수익화 전략
library;

/// 채팅 내 광고 유형
enum ChatAdType {
  /// Inline Adaptive Banner (간단, $1~3 eCPM)
  inlineBanner,

  /// Native Ad Medium (채팅 버블 스타일, $3~15 eCPM)
  nativeMedium,

  /// Native Ad Compact (작은 크기, $2~8 eCPM)
  nativeCompact,
}

/// 광고 표시 전략
///
/// ## 수익화 포인트
///
/// ### 1. 배너 광고 (기본 수익)
/// - 위치: 메인 화면 하단 (BottomNavigationBar 위)
/// - 타이밍: 상시 노출
/// - eCPM: $0.5~2 (낮지만 impression 수 많음)
///
/// ### 2. 전면 광고 (중간 수익)
/// - 위치: 화면 전환 시
/// - 타이밍:
///   - 사주 분석 결과 보기 전
///   - 채팅 N개 메시지 후
///   - 새 채팅 세션 시작 시 (하루 3회 제한)
/// - eCPM: $2~10
///
/// ### 3. 보상형 광고 (높은 수익)
/// - 위치: 프리미엄 기능 해제
/// - 타이밍:
///   - 상세 사주 분석 보기
///   - 일일 무료 채팅 횟수 초과
///   - 궁합 분석 무료 체험
/// - eCPM: $10~50 (가장 높음)
abstract class AdStrategy {
  AdStrategy._();

  // ==================== 배너 광고 ====================

  /// 배너 광고 표시 화면
  static const List<String> bannerScreens = [
    '/home',
    '/saju/chat',
    '/relationship',
  ];

  // ==================== 채팅 내 광고 ====================

  /// 채팅 내 광고 유형 설정
  /// - inlineBanner: 간단한 배너 ($1~3 eCPM)
  /// - nativeMedium: 채팅 버블 스타일 ($3~15 eCPM) ★ 추천
  /// - nativeCompact: 컴팩트 네이티브 ($2~8 eCPM)
  static const ChatAdType chatAdType = ChatAdType.nativeMedium;

  /// 인라인 광고 표시 간격 (메시지 수)
  /// 6 = 3번째 대화 후 광고 1회 (유저+AI = 2메시지 × 3 = 6)
  static const int inlineAdMessageInterval = 6;

  /// 인라인 광고 최대 개수 (세션당) 이건그냥 많은게좋음
  static const int inlineAdMaxCount = 9999;
  /// 인라인 광고 최소 메시지 수 (이보다 적으면 광고 안 보임)
  /// 6 = 3번째 대화 후부터 광고 시작
  static const int inlineAdMinMessages = 6;

  // ==================== 전면 광고 ====================

  /// 전면 광고 표시 간격 (메시지 수)
  static const int interstitialMessageInterval = 5;

  /// 하루 최대 전면 광고 횟수 (9999 = 무제한)
  static const int interstitialDailyLimit = 9999;

  /// 전면 광고 쿨다운 (초) - 0 = 제한 없음
  static const int interstitialCooldownSeconds = 0;

  /// 새 세션 시작 시 전면 광고 표시 여부
  static const bool showInterstitialOnNewSession = true;

  /// 새 세션 전면 광고 하루 최대 횟수 (9999 = 무제한)
  static const int newSessionInterstitialDailyLimit = 9999;

  // ==================== 토큰 보상 설정 ====================
  // ★ 여기서 보상 토큰 값 조정 ★
  // 1교환(유저+AI) ≈ 7,200 토큰

  /// 토큰 소진 → 영상 광고(Rewarded Video) 보상 토큰
  /// eCPM $15~30 → 1회 수익 $0.015~0.030
  static const int depletedRewardTokensVideo = 20000;

  /// 토큰 소진 → 네이티브 광고 보상 토큰 (클릭 시에만 지급)
  /// Native eCPM $3~7 → 클릭 시 CPC $0.10~0.50
  static const int depletedRewardTokensNative = 30000;

  /// 인터벌(대화 중) 네이티브 광고 클릭 시 보상 토큰
  static const int intervalClickRewardTokens = 30000;

  // ==================== 프리미엄 기능 ====================

  /// 광고 없이 사용 가능한 프리미엄 기능 목록
  static const List<String> premiumFeatures = [
    'detailed_saju_analysis', // 상세 사주 분석
    'compatibility_analysis', // 궁합 분석
    'yearly_fortune', // 연간 운세
    'career_advice', // 직업/사업 조언
    'ad_free', // 광고 제거
  ];
}

/// 광고 표시 조건 체크 결과
class AdCheckResult {
  final bool shouldShow;
  final String? reason;

  const AdCheckResult({
    required this.shouldShow,
    this.reason,
  });

  const AdCheckResult.show() : shouldShow = true, reason = null;

  const AdCheckResult.skip(this.reason) : shouldShow = false;
}
