import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';

/// 정통궁합 랜딩 페이지
class CompatibilityScreen extends ConsumerWidget {
  const CompatibilityScreen({super.key});

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
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '정통궁합',
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
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
        const SizedBox(height: 24),
        // 서비스 설명
        _buildServiceDescription(theme),
        const SizedBox(height: 24),
        // 궁합 유형
        _buildCompatibilityTypes(theme),
        const SizedBox(height: 24),
        // 분석 항목
        _buildAnalysisItems(theme),
        const SizedBox(height: 24),
        // 특징
        _buildFeatures(theme),
        const SizedBox(height: 32),
        // 상담 시작 버튼
        _buildStartButton(context, theme),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeaderBanner(AppThemeExtension theme) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEC4899),
            const Color(0xFFF472B6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.favorite,
              size: 140,
              color: Colors.white.withValues(alpha:0.15),
            ),
          ),
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
                  child: const Text(
                    '사주 궁합 분석',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '정통궁합',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '두 사람의 사주로 궁합을 분석합니다',
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '정통궁합이란?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '정통궁합은 두 사람의 사주팔자를 비교 분석하여 '
            '서로의 인연, 상성, 화합 정도를 파악하는 전통 명리학입니다.\n\n'
            '오행의 상생상극, 일주 궁합, 천간지지 조합 등을 종합적으로 '
            '분석하여 두 사람의 관계를 심층적으로 살펴봅니다.',
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityTypes(AppThemeExtension theme) {
    final types = [
      {'icon': Icons.favorite, 'title': '연애/결혼 궁합', 'color': const Color(0xFFEC4899)},
      {'icon': Icons.people, 'title': '친구/동료 궁합', 'color': const Color(0xFF3B82F6)},
      {'icon': Icons.business, 'title': '비즈니스 궁합', 'color': const Color(0xFF10B981)},
      {'icon': Icons.family_restroom, 'title': '가족 궁합', 'color': const Color(0xFFF59E0B)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '궁합 유형',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ),
        Row(
          children: types.map((type) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: type == types.last ? 0 : 8,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (type['color'] as Color).withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        type['icon'] as IconData,
                        color: type['color'] as Color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      type['title'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
      {'icon': Icons.compare_arrows, 'title': '오행 상성', 'desc': '오행의 조화와 균형'},
      {'icon': Icons.calendar_today, 'title': '일주 궁합', 'desc': '일간과 일지 분석'},
      {'icon': Icons.sync_alt, 'title': '천간 합', 'desc': '천간의 합과 충'},
      {'icon': Icons.hub, 'title': '지지 합충', 'desc': '지지의 합충형파해'},
      {'icon': Icons.percent, 'title': '종합 점수', 'desc': '전체 궁합 점수'},
      {'icon': Icons.tips_and_updates, 'title': '관계 조언', 'desc': '화합을 위한 조언'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '분석 항목',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: const Color(0xFFEC4899),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                        Text(
                          item['desc'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textMuted,
                          ),
                        ),
                      ],
                    ),
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
      '두 사람의 사주 비교 분석',
      '상성 점수 및 그래프',
      '강점/약점 상세 분석',
      '관계 개선을 위한 조언',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEC4899).withValues(alpha:0.1),
            const Color(0xFFF472B6).withValues(alpha:0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFEC4899), size: 20),
              const SizedBox(width: 8),
              Text(
                '만톡 정통궁합 특징',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.isDark ? const Color(0xFFF472B6) : const Color(0xFFEC4899),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFFEC4899), size: 18),
                const SizedBox(width: 10),
                Text(
                  feature,
                  style: TextStyle(
                    fontSize: 14,
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
      onTap: () => context.push('/saju/chat?type=compatibility'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFEC4899),
              Color(0xFFF472B6),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEC4899).withValues(alpha:0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              '궁합 상담 시작하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
