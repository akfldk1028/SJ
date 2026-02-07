import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadButton, ShadCard;

import '../../core/theme/app_theme.dart';
import '../../router/routes.dart';
import '../providers/purchase_provider.dart';
import 'restore_button_widget.dart';

/// 구독 관리 화면
///
/// - 현재 플랜 정보
/// - 남은 기간 (N일 N시간 N분)
/// - 만료일 (2/13까지 유효)
/// - 만료 임박 경고
/// - 구매/업그레이드 버튼
/// - 구매 복원
class SubscriptionManageScreen extends ConsumerStatefulWidget {
  const SubscriptionManageScreen({super.key});

  @override
  ConsumerState<SubscriptionManageScreen> createState() =>
      _SubscriptionManageScreenState();
}

class _SubscriptionManageScreenState
    extends ConsumerState<SubscriptionManageScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    ref.watch(purchaseNotifierProvider);
    final notifier = ref.read(purchaseNotifierProvider.notifier);
    final isPremium = notifier.isPremium;
    final planName = notifier.activePlanName;
    final expiresAt = notifier.expiresAt;
    final isExpiringSoon = notifier.isExpiringSoon;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text('purchase.subscriptionManage'.tr(), style: TextStyle(color: theme.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 현재 구독 상태 카드
            _buildStatusCard(theme, isPremium, planName, expiresAt, isExpiringSoon),
            const SizedBox(height: 20),

            // 남은 기간 상세
            if (isPremium && expiresAt != null) ...[
              _buildRemainingTimeCard(theme, expiresAt, isExpiringSoon),
              const SizedBox(height: 16),
              _buildValidUntilCard(theme, expiresAt, isExpiringSoon),
              const SizedBox(height: 20),
            ],

            // 만료 임박 경고
            if (isExpiringSoon) ...[
              _buildExpiryWarning(theme),
              const SizedBox(height: 20),
            ],

            // 액션 버튼
            if (isPremium)
              ShadButton.outline(
                onPressed: () => context.push(Routes.settingsPremium),
                child: Text(
                  'purchase.changePlanUpgrade'.tr(),
                  style: TextStyle(color: theme.textPrimary, fontSize: 15),
                ),
              )
            else
              ShadButton(
                onPressed: () => context.push(Routes.settingsPremium),
                backgroundColor: theme.primaryColor,
                child: Text(
                  'purchase.purchasePremium'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 16),
            const RestoreButtonWidget(),
            const SizedBox(height: 32),

            // 안내
            Text(
              'purchase.termsManage'.tr(),
              style: TextStyle(color: theme.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 구독 상태 카드
  Widget _buildStatusCard(
    AppThemeExtension theme,
    bool isPremium,
    String? planName,
    DateTime? expiresAt,
    bool isExpiringSoon,
  ) {
    return ShadCard(
      child: Column(
        children: [
          // 아이콘
          Icon(
            isPremium ? Icons.workspace_premium : Icons.lock_outline,
            size: 48,
            color: isPremium
                ? (isExpiringSoon ? Colors.orange : Colors.amber)
                : theme.textMuted,
          ),
          const SizedBox(height: 12),

          // 상태 텍스트
          Text(
            isPremium ? 'purchase.premiumActive'.tr() : 'purchase.freePlan'.tr(),
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          if (planName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                planName,
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Text(
              'purchase.freeDescription'.tr(),
              style: TextStyle(color: theme.textMuted, fontSize: 13),
            ),
        ],
      ),
    );
  }

  /// 남은 기간 카드 (N일 N시간 N분)
  Widget _buildRemainingTimeCard(
    AppThemeExtension theme,
    DateTime expiresAt,
    bool isExpiringSoon,
  ) {
    var remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) remaining = Duration.zero;
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;

    final color = isExpiringSoon ? Colors.redAccent : theme.primaryColor;

    return ShadCard(
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'purchase.remainingPeriod'.tr(),
                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRemainingDetailed(days, hours, minutes),
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 유효기간 카드 (N월 N일까지 유효)
  Widget _buildValidUntilCard(
    AppThemeExtension theme,
    DateTime expiresAt,
    bool isExpiringSoon,
  ) {
    final dateStr = '${expiresAt.month}/${expiresAt.day}';
    final timeStr =
        '${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}';

    return ShadCard(
      child: Row(
        children: [
          Icon(
            Icons.event_outlined,
            color: isExpiringSoon ? Colors.orange : theme.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'purchase.validPeriod'.tr(),
                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'purchase.validUntil'.tr(namedArgs: {'date': dateStr, 'time': timeStr}),
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 만료 임박 경고 배너
  Widget _buildExpiryWarning(AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'purchase.expiryWarningTitle'.tr(),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'purchase.expiryWarningMessage'.tr(),
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 남은 시간 상세 포맷
  String _formatRemainingDetailed(int days, int hours, int minutes) {
    if (days > 0) {
      return 'purchase.remainingDaysHoursMinutes'.tr(namedArgs: {
        'days': '$days',
        'hours': '$hours',
        'minutes': '$minutes',
      });
    }
    if (hours > 0) {
      return 'purchase.remainingHoursMinutes'.tr(namedArgs: {
        'hours': '$hours',
        'minutes': '$minutes',
      });
    }
    return 'purchase.remainingMinutes'.tr(namedArgs: {'minutes': '$minutes'});
  }
}
