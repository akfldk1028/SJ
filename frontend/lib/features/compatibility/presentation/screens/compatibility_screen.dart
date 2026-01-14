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
          '정통궁합',
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
            color: _primaryColor.withOpacity(0.4),
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
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.0),
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
                Icon(Icons.favorite, size: 50, color: Colors.white.withOpacity(0.2)),
                Transform.translate(
                  offset: const Offset(-15, 0),
                  child: Icon(Icons.favorite, size: 50, color: Colors.white.withOpacity(0.15)),
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
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        '사주 궁합 분석',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '정통궁합',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '두 사람의 사주로 궁합을 분석합니다',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
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
        border: Border.all(color: _primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_rounded, color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '정통궁합이란?',
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
            '정통궁합은 두 사람의 사주팔자를 비교 분석하여 '
            '서로의 인연, 상성, 화합 정도를 파악하는 전통 명리학입니다.',
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
              color: _primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology_rounded, color: _primaryColor.withOpacity(0.8), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '오행의 상생상극, 일주 궁합, 천간지지 조합 등을 종합 분석합니다',
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
      {'icon': Icons.favorite_rounded, 'title': '연애/결혼', 'color': const Color(0xFFEC4899)},
      {'icon': Icons.people_rounded, 'title': '친구/동료', 'color': const Color(0xFF3B82F6)},
      {'icon': Icons.business_center_rounded, 'title': '비즈니스', 'color': const Color(0xFF10B981)},
      {'icon': Icons.family_restroom_rounded, 'title': '가족', 'color': const Color(0xFFF59E0B)},
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
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.category_rounded, color: _primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                '궁합 유형',
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
                  border: Border.all(color: color.withOpacity(0.15)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
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
                      type['title'] as String,
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
      {'icon': Icons.compare_arrows_rounded, 'title': '오행 상성', 'desc': '오행의 조화와 균형', 'color': const Color(0xFF10B981)},
      {'icon': Icons.calendar_today_rounded, 'title': '일주 궁합', 'desc': '일간과 일지 분석', 'color': const Color(0xFF6B48FF)},
      {'icon': Icons.sync_alt_rounded, 'title': '천간 합', 'desc': '천간의 합과 충', 'color': const Color(0xFF3B82F6)},
      {'icon': Icons.hub_rounded, 'title': '지지 합충', 'desc': '지지의 합충형파해', 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.percent_rounded, 'title': '종합 점수', 'desc': '전체 궁합 점수', 'color': const Color(0xFFEC4899)},
      {'icon': Icons.lightbulb_rounded, 'title': '관계 조언', 'desc': '화합을 위한 조언', 'color': const Color(0xFFEF4444)},
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
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: _primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                '분석 항목',
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
            childAspectRatio: 1.8,
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
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['desc'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textMuted,
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
      {'icon': Icons.people_outline_rounded, 'text': '두 사람의 사주 비교 분석'},
      {'icon': Icons.bar_chart_rounded, 'text': '상성 점수 및 그래프'},
      {'icon': Icons.search_rounded, 'text': '강점/약점 상세 분석'},
      {'icon': Icons.tips_and_updates_rounded, 'text': '관계 개선을 위한 조언'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withOpacity(0.1),
            _secondaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_rounded, color: _primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                '만톡 정통궁합 특징',
                style: TextStyle(
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
                  feature['text'] as String,
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
              color: _primaryColor.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              '궁합 상담 시작하기',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
