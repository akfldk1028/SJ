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
/// ### Gemini API 비용 (2026-03, Gemini 3 Flash)
/// - input: $0.50/1M tokens, output: $3.00/1M tokens
/// - v52: tokens_used = completion only (prompt 제외)
/// - 메시지당 ~400 completion tokens, Gemini 비용 ~$0.0012/메시지
/// - 30K completion 보상 비용: ~$0.09 (completion) + ~$0.02 (prompt) = ~$0.11
///
/// ### 유저 행동 (비프리미엄, daily_quota=20,000, completion-only 카운트)
/// - 메시지당 평균 ~400 completion tokens
/// - 기본 쿼타 대화량: 20,000 / 400 = ~50회
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

  /// 하루 최대 전면 광고 횟수
  static const int interstitialDailyLimit = 15;

  /// 전면 광고 쿨다운 (초)
  static const int interstitialCooldownSeconds = 60;

  /// 새 세션 시작 시 전면 광고 표시 여부
  static const bool showInterstitialOnNewSession = true;

  /// 새 세션 전면 광고 하루 최대 횟수
  static const int newSessionInterstitialDailyLimit = 5;

  // ==================== 토큰 보상 설정 ====================
  // ★ 여기서 보상 토큰 값 조정 ★
  //
  // [v52] completion-only 카운트 전환 (2026-03-17)
  // - tokens_used = candidatesTokenCount (prompt 제외)
  // - 메시지당 ~400 completion tokens (이전 ~5,200 total)
  // - 30K completion = ~50메시지, Gemini 비용 ~$0.11
  // - 광고 11회($0.01×11=$0.11)로 커버
  //
  // [Gemini 3 Flash 가격] input $0.50/1M, output $3.00/1M
  // [유저 패턴] 광고 시청 유저: 평균 6번 클릭 → 대화 19회/일

  /// 토큰 소진 → 리워드 영상 후 충전할 토큰량 (모든 네트워크 공통)
  /// 5K completion tokens ≈ 9메시지, API 비용 ~$0.07
  static const int depletedRewardTokensVideo = 5000;

  /// 토큰 소진 → 광고 로드 실패 시 최소 fallback 토큰
  /// 500 tokens ≈ 1회 대화 (악용 방지: 비행기모드→로드실패→무료토큰 반복 차단)
  static const int depletedFallbackTokens = 500;

  /// 토큰 소진 → 네이티브 광고 보상 토큰: 0 (정책 위반 방지)
  /// v3: 네이티브 클릭 → 토큰 보상 제거 (AdMob 인센티브화 클릭 정책 위반)
  static const int depletedRewardTokensNative = 0;

  /// 인터벌(대화 중) 네이티브 광고 클릭 시 보상 토큰: 0 (정책 위반 방지)
  /// v3: 네이티브 클릭 → 토큰 보상 제거 (AdMob 인센티브화 클릭 정책 위반)
  static const int intervalClickRewardTokens = 0;

  // ==================== AdFit 보상 설정 ====================
  // AdFit 운영정책 5.2: 광고 클릭 유도/보상 약속 금지
  // → 네이티브 클릭 토큰 보상 제거 (정책 위반)

  /// AdFit 네이티브 클릭 보상 토큰: 0 (AdFit 운영정책 5.2 위반 방지)
  static const int adfitNativeClickRewardTokens = 0;

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
