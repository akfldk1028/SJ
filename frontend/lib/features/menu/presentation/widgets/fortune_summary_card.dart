import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/illustrations/illustrations.dart';
import '../providers/daily_fortune_provider.dart';

/// Fortune summary card - AI 데이터 연동
/// 시간대별 오행(五行) 기반 디자인
class FortuneSummaryCard extends ConsumerWidget {
  const FortuneSummaryCard({super.key});

  static const _shadowLight = Color.fromRGBO(0, 0, 0, 0.06);
  static const _shadowDark = Color.fromRGBO(0, 0, 0, 0.3);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final fortuneAsync = ref.watch(dailyFortuneProvider);

    return fortuneAsync.when(
      loading: () => _buildLoadingCard(theme),
      error: (error, stack) => _buildErrorCard(context, theme, error),
      data: (fortune) {
        // fortune이 null이면 AI 분석 중 → 로딩 표시
        if (fortune == null) {
          return _buildAnalyzingCard(theme);
        }
        return _buildFortuneCard(context, theme, fortune);
      },
    );
  }

  Widget _buildLoadingCard(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: AnimatedYinYangIllustration(
                  size: 120,
                  showGlow: true,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '운세를 불러오는 중...',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// AI 분석 중일 때 표시하는 카드
  Widget _buildAnalyzingCard(AppThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.isDark ? _shadowDark : _shadowLight,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: AnimatedYinYangIllustration(
                  size: 100,
                  showGlow: true,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '🔮 AI가 운세를 분석하고 있어요',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '잠시만 기다려주세요...',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, AppThemeExtension theme, Object error) {
    return _buildFortuneCard(context, theme, _getSampleFortuneData());
  }

  DailyFortuneData _getSampleFortuneData() {
    return DailyFortuneData(
      overallScore: 85,
      overallMessage: '오늘은 새로운 시작에 좋은 날입니다. 중요한 결정을 내리기에 적합합니다.',
      overallMessageShort: '새로운 시작에 좋은 날, 중요한 결정을 내리세요.',
      date: DateTime.now().toString().split(' ')[0],
      categories: {
        'wealth': const CategoryScore(
          score: 92,
          message: '재물운이 상승하는 시기입니다. 투자에 좋은 기회가 올 수 있습니다.',
          tip: '오전 중에 중요한 재정 결정을 하세요.',
        ),
        'love': const CategoryScore(
          score: 78,
          message: '대인관계에서 좋은 소식이 있을 수 있습니다.',
          tip: '진심어린 대화가 관계를 발전시킵니다.',
        ),
        'work': const CategoryScore(
          score: 85,
          message: '업무에서 인정받을 수 있는 기회가 있습니다.',
          tip: '창의적인 아이디어를 적극적으로 제안해보세요.',
        ),
        'health': const CategoryScore(
          score: 70,
          message: '건강 관리에 신경 쓰세요.',
          tip: '충분한 휴식과 가벼운 운동을 권합니다.',
        ),
      },
      lucky: const LuckyInfo(
        time: '오전 10시',
        color: '파랑',
        number: 7,
        direction: '동쪽',
      ),
      caution: '급한 결정은 피하고 신중하게 행동하세요.',
      affirmation: '나는 오늘도 최선을 다하며 좋은 기운을 받아들입니다.',
    );
  }

  /// 시간대별 테마 정보 (오행 기반)
  _TimeTheme _getTimeTheme(int hour) {
    if (hour >= 5 && hour < 11) {
      // 오전
      return _TimeTheme(
        period: '오전',
        element: '',
        meaning: '',
        colors: [const Color(0xFFE65100), const Color(0xFFFF8A65)], // 주황-살몬
        iconData: Icons.wb_sunny_rounded,
        iconColor: const Color(0xFFFFE0B2),
      );
    } else if (hour >= 11 && hour < 17) {
      // 오후 - 안정, 균형, 성취
      return _TimeTheme(
        period: '오후',
        element: '',
        meaning: '',
        colors: [const Color(0xFFD4A574), const Color(0xFFC9A66B)], // 황금-브라운
        iconData: Icons.wb_sunny_outlined,
        iconColor: const Color(0xFFFFF8E1),
      );
    } else if (hour >= 17 && hour < 23) {
      // 저녁
      return _TimeTheme(
        period: '저녁',
        element: '',
        meaning: '',
        colors: [const Color(0xFF1a1a2e), const Color(0xFF16213e)], // 네이비
        iconData: Icons.nightlight_round,
        iconColor: const Color(0xFFE8EAF6),
      );
    } else {
      // 새벽
      return _TimeTheme(
        period: '새벽',
        element: '',
        meaning: '',
        colors: [const Color(0xFF0D47A1), const Color(0xFF1565C0)], // 진한 파랑
        iconData: Icons.nightlight_round,
        iconColor: const Color(0xFFBBDEFB),
      );
    }
  }

  Widget _buildFortuneCard(
    BuildContext context,
    AppThemeExtension theme,
    DailyFortuneData fortune,
  ) {
    final score = fortune.overallScore;
    // 짧은 메시지 우선 사용 (오늘의 한마디), 없으면 긴 메시지 fallback
    final message = fortune.overallMessageShort.isNotEmpty
        ? fortune.overallMessageShort
        : fortune.overallMessage;
    final hour = DateTime.now().hour;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.scaledPadding(20)),
      child: Column(
        children: [
          // 메인 운세 카드 (시간대별 오행 테마)
          _buildMainScoreCard(context, theme, score, message, hour, fortune.idiom),
          SizedBox(height: context.scaledPadding(16)),
          // 4개 카테고리 통계 그리드
          _buildCategoryStatsGrid(context, theme, fortune),
          SizedBox(height: context.scaledPadding(16)),
          // 오늘의 행운 아이템
          _buildLuckyItemsRow(context, theme, fortune.lucky),
        ],
      ),
    );
  }

  Widget _buildMainScoreCard(
    BuildContext context,
    AppThemeExtension theme,
    int score,
    String message,
    int hour,
    IdiomInfo idiom,
  ) {
    final timeTheme = _getTimeTheme(hour);
    final isNight = hour >= 17 || hour < 5;

    return GestureDetector(
      onTap: () => context.push('/fortune/daily'),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: timeTheme.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: timeTheme.colors[0].withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // 배경 일러스트 - 오른쪽 중앙
            Positioned(
              right: 10,
              top: 20,
              bottom: 20,
              child: Center(
                child: _buildTimeIllustration(hour, isNight),
              ),
            ),
            // 플로팅 별 (저녁/새벽만)
            if (isNight)
              Positioned.fill(
                child: CustomPaint(
                  painter: _StarsPainter(),
                ),
              ),
            // 콘텐츠
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 라벨 (시간대 + 오행)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              timeTheme.iconData,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${timeTheme.period} 운세',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.scaledPadding(16)),
                  // 점수 영역
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w200,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 10),
                        child: Text(
                          _getGradeText(score),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 사자성어 (점수 아래)
                  if (idiom.isValid) ...[
                    SizedBox(height: context.scaledPadding(12)),
                    Text(
                      idiom.korean,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${idiom.chinese} · ${idiom.meaning}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                  SizedBox(height: context.scaledPadding(16)),
                  // 메시지 텍스트
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 시간대별 일러스트
  Widget _buildTimeIllustration(int hour, bool isNight) {
    if (hour >= 5 && hour < 11) {
      // 오전 - 연꽃 (생명력)
      return Opacity(
        opacity: 0.2,
        child: LotusIllustration(
          size: 140,
          primaryColor: Colors.white,
          showWater: false,
        ),
      );
    } else if (hour >= 11 && hour < 17) {
      // 오후 - 태극 (균형)
      return Opacity(
        opacity: 0.15,
        child: YinYangIllustration(
          size: 120,
          showTrigrams: false,
          showGlow: false,
        ),
      );
    } else if (hour >= 17 && hour < 23) {
      // 저녁 - 달 (내면)
      return Opacity(
        opacity: 0.25,
        child: MysticMoonIllustration(
          size: 140,
          showClouds: true,
        ),
      );
    } else {
      // 새벽 - 달 (재생)
      return Opacity(
        opacity: 0.2,
        child: MysticMoonIllustration(
          size: 130,
          showClouds: false,
          showStars: true,
        ),
      );
    }
  }

  Widget _buildCategoryStatsGrid(
    BuildContext context,
    AppThemeExtension theme,
    DailyFortuneData fortune,
  ) {
    final categories = [
      {'key': 'wealth', 'icon': Icons.monetization_on_outlined, 'label': '재물', 'color': const Color(0xFFF59E0B)},
      {'key': 'love', 'icon': Icons.favorite_outline_rounded, 'label': '애정', 'color': const Color(0xFFEC4899)},
      {'key': 'work', 'icon': Icons.work_outline_rounded, 'label': '직장', 'color': const Color(0xFF3B82F6)},
      {'key': 'health', 'icon': Icons.directions_run_rounded, 'label': '건강', 'color': const Color(0xFF10B981)},
    ];

    return GestureDetector(
      onTap: () => context.push('/fortune/daily'),
      child: Container(
        padding: EdgeInsets.all(context.scaledPadding(16)),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.isDark ? _shadowDark : _shadowLight,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '운세 분석',
                  style: TextStyle(
                    fontSize: context.scaledFont(15),
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.textMuted,
                  size: context.scaledIcon(20),
                ),
              ],
            ),
            SizedBox(height: context.scaledPadding(16)),
            // 2x2 그리드
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: context.scaledPadding(12),
                mainAxisSpacing: context.scaledPadding(12),
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final score = fortune.getCategoryScore(cat['key'] as String);
                return _buildStatCard(context, 
                  theme,
                  cat['icon'] as IconData,
                  cat['label'] as String,
                  score,
                  cat['color'] as Color,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
    AppThemeExtension theme,
    IconData icon,
    String label,
    int score,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(context.scaledPadding(14)),
      decoration: BoxDecoration(
        color: theme.isDark
            ? color.withValues(alpha: 0.1)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(context.scaledSize(16)),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.scaledPadding(6)),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: context.scaledIcon(16)),
              ),
              const Spacer(),
              SizedBox(
                width: context.scaledSize(40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: context.scaledFont(13),
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: context.scaledFont(24),
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildLuckyItemsRow(BuildContext context, AppThemeExtension theme, LuckyInfo lucky) {
    final items = [
      {'icon': Icons.access_time_rounded, 'label': '행운의 시간', 'value': lucky.time},
      {'icon': Icons.palette_outlined, 'label': '행운의 색상', 'value': lucky.color},
      {'icon': Icons.tag_rounded, 'label': '행운의 숫자', 'value': '${lucky.number}'},
      {'icon': Icons.explore_outlined, 'label': '행운의 방향', 'value': lucky.direction},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.isDark ? _shadowDark : _shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: theme.accentColor, size: context.scaledIcon(18)),
              const SizedBox(width: 6),
              Text(
                '오늘의 행운',
                style: TextStyle(
                  fontSize: context.scaledFont(14),
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: context.scaledPadding(12)),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3.0,
            mainAxisSpacing: context.scaledPadding(8),
            crossAxisSpacing: context.scaledPadding(8),
            children: items.map((item) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: context.scaledPadding(12), vertical: context.scaledPadding(8)),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: theme.primaryColor,
                      size: context.scaledIcon(18),
                    ),
                    SizedBox(width: context.scaledPadding(8)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: context.scaledFont(10),
                              color: theme.textMuted,
                            ),
                          ),
                          Text(
                            item['value'] as String,
                            style: TextStyle(
                              fontSize: context.scaledFont(13),
                              fontWeight: FontWeight.w600,
                              color: theme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  String _getGradeText(int score) {
    if (score >= 90) return '대길';
    if (score >= 80) return '길';
    if (score >= 70) return '중길';
    if (score >= 60) return '소길';
    return '평';
  }
}

/// 시간대별 테마 데이터
class _TimeTheme {
  final String period;
  final String element;
  final String meaning;
  final List<Color> colors;
  final IconData iconData;
  final Color iconColor;

  const _TimeTheme({
    required this.period,
    required this.element,
    required this.meaning,
    required this.colors,
    required this.iconData,
    required this.iconColor,
  });
}

/// 별 그리기 페인터
class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint()..color = Colors.white;

    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final starSize = 1 + random.nextDouble() * 2;
      paint.color = Colors.white.withValues(alpha: 0.1 + random.nextDouble() * 0.4);
      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
