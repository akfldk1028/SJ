import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../router/routes.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/providers/relation_provider.dart';
import '../../../compatibility/presentation/providers/compatibility_provider.dart';

/// 궁합 프로모 배너 카드
///
/// - 인연 0명: "인연 등록하고 궁합 보기" → 인연 추가 화면
/// - 인연 1명+, 궁합 0건: "궁합 분석 해보세요" → 궁합 채팅
/// - 궁합 1건+: 최근 결과 요약 표시 → 궁합 상세/목록
class CompatibilityPromoCard extends ConsumerWidget {
  const CompatibilityPromoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = context.horizontalPadding;
    final activeProfileAsync = ref.watch(activeProfileProvider);

    return activeProfileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return _CompatibilityPromoContent(
          profileId: profile.id,
          horizontalPadding: horizontalPadding,
        );
      },
    );
  }
}

class _CompatibilityPromoContent extends ConsumerWidget {
  final String profileId;
  final double horizontalPadding;

  const _CompatibilityPromoContent({
    required this.profileId,
    required this.horizontalPadding,
  });

  static const _promoColor = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final relationsAsync = ref.watch(relationListProvider(profileId));
    final compatCountAsync = ref.watch(compatibilityCountProvider(profileId));

    // 로딩/에러 중에는 숨김
    if (relationsAsync is AsyncLoading || compatCountAsync is AsyncLoading ||
        relationsAsync is AsyncError || compatCountAsync is AsyncError) {
      return const SizedBox.shrink();
    }
    final relationsCount = relationsAsync.requireValue.length;
    final compatCount = compatCountAsync.requireValue;

    if (relationsCount == 0) {
      // 인연 0명 → 인연 등록 유도
      return _buildRegisterPromoBanner(context, theme);
    } else if (compatCount == 0) {
      // 인연 있지만 궁합 0건 → 궁합 분석 유도
      return _buildAnalyzePromoBanner(context, theme);
    } else {
      // 궁합 1건+ → 최근 결과 요약
      return _buildResultSummaryBanner(context, ref, theme);
    }
  }

  /// 인연 등록 유도 배너
  Widget _buildRegisterPromoBanner(BuildContext context, AppThemeExtension theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GestureDetector(
        onTap: () => context.push('${Routes.relationshipAdd}?from=compatibility'),
        child: Container(
          padding: EdgeInsets.all(context.scaledPadding(16)),
          decoration: _bannerDecoration(theme),
          child: Row(
            children: [
              _buildIconBox(context, Icons.person_add_alt_1_rounded),
              SizedBox(width: context.scaledPadding(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'menu.compatPromoRegisterTitle'.tr(),
                      style: TextStyle(
                        fontSize: context.scaledFont(14),
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    SizedBox(height: context.scaledPadding(2)),
                    Text(
                      'menu.compatPromoRegisterSubtitle'.tr(),
                      style: TextStyle(
                        fontSize: context.scaledFont(12),
                        color: theme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.scaledPadding(8)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _promoColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'menu.compatPromoRegister'.tr(),
                  style: TextStyle(
                    fontSize: context.scaledFont(12),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 궁합 분석 유도 배너
  Widget _buildAnalyzePromoBanner(BuildContext context, AppThemeExtension theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GestureDetector(
        onTap: () => context.push('${Routes.sajuChat}?type=compatibility'),
        child: Container(
          padding: EdgeInsets.all(context.scaledPadding(16)),
          decoration: _bannerDecoration(theme),
          child: Row(
            children: [
              _buildIconBox(context, Icons.favorite_rounded),
              SizedBox(width: context.scaledPadding(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'menu.compatPromoAnalyzeTitle'.tr(),
                      style: TextStyle(
                        fontSize: context.scaledFont(14),
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    SizedBox(height: context.scaledPadding(2)),
                    Text(
                      'menu.compatPromoAnalyzeSubtitle'.tr(),
                      style: TextStyle(
                        fontSize: context.scaledFont(12),
                        color: theme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.scaledPadding(8)),
              Icon(
                Icons.chevron_right_rounded,
                color: _promoColor.withValues(alpha: 0.6),
                size: context.scaledIcon(24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 궁합 결과 요약 배너
  Widget _buildResultSummaryBanner(BuildContext context, WidgetRef ref, AppThemeExtension theme) {
    final recentAsync = ref.watch(recentCompatibilityAnalysesProvider(profileId, limit: 1));

    return recentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (analyses) {
        if (analyses.isEmpty) return const SizedBox.shrink();
        final latest = analyses.first;
        final score = latest.overallScore ?? 0;
        final scoreColor = _getScoreColor(score);
        final targetName = latest.profile2?.displayName ?? '상대방';

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: GestureDetector(
            onTap: () => context.push('${Routes.compatibilityDetail}?analysisId=${latest.id}'),
            child: Container(
              padding: EdgeInsets.all(context.scaledPadding(16)),
              decoration: _bannerDecoration(theme, accentColor: scoreColor),
              child: Row(
                children: [
                  // 점수 원형
                  Container(
                    width: context.scaledSize(44),
                    height: context.scaledSize(44),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scoreColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$score',
                        style: TextStyle(
                          fontSize: context.scaledFont(18),
                          fontWeight: FontWeight.w700,
                          color: scoreColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.scaledPadding(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'menu.compatPromoResultTitle'.tr(namedArgs: {'name': targetName}),
                          style: TextStyle(
                            fontSize: context.scaledFont(14),
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                        SizedBox(height: context.scaledPadding(2)),
                        Text(
                          '${latest.scoreGrade} ${'compatibility.score_suffix'.tr()} · ${latest.analysisTypeLabel}',
                          style: TextStyle(
                            fontSize: context.scaledFont(12),
                            color: scoreColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.scaledPadding(8)),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scoreColor.withValues(alpha: 0.6),
                    size: context.scaledIcon(24),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _bannerDecoration(AppThemeExtension theme, {Color? accentColor}) {
    final color = accentColor ?? _promoColor;
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color.withValues(alpha: 0.12),
          color.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: color.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildIconBox(BuildContext context, IconData icon) {
    return Container(
      width: context.scaledSize(44),
      height: context.scaledSize(44),
      decoration: BoxDecoration(
        color: _promoColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: _promoColor,
        size: context.scaledIcon(22),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFFEC4899);
    if (score >= 60) return const Color(0xFF3B82F6);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFF6B7280);
  }
}
