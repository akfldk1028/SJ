import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../ad/ad_config.dart';
import '../../ad/ad_service.dart';
import '../../ad/feature_unlock_service.dart';
import '../../AI/fortune/common/korea_date_utils.dart';
import '../../purchase/providers/purchase_provider.dart';
import '../../router/routes.dart';

/// 공통 카테고리 데이터 인터페이스
/// v8.2: 평생운세용 상세 필드 추가
/// v9.4: 카테고리별 상세 필드 전체 추가 (DB 필드 100% 매핑)
class CategoryData {
  final String title;
  final int score;
  final String reading;
  final String? summary;
  final List<int>? bestMonths;
  final List<int>? cautionMonths;
  final String? actionTip;
  final List<String>? focusAreas;

  // v8.2: 평생운세 상세 필드
  final String? advice;                    // 조언
  final List<String>? cautions;            // 주의사항
  final List<String>? strengths;           // 강점
  final List<String>? weaknesses;          // 약점
  final String? timing;                    // 타이밍 정보
  final List<String>? suitableFields;      // 적합 분야
  final List<String>? unsuitableFields;    // 비적합 분야

  // v9.4: 카테고리별 상세 필드 추가
  // 직업운
  final String? workStyle;                 // 업무 스타일
  final String? leadershipPotential;       // 리더십 잠재력

  // 연애운
  final String? datingPattern;             // 연애 패턴
  final String? attractionStyle;           // 끌리는 유형
  final List<String>? idealPartnerTraits;  // 이상형 특성

  // 재물운
  final String? overallTendency;           // 전반적 경향
  final String? earningStyle;              // 돈 버는 방식
  final String? spendingTendency;          // 소비 성향
  final String? investmentAptitude;        // 투자 적성

  // 사업운
  final String? entrepreneurshipAptitude;  // 창업 적성
  final String? businessPartnerTraits;     // 사업 파트너 특성

  // 결혼운
  final String? spousePalaceAnalysis;      // 배우자궁 분석
  final String? spouseCharacteristics;     // 배우자 특성
  final String? marriedLifeTendency;       // 결혼 생활 경향

  // 건강운
  final String? mentalHealth;              // 정신 건강
  final List<String>? lifestyleAdvice;     // 생활 습관 조언

  const CategoryData({
    required this.title,
    required this.score,
    required this.reading,
    this.summary,
    this.bestMonths,
    this.cautionMonths,
    this.actionTip,
    this.focusAreas,
    this.advice,
    this.cautions,
    this.strengths,
    this.weaknesses,
    this.timing,
    this.suitableFields,
    this.unsuitableFields,
    // v9.4: 카테고리별 상세 필드
    this.workStyle,
    this.leadershipPotential,
    this.datingPattern,
    this.attractionStyle,
    this.idealPartnerTraits,
    this.overallTendency,
    this.earningStyle,
    this.spendingTendency,
    this.investmentAptitude,
    this.entrepreneurshipAptitude,
    this.businessPartnerTraits,
    this.spousePalaceAnalysis,
    this.spouseCharacteristics,
    this.marriedLifeTendency,
    this.mentalHealth,
    this.lifestyleAdvice,
  });
}

/// 분야별 운세 카테고리 칩 섹션 (공통)
///
/// - 카테고리가 칩으로 표시되고 탭하면 펼쳐짐
/// - 잠긴 카테고리는 광고를 봐야 해제
/// - fortuneType으로 운세 종류 구분
class FortuneCategoryChipSection extends ConsumerStatefulWidget {
  /// 운세 타입 (lifetime, yearly_2025, yearly_2026, monthly)
  final String fortuneType;

  /// 카테고리 데이터 맵 (key: career, wealth 등)
  final Map<String, CategoryData> categories;

  /// 섹션 제목
  final String? title;

  /// 상세 내용 표시 여부
  final bool showDetailedContent;

  /// 현재 활성 프로필 ID (해금 추적용)
  final String? profileId;

  const FortuneCategoryChipSection({
    super.key,
    required this.fortuneType,
    required this.categories,
    this.title,
    this.showDetailedContent = true,
    this.profileId,
  });

  @override
  ConsumerState<FortuneCategoryChipSection> createState() =>
      _FortuneCategoryChipSectionState();
}

