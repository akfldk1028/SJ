import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/services/quota_service.dart';

/// Quota 초과 다이얼로그
///
/// 일일 토큰 사용량 초과 시 표시
/// - 현재 사용량 표시
/// - 광고 시청 버튼 제공
/// - 광고 시청 후 콜백 처리
class QuotaExceededDialog extends StatefulWidget {
  /// 오늘 사용한 토큰 수
  final int tokensUsed;

  /// 일일 quota 한도
  final int quotaLimit;

  /// 광고 시청 완료 콜백
  final VoidCallback? onAdWatched;

  /// 닫기 콜백
  final VoidCallback? onClose;

  const QuotaExceededDialog({
    super.key,
    required this.tokensUsed,
    required this.quotaLimit,
    this.onAdWatched,
    this.onClose,
  });

  @override
  State<QuotaExceededDialog> createState() => _QuotaExceededDialogState();

  /// 다이얼로그 표시
  static Future<bool?> show(
    BuildContext context, {
    required int tokensUsed,
    required int quotaLimit,
    VoidCallback? onAdWatched,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuotaExceededDialog(
        tokensUsed: tokensUsed,
        quotaLimit: quotaLimit,
        onAdWatched: onAdWatched,
        onClose: () => Navigator.of(context).pop(false),
      ),
    );
  }
}

class _QuotaExceededDialogState extends State<QuotaExceededDialog> {
  bool _isLoading = false;

  /// 광고 시청 처리
  Future<void> _watchAd() async {
    setState(() => _isLoading = true);

    try {
      // TODO: 실제 광고 SDK 연동 (Google AdMob 등)
      // 현재는 시뮬레이션: 2초 대기 후 보너스 토큰 추가
      await Future.delayed(const Duration(seconds: 2));

      // 보너스 토큰 추가
      final result = await QuotaService.addAdBonusTokens();

      if (!mounted) return;

      if (result.success) {
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.bonusEarned ?? QuotaService.adBonusTokens} 토큰이 추가되었습니다!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // 콜백 호출
        widget.onAdWatched?.call();

        // 다이얼로그 닫기 (true = 광고 시청 완료)
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        // 실패 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? '보너스 토큰 추가에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usagePercent = widget.quotaLimit > 0
        ? ((widget.tokensUsed / widget.quotaLimit) * 100).round()
        : 100;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('일일 사용량 초과'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘 AI 상담 사용량을 모두 소진했습니다.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),

          // 사용량 표시
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '사용량',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${_formatNumber(widget.tokensUsed)} / ${_formatNumber(widget.quotaLimit)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 프로그레스 바
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 1.0, // 초과 상태이므로 100%
                    backgroundColor: theme.colorScheme.surfaceContainerLow,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.error,
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$usagePercent%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 안내 메시지
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(77),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withAlpha(77),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '광고를 시청하면 ${_formatNumber(QuotaService.adBonusTokens)} 토큰을 추가로 받을 수 있습니다.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // 닫기 버튼
        TextButton(
          onPressed: _isLoading ? null : widget.onClose,
          child: const Text('나중에'),
        ),
        // 광고 시청 버튼
        ShadButton(
          onPressed: _isLoading ? null : _watchAd,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 18),
                    SizedBox(width: 4),
                    Text('광고 보고 토큰 받기'),
                  ],
                ),
        ),
      ],
    );
  }

  /// 숫자 포맷 (1000 → 1,000)
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
