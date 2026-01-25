import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../domain/models/calendar_event.dart';

part 'calendar_event_provider.g.dart';

/// 캘린더 일정 상태 관리
@riverpod
class CalendarEventNotifier extends _$CalendarEventNotifier {
  static const String _storageKey = 'calendar_events';

  @override
  Future<List<CalendarEvent>> build() async {
    return _loadEvents();
  }

  /// 저장된 일정 로드
  Future<List<CalendarEvent>> _loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      return [];
    }
  }

  /// 일정 저장
  Future<void> _saveEvents(List<CalendarEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = events.map((e) => e.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// 일정 추가
  Future<void> addEvent(CalendarEvent event) async {
    final currentEvents = await future;
    final newEvents = [...currentEvents, event]
      ..sort((a, b) => a.date.compareTo(b.date));

    state = AsyncData(newEvents);
    await _saveEvents(newEvents);
  }

  /// 일정 수정
  Future<void> updateEvent(CalendarEvent event) async {
    final currentEvents = await future;
    final newEvents = currentEvents.map((e) {
      return e.id == event.id ? event : e;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    state = AsyncData(newEvents);
    await _saveEvents(newEvents);
  }

  /// 일정 삭제
  Future<void> deleteEvent(String eventId) async {
    final currentEvents = await future;
    final newEvents = currentEvents.where((e) => e.id != eventId).toList();

    state = AsyncData(newEvents);
    await _saveEvents(newEvents);
  }

  /// 특정 날짜의 일정 조회
  List<CalendarEvent> getEventsForDay(DateTime day, List<CalendarEvent> events) {
    return events.where((event) => isSameDay(event.date, day)).toList();
  }
}

/// 특정 날짜의 일정 provider
@riverpod
List<CalendarEvent> eventsForDay(Ref ref, DateTime day) {
  final eventsAsync = ref.watch(calendarEventNotifierProvider);

  return eventsAsync.when(
    data: (events) => events.where((e) => isSameDay(e.date, day)).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
}

/// 일정이 있는 날짜들 provider
@riverpod
Set<DateTime> datesWithEvents(Ref ref) {
  final eventsAsync = ref.watch(calendarEventNotifierProvider);

  return eventsAsync.when(
    data: (events) => events
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet(),
    loading: () => {},
    error: (_, __) => {},
  );
}
