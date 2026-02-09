import 'package:flutter/material.dart';
import '../../data/constants/cheongan_jiji.dart';
import '../../domain/entities/pillar.dart';

/// 사주 기둥(년주/월주/일주/시주) 표시 위젯
///
/// 포스텔러 스타일:
/// - 천간 한글 + 한자
/// - 지지 한글 + 한자
/// - 오행 표시 (색상)
class PillarColumnWidget extends StatelessWidget {
  final Pillar pillar;
  final String label;
  final bool isDayMaster; // 일주(나)인지 여부

  const PillarColumnWidget({
    super.key,
    required this.pillar,
    required this.label,
    this.isDayMaster = false,
  });

  /// 오행별 색상
  Color _getOhengColor(String oheng) {
    switch (oheng) {
      case '목':
        return const Color(0xFF4CAF50); // 초록
      case '화':
        return const Color(0xFFF44336); // 빨강
      case '토':
        return const Color(0xFFFF9800); // 주황/황토
      case '금':
        return const Color(0xFF708090); // 슬레이트 그레이 (은색 계열)
      case '수':
        return const Color(0xFF2196F3); // 파랑
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ganHanja = cheonganHanja[pillar.gan] ?? '';
    final jiHanja = jijiHanja[pillar.ji] ?? '';
    final ganOheng = pillar.ganOheng;
    final jiOheng = pillar.jiOheng;
    final animal = pillar.jiAnimal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDayMaster
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isDayMaster
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 라벨 (년주, 월주, 일주, 시주)
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDayMaster
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
              fontWeight: isDayMaster ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
          // 천간 한자
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getOhengColor(ganOheng).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getOhengColor(ganOheng),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                ganHanja,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _getOhengColor(ganOheng),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 천간 한글 + 오행
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pillar.gan,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getOhengColor(ganOheng).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ganOheng,
                  style: TextStyle(
                    fontSize: 13,
                    color: _getOhengColor(ganOheng),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 지지 한자
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getOhengColor(jiOheng).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getOhengColor(jiOheng),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                jiHanja,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _getOhengColor(jiOheng),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 지지 한글 + 오행
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pillar.ji,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getOhengColor(jiOheng).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  jiOheng,
                  style: TextStyle(
                    fontSize: 13,
                    color: _getOhengColor(jiOheng),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // 동물 표시 (지지)
          if (animal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              animal,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 시주 없음(출생시간 모름) 위젯
class UnknownHourPillarWidget extends StatelessWidget {
  const UnknownHourPillarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '시주',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          // 빈 천간 박스
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[400]!,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '미상',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          // 빈 지지 박스
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[400]!,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '미상',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
