import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../menu/presentation/providers/daily_fortune_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// 캘린더 화면 - 날짜별 운세 기록 조회
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: MysticBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(theme),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCalendar(theme),
                      const SizedBox(height: 16),
                      if (_selectedDay != null)
                        _buildSelectedDateFortune(theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.isDark
                        ? const Color.fromRGBO(0, 0, 0, 0.3)
                        : const Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: theme.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '운세 캘린더',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
          ),
          // 오늘 버튼
          GestureDetector(
            onTap: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Text(
                '오늘',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(AppThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? const Color.fromRGBO(0, 0, 0, 0.3)
                : const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        locale: 'ko_KR',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          // 기본 텍스트 스타일
          defaultTextStyle: TextStyle(color: theme.textPrimary),
          weekendTextStyle: TextStyle(color: theme.textSecondary),
          outsideTextStyle: TextStyle(color: theme.textMuted),

          // 선택된 날짜
          selectedDecoration: BoxDecoration(
            color: theme.primaryColor,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: theme.isDark ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),

          // 오늘 날짜
          todayDecoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
          ),

          // 마커 (운세 데이터 있는 날)
          markerDecoration: BoxDecoration(
            color: theme.primaryColor,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
          markerSize: 6,
          markerMargin: const EdgeInsets.only(top: 6),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: theme.textSecondary,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: theme.textSecondary,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: theme.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          weekendStyle: TextStyle(
            color: theme.textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDateFortune(AppThemeExtension theme) {
    final selectedDay = _selectedDay!;
    final fortuneAsync = ref.watch(dailyFortuneForDateProvider(selectedDay));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? const Color.fromRGBO(0, 0, 0, 0.3)
                : const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatDateHeader(selectedDay),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 운세 내용
          fortuneAsync.when(
            loading: () => _buildLoadingState(theme),
            error: (_, __) => _buildErrorState(theme),
            data: (fortune) {
              if (fortune == null) {
                return _buildNoDataState(theme, selectedDay);
              }
              return _buildFortuneContent(theme, fortune);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: CircularProgressIndicator(
          color: theme.primaryColor,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorState(AppThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: theme.textMuted,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '운세를 불러오는데 실패했습니다',
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState(AppThemeExtension theme, DateTime date) {
    final isToday = isSameDay(date, DateTime.now());
    final isFuture = date.isAfter(DateTime.now());

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              isFuture ? Icons.schedule_rounded : Icons.history_rounded,
              color: theme.textMuted,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              isFuture
                  ? '미래의 운세는 아직 볼 수 없습니다'
                  : isToday
                      ? '오늘의 운세를 확인하려면\n메인 화면으로 이동하세요'
                      : '해당 날짜의 운세 기록이 없습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (isToday) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.go('/menu'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '메인 화면으로',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFortuneContent(AppThemeExtension theme, DailyFortuneData fortune) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 종합 점수
        Row(
          children: [
            _buildScoreIndicator(theme, fortune.overallScore),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '종합 운세',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getScoreLabel(fortune.overallScore),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 종합 메시지
        Text(
          fortune.overallMessage,
          style: TextStyle(
            fontSize: 14,
            color: theme.textSecondary,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 20),

        // 카테고리별 점수
        _buildCategoryScores(theme, fortune),

        const SizedBox(height: 16),

        // 행운 정보
        _buildLuckyInfo(theme, fortune.lucky),
      ],
    );
  }

  Widget _buildScoreIndicator(AppThemeExtension theme, int score) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withOpacity(0.2),
            theme.primaryColor.withOpacity(0.1),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$score',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryScores(AppThemeExtension theme, DailyFortuneData fortune) {
    final categories = [
      ('love', '연애운', Icons.favorite_rounded),
      ('money', '재물운', Icons.monetization_on_rounded),
      ('work', '직장운', Icons.work_rounded),
      ('health', '건강운', Icons.health_and_safety_rounded),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final score = fortune.getCategoryScore(cat.$1);
        return _buildCategoryChip(theme, cat.$2, cat.$3, score);
      }).toList(),
    );
  }

  Widget _buildCategoryChip(
    AppThemeExtension theme,
    String label,
    IconData icon,
    int score,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            '$label $score',
            style: TextStyle(
              fontSize: 12,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuckyInfo(AppThemeExtension theme, LuckyInfo lucky) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.stars_rounded,
            size: 16,
            color: theme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '행운의 시간: ${lucky.time} · 색상: ${lucky.color} · 숫자: ${lucky.number}',
              style: TextStyle(
                fontSize: 12,
                color: theme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}년 ${date.month}월 ${date.day}일 ($weekday)';
  }

  String _getScoreLabel(int score) {
    if (score >= 90) return '대길';
    if (score >= 80) return '길';
    if (score >= 70) return '소길';
    if (score >= 60) return '평';
    if (score >= 50) return '소흉';
    return '흉';
  }
}
