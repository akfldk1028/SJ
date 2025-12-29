# Supadart Generated Types

> 자동 생성됨 - 직접 수정 금지
> 생성 도구: [supadart](https://pub.dev/packages/supadart)

---

## 개요

Supabase DB 스키마에서 자동 생성된 Dart 타입 정의 파일들입니다.
**이 폴더의 파일은 직접 수정하지 마세요** - 재생성 시 덮어씌워집니다.

---

## 파일 구조

```
generated/
├── supadart_header.dart       # 공통 인터페이스 + Extension
├── supadart_exports.dart      # 전체 export (import용)
├── saju_analyses.dart         # saju_analyses 테이블 타입
├── saju_profiles.dart         # saju_profiles 테이블 타입
├── chat_sessions.dart         # chat_sessions 테이블 타입
├── chat_messages.dart         # chat_messages 테이블 타입
├── compatibility_analyses.dart # compatibility_analyses 테이블 타입
└── README.md                  # 이 파일
```

---

## 파일별 역할

| 파일 | 역할 |
|------|------|
| `supadart_header.dart` | `SupadartClass` 인터페이스, `SupadartClient` Extension |
| `supadart_exports.dart` | 모든 테이블 타입 re-export (import 간소화) |
| `saju_analyses.dart` | 사주 분석 테이블 - 사주팔자, 오행, 용신 등 |
| `saju_profiles.dart` | 프로필 테이블 - 생년월일, 이름, 설정 |
| `chat_sessions.dart` | 채팅 세션 테이블 - 대화 목록 |
| `chat_messages.dart` | 채팅 메시지 테이블 - 개별 메시지 |
| `compatibility_analyses.dart` | 궁합 분석 테이블 |

---

## 사용법

### Import

```dart
import 'package:frontend/core/supabase/generated/supadart_exports.dart';
```

### 테이블명 접근

```dart
// 하드코딩 대신
supabase.from('saju_analyses')

// 타입 안전하게
supabase.from(SajuAnalyses.table_name)
```

### 컬럼명 접근

```dart
// 하드코딩 대신
.eq('profile_id', id)

// 타입 안전하게
.eq(SajuAnalyses.c_profileId, id)
```

### 조회 + 타입 변환

```dart
final response = await supabase
    .from(SajuAnalyses.table_name)
    .select()
    .eq(SajuAnalyses.c_profileId, profileId);

// List 변환
final analyses = SajuAnalyses.converter(response);

// 단일 객체 변환
final analysis = SajuAnalyses.converterSingle(response.first);
```

### Insert

```dart
await supabase
    .from(SajuAnalyses.table_name)
    .insert(SajuAnalyses.insert(
      profileId: 'xxx',
      yearGan: '갑',
      yearJi: '자',
      // ... required 필드들
    ));
```

### Update

```dart
await supabase
    .from(SajuAnalyses.table_name)
    .update(SajuAnalyses.update(
      dayStrength: {'score': 55},
    ))
    .eq(SajuAnalyses.c_id, analysisId);
```

---

## 생성된 클래스 구조

각 테이블 클래스는 다음 구조를 가집니다:

```dart
class SajuAnalyses implements SupadartClass<SajuAnalyses> {
  // 필드 (camelCase)
  final String id;
  final String profileId;
  final String yearGan;
  // ...

  // 테이블명
  static String get table_name => 'saju_analyses';

  // 컬럼명 (snake_case 반환)
  static String get c_id => 'id';
  static String get c_profileId => 'profile_id';
  static String get c_yearGan => 'year_gan';
  // ...

  // 변환 메서드
  static List<SajuAnalyses> converter(List<Map<String, dynamic>> data);
  static SajuAnalyses converterSingle(Map<String, dynamic> data);
  factory SajuAnalyses.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();

  // CRUD 헬퍼
  static Map<String, dynamic> insert({...});  // required 필드 강제
  static Map<String, dynamic> update({...});  // 모두 optional

  // Immutable 업데이트
  SajuAnalyses copyWith({...});
}
```

---

## 재생성 방법

DB 스키마 변경 시:

```bash
cd frontend
dart pub global run supadart
```

또는 CLI 옵션으로:

```bash
dart pub global run supadart \
  -u "https://xxx.supabase.co" \
  -k "YOUR_ANON_KEY"
```

---

## 설정 파일

`frontend/supadart.yaml` (gitignored):

```yaml
supabase_url: https://YOUR_PROJECT.supabase.co
supabase_api_key: YOUR_ANON_KEY
output: lib/core/supabase/generated/
separated: true
```

템플릿: `frontend/supadart.yaml.example`

---

## 테스트

```bash
cd frontend
flutter test test/supadart_test.dart
```

---

## 관련 문서

- `docs/06_supadart_guide.md` - 상세 가이드
- [supadart | pub.dev](https://pub.dev/packages/supadart)
- [GitHub - mmvergara/supadart](https://github.com/mmvergara/supadart)
