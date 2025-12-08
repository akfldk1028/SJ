/// 천간지지 상수 및 데이터
/// 사주팔자 계산에 사용되는 천간(10개)과 지지(12개) 정의
///
/// JSON 기반 통합 데이터 구조로 리팩토링됨
/// - 타입 안전성 향상
/// - 확장성 개선 (음양, 시간대, 월 등 추가 속성)
/// - 단일 소스(Single Source of Truth)
library;

import 'dart:convert';
import '../models/cheongan_model.dart';
import '../models/jiji_model.dart';
import '../models/oheng_model.dart';

// ============================================================================
// JSON 임베드 데이터 (컴파일 타임 최적화)
// ============================================================================

const String _cheonganJijiJson = '''
{
  "cheongan": [
    {"hangul": "갑", "hanja": "甲", "oheng": "목", "eum_yang": "양", "order": 0},
    {"hangul": "을", "hanja": "乙", "oheng": "목", "eum_yang": "음", "order": 1},
    {"hangul": "병", "hanja": "丙", "oheng": "화", "eum_yang": "양", "order": 2},
    {"hangul": "정", "hanja": "丁", "oheng": "화", "eum_yang": "음", "order": 3},
    {"hangul": "무", "hanja": "戊", "oheng": "토", "eum_yang": "양", "order": 4},
    {"hangul": "기", "hanja": "己", "oheng": "토", "eum_yang": "음", "order": 5},
    {"hangul": "경", "hanja": "庚", "oheng": "금", "eum_yang": "양", "order": 6},
    {"hangul": "신", "hanja": "辛", "oheng": "금", "eum_yang": "음", "order": 7},
    {"hangul": "임", "hanja": "壬", "oheng": "수", "eum_yang": "양", "order": 8},
    {"hangul": "계", "hanja": "癸", "oheng": "수", "eum_yang": "음", "order": 9}
  ],
  "jiji": [
    {"hangul": "자", "hanja": "子", "oheng": "수", "eum_yang": "양", "animal": "쥐", "month": 11, "hour_start": 23, "hour_end": 1, "order": 0},
    {"hangul": "축", "hanja": "丑", "oheng": "토", "eum_yang": "음", "animal": "소", "month": 12, "hour_start": 1, "hour_end": 3, "order": 1},
    {"hangul": "인", "hanja": "寅", "oheng": "목", "eum_yang": "양", "animal": "호랑이", "month": 1, "hour_start": 3, "hour_end": 5, "order": 2},
    {"hangul": "묘", "hanja": "卯", "oheng": "목", "eum_yang": "음", "animal": "토끼", "month": 2, "hour_start": 5, "hour_end": 7, "order": 3},
    {"hangul": "진", "hanja": "辰", "oheng": "토", "eum_yang": "양", "animal": "용", "month": 3, "hour_start": 7, "hour_end": 9, "order": 4},
    {"hangul": "사", "hanja": "巳", "oheng": "화", "eum_yang": "음", "animal": "뱀", "month": 4, "hour_start": 9, "hour_end": 11, "order": 5},
    {"hangul": "오", "hanja": "午", "oheng": "화", "eum_yang": "양", "animal": "말", "month": 5, "hour_start": 11, "hour_end": 13, "order": 6},
    {"hangul": "미", "hanja": "未", "oheng": "토", "eum_yang": "음", "animal": "양", "month": 6, "hour_start": 13, "hour_end": 15, "order": 7},
    {"hangul": "신", "hanja": "申", "oheng": "금", "eum_yang": "양", "animal": "원숭이", "month": 7, "hour_start": 15, "hour_end": 17, "order": 8},
    {"hangul": "유", "hanja": "酉", "oheng": "금", "eum_yang": "음", "animal": "닭", "month": 8, "hour_start": 17, "hour_end": 19, "order": 9},
    {"hangul": "술", "hanja": "戌", "oheng": "토", "eum_yang": "양", "animal": "개", "month": 9, "hour_start": 19, "hour_end": 21, "order": 10},
    {"hangul": "해", "hanja": "亥", "oheng": "수", "eum_yang": "음", "animal": "돼지", "month": 10, "hour_start": 21, "hour_end": 23, "order": 11}
  ],
  "oheng": [
    {"name": "목", "hanja": "木", "color": "#4CAF50", "season": "봄", "direction": "동"},
    {"name": "화", "hanja": "火", "color": "#F44336", "season": "여름", "direction": "남"},
    {"name": "토", "hanja": "土", "color": "#FF9800", "season": "환절기", "direction": "중앙"},
    {"name": "금", "hanja": "金", "color": "#FFD700", "season": "가을", "direction": "서"},
    {"name": "수", "hanja": "水", "color": "#2196F3", "season": "겨울", "direction": "북"}
  ]
}
''';

// ============================================================================
// 데이터 저장소 (Singleton)
// ============================================================================

class CheonganJijiData {
  static CheonganJijiData? _instance;

  final List<CheonganModel> cheonganList;
  final List<JijiModel> jijiList;
  final List<OhengModel> ohengList;

  // 빠른 조회를 위한 Map 캐시
  final Map<String, CheonganModel> _cheonganByHangul;
  final Map<String, CheonganModel> _cheonganByHanja;
  final Map<String, JijiModel> _jijiByHangul;
  final Map<String, JijiModel> _jijiByHanja;
  final Map<String, OhengModel> _ohengByName;

