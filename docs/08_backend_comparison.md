# Firebase vs Supabase 비교 분석

> 만톡: AI 사주 챗봇 백엔드 선택을 위한 비교 검토

---

## 1. 요약 결론

| 항목 | 추천 | 이유 |
|------|------|------|
| **만톡 앱** | **Supabase** | 관계형 데이터(사주 프로필/차트), SQL 쿼리 필요, 비용 효율적 |

---

## 2. 서비스 개요

| 항목 | Firebase | Supabase |
|------|----------|----------|
| 제공사 | Google | 오픈소스 (YC 스타트업) |
| 출시 | 2011년 | 2020년 |
| 데이터베이스 | NoSQL (Firestore, Realtime DB) | PostgreSQL (관계형) |
| 오픈소스 | X | O (자체 호스팅 가능) |
| Flutter 지원 | 공식 SDK | 공식 SDK |

---

## 3. 만톡 앱 요구사항 기준 비교

### 3.1 데이터 구조 적합성

**만톡의 핵심 데이터:**
```
User (1) ─────< (N) SajuProfile
                      │
                      ├── (1) SajuChart
                      │         └── (4) Pillar
                      │         └── (N) Daewoon
                      │
                      ├── (1) SajuSummary
                      │
                      └──< (N) ChatSession
                                  └──< (N) ChatMessage
```

| 기준 | Firebase | Supabase | 승자 |
|------|----------|----------|------|
| 관계형 데이터 | 비정규화 필요 | 자연스러운 JOIN | **Supabase** |
| 프로필 ↔ 차트 관계 | 서브컬렉션 or 별도 문서 | Foreign Key | **Supabase** |
| 복잡한 쿼리 | 제한적 (복합 인덱스 필요) | 완전한 SQL | **Supabase** |
| 히스토리 검색 | 어려움 | LIKE, Full-text | **Supabase** |

### 3.2 인증 (Auth)

| 기준 | Firebase | Supabase |
|------|----------|----------|
| 이메일/비밀번호 | O | O |
| 소셜 로그인 | Google, Apple, Facebook 등 | Google, Apple, GitHub 등 |
| 익명 로그인 | O | O |
| 전화번호 인증 | O | X (Twilio 연동 필요) |
| **Flutter 통합** | 매우 쉬움 | 쉬움 |

**결론**: 둘 다 충분. 전화번호 인증이 필요하면 Firebase 유리.

### 3.3 실시간 기능

| 기준 | Firebase | Supabase |
|------|----------|----------|
| 실시간 리스너 | Firestore Streams | Realtime Subscriptions |
| 채팅 실시간 | 매우 적합 | 적합 |
| 성능 | 검증됨 | 좋음 |

**결론**: Firebase가 약간 우위, 하지만 만톡은 AI 응답 기반이라 실시간 중요도 낮음.

### 3.4 파일 저장소

| 기준 | Firebase | Supabase |
|------|----------|----------|
| 이미지 업로드 | Cloud Storage | Supabase Storage |
| CDN | O | O |
| 접근 제어 | Security Rules | Row Level Security |

**결론**: 동등. 만톡 MVP에서는 파일 업로드 없음.

### 3.5 서버리스 함수

| 기준 | Firebase | Supabase |
|------|----------|----------|
| 함수 서비스 | Cloud Functions | Edge Functions (Deno) |
| 언어 | Node.js, Python | TypeScript (Deno) |
| 콜드 스타트 | 있음 | 적음 |
| **Gemini 연동** | Cloud Functions에서 호출 | Edge Functions에서 호출 |

**결론**: 동등. 둘 다 LLM API 호출 가능.

---

## 4. 비용 비교

### 4.1 무료 티어

| 항목 | Firebase (Spark) | Supabase (Free) |
|------|------------------|-----------------|
| DB 저장소 | 1GB | 500MB |
| Auth 사용자 | 무제한 | 50,000 MAU |
| 함수 호출 | 125K/월 | 500K/월 |
| 파일 저장소 | 5GB | 1GB |
| 대역폭 | 10GB/월 | 2GB/월 |

### 4.2 유료 티어 (월 예상 비용)

**만톡 예상 사용량** (MAU 1,000명 기준):
- DB 읽기: 100K/일
- DB 쓰기: 10K/일
- 함수 호출: 50K/월
- 저장소: 1GB

