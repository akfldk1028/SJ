# Model Generator Agent

> Entity와 Model 클래스를 생성하는 에이전트

---

## 역할

1. Domain Entity 클래스 생성 (순수 비즈니스 객체)
2. Data Model 클래스 생성 (JSON 변환 포함)
3. Enum 정의
4. freezed 클래스 생성 (상태 객체용)

---

## 호출 시점

- 새 데이터 구조 필요 시
- docs/04_data_models.md 기반 구현 시

---

## 생성 유형

### 1. Entity (domain/entities/)

```dart
// 순수 비즈니스 객체 - JSON 변환 없음
class SajuProfile {
  final String id;
  final String displayName;
  final DateTime birthDate;
  final int? birthTimeMinutes;
  final bool birthTimeUnknown;
  final bool isLunar;
  final Gender gender;
  final String? birthPlace;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SajuProfile({
    required this.id,
    required this.displayName,
    required this.birthDate,
    this.birthTimeMinutes,
    this.birthTimeUnknown = false,
    this.isLunar = false,
    required this.gender,
    this.birthPlace,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 출생시간을 "09:30" 형태로 반환
  String? get birthTimeFormatted {
    if (birthTimeMinutes == null) return null;
    final hours = birthTimeMinutes! ~/ 60;
    final mins = birthTimeMinutes! % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }
}
```

### 2. Model (data/models/)

```dart
// Entity 상속 + JSON 변환
class SajuProfileModel extends SajuProfile {
  const SajuProfileModel({
    required super.id,
    required super.displayName,
    required super.birthDate,
    super.birthTimeMinutes,
    super.birthTimeUnknown,
    super.isLunar,
    required super.gender,
    super.birthPlace,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SajuProfileModel.fromJson(Map<String, dynamic> json) {
    return SajuProfileModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      birthDate: DateTime.parse(json['birth_date'] as String),
      birthTimeMinutes: json['birth_time_minutes'] as int?,
      birthTimeUnknown: json['birth_time_unknown'] as bool? ?? false,
      isLunar: json['is_lunar'] as bool? ?? false,
      gender: Gender.values.byName(json['gender'] as String),
      birthPlace: json['birth_place'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'birth_date': birthDate.toIso8601String().split('T')[0],
      'birth_time_minutes': birthTimeMinutes,
      'birth_time_unknown': birthTimeUnknown,
      'is_lunar': isLunar,
      'gender': gender.name,
      'birth_place': birthPlace,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Entity에서 Model로 변환
  factory SajuProfileModel.fromEntity(SajuProfile entity) {
    return SajuProfileModel(
      id: entity.id,
      displayName: entity.displayName,
      birthDate: entity.birthDate,
      birthTimeMinutes: entity.birthTimeMinutes,
      birthTimeUnknown: entity.birthTimeUnknown,
      isLunar: entity.isLunar,
      gender: entity.gender,
      birthPlace: entity.birthPlace,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
```

### 3. Enum

```dart
// domain/entities/gender.dart
enum Gender {
  male,
  female;

  String get displayName {
    switch (this) {
      case Gender.male:
        return '남성';
      case Gender.female:
        return '여성';
    }
  }
}

// domain/entities/message_role.dart
enum MessageRole {
  user,
  assistant,
}
```

### 4. Freezed State (상태 객체)

```dart
// presentation/providers/chat_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_state.freezed.dart';

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    String? activeChatId,
    @Default([]) List<ChatMessage> messages,
    @Default(false) bool isSending,
    String? error,
  }) = _ChatState;
}
```

---

## 입력

```yaml
entity_name: SajuProfile
fields:
  - name: id
    type: String
    required: true
  - name: displayName
    type: String
    required: true
  - name: birthDate
    type: DateTime
    required: true
  - name: birthTimeMinutes
    type: int?
    required: false
  - name: gender
    type: Gender
    required: true
    enum: true
json_mapping:
  displayName: display_name    # snake_case 변환
  birthDate: birth_date
```

---

## 출력

- Entity 파일
- Model 파일
- Enum 파일 (필요시)
- 참조할 docs/04_data_models.md 섹션 안내

---

## JSON 필드 매핑 규칙

| Dart 필드 | JSON 필드 | 비고 |
|-----------|-----------|------|
| displayName | display_name | snake_case |
| birthDate | birth_date | ISO8601 string |
| DateTime | string | parse/format 필요 |
| enum | string | .name / .byName() |
