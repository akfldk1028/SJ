# Prompt Version Tracking System

## 개요

만톡 앱의 AI 프롬프트 버전 관리 및 사용자 데이터 추적 시스템 문서입니다.

---

## 현재 시스템 구조

### 버전 관리 중앙 허브

**파일**: `frontend/lib/AI/core/ai_constants.dart`

```dart
abstract class PromptVersions {
  /// 사주 기본 분석 프롬프트 버전
  /// - V9.4 (2026-01-24): 카테고리별 상세 필드 전체 매핑
  /// - V9.5 (2026-01-24): Phase maxTokens 대폭 확장
  static const String sajuBase = 'V9.5';

  /// 일운 프롬프트 버전
  static const String dailyFortune = 'V2.1';

  /// 월운 프롬프트 버전
  static const String monthlyFortune = 'V5.1';

  /// 연운 프롬프트 버전
  static const String yearlyFortune = 'V1.0';
  static const String yearlyFortune2026 = 'V5.1';
  static const String yearlyFortune2025 = 'V3.1';
}
```

### 데이터 흐름

```
ai_constants.dart (버전 정의)
       ↓
  queries.dart (버전 re-export + 캐시 검증)
       ↓
  mutations.dart (DB 저장 시 버전 포함)
       ↓
  ai_summaries 테이블 (prompt_version 필드)
```

---

## 버전 관리 방식 비교

### 1. 수동 시맨틱 버전 (현재 방식) ✅ 권장

```
V9.5, V2.1, V5.1
```

**장점**:
- 버전 순서 추적 가능 (`WHERE prompt_version >= 'V9.0'`)
- 히스토리 이해 용이
- CS/디버깅 쉬움
- 마이그레이션 가능

**단점**:
- 수동 업데이트 필요
- 프롬프트 수정 시 버전 업데이트 누락 가능

### 2. 해시 기반 자동 버전 ❌ 비권장

```
Ha3f8c2d, Hb7e9f1a
```

**장점**:
- 프롬프트 수정 시 자동 버전 변경
- 콘텐츠 무결성 보장

**단점**:
- 버전 순서 추적 불가
- SQL 범위 쿼리 불가
- 10,000+ 사용자 데이터 추적 어려움
- 디버깅/CS 대응 어려움
- 마이그레이션 불가

---

## 업계 표준 (리서치 결과)

### Langfuse (프롬프트 관리 표준)

> "Production traces capture which prompt version generated each output"

- **시맨틱 버전 + 라벨** 사용
- 환경별 배포: `production`, `staging`, `latest`
- 롤백 기능 제공

### Braintrust

- 콘텐츠 해시 사용하되 **버전 매핑 테이블** 유지
- 해시 → 시맨틱 버전 매핑으로 추적성 확보

### LaunchDarkly

- Feature flag 기반 점진적 롤아웃
- 버전별 A/B 테스트 지원

---

## 캐시 무효화 로직

**파일**: `frontend/lib/AI/fortune/daily/daily_queries.dart`

```dart
const String kDailyFortunePromptVersion = PromptVersions.dailyFortune;

// 캐시 검증 (lines 65-70)
final cachedVersion = response['prompt_version'];
if (cachedVersion != kDailyFortunePromptVersion) {
  print('[DailyQueries] 프롬프트 버전 불일치...');
  return null;  // 캐시 무효화 → 재분석 트리거
}
```

**동작 원리**:
1. DB에서 캐시된 분석 결과 조회
2. 저장된 `prompt_version`과 현재 버전 비교
3. 불일치 시 `null` 반환 → 새로운 AI 분석 실행
4. 새 분석 결과에 현재 버전 저장

---

## DB 스키마

### ai_summaries 테이블

| 필드 | 타입 | 설명 |
|------|------|------|
| id | uuid | PK |
| profile_id | uuid | FK → profiles |
| summary_type | text | 'saju_base', 'daily_fortune' 등 |
| **prompt_version** | text | 'V9.5', 'V2.1' 등 |
| content | jsonb | AI 분석 결과 |
| target_date | date | 일운/월운 대상 날짜 |
| created_at | timestamp | 생성 시간 |
| expires_at | timestamp | 만료 시간 |

### 버전별 데이터 현황 조회

```sql
SELECT
  summary_type,
  prompt_version,
  COUNT(*) as count
FROM ai_summaries
GROUP BY summary_type, prompt_version
ORDER BY summary_type, prompt_version;
```

---

## 버전 업데이트 절차

### 프롬프트 수정 시

1. **프롬프트 파일 수정**
   - `frontend/lib/AI/prompts/` 내 해당 파일

2. **버전 업데이트**
   - `ai_constants.dart`의 `PromptVersions` 클래스에서 버전 증가
   - 변경 이력 주석 추가

3. **테스트**
   - 캐시 무효화 동작 확인
   - 새 버전으로 분석 실행 확인

4. **커밋**
   ```bash
   git commit -m "[JH_AI/Jina] feat: 프롬프트 V9.6 업데이트 - OOO 개선"
   ```

### 버전 히스토리 기록 예시

```dart
/// 사주 기본 분석 프롬프트 버전
///
/// ## 변경 이력
/// - V9.0 (2026-01-20): JSON 스키마 통합
/// - V9.1 (2026-01-21): 오행 분석 상세화
/// - V9.2 (2026-01-22): 용신 판단 로직 개선
/// - V9.3 (2026-01-23): 대운 분석 추가
/// - V9.4 (2026-01-24): 카테고리별 상세 필드 전체 매핑
/// - V9.5 (2026-01-24): Phase maxTokens 대폭 확장
static const String sajuBase = 'V9.5';
```

---

## 향후 개선 옵션 (선택사항)

### 옵션 1: prompt_versions 레지스트리 테이블

```sql
CREATE TABLE prompt_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prompt_type text NOT NULL,        -- 'saju_base', 'daily_fortune'
  version text NOT NULL,            -- 'V9.5'
  description text,                 -- 변경 내용
  content_hash text,                -- 콘텐츠 해시 (참조용)
  environment text DEFAULT 'production',
  created_at timestamp DEFAULT now(),
  created_by text,                  -- 'JH_AI', 'Jina'
  UNIQUE(prompt_type, version)
);
```

### 옵션 2: 환경 라벨 시스템

```dart
abstract class PromptVersions {
  static const String sajuBase = 'V9.5';
  static const String sajuBaseEnv = 'production';  // production, staging, latest
}
```

### 옵션 3: Git Pre-commit Hook (경고용)

```bash
#!/bin/bash
# .git/hooks/pre-commit

PROMPT_FILES=$(git diff --cached --name-only | grep "lib/AI/prompts/")
if [ -n "$PROMPT_FILES" ]; then
  echo "⚠️ 프롬프트 파일 수정 감지됨:"
  echo "$PROMPT_FILES"
  echo ""
  echo "ai_constants.dart의 버전도 업데이트했는지 확인하세요!"
fi
```

---

## 참고 자료

- [Langfuse Prompt Management](https://langfuse.com/docs/prompts)
- [Braintrust Prompt Versioning](https://braintrustdata.com)
- [LaunchDarkly Feature Flags](https://launchdarkly.com)

---

## 담당자

| 영역 | 담당 |
|------|------|
| 사주 분석 프롬프트 | JH_AI |
| 대화 프롬프트 | Jina |
| DB 스키마 | JH_BE |

---

*최종 업데이트: 2026-01-24*
