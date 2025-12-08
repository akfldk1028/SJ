import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/saju_profile.dart';
import '../../../domain/entities/gender.dart';
import '../../../domain/entities/relationship_type.dart';
import '../../../../saju_chart/domain/entities/saju_chart.dart';
import '../../../../saju_chart/domain/entities/pillar.dart';
import '../../../../saju_chart/domain/services/saju_calculation_service.dart';
import '../../../../saju_chart/domain/services/jasi_service.dart';
import '../../../../saju_chart/data/constants/cheongan_jiji.dart';

/// 사주 빠른보기 바텀시트
///
/// 노드 탭 시 프로필의 사주팔자 정보를 표시
class SajuQuickViewSheet extends ConsumerStatefulWidget {
  const SajuQuickViewSheet({
    super.key,
    required this.profile,
    this.onChatPressed,
    this.onDetailPressed,
  });

  final SajuProfile profile;
  final VoidCallback? onChatPressed;
  final VoidCallback? onDetailPressed;

  @override
  ConsumerState<SajuQuickViewSheet> createState() => _SajuQuickViewSheetState();
}

class _SajuQuickViewSheetState extends ConsumerState<SajuQuickViewSheet> {
  SajuChart? _sajuChart;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _calculateSaju();
  }

  void _calculateSaju() {
    try {
      final service = SajuCalculationService();
      final profile = widget.profile;

      // birthTimeMinutes를 DateTime으로 변환
      DateTime birthDateTime;
      if (profile.birthTimeUnknown || profile.birthTimeMinutes == null) {
        birthDateTime = DateTime(
          profile.birthDate.year,
          profile.birthDate.month,
          profile.birthDate.day,
          12, 0, // 정오 기준
        );
      } else {
        final hours = profile.birthTimeMinutes! ~/ 60;
        final minutes = profile.birthTimeMinutes! % 60;
        birthDateTime = DateTime(
          profile.birthDate.year,
          profile.birthDate.month,
          profile.birthDate.day,
          hours,
          minutes,
        );
      }

      final chart = service.calculate(
        birthDateTime: birthDateTime,
        birthCity: profile.birthCity,
        isLunarCalendar: profile.isLunar,
        isLeapMonth: profile.isLeapMonth,
        birthTimeUnknown: profile.birthTimeUnknown,
        jasiMode: profile.useYaJasi ? JasiMode.yaJasi : JasiMode.joJasi,
      );

      setState(() {
        _sajuChart = chart;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.profile;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 프로필 헤더
              _buildProfileHeader(context, profile),

              const SizedBox(height: 20),

              // 사주 정보
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('사주 계산 오류: $_error'),
                )
              else if (_sajuChart != null)
                _buildSajuDisplay(context, _sajuChart!),

              const SizedBox(height: 20),

              // 액션 버튼
              _buildActionButtons(context),

              // Safe area padding
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, SajuProfile profile) {
    final theme = Theme.of(context);
    final relationColor = _getRelationColor(profile.relationType);

    return Row(
      children: [
        // 아바타
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: relationColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: relationColor, width: 2),
          ),
          child: Center(
            child: Text(
              profile.displayName.isNotEmpty
                  ? profile.displayName.substring(0, 1)
                  : '?',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: relationColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // 이름 및 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    profile.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: relationColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      profile.relationType.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: relationColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${profile.birthDateFormatted} (${profile.calendarTypeLabel})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              if (!profile.birthTimeUnknown && profile.birthTimeFormatted != null)
                Text(
                  '${profile.birthTimeFormatted} 출생',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSajuDisplay(BuildContext context, SajuChart chart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // 사주팔자 한자 헤더
          Text(
            chart.fullSajuHanja,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chart.fullSaju,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              letterSpacing: 4,
            ),
          ),
          const Divider(height: 24),

          // 4개 기둥 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPillarColumn(
                context,
                '시주',
                chart.hourPillar,
                chart.hasUnknownBirthTime,
              ),
              _buildPillarColumn(context, '일주', chart.dayPillar, false, isDayMaster: true),
              _buildPillarColumn(context, '월주', chart.monthPillar, false),
              _buildPillarColumn(context, '년주', chart.yearPillar, false),
            ],
          ),

          const SizedBox(height: 16),

          // 일간 설명
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('일간(나): ', style: TextStyle(fontSize: 13)),
                Text(
                  '${chart.dayMaster} (${_getOhengText(chart.dayPillar.ganOheng)})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _getOhengColor(chart.dayPillar.ganOheng),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarColumn(
    BuildContext context,
    String label,
    Pillar? pillar,
    bool isUnknown, {
    bool isDayMaster = false,
  }) {
    if (isUnknown || pillar == null) {
      return _buildUnknownPillar(context, label);
    }

    final ganHanja = cheonganHanja[pillar.gan] ?? '';
    final jiHanja = jijiHanja[pillar.ji] ?? '';
    final ganColor = _getOhengColor(pillar.ganOheng);
    final jiColor = _getOhengColor(pillar.jiOheng);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: isDayMaster
          ? BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber, width: 2),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDayMaster ? Colors.amber[800] : Colors.grey[600],
              fontWeight: isDayMaster ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          // 천간
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ganColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ganColor),
            ),
            child: Center(
              child: Text(
                ganHanja,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ganColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            pillar.gan,
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 6),
          // 지지
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: jiColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: jiColor),
            ),
            child: Center(
              child: Text(
                jiHanja,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: jiColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            pillar.ji,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownPillar(BuildContext context, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: Center(
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text('미상', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: Center(
            child: Text(
              '?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text('미상', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onChatPressed,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('사주 상담'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: widget.onDetailPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          child: const Text('상세보기'),
        ),
      ],
    );
  }

  Color _getRelationColor(RelationshipType type) {
    if (type == RelationshipType.me) return const Color(0xFFFF69B4);
    if (type == RelationshipType.family) return const Color(0xFFFF6B6B);
    if (type == RelationshipType.friend) return const Color(0xFF4ECDC4);
    if (type == RelationshipType.lover) return const Color(0xFFFF69B4);
    if (type == RelationshipType.work) return const Color(0xFF45B7D1);
    return const Color(0xFF95A5A6);
  }

  Color _getOhengColor(String oheng) {
    switch (oheng) {
      case '목':
        return const Color(0xFF4CAF50);
      case '화':
        return const Color(0xFFF44336);
      case '토':
        return const Color(0xFFFF9800);
      case '금':
        return const Color(0xFFFFD700);
      case '수':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  String _getOhengText(String oheng) {
    switch (oheng) {
      case '목':
        return '목(木)';
      case '화':
        return '화(火)';
      case '토':
        return '토(土)';
      case '금':
        return '금(金)';
      case '수':
        return '수(水)';
      default:
        return oheng;
    }
  }
}

/// 사주 빠른보기 바텀시트 표시
void showSajuQuickView(
  BuildContext context, {
  required SajuProfile profile,
  VoidCallback? onChatPressed,
  VoidCallback? onDetailPressed,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SajuQuickViewSheet(
      profile: profile,
      onChatPressed: onChatPressed,
      onDetailPressed: onDetailPressed,
    ),
  );
}
