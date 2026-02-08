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
/// ## 실측 데이터 (2026-02 기준, Supabase DB)
///
/// ### Gemini API 비용
/// - 평균 $0.56/1M 토큰 (Gemini Flash)
/// - 일일 유저당 평균 API 비용: $0.03
/// - 10,000 토큰 보상 시 API 원가: $0.006
///
/// ### 유저 행동 (비프리미엄, daily_quota=20,000)
/// - 메시지당 평균 토큰: ~5,200 (assistant 응답 기준)
/// - 기본 쿼타 대화량: 20,000 / 5,200 = ~3.8회
/// - 광고 시청 유저 평균: 대화 19회/일, 광고 ~6번 클릭
/// - 기본 유저 평균: 대화 5회/일
///
/// ### AdMob 수익 (한국 시장)
/// - 네이티브 CPC: $0.05~$1.00 (평균 ~$0.25)
/// - 리워드 영상: eCPM $15~$30 (한국 iOS $29), 1회 $0.015~$0.030
/// - 인라인 배너: eCPM $0.50~$1.50
/// - 전면 광고: eCPM $5~$11 (한국 Android $11.23)
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
  static const int inlineAdMessageInterval = 4;

  /// 인라인 광고 최대 개수 (세션당) 이건그냥 많은게좋음
  static const int inlineAdMaxCount = 9999;
  /// 인라인 광고 최소 메시지 수 (이보다 적으면 광고 안 보임)
  /// 6 = 3번째 대화 후부터 광고 시작
  static const int inlineAdMinMessages = 4;

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
  //
  // [실측] 메시지당 평균 ~5,200 토큰, 일일 쿼타 20,000
  // 기본 대화 ~3.8회 → 광고로 추가 대화 확보
  //
  // [수익성] 네이티브 CPC ~$0.25, API 비용 $0.006/10K토큰
  //   → 10,000 토큰 보상: 순이익 $0.244/클릭 (마진 97.6%)
  //
  // [유저 패턴] 광고 시청 유저: 평균 6번 클릭 → 대화 19회/일

  /// 토큰 소진 → 영상 광고(Rewarded Video) 보상 토큰
  /// 한국 eCPM $15~$30 (iOS $29) → 1회 수익 $0.015~$0.030
  /// v2: 영상 광고 비활성화 (네이티브 클릭 CPC가 10x 더 수익성 높음)
  static const int depletedRewardTokensVideo = 0;

  /// 토큰 소진 → 네이티브 광고 보상 토큰 (클릭 시에만 지급)
  /// CPC ~$0.25 수익 vs API 원가 $0.0084 → 순이익 $0.24/클릭
  /// 15,000 토큰 = 대화 ~2.9회 추가 (소진 후 재시작용, 넉넉하게)
  static const int depletedRewardTokensNative = 15000;

  /// 인터벌(대화 중) 네이티브 광고 클릭 시 보상 토큰
  /// CPC ~$0.25 수익 vs API 원가 $0.006 → 순이익 $0.244/클릭
  /// 10,000 토큰 = 대화 ~1.9회 추가
  /// 광고 6번 클릭으로 기본 3.8회 → 총 ~19회 대화 가능
  static const int intervalClickRewardTokens = 10000;

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
