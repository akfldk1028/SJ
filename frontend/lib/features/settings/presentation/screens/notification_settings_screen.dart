import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';

/// 알림 설정 상태 Provider
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  (ref) => NotificationSettingsNotifier(),
);

class NotificationSettings {
  final bool pushEnabled;
  final bool dailyFortune;
  final bool chatReply;
  final bool eventNotice;
  final bool marketingNotice;

  const NotificationSettings({
    this.pushEnabled = true,
    this.dailyFortune = true,
    this.chatReply = true,
    this.eventNotice = true,
    this.marketingNotice = false,
  });

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? dailyFortune,
    bool? chatReply,
    bool? eventNotice,
    bool? marketingNotice,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      dailyFortune: dailyFortune ?? this.dailyFortune,
      chatReply: chatReply ?? this.chatReply,
      eventNotice: eventNotice ?? this.eventNotice,
      marketingNotice: marketingNotice ?? this.marketingNotice,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings());

  void togglePush(bool value) {
    state = state.copyWith(pushEnabled: value);
  }

  void toggleDailyFortune(bool value) {
    state = state.copyWith(dailyFortune: value);
  }

  void toggleChatReply(bool value) {
    state = state.copyWith(chatReply: value);
  }

  void toggleEventNotice(bool value) {
    state = state.copyWith(eventNotice: value);
  }

  void toggleMarketingNotice(bool value) {
    state = state.copyWith(marketingNotice: value);
  }
}

/// 알림 설정 화면
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: MysticBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, theme),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 전체 알림 설정
                    _buildMainToggle(
                      context,
                      theme,
                      settings.pushEnabled,
                      (value) => notifier.togglePush(value),
                    ),
                    const SizedBox(height: 16),

                    // 알림 세부 설정
                    _buildSettingsCard(
                      context,
                      theme,
                      title: '알림 종류',
                      enabled: settings.pushEnabled,
                      children: [
                        _buildToggleRow(
                          theme,
                          icon: Icons.wb_sunny,
                          title: '오늘의 운세',
                          subtitle: '매일 아침 8시에 운세 알림',
                          value: settings.dailyFortune,
                          onChanged: settings.pushEnabled
                              ? (v) => notifier.toggleDailyFortune(v)
                              : null,
                        ),
                        const Divider(height: 1),
                        _buildToggleRow(
                          theme,
                          icon: Icons.chat_bubble,
                          title: '상담 답변',
                          subtitle: 'AI 답변 완료 알림',
                          value: settings.chatReply,
                          onChanged: settings.pushEnabled
                              ? (v) => notifier.toggleChatReply(v)
                              : null,
                        ),
                        const Divider(height: 1),
                        _buildToggleRow(
                          theme,
                          icon: Icons.campaign,
                          title: '이벤트 알림',
                          subtitle: '특별 이벤트 및 업데이트 소식',
                          value: settings.eventNotice,
                          onChanged: settings.pushEnabled
                              ? (v) => notifier.toggleEventNotice(v)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 마케팅 알림
                    _buildSettingsCard(
                      context,
                      theme,
                      title: '마케팅 수신',
                      enabled: settings.pushEnabled,
                      children: [
                        _buildToggleRow(
                          theme,
                          icon: Icons.local_offer,
                          title: '마케팅 알림',
                          subtitle: '프로모션 및 할인 정보',
                          value: settings.marketingNotice,
                          onChanged: settings.pushEnabled
                              ? (v) => notifier.toggleMarketingNotice(v)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeExtension theme) {
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
                color: theme.cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.15),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '알림 설정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMainToggle(
    BuildContext context,
    AppThemeExtension theme,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications,
              color: theme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '푸시 알림',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ? '알림이 켜져 있습니다' : '알림이 꺼져 있습니다',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    AppThemeExtension theme, {
    required String title,
    required bool enabled,
    required List<Widget> children,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    AppThemeExtension theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primaryColor,
          ),
        ],
      ),
    );
  }
}