class _FortuneCategoryChipSectionState
    extends ConsumerState<FortuneCategoryChipSection> {
  /// 현재 펼쳐진 카테고리
  String? _expandedCategory;

  /// 광고 로딩 중 플래그
  bool _isLoadingAd = false;

  /// 현재 로딩 중인 카테고리 키
  String? _loadingCategoryKey;

  /// [Static] 세션 기반 잠금해제 상태 - 앱 종료 전까지 유지!
  /// fortuneType별로 구분 (lifetime, yearly_2025, yearly_2026, monthly)
  static final Map<String, Set<String>> _sessionUnlockedCategories = {};

  /// 현재 fortuneType의 해금된 카테고리 Set
  Set<String> get _unlockedCategories =>
      _sessionUnlockedCategories[widget.fortuneType] ?? {};

  @override
  void initState() {
    super.initState();
    // static 변수 초기화 (fortuneType별로)
    _sessionUnlockedCategories[widget.fortuneType] ??= {};
    // DB에서 이미 해금된 카테고리 로드
    _loadUnlockedCategoriesFromDb();
  }

  /// DB에서 이미 해금된 카테고리 로드
  Future<void> _loadUnlockedCategoriesFromDb() async {
    final unlockInfo = _parseFortuneType();
    if (unlockInfo == null) return;

    // 모든 카테고리에 대해 해금 상태 확인
    for (final categoryKey in widget.categories.keys) {
      final isUnlocked = await FeatureUnlockService.instance.isUnlocked(
        featureType: unlockInfo.featureType,
        featureKey: categoryKey,
        targetYear: unlockInfo.targetYear,
        targetMonth: unlockInfo.targetMonth,
      );
      if (isUnlocked && mounted) {
        _sessionUnlockedCategories[widget.fortuneType] ??= {};
        _sessionUnlockedCategories[widget.fortuneType]!.add(categoryKey);
      }
    }
    if (mounted) setState(() {});
  }

  /// fortuneType에서 해금 정보 파싱
  /// - yearly_2026 → FeatureType.categoryYearly, year=2026, month=0
  /// - monthly → FeatureType.categoryMonthly, year=현재연도, month=현재월
  /// - lifetime → FeatureType.lifetime, year=현재연도, month=0
  ({FeatureType featureType, int targetYear, int targetMonth})? _parseFortuneType() {
    final fortuneType = widget.fortuneType;

    if (fortuneType.startsWith('yearly_')) {
      // yearly_2026 형태
      final yearStr = fortuneType.replaceFirst('yearly_', '');
      final year = int.tryParse(yearStr);
      if (year != null) {
        return (
          featureType: FeatureType.categoryYearly,
          targetYear: year,
          targetMonth: 0,
        );
      }
    } else if (fortuneType == 'monthly') {
      return (
        featureType: FeatureType.categoryMonthly,
        targetYear: KoreaDateUtils.currentYear,
        targetMonth: KoreaDateUtils.currentMonth,
      );
    } else if (fortuneType == 'lifetime') {
      return (
        featureType: FeatureType.lifetime,
        targetYear: KoreaDateUtils.currentYear,
        targetMonth: 0,
      );
    }

    // 기본값: 연간 운세
    return (
      featureType: FeatureType.categoryYearly,
      targetYear: KoreaDateUtils.currentYear,
      targetMonth: 0,
    );
  }

  /// 카테고리 잠금 해제 (세션 메모리 - 앱 종료 시 초기화!)
  void _unlockCategory(String category) {
    _sessionUnlockedCategories[widget.fortuneType] ??= {};
    _sessionUnlockedCategories[widget.fortuneType]!.add(category);
    if (mounted) {
      setState(() {}); // UI 갱신
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Text(
          widget.title ?? 'common.categoryFortune'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // 안내 텍스트
        Text(
          'common.tapToViewFortune'.tr(),
          style: TextStyle(
            fontSize: 13,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // 카테고리 칩들
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.categories.entries.map((entry) {
            final key = entry.key;
            final cat = entry.value;
            final isUnlocked = _unlockedCategories.contains(key);
            final isExpanded = _expandedCategory == key;
            final categoryName = _getCategoryName(key);

            return _buildCategoryChip(
              theme: theme,
              categoryKey: key,
              categoryName: categoryName,
              score: cat.score,
              isUnlocked: isUnlocked,
              isExpanded: isExpanded,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 펼쳐진 카테고리 내용
        if (_expandedCategory != null && widget.showDetailedContent) ...[
          _buildExpandedContent(theme, _expandedCategory!),
        ],
      ],
    );
  }

  Widget _buildCategoryChip({
    required AppThemeExtension theme,
    required String categoryKey,
    required String categoryName,
    required int score,
    required bool isUnlocked,
    required bool isExpanded,
  }) {
    return GestureDetector(
      onTap: () => _onChipTap(categoryKey, isUnlocked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isExpanded
              ? theme.primaryColor.withValues(alpha: 0.15)
              : isUnlocked
                  ? theme.cardColor
                  : theme.cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? theme.primaryColor
                : isUnlocked
                    ? theme.textMuted.withValues(alpha: 0.3)
                    : theme.textMuted.withValues(alpha: 0.2),
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 잠금 아이콘 또는 로딩 스피너
            if (!isUnlocked) ...[
              if (_loadingCategoryKey == categoryKey)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.textSecondary,
                  ),
                )
              else
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: theme.textSecondary,
                ),
              const SizedBox(width: 4),
            ],

            // 카테고리 이름
            Text(
              categoryName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
                color: isUnlocked ? theme.textPrimary : theme.textSecondary,
              ),
            ),

            // 점수 (해제된 경우)
            if (isUnlocked) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getScoreColor(score).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'common.scoreUnit'.tr(namedArgs: {'score': '$score'}),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getScoreColor(score),
                  ),
                ),
              ),
            ],

            // 펼침 아이콘
            if (isUnlocked) ...[
              const SizedBox(width: 4),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: theme.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(AppThemeExtension theme, String categoryKey) {
    final cat = widget.categories[categoryKey];
    if (cat == null) return const SizedBox.shrink();

    final categoryName = _getCategoryName(categoryKey);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Text(
                categoryName,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(cat.score).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'common.scoreUnit'.tr(namedArgs: {'score': '${cat.score}'}),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getScoreColor(cat.score),
                  ),
                ),
              ),
              const Spacer(),
              // 닫기 버튼
              GestureDetector(
                onTap: () => setState(() => _expandedCategory = null),
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary (있으면)
          if (cat.summary != null && cat.summary!.isNotEmpty) ...[
            Text(
              cat.summary!,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 내용
          if (cat.reading.isNotEmpty)
            Text(
              cat.reading,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondary,
                height: 1.8,
              ),
            ),

          // 좋은 달 / 주의할 달
          if (cat.bestMonths != null && cat.bestMonths!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'common.bestMonths'.tr(namedArgs: {'months': cat.bestMonths!.map((m) => 'common.monthLabel'.tr(namedArgs: {'month': '$m'})).join(', ')}),
              style: TextStyle(
                fontSize: 14,
                color: Colors.green.shade700,
                height: 1.6,
              ),
            ),
          ],
          if (cat.cautionMonths != null && cat.cautionMonths!.isNotEmpty)
            Text(
              'common.cautionMonths'.tr(namedArgs: {'months': cat.cautionMonths!.map((m) => 'common.monthLabel'.tr(namedArgs: {'month': '$m'})).join(', ')}),
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade700,
                height: 1.6,
              ),
            ),

          // 실천 팁
          if (cat.actionTip != null && cat.actionTip!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.actionTip'.tr(), cat.actionTip!),
          ],

          // 집중 영역
          if (cat.focusAreas != null && cat.focusAreas!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'common.focusAreas'.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            ...cat.focusAreas!.map((area) => _buildListItem(theme, area)),
          ],

          // ═══════════════════════════════════════════════════════════════
          // v8.2: 평생운세 상세 필드 (조언, 주의사항, 강점/약점 등)
          // ═══════════════════════════════════════════════════════════════

          // 조언 (가장 중요!)
          if (cat.advice != null && cat.advice!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'common.advice'.tr(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.advice!,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 타이밍
          if (cat.timing != null && cat.timing!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.timing'.tr(), cat.timing!),
          ],

          // 강점
          if (cat.strengths != null && cat.strengths!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'common.strengths'.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 4),
            ...cat.strengths!.map((s) => _buildListItem(theme, s)),
          ],

          // 약점
          if (cat.weaknesses != null && cat.weaknesses!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'common.weaknesses'.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 4),
            ...cat.weaknesses!.map((w) => _buildListItem(theme, w)),
          ],

          // 적합 분야
          if (cat.suitableFields != null && cat.suitableFields!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'common.suitableFields'.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            ...cat.suitableFields!.map((f) => _buildListItem(theme, f)),
          ],

          // 비적합 분야
          if (cat.unsuitableFields != null && cat.unsuitableFields!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'common.unsuitableFields'.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            ...cat.unsuitableFields!.map((f) => _buildListItem(theme, f)),
          ],

          // 주의사항 (cautions 리스트)
          if (cat.cautions != null && cat.cautions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        size: 18,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'common.cautions'.tr(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...cat.cautions!.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade800,
                            height: 1.6,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            c,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade800,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],

          // ═══════════════════════════════════════════════════════════════
          // v9.4: 카테고리별 상세 필드 (DB 필드 100% 표시)
          // ═══════════════════════════════════════════════════════════════

          // 직업운 전용 필드
          if (cat.workStyle != null && cat.workStyle!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.workStyle'.tr(), cat.workStyle!),
          ],
          if (cat.leadershipPotential != null && cat.leadershipPotential!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.leadershipPotential'.tr(), cat.leadershipPotential!),
          ],

          // 연애운 전용 필드
          if (cat.datingPattern != null && cat.datingPattern!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.datingPattern'.tr(), cat.datingPattern!),
          ],
          if (cat.attractionStyle != null && cat.attractionStyle!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.attractionStyle'.tr(), cat.attractionStyle!),
          ],
          if (cat.idealPartnerTraits != null && cat.idealPartnerTraits!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'common.idealPartnerTraits'.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.pink.shade600,
              ),
            ),
            const SizedBox(height: 4),
            ...cat.idealPartnerTraits!.map((t) => _buildListItem(theme, t)),
          ],

          // 재물운 전용 필드
          if (cat.overallTendency != null && cat.overallTendency!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.overallTendency'.tr(), cat.overallTendency!),
          ],
          if (cat.earningStyle != null && cat.earningStyle!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.earningStyle'.tr(), cat.earningStyle!),
          ],
          if (cat.spendingTendency != null && cat.spendingTendency!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.spendingTendency'.tr(), cat.spendingTendency!),
          ],
          if (cat.investmentAptitude != null && cat.investmentAptitude!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.investmentAptitude'.tr(), cat.investmentAptitude!),
          ],

          // 사업운 전용 필드
          if (cat.entrepreneurshipAptitude != null && cat.entrepreneurshipAptitude!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.entrepreneurshipAptitude'.tr(), cat.entrepreneurshipAptitude!),
          ],
          if (cat.businessPartnerTraits != null && cat.businessPartnerTraits!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.businessPartnerTraits'.tr(), cat.businessPartnerTraits!),
          ],

          // 결혼운 전용 필드
          if (cat.spousePalaceAnalysis != null && cat.spousePalaceAnalysis!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.spousePalaceAnalysis'.tr(), cat.spousePalaceAnalysis!),
          ],
          if (cat.spouseCharacteristics != null && cat.spouseCharacteristics!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.spouseCharacteristics'.tr(), cat.spouseCharacteristics!),
          ],
          if (cat.marriedLifeTendency != null && cat.marriedLifeTendency!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.marriedLifeTendency'.tr(), cat.marriedLifeTendency!),
          ],

          // 건강운 전용 필드
          if (cat.mentalHealth != null && cat.mentalHealth!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubSection(theme, 'common.mentalHealth'.tr(), cat.mentalHealth!),
          ],
          if (cat.lifestyleAdvice != null && cat.lifestyleAdvice!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'common.lifestyleAdvice'.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade600,
              ),
            ),
            const SizedBox(height: 4),
            ...cat.lifestyleAdvice!.map((a) => _buildListItem(theme, a)),
          ],
        ],
      ),
    );
  }

  Widget _buildSubSection(AppThemeExtension theme, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 14,
            color: theme.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(AppThemeExtension theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondary,
              height: 1.6,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onChipTap(String categoryKey, bool isUnlocked) async {
    if (isUnlocked) {
      // 이미 해제된 카테고리 - 토글
      setState(() {
        if (_expandedCategory == categoryKey) {
          _expandedCategory = null;
        } else {
          _expandedCategory = categoryKey;
        }
      });
    } else {
      // 잠긴 카테고리 - 보상형 광고 후 해금
      await _showRewardedAndUnlock(categoryKey);
    }
  }

  /// 보상형 광고 표시 후 카테고리 해금
  ///
  /// v4: 전면 광고 → 보상형 광고로 전환
  /// showRewardedAdWithUnlock 내부에서 FeatureUnlockService 해금 처리
  Future<void> _showRewardedAndUnlock(String categoryKey) async {
    if (_isLoadingAd) return;

    final categoryName = _getCategoryName(categoryKey);

    // 프리미엄 유저는 광고 없이 바로 해제
    final isPremium = ref.read(purchaseNotifierProvider.notifier).isPremium;
    if (isPremium) {
      _unlockAndExpand(categoryKey, categoryName);
      return;
    }

    // 웹에서는 광고 스킵하고 바로 해제 (테스트용)
    if (kIsWeb) {
      _unlockAndExpand(categoryKey, categoryName, suffix: ' (웹 테스트)');
      return;
    }

    // 광고 킬스위치 OFF → 구매 안내
    if (!adEnabled) {
      _showPurchaseDialog(categoryName);
      return;
    }

    setState(() {
      _isLoadingAd = true;
      _loadingCategoryKey = categoryKey;
    });

    final unlockInfo = _parseFortuneType();

    // 보상형 광고 로드 대기 (최대 5초) → 표시
    await AdService.instance.waitForRewardedLoad();
    final shown = await AdService.instance.showRewardedAdWithUnlock(
      onRewarded: (amount, type) {
        // 보상 콜백 후 해금
        if (mounted) {
          setState(() {
            _isLoadingAd = false;
            _loadingCategoryKey = null;
          });
          _unlockAndExpand(categoryKey, categoryName);
        }
      },
      featureType: unlockInfo?.featureType,
      featureKey: categoryKey,
      targetYear: unlockInfo?.targetYear,
      targetMonth: unlockInfo?.targetMonth,
      profileId: widget.profileId,
    );

    if (!shown) {
      // 보상형 광고 로드 안 됨 (AdMob + Unity 둘 다 실패) → 구매 안내
      if (mounted) {
        setState(() {
          _isLoadingAd = false;
          _loadingCategoryKey = null;
        });
        _showPurchaseDialog(categoryName);
      }
    }
  }

  /// 해금 + 펼치기 + SnackBar 공통 처리
  void _unlockAndExpand(String categoryKey, String categoryName, {String suffix = ''}) {
    _unlockCategory(categoryKey);
    if (mounted) {
      setState(() {
        _expandedCategory = categoryKey;
        _isLoadingAd = false;
      });
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(suffix.isEmpty
                ? 'common.unlocked'.tr(namedArgs: {'name': categoryName})
                : 'common.unlockedWebTest'.tr(namedArgs: {'name': categoryName})),
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (_) {}
    }
  }

  /// 광고 실패 시 구매 안내 다이얼로그
  void _showPurchaseDialog(String categoryName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('common.premiumViewNow'.tr()),
        content: Text(
          'common.premiumAdNotAvailable'.tr(namedArgs: {'name': categoryName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.close'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(Routes.settingsPremium);
            },
            child: Text('common.viewPremium'.tr()),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String key) {
    final names = {
      'career': 'fortune_common.catCareer'.tr(),
      'work': 'fortune_common.catWork'.tr(),
      'business': 'fortune_common.catBusiness'.tr(),
      'wealth': 'fortune_common.catWealth'.tr(),
      'love': 'fortune_common.catLove'.tr(),
      'marriage': 'fortune_common.catMarriage'.tr(),
      'study': 'fortune_common.catStudy'.tr(),
      'health': 'fortune_common.catHealth'.tr(),
      'overall': 'fortune_common.catOverall'.tr(),
      'family': 'fortune_common.catFamily'.tr(),
      'social': 'fortune_common.catSocial'.tr(),
    };
    return names[key] ?? key;
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}
