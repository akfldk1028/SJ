import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';

/// 정통궁합 랜딩 페이지
class CompatibilityScreen extends ConsumerWidget {
  const CompatibilityScreen({super.key});

  static const _primaryColor = Color(0xFFEC4899);
  static const _secondaryColor = Color(0xFFF472B6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'compatibility.traditional_title'.tr(),
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: MysticBackground(
        child: SafeArea(
          child: _buildContent(context, theme),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppThemeExtension theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 헤더 배너
        _buildHeaderBanner(theme),
        const SizedBox(height: 20),
        // 서비스 설명
        _buildServiceDescription(theme),
        const SizedBox(height: 20),
        // 궁합 유형
        _buildCompatibilityTypes(theme),
        const SizedBox(height: 20),
        // 분석 항목
        _buildAnalysisItems(theme),
        const SizedBox(height: 20),
        // 특징
        _buildFeatures(theme),
        const SizedBox(height: 28),
        // 상담 시작 버튼
        _buildStartButton(context, theme),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeaderBanner(AppThemeExtension theme) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha:0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 배경 패턴
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha:0.15),
                    Colors.white.withValues(alpha:0.0),
                  ],
                ),
              ),
            ),
          ),
          // 하트 아이콘 두 개
          Positioned(
            right: 30,
            bottom: 30,
            child: Row(
              children: [
                Icon(Icons.favorite, size: 50, color: Colors.white.withValues(alpha:0.2)),
                Transform.translate(
                  offset: const Offset(-15, 0),
                  child: Icon(Icons.favorite, size: 50, color: Colors.white.withValues(alpha:0.15)),
                ),
              ],
            ),
          ),
          // 콘텐츠
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'compatibility.saju_analysis_badge'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'compatibility.traditional_title'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'compatibility.banner_subtitle'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha:0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDescription(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withValues(alpha:0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded, color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'compatibility.what_is_title'.tr(),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'compatibility.what_is_desc'.tr(),
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology_rounded, color: _primaryColor.withValues(alpha:0.8), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'compatibility.what_is_detail'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityTypes(AppThemeExtension theme) {
    final types = [
      {'icon': Icons.favorite_rounded, 'titleKey': 'compatibility.type_love', 'color': const Color(0xFFEC4899)},
      {'icon': Icons.people_rounded, 'titleKey': 'compatibility.type_friend', 'color': const Color(0xFF3B82F6)},
      {'icon': Icons.business_center_rounded, 'titleKey': 'compatibility.type_business', 'color': const Color(0xFF10B981)},
      {'icon': Icons.family_restroom_rounded, 'titleKey': 'compatibility.type_family', 'color': const Color(0xFFF59E0B)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.category_rounded, color: _primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'compatibility.type_title'.tr(),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: types.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            final color = type['color'] as Color;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == types.length - 1 ? 0 : 10),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha:0.15)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        type['icon'] as IconData,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (type['titleKey'] as String).tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnalysisItems(AppThemeExtension theme) {
    final items = [
      {'icon': Icons.compare_arrows_rounded, 'titleKey': 'compatibility.analysis_oheng', 'descKey': 'compatibility.analysis_oheng_desc', 'color': const Color(0xFF10B981)},
      {'icon': Icons.calendar_today_rounded, 'titleKey': 'compatibility.analysis_ilju', 'descKey': 'compatibility.analysis_ilju_desc', 'color': const Color(0xFF6B48FF)},
      {'icon': Icons.sync_alt_rounded, 'titleKey': 'compatibility.analysis_cheongan', 'descKey': 'compatibility.analysis_cheongan_desc', 'color': const Color(0xFF3B82F6)},
      {'icon': Icons.hub_rounded, 'titleKey': 'compatibility.analysis_jiji', 'descKey': 'compatibility.analysis_jiji_desc', 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.percent_rounded, 'titleKey': 'compatibility.analysis_score', 'descKey': 'compatibility.analysis_score_desc', 'color': const Color(0xFFEC4899)},
      {'icon': Icons.lightbulb_rounded, 'titleKey': 'compatibility.analysis_advice', 'descKey': 'compatibility.analysis_advice_desc', 'color': const Color(0xFFEF4444)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: _primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'compatibility.analysis_section_title'.tr(),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4, // 1.8 → 1.4로 조정
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final color = item['color'] as Color;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha:0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (item['titleKey'] as String).tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (item['descKey'] as String).tr(),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatures(AppThemeExtension theme) {
    final features = [
      {'icon': Icons.people_outline_rounded, 'textKey': 'compatibility.feature_compare'},
      {'icon': Icons.bar_chart_rounded, 'textKey': 'compatibility.feature_graph'},
      {'icon': Icons.search_rounded, 'textKey': 'compatibility.feature_detail'},
      {'icon': Icons.tips_and_updates_rounded, 'textKey': 'compatibility.feature_advice'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withValues(alpha:0.1),
            _secondaryColor.withValues(alpha:0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_rounded, color: _primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'compatibility.features_title'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  (feature['textKey'] as String).tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, AppThemeExtension theme) {
    return GestureDetector(
      onTap: () => context.go('/saju/chat?type=compatibility'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primaryColor, _secondaryColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha:0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_outline_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              'compatibility.start_button'.tr(),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