  CheonganJijiData._({
    required this.cheonganList,
    required this.jijiList,
    required this.ohengList,
  })  : _cheonganByHangul = {for (var c in cheonganList) c.hangul: c},
        _cheonganByHanja = {for (var c in cheonganList) c.hanja: c},
        _jijiByHangul = {for (var j in jijiList) j.hangul: j},
        _jijiByHanja = {for (var j in jijiList) j.hanja: j},
        _ohengByName = {for (var o in ohengList) o.name: o};

  /// 싱글톤 인스턴스
  static CheonganJijiData get instance {
    _instance ??= _parseFromJson(_cheonganJijiJson);
    return _instance!;
  }

  /// JSON 파싱
  static CheonganJijiData _parseFromJson(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);

    final cheonganList = (data['cheongan'] as List)
        .map((e) => CheonganModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final jijiList = (data['jiji'] as List)
        .map((e) => JijiModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final ohengList = (data['oheng'] as List)
        .map((e) => OhengModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return CheonganJijiData._(
      cheonganList: cheonganList,
      jijiList: jijiList,
      ohengList: ohengList,
    );
  }

  // ============================================================================
  // 조회 메서드
  // ============================================================================

  /// 한글로 천간 조회
  CheonganModel? getCheonganByHangul(String hangul) => _cheonganByHangul[hangul];

  /// 한자로 천간 조회
  CheonganModel? getCheonganByHanja(String hanja) => _cheonganByHanja[hanja];

  /// 한글로 지지 조회
  JijiModel? getJijiByHangul(String hangul) => _jijiByHangul[hangul];

  /// 한자로 지지 조회
  JijiModel? getJijiByHanja(String hanja) => _jijiByHanja[hanja];

  /// 오행 조회
  OhengModel? getOhengByName(String name) => _ohengByName[name];

  /// 인덱스로 천간 조회
  CheonganModel getCheonganByIndex(int index) => cheonganList[index % 10];

  /// 인덱스로 지지 조회
  JijiModel getJijiByIndex(int index) => jijiList[index % 12];

  /// 시간으로 지지 조회 (0-23시)
  JijiModel? getJijiByHour(int hour) {
    for (final jiji in jijiList) {
      if (jiji.hourStart <= jiji.hourEnd) {
        // 일반 시간대 (예: 1-3시)
        if (hour >= jiji.hourStart && hour < jiji.hourEnd) {
          return jiji;
        }
      } else {
        // 자시처럼 자정을 넘기는 경우 (23-1시)
        if (hour >= jiji.hourStart || hour < jiji.hourEnd) {
          return jiji;
        }
      }
    }
    return null;
  }
}

// ============================================================================
// 하위 호환성을 위한 기존 인터페이스 (Backward Compatibility)
// ============================================================================

/// 천간 (天干) - 10개 리스트
List<String> get cheongan =>
    CheonganJijiData.instance.cheonganList.map((c) => c.hangul).toList();

/// 지지 (地支) - 12개 리스트
List<String> get jiji =>
    CheonganJijiData.instance.jijiList.map((j) => j.hangul).toList();

/// 천간 오행 매핑
Map<String, String> get cheonganOheng => {
  for (var c in CheonganJijiData.instance.cheonganList) c.hangul: c.oheng
};

/// 지지 오행 매핑
Map<String, String> get jijiOheng => {
  for (var j in CheonganJijiData.instance.jijiList) j.hangul: j.oheng
};

/// 천간 한자 매핑
Map<String, String> get cheonganHanja => {
  for (var c in CheonganJijiData.instance.cheonganList) c.hangul: c.hanja
};

/// 지지 한자 매핑
Map<String, String> get jijiHanja => {
  for (var j in CheonganJijiData.instance.jijiList) j.hangul: j.hanja
};

/// 지지 동물 매핑
Map<String, String> get jijiAnimal => {
  for (var j in CheonganJijiData.instance.jijiList) j.hangul: j.animal
};

/// 천간 음양 매핑
Map<String, String> get cheonganEumYang => {
  for (var c in CheonganJijiData.instance.cheonganList) c.hangul: c.eumYang
};

/// 지지 음양 매핑
Map<String, String> get jijiEumYang => {
  for (var j in CheonganJijiData.instance.jijiList) j.hangul: j.eumYang
};

/// 오행 한자 매핑
Map<String, String> get ohengHanja => {
  for (var o in CheonganJijiData.instance.ohengList) o.name: o.hanja
};

/// 오행 색상 매핑 (hex string)
Map<String, String> get ohengColor => {
  for (var o in CheonganJijiData.instance.ohengList) o.name: o.color
};

// ============================================================================
// 헬퍼 함수
// ============================================================================

/// 오행 조회 함수 (기존 호환성)
String? getOheng(String char, {bool isCheongan = true}) {
  if (isCheongan) {
    return cheonganOheng[char];
  }
  return jijiOheng[char];
}

/// 한글 → 한자 변환
String? toHanja(String hangul, {bool isCheongan = true}) {
  if (isCheongan) {
    return cheonganHanja[hangul];
  }
  return jijiHanja[hangul];
}

/// 한자 → 한글 변환
String? toHangul(String hanja, {bool isCheongan = true}) {
  final data = CheonganJijiData.instance;
  if (isCheongan) {
    return data.getCheonganByHanja(hanja)?.hangul;
  }
  return data.getJijiByHanja(hanja)?.hangul;
}

/// 천간 인덱스 조회
int? getCheonganIndex(String hangul) {
  final model = CheonganJijiData.instance.getCheonganByHangul(hangul);
  return model?.order;
}

/// 지지 인덱스 조회
int? getJijiIndex(String hangul) {
  final model = CheonganJijiData.instance.getJijiByHangul(hangul);
  return model?.order;
}
