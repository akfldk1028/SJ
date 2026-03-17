import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/calendar_event.dart';
import '../providers/calendar_event_provider.dart';

/// 일정 추가/수정 Bottom Sheet
class AddEventBottomSheet extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final CalendarEvent? editEvent; // null이면 추가, 있으면 수정

  const AddEventBottomSheet({
    super.key,
    required this.selectedDate,
    this.editEvent,
  });

  @override
  ConsumerState<AddEventBottomSheet> createState() => _AddEventBottomSheetState();
}

class _AddEventBottomSheetState extends ConsumerState<AddEventBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late EventCategory _selectedCategory;
  TimeOfDay? _selectedTime;
  bool _isAllDay = true;

  bool get _isEditing => widget.editEvent != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.editEvent?.title ?? '');
    _descriptionController = TextEditingController(text: widget.editEvent?.description ?? '');
    _selectedCategory = widget.editEvent?.category ?? EventCategory.general;
    _selectedTime = widget.editEvent?.time;
    _isAllDay = widget.editEvent?.time == null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        final theme = context.appTheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: theme.primaryColor,
              surface: theme.cardColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
        _isAllDay = false;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('calendar.event_title_required'.tr())),
      );
      return;
    }

    final event = CalendarEvent(
      id: widget.editEvent?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      date: widget.selectedDate,
      time: _isAllDay ? null : _selectedTime,
      category: _selectedCategory,
      createdAt: widget.editEvent?.createdAt ?? DateTime.now(),
    );

    final notifier = ref.read(calendarEventNotifierProvider.notifier);
    if (_isEditing) {
      await notifier.updateEvent(event);
    } else {
      await notifier.addEvent(event);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 핸들 바
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 헤더
              Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit_rounded : Icons.add_rounded,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isEditing ? 'calendar.event_edit'.tr() : 'calendar.event_add'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(widget.selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 제목 입력
              _buildTextField(
                theme,
                controller: _titleController,
                hint: 'calendar.event_title_hint'.tr(),
                icon: Icons.title_rounded,
              ),
              const SizedBox(height: 16),

              // 설명 입력
              _buildTextField(
                theme,
                controller: _descriptionController,
                hint: 'calendar.event_memo_hint'.tr(),
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // 시간 설정
              Row(
                children: [
                  Expanded(
                    child: _buildOptionButton(
                      theme,
                      icon: Icons.access_time_rounded,
                      label: _isAllDay ? 'calendar.all_day'.tr() : _formatTime(_selectedTime!),
                      isSelected: !_isAllDay,
                      onTap: _selectTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isAllDay = true;
                        _selectedTime = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isAllDay
                            ? theme.primaryColor.withOpacity(0.1)
                            : theme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isAllDay
                              ? theme.primaryColor.withOpacity(0.3)
                              : theme.textMuted.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        'calendar.all_day'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: _isAllDay ? theme.primaryColor : theme.textSecondary,
                          fontWeight: _isAllDay ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 카테고리 선택
              Text(
                'calendar.category'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EventCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? category.color.withOpacity(0.15)
                            : theme.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? category.color.withOpacity(0.5)
                              : theme.textMuted.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category.icon,
                            size: 16,
                            color: isSelected ? category.color : theme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getCategoryLabel(category),
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? category.color : theme.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isEditing ? 'calendar.save_edit'.tr() : 'calendar.save_add'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    AppThemeExtension theme, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.textMuted.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: theme.textMuted,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            color: theme.textMuted,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    AppThemeExtension theme, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.1)
              : theme.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor.withOpacity(0.3)
                : theme.textMuted.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? theme.primaryColor : theme.textMuted,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? theme.primaryColor : theme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(EventCategory category) {
    switch (category) {
      case EventCategory.general:
        return 'calendar.event_category_general'.tr();
      case EventCategory.important:
        return 'calendar.event_category_important'.tr();
      case EventCategory.fortune:
        return 'calendar.event_category_fortune'.tr();
      case EventCategory.memo:
        return 'calendar.event_category_memo'.tr();
      case EventCategory.anniversary:
        return 'calendar.event_category_anniversary'.tr();
    }
  }

  String _formatDate(DateTime date) {
    const weekdayKeys = [
      'calendar.weekday_mon',
      'calendar.weekday_tue',
      'calendar.weekday_wed',
      'calendar.weekday_thu',
      'calendar.weekday_fri',
      'calendar.weekday_sat',
      'calendar.weekday_sun',
    ];
    final weekday = weekdayKeys[date.weekday - 1].tr();
    return 'calendar.date_format_short'.tr(namedArgs: {
      'month': date.month.toString(),
      'day': date.day.toString(),
      'weekday': weekday,
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
