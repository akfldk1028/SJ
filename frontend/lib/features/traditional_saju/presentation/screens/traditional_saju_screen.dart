import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';

/// 정통사주 랜딩 페이지
class TraditionalSajuScreen extends ConsumerWidget {
  const TraditionalSajuScreen({super.key});

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
          '정통사주',
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
            const Color(0xFF6B48FF),
            const Color(0xFF8B5CF6),
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
              Icons.auto_awesome,
              size: 140,
              color: Colors.white.withValues(alpha: 0.15),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '사주팔자 분석',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '정통사주',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '당신의 사주팔자를 정밀 분석합니다',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
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
                '정통사주란?',
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
            '정통사주는 생년월일시를 기준으로 사주팔자(四柱八字)를 분석하여 '
            '타고난 성격, 적성, 재능, 운명의 흐름을 파악하는 전통 명리학입니다.\n\n'
            'AI가 수천 년의 동양 철학과 현대 기술을 결합하여 '
            '당신만의 사주를 정밀하게 분석해 드립니다.',
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

  Widget _buildAnalysisItems(AppThemeExtension theme) {
    final items = [
      {'icon': Icons.person_outline, 'title': '성격 분석', 'desc': '타고난 성격과 기질'},
      {'icon': Icons.work_outline, 'title': '적성 분석', 'desc': '직업과 재능'},
      {'icon': Icons.favorite_outline, 'title': '인연 분석', 'desc': '대인관계와 인연'},
      {'icon': Icons.timeline, 'title': '대운 분석', 'desc': '10년 주기 운의 흐름'},
      {'icon': Icons.calendar_today, 'title': '세운 분석', 'desc': '올해의 운세'},
      {'icon': Icons.attach_money, 'title': '재물운', 'desc': '재물과 금전운'},
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
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: theme.primaryColor,
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
      'GPT-5.2 기반 정밀 분석',
      '합충형파해 자동 계산',
      '십성 및 신살 분석',
      '무제한 질문 가능',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.1),
            (theme.accentColor ?? theme.primaryColor).withValues(alpha: 0.05),
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
              Icon(Icons.star, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '만톡 정통사주 특징',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: theme.primaryColor, size: 18),
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
      onTap: () => context.push('/saju/chat?type=sajuAnalysis'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor,
              theme.accentColor ?? theme.primaryColor,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              '사주 상담 시작하기',
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
