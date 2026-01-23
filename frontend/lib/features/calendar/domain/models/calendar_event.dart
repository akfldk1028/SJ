import 'package:flutter/material.dart';

/// 캘린더 일정 모델
class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final TimeOfDay? time;
  final EventCategory category;
  final DateTime createdAt;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.time,
    required this.category,
    required this.createdAt,
  });

  /// 복사본 생성
  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    EventCategory? category,
    DateTime? createdAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time != null ? '${time!.hour}:${time!.minute}' : null,
      'category': category.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// JSON 역직렬화
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    TimeOfDay? time;
    if (json['time'] != null) {
      final parts = (json['time'] as String).split(':');
      time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      time: time,
      category: EventCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => EventCategory.general,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 포맷된 시간 문자열
  String get formattedTime {
    if (time == null) return '종일';
    final hour = time!.hour.toString().padLeft(2, '0');
    final minute = time!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// 일정 카테고리
enum EventCategory {
  general('일반', Icons.event_rounded, Color(0xFF6B7280)),
  important('중요', Icons.star_rounded, Color(0xFFB8860B)),
  fortune('운세', Icons.auto_awesome_rounded, Color(0xFF8B5CF6)),
  memo('메모', Icons.note_rounded, Color(0xFF3B82F6)),
  anniversary('기념일', Icons.cake_rounded, Color(0xFFEC4899));

  final String label;
  final IconData icon;
  final Color color;

  const EventCategory(this.label, this.icon, this.color);
}
