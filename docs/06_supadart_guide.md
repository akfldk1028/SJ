# Supadart 가이드

> Supabase DB 스키마 → Dart 타입 자동 생성

## 개요

**supadart**는 Supabase 테이블 스키마를 읽어서 Dart 클래스를 자동 생성합니다.
- 타입 안전성 보장
- snake_case → camelCase 자동 변환
- fromJson/toJson 자동 생성
- insert/update 헬퍼 메서드 제공

---

## 설치 (최초 1회)

```bash
dart pub global activate supadart
```

---

## 설정

### 1. 설정 파일 생성

```bash
cd frontend
cp supadart.yaml.example supadart.yaml
```

### 2. API 키 입력

`supadart.yaml` 편집:
```yaml
supabase_url: https://YOUR_PROJECT_REF.supabase.co
supabase_api_key: YOUR_ANON_KEY_HERE
output: lib/core/supabase/generated/
separated: true
```

> **주의**: `supadart.yaml`은 `.gitignore`에 포함됨 (API 키 보안)

### API 키 확인 방법
1. [Supabase Dashboard](https://supabase.com/dashboard) 접속
2. Project Settings → API
3. `anon` public key 복사

---

## 타입 생성

### 기본 명령어

```bash
cd frontend
dart pub global run supadart
```

### CLI 옵션으로 직접 실행

```bash
dart pub global run supadart \
  -u "https://xxx.supabase.co" \
  -k "eyJhbGci..."
```

### 도움말

```bash
dart pub global run supadart --help
```

---

## 생성되는 파일

```
lib/core/supabase/generated/
├── supadart_exports.dart      # 전체 export
├── supadart_header.dart       # 공통 인터페이스
├── saju_analyses.dart         # saju_analyses 테이블
├── saju_profiles.dart         # saju_profiles 테이블
├── chat_sessions.dart         # chat_sessions 테이블
├── chat_messages.dart         # chat_messages 테이블
└── compatibility_analyses.dart # compatibility_analyses 테이블
```

---

## 사용법

### Import

```dart
import 'package:frontend/core/supabase/generated/supadart_exports.dart';
```

### 테이블명 접근

```dart
// 하드코딩 대신:
supabase.from('saju_analyses')

// 타입 안전하게:
supabase.from(SajuAnalyses.table_name)
```

### 컬럼명 접근

```dart
// 하드코딩 대신:
.eq('profile_id', id)

// 타입 안전하게:
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
      monthGan: '을',
      monthJi: '축',
      dayGan: '병',
      dayJi: '인',
      ohengDistribution: {'wood': 2, 'fire': 3, 'earth': 1, 'metal': 1, 'water': 1},
    ));
```

### Update

```dart
await supabase
    .from(SajuAnalyses.table_name)
    .update(SajuAnalyses.update(
      dayStrength: {'score': 55, 'is_singang': true},
    ))
    .eq(SajuAnalyses.c_id, analysisId);
```

### copyWith (Immutable 업데이트)

```dart
final updated = original.copyWith(
  yearGan: '을',
  dayStrength: {'score': 60},
);
```

---

## 생성된 클래스 구조

```dart
class SajuAnalyses {
  // 필드
  final String id;
  final String profileId;
  final String yearGan;
  // ...

  // 테이블명
  static String get table_name => 'saju_analyses';

  // 컬럼명 (snake_case)
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

## DB 스키마 변경 시

1. Supabase에서 테이블/컬럼 수정
2. 타입 재생성:
   ```bash
   cd frontend
   dart pub global run supadart
   ```
3. 컴파일 에러 확인 및 수정
4. 테스트 실행:
   ```bash
   flutter test test/supadart_test.dart
   ```

---

## 테스트

```bash
cd frontend
flutter test test/supadart_test.dart
```

---

## 문제 해결

### "supadart not found"
```bash
# PATH에 추가 필요
# Windows: C:\Users\{USER}\AppData\Local\Pub\Cache\bin

# 또는 dart로 직접 실행
dart pub global run supadart
```

### "401 Unauthorized"
- API 키가 올바른지 확인
- `anon` 키 사용 (service_role 아님)

### "Config file not found"
```bash
# supadart.yaml 생성
cp supadart.yaml.example supadart.yaml
# API 키 입력
```

---

## 참고 링크

- [supadart | pub.dev](https://pub.dev/packages/supadart)
- [GitHub - mmvergara/supadart](https://github.com/mmvergara/supadart)
- [Supabase Dashboard](https://supabase.com/dashboard)
