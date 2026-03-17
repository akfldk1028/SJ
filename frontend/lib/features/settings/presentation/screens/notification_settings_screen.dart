import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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

/// 알림 설정 화면 - shadcn_ui 기반
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.notification'.tr()),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 전체 알림 설정
              ShadCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.bell,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'settings.pushNotification'.tr(),
                            style: theme.textTheme.p.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            settings.pushEnabled
                                ? 'settings.pushEnabled'.tr()
                                : 'settings.pushDisabled'.tr(),
                            style: theme.textTheme.small.copyWith(
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ShadSwitch(
                      value: settings.pushEnabled,
                      onChanged: (value) => notifier.togglePush(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 알림 세부 설정
              _buildSectionHeader(context, 'settings.notificationType'.tr()),
              const SizedBox(height: 8),
              Opacity(
                opacity: settings.pushEnabled ? 1.0 : 0.5,
                child: ShadCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildToggleRow(
                        context,
                        icon: LucideIcons.sun,
                        title: 'settings.dailyFortune'.tr(),
                        subtitle: 'settings.dailyFortuneDesc'.tr(),
                        value: settings.dailyFortune,
                        onChanged: settings.pushEnabled
                            ? (v) => notifier.toggleDailyFortune(v)
                            : null,
                      ),
                      const Divider(height: 1),
                      _buildToggleRow(
                        context,
                        icon: LucideIcons.messageCircle,
                        title: 'settings.chatReply'.tr(),
                        subtitle: 'settings.chatReplyDesc'.tr(),
                        value: settings.chatReply,
                        onChanged: settings.pushEnabled
                            ? (v) => notifier.toggleChatReply(v)
                            : null,
                      ),
                      const Divider(height: 1),
                      _buildToggleRow(
                        context,
                        icon: LucideIcons.megaphone,
                        title: 'settings.eventNotice'.tr(),
                        subtitle: 'settings.eventNoticeDesc'.tr(),
                        value: settings.eventNotice,
                        onChanged: settings.pushEnabled
                            ? (v) => notifier.toggleEventNotice(v)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 마케팅 알림
              _buildSectionHeader(context, 'settings.marketingConsent'.tr()),
              const SizedBox(height: 8),
              Opacity(
                opacity: settings.pushEnabled ? 1.0 : 0.5,
                child: ShadCard(
                  padding: EdgeInsets.zero,
                  child: _buildToggleRow(
                    context,
                    icon: LucideIcons.tag,
                    title: 'settings.marketingNotice'.tr(),
                    subtitle: 'settings.marketingNoticeDesc'.tr(),
                    value: settings.marketingNotice,
                    onChanged: settings.pushEnabled
                        ? (v) => notifier.toggleMarketingNotice(v)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = ShadTheme.of(context);
    return Text(
      title,
      style: theme.textTheme.small.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.mutedForeground,
      ),
    );
  }

  Widget _buildToggleRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.mutedForeground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.p),
                Text(
                  subtitle,
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          ShadSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
