import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../profile/domain/entities/saju_profile.dart';
import '../../domain/entities/saju_chart.dart';
import '../../data/constants/cheongan_jiji.dart';

/// 사주 정보 헤더 위젯
///
/// 포스텔러 스타일:
/// - 이름 + 띠 아이콘
/// - 양력/음력 날짜 + 도시 + 보정시간
class SajuInfoHeader extends StatelessWidget {
  final SajuProfile profile;
  final SajuChart chart;

  const SajuInfoHeader({
    super.key,
    required this.profile,
    required this.chart,
  });

  /// 띠 동물 이모지
  String _getAnimalEmoji(String animal) {
    switch (animal) {
      case '쥐':
        return '🐭';
      case '소':
        return '🐮';
      case '호랑이':
        return '🐯';
      case '토끼':
        return '🐰';
      case '용':
        return '🐲';
      case '뱀':
        return '🐍';
      case '말':
        return '🐴';
      case '양':
        return '🐑';
      case '원숭이':
        return '🐵';
      case '닭':
        return '🐔';
      case '개':
        return '🐕';
      case '돼지':
        return '🐷';
      default:
        return '🔮';
    }
  }

  @override
  Widget build(BuildContext context) {
    final yearJi = chart.yearPillar.ji;
    final animal = jijiAnimal[yearJi] ?? '';
    final animalEmoji = _getAnimalEmoji(animal);

    // 날짜 포맷
    final dateFormat = DateFormat('yyyy년 M월 d일');
    final birthDateStr = dateFormat.format(profile.birthDate);

    // 시간 포맷
    String birthTimeStr;
    if (profile.birthTimeUnknown) {
      birthTimeStr = '시간 미상';
    } else if (profile.birthTimeMinutes != null) {
      final hours = profile.birthTimeMinutes! ~/ 60;
      final minutes = profile.birthTimeMinutes! % 60;
      birthTimeStr = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } else {
      birthTimeStr = '시간 미상';
    }

    // 보정 시간
    final correctionMinutes = profile.timeCorrection;
    final correctionStr = correctionMinutes >= 0
        ? '+$correctionMinutes분'
        : '$correctionMinutes분';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이름 + 띠
          Row(
            children: [
              Text(
                animalEmoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$animal띠 (${chart.yearPillar.fullName}년)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              // 성별 아이콘
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: profile.gender.name == 'male'
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.pink.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  profile.gender.name == 'male' ? Icons.male : Icons.female,
                  color: profile.gender.name == 'male' ? Colors.blue : Colors.pink,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          // 생년월일 정보
          _buildInfoRow(
            context,
            icon: Icons.calendar_today,
            label: profile.isLunar ? '음력' : '양력',
            value: birthDateStr,
          ),
          const SizedBox(height: 8),
          // 출생시간
          _buildInfoRow(
            context,
            icon: Icons.access_time,
            label: '출생시간',
            value: birthTimeStr,
          ),
          const SizedBox(height: 8),
          // 출생지
          _buildInfoRow(
            context,
            icon: Icons.location_on,
            label: '출생지',
            value: profile.birthCity,
          ),
          const SizedBox(height: 8),
          // 진태양시 보정
          _buildInfoRow(
            context,
            icon: Icons.tune,
            label: '진태양시 보정',
            value: correctionStr,
            valueColor: correctionMinutes >= 0 ? Colors.orange : Colors.blue,
          ),
          // 윤달 표시 (음력인 경우)
          if (profile.isLunar && profile.isLeapMonth) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              icon: Icons.brightness_3,
              label: '윤달',
              value: '해당',
              valueColor: Colors.purple,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
