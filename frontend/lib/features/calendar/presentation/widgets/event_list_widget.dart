import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/calendar_event.dart';
import '../providers/calendar_event_provider.dart';
import 'add_event_bottom_sheet.dart';

/// 일정 목록 위젯
class EventListWidget extends ConsumerWidget {
  final DateTime selectedDate;
  final List<CalendarEvent> events;

  const EventListWidget({
    super.key,
    required this.selectedDate,
    required this.events,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;

    if (events.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Row(
          children: [
            Icon(
              Icons.event_note_rounded,
              color: theme.primaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'calendar.events_header'.tr(namedArgs: {'count': events.length.toString()}),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 일정 목록
        ...events.map((event) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _EventCard(
            event: event,
            selectedDate: selectedDate,
            onDelete: () => _deleteEvent(context, ref, event),
            onEdit: () => _editEvent(context, event),
          ),
        )),
      ],
    );
  }

  Widget _buildEmptyState(AppThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              color: theme.textMuted.withOpacity(0.5),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'calendar.no_events_registered'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: theme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(BuildContext context, WidgetRef ref, CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = context.appTheme;
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'calendar.event_delete_title'.tr(),
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'calendar.event_delete_confirm'.tr(namedArgs: {'title': event.title}),
            style: TextStyle(color: theme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'common.buttonCancel'.tr(),
                style: TextStyle(color: theme.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'common.delete'.tr(),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(calendarEventNotifierProvider.notifier).deleteEvent(event.id);
    }
  }

  Future<void> _editEvent(BuildContext context, CalendarEvent event) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEventBottomSheet(
        selectedDate: selectedDate,
        editEvent: event,
      ),
    );
  }
}

/// 개별 일정 카드
class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final DateTime selectedDate;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _EventCard({
    required this.event,
    required this.selectedDate,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final category = event.category;

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      confirmDismiss: (_) async {
        onDelete();
        return false; // 직접 삭제 처리
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.red,
        ),
      ),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: category.color.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              // 카테고리 아이콘
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // 일정 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          event.formattedTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textMuted,
                          ),
                        ),
                        if (event.description != null) ...[
                          Text(
                            ' · ',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textMuted,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              event.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // 삭제 버튼
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
