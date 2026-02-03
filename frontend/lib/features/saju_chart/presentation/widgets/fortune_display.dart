import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/constants/cheongan_jiji.dart';
import '../../data/constants/jijanggan_table.dart';
import '../../data/constants/sipsin_relations.dart';
import '../../domain/entities/daeun.dart';
import '../../domain/entities/pillar.dart';
import '../../domain/entities/saju_analysis.dart';
import '../../domain/services/daeun_service.dart';

/// 대운/세운/월운 종합 표시 위젯 (포스텔러 스타일)
class FortuneDisplay extends StatelessWidget {
  final SajuAnalysis analysis;

  const FortuneDisplay({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 대운수 정보
          if (analysis.daeun != null) ...[
            _buildDaeunHeader(context, analysis.daeun!, theme),
            const SizedBox(height: 20),
            // 대운 슬라이더
            _buildSectionTitle(context, '대운', theme),
            const SizedBox(height: 8),
            _buildSubtitle(context, '좌우로 슬라이드해서 더 볼 수 있어요.', theme),
            const SizedBox(height: 12),
            DaeunSlider(
              daeunResult: analysis.daeun!,
              dayGan: analysis.chart.dayPillar.gan,
              currentAge: _calculateCurrentAge(analysis.chart.birthDateTime),
            ),
            const SizedBox(height: 24),
          ],

          // 세운 (연운)
          _buildSectionTitle(context, '연운', theme),
          const SizedBox(height: 12),
          SeunSlider(
            birthYear: analysis.chart.birthDateTime.year,
            dayGan: analysis.chart.dayPillar.gan,
            currentYear: DateTime.now().year,
          ),
          const SizedBox(height: 24),

          // 월운
          _buildSectionTitle(context, '월운', theme),
          const SizedBox(height: 12),
          WolunSlider(
            birthYear: analysis.chart.birthDateTime.year,
            dayGan: analysis.chart.dayPillar.gan,
            currentYear: DateTime.now().year,
          ),
        ],
      ),
    );
  }

  Widget _buildDaeunHeader(BuildContext context, DaeUnResult daeun, AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.timeline, color: theme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '대운수 : ${daeun.startAge}(${daeun.daeUnList.isNotEmpty ? daeun.daeUnList.first.pillar.ji : ""}${daeun.daeUnList.isNotEmpty ? jijiHanja[daeun.daeUnList.first.pillar.ji] ?? "" : ""})',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  daeun.isForward ? '순행 (順行)' : '역행 (逆行)',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, AppThemeExtension theme) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showSectionHelp(context, title, theme),
          child: Icon(Icons.help_outline, size: 16, color: theme.textMuted),
        ),
      ],
    );
  }

  void _showSectionHelp(BuildContext context, String title, AppThemeExtension theme) {
    final descriptions = {
      '대운': '10년 단위로 변하는 큰 운의 흐름입니다. 대운이 바뀌면 인생의 주요 흐름이 변화하며, 일간과의 관계에 따라 길흉이 달라집니다.',
      '연운': '매년 변하는 운세입니다. 세운이라고도 하며, 그 해의 천간·지지가 사주와 어떤 관계를 맺는지에 따라 한 해의 흐름이 결정됩니다.',
      '월운': '매달 변하는 운세입니다. 월지의 변화에 따라 세부적인 운의 흐름을 파악할 수 있어 단기적인 계획 수립에 도움이 됩니다.',
    };
    final desc = descriptions[title] ?? '';
    if (desc.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: theme.primaryColor, size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text(
              '$title이란?',
              style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            )),
          ],
        ),
        content: Text(desc, style: TextStyle(color: theme.textSecondary, fontSize: 15, height: 1.7)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('확인', style: TextStyle(color: theme.primaryColor, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, String text, AppThemeExtension theme) {
    return Text(
      text,
      style: TextStyle(
        color: theme.textMuted,
        fontSize: 13,
      ),
    );
  }

  int _calculateCurrentAge(DateTime birthDate) {
    final now = DateTime.now();
    // 한국식 나이 (만 나이 + 1)
    final age = now.year - birthDate.year + 1;
    return age;
  }
}

/// 대운 슬라이더 위젯
class DaeunSlider extends StatelessWidget {
  final DaeUnResult daeunResult;
  final String dayGan;
  final int currentAge;

  const DaeunSlider({
    super.key,
    required this.daeunResult,
    required this.dayGan,
    required this.currentAge,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: daeunResult.daeUnList.length,
        itemBuilder: (context, index) {
          // 역순으로 표시 (포스텔러처럼 최신 대운이 왼쪽)
          final reversedIndex = daeunResult.daeUnList.length - 1 - index;
          final daeun = daeunResult.daeUnList[reversedIndex];
          final isCurrent =
              currentAge >= daeun.startAge && currentAge <= daeun.endAge;

          return _buildDaeunCard(context, daeun, isCurrent);
        },
      ),
    );
  }

  Widget _buildDaeunCard(BuildContext context, DaeUn daeun, bool isCurrent) {
    final theme = context.appTheme;
    final ganSipsin = calculateSipSin(dayGan, daeun.pillar.gan);
    final jiSipsin = calculateSipSin(dayGan, getJeongGi(daeun.pillar.ji) ?? '갑');
    final ganColor = _getOhengColor(daeun.pillar.ganOheng);
    final jiColor = _getOhengColor(daeun.pillar.jiOheng);

    return Container(
      width: 76,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent ? theme.primaryColor.withOpacity(0.15) : theme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? theme.primaryColor : theme.border,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 나이 + 십성
          Text(
            '${daeun.startAge}',
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 13,
            ),
          ),
          Text(
            ganSipsin.korean.substring(0, 2),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          // 천간 (한자)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ganColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                cheonganHanja[daeun.pillar.gan] ?? daeun.pillar.gan,
                style: TextStyle(
                  color: ganColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 지지 (한자)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: jiColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                jijiHanja[daeun.pillar.ji] ?? daeun.pillar.ji,
                style: TextStyle(
                  color: jiColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 지지 십성
          Text(
            jiSipsin.korean.substring(0, 2),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Color _getOhengColor(String oheng) {
    return switch (oheng) {
      '목' => AppColors.wood,
      '화' => AppColors.fire,
      '토' => AppColors.earth,
      '금' => AppColors.metal,
      '수' => AppColors.water,
      _ => AppColors.textPrimary,
    };
  }
}

/// 세운 (연운) 슬라이더 위젯
class SeunSlider extends StatelessWidget {
  final int birthYear;
  final String dayGan;
  final int currentYear;

  const SeunSlider({
    super.key,
    required this.birthYear,
    required this.dayGan,
    required this.currentYear,
  });

  @override
  Widget build(BuildContext context) {
    final daeunService = DaeUnService();
    // 최근 10년 세운
    final seunList = daeunService.generateSeUnList(
      birthYear: birthYear,
      startYear: currentYear - 9,
      endYear: currentYear,
    );

    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: seunList.length,
        itemBuilder: (context, index) {
          // 역순 표시 (최신이 왼쪽)
          final reversedIndex = seunList.length - 1 - index;
          final seun = seunList[reversedIndex];
          final isCurrent = seun.year == currentYear;

          return _buildSeunCard(context, seun, isCurrent);
        },
      ),
    );
  }

  Widget _buildSeunCard(BuildContext context, SeUn seun, bool isCurrent) {
    final theme = context.appTheme;
    final ganSipsin = calculateSipSin(dayGan, seun.pillar.gan);
    final jiSipsin = calculateSipSin(dayGan, getJeongGi(seun.pillar.ji) ?? '갑');
    final ganColor = _getOhengColor(seun.pillar.ganOheng);
    final jiColor = _getOhengColor(seun.pillar.jiOheng);

    return Container(
      width: 76,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent ? theme.primaryColor.withOpacity(0.15) : theme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? theme.primaryColor : theme.border,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 연도
          Text(
            '${seun.year}',
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 13,
            ),
          ),
          Text(
            ganSipsin.korean.substring(0, 2),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          // 천간
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ganColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                cheonganHanja[seun.pillar.gan] ?? seun.pillar.gan,
                style: TextStyle(
                  color: ganColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 지지
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: jiColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                jijiHanja[seun.pillar.ji] ?? seun.pillar.ji,
                style: TextStyle(
                  color: jiColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 지지 십성
          Text(
            jiSipsin.korean.substring(0, 2),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Color _getOhengColor(String oheng) {
    return switch (oheng) {
      '목' => AppColors.wood,
      '화' => AppColors.fire,
      '토' => AppColors.earth,
      '금' => AppColors.metal,
      '수' => AppColors.water,
      _ => AppColors.textPrimary,
    };
  }
}

/// 월운 슬라이더 위젯
class WolunSlider extends StatelessWidget {
  final int birthYear;
  final String dayGan;
  final int currentYear;

  const WolunSlider({
    super.key,
    required this.birthYear,
    required this.dayGan,
    required this.currentYear,
  });

  @override
  Widget build(BuildContext context) {
    // 현재 월 기준 12개월 월운 생성
    final currentMonth = DateTime.now().month;
    final wolunList = _generateWolunList(currentYear, currentMonth);

    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: wolunList.length,
        itemBuilder: (context, index) {
          // 역순 표시 (최신이 왼쪽)
          final reversedIndex = wolunList.length - 1 - index;
          final wolun = wolunList[reversedIndex];
          final isCurrent =
              wolun['year'] == currentYear && wolun['month'] == currentMonth;

          return _buildWolunCard(context, wolun, isCurrent);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _generateWolunList(int year, int currentMonth) {
    final result = <Map<String, dynamic>>[];

    // 최근 12개월
    for (int i = 11; i >= 0; i--) {
      int month = currentMonth - i;
      int targetYear = year;

      if (month <= 0) {
        month += 12;
        targetYear -= 1;
      }

      final pillar = _calculateMonthPillar(targetYear, month);
      result.add({
        'year': targetYear,
        'month': month,
        'pillar': pillar,
      });
    }

    return result;
  }

  /// 월주 계산 (간단 버전)
  Pillar _calculateMonthPillar(int year, int month) {
    // 년간에 따른 월건 시작점
    final yearGanIndex = (year - 4) % 10;
    final monthGanStartIndex = (yearGanIndex % 5) * 2;

    // 월건 계산 (인월=1월 기준)
    final lunarMonth = month; // 양력 월을 그대로 사용 (간략화)
    final ganIndex = (monthGanStartIndex + lunarMonth - 1) % 10;
    final jiIndex = (lunarMonth + 1) % 12; // 인월=1, 묘월=2, ...

    return Pillar(
      gan: cheongan[ganIndex],
      ji: jiji[jiIndex],
    );
  }

  Widget _buildWolunCard(
      BuildContext context, Map<String, dynamic> wolun, bool isCurrent) {
    final theme = context.appTheme;
    final pillar = wolun['pillar'] as Pillar;
    final month = wolun['month'] as int;

    final ganSipsin = calculateSipSin(dayGan, pillar.gan);
    final jiSipsin = calculateSipSin(dayGan, getJeongGi(pillar.ji) ?? '갑');
    final ganColor = _getOhengColor(pillar.ganOheng);
    final jiColor = _getOhengColor(pillar.jiOheng);

    return Container(
      width: 76,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isCurrent ? theme.primaryColor.withOpacity(0.15) : theme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? theme.primaryColor : theme.border,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 월
          Text(
            '$month월',
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 13,
            ),
          ),
          Text(
            ganSipsin.korean.substring(0, 2),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          // 천간
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ganColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                cheonganHanja[pillar.gan] ?? pillar.gan,
                style: TextStyle(
                  color: ganColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 지지
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: jiColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                jijiHanja[pillar.ji] ?? pillar.ji,
                style: TextStyle(
                  color: jiColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 지지 십성
          Text(
            jiSipsin.korean.substring(0, 2),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Color _getOhengColor(String oheng) {
    return switch (oheng) {
      '목' => AppColors.wood,
      '화' => AppColors.fire,
      '토' => AppColors.earth,
      '금' => AppColors.metal,
      '수' => AppColors.water,
      _ => AppColors.textPrimary,
    };
  }
}