| 항목 | Firebase | Supabase |
|------|----------|----------|
| 예상 월 비용 | $25~50 | $25 (Pro 고정) |
| 확장성 | 사용량 비례 (예측 어려움) | 예측 가능 (단계별 요금) |

**결론**: Supabase가 비용 예측이 쉽고, 초기 스타트업에 유리.

---

## 5. Flutter 통합 난이도

### 5.1 Firebase Flutter 설정
```bash
# FlutterFire CLI 사용
dart pub global activate flutterfire_cli
flutterfire configure
```

```dart
// main.dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

**장점**: 공식 도구로 설정 자동화, 문서 풍부
**단점**: google-services.json, GoogleService-Info.plist 관리 필요

### 5.2 Supabase Flutter 설정
```yaml
dependencies:
  supabase_flutter: ^2.0.0
```

```dart
// main.dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_ANON_KEY',
  );
  runApp(MyApp());
}
```

**장점**: 설정 단순, URL과 Key만 필요
**단점**: Firebase 대비 레퍼런스 적음

---

## 6. 만톡 앱 시나리오별 비교

### 6.1 사주 프로필 저장/조회

**Firebase (Firestore):**
```dart
// 프로필 저장
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('profiles')
    .add(profileData);

// 프로필 + 차트 조회 (2번 쿼리 필요)
final profile = await profileRef.get();
final chart = await chartRef.get();
```

**Supabase (PostgreSQL):**
```dart
// 프로필 저장
await supabase.from('saju_profiles').insert(profileData);

// 프로필 + 차트 조회 (JOIN으로 1번에)
final data = await supabase
    .from('saju_profiles')
    .select('*, saju_charts(*)')
    .eq('id', profileId)
    .single();
```

**승자**: Supabase (관계형 쿼리 효율적)

### 6.2 채팅 히스토리 검색

**Firebase:**
```dart
// 제목으로 검색 - 전체 데이터 가져와서 클라이언트 필터링
// 또는 Algolia 같은 외부 검색 서비스 필요
```

**Supabase:**
```dart
// SQL LIKE 검색
final chats = await supabase
    .from('chat_sessions')
    .select()
    .ilike('title', '%이직%');
```

**승자**: Supabase (검색 기능 내장)

---

## 7. 최종 추천

### 7.1 Supabase 추천 이유

1. **관계형 데이터 적합**
   - 사주 프로필 ↔ 차트 ↔ 채팅 관계가 명확
   - JOIN 쿼리로 효율적 데이터 조회

2. **비용 예측 가능**
   - Pro 플랜 $25/월 고정
   - 스타트업 초기에 비용 관리 용이

3. **오픈소스**
   - Vendor Lock-in 위험 낮음
   - 자체 호스팅 옵션 있음

4. **SQL 지원**
   - 복잡한 통계, 검색 쿼리 가능
   - 만세력 데이터 분석에 유리

### 7.2 Firebase가 나은 경우

- 전화번호 인증이 필수인 경우
- 실시간 협업 기능이 핵심인 경우
- Google 생태계 (GCP, BigQuery) 활용 계획
- 팀에 Firebase 경험자가 있는 경우

---

## 8. 선택 가이드 체크리스트

| 질문 | Firebase | Supabase |
|------|----------|----------|
| 데이터가 관계형인가? | | **O** |
| SQL 쿼리가 필요한가? | | **O** |
| 비용 예측이 중요한가? | | **O** |
| 전화번호 인증이 필요한가? | **O** | |
| 실시간 협업이 핵심인가? | **O** | |
| Google 생태계 활용 예정? | **O** | |
| 오픈소스/자체 호스팅 원하는가? | | **O** |

---

## 9. 결론

**만톡 앱에는 Supabase 추천**

- 사주 프로필, 차트, 채팅 히스토리 등 관계형 데이터 구조
- PostgreSQL의 강력한 쿼리 기능
- 예측 가능한 비용 구조
- Flutter SDK 공식 지원

단, MVP 단계에서는 로컬 저장소(Hive)만으로도 충분하며,
서버 연동은 로그인/동기화 기능 추가 시 도입 권장.

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| 2025-12-01 | 0.1 | 초안 작성 | - |
