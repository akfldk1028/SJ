# /log - LOG AGENT

최근 Agent 활동 로그를 조회합니다.

## 로그 위치

`.claude/logs/[YYYY-MM-DD].md`

## 로그 형식

```markdown
## 2025-12-01 14:30:00

### [TODO] profile_input
- 작업 5개로 분해
- 체크리스트 생성 완료

### [ARCH] profile_input
- lib/features/profile/ 구조 생성
- 12개 파일 템플릿 생성

### [MODULE] profile_input
- saju_profile.dart 구현
- profile_repository.dart 구현
- profile_provider.dart 구현

### [ERROR]
- ProfileScreen: missing import 'package:flutter_riverpod'
- 자동 수정 완료

### [TEST] profile_input
- 8개 테스트 작성
- 8/8 통과 (100%)

### [DELETE]
- 3개 unused import 제거
- 1개 commented code 삭제

### [SUMMARY]
- 총 소요 시간: 15분
- 생성 파일: 12개
- 테스트: 8/8 통과
- 정리: 4개 항목
```

## 조회 옵션

```bash
# 오늘 로그
/log

# 특정 날짜
/log 2025-12-01

# 특정 기능
/log profile_input

# 에러만
/log errors
```

## 출력

- 로그 내용 표시
- 요약 통계
