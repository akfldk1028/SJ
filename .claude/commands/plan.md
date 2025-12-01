# /plan - 기획/설계 Agent

$ARGUMENTS 에 대한 기획/설계를 수행합니다.

## 실행 순서

1. **프로젝트 컨텍스트**: `docs/01_overview.md` 읽기
2. **기존 문서 확인**: `docs/` 전체 구조 파악
3. **기획서 작성/수정**

## 작업 유형

### 새 기능 기획
- `docs/02_features/[기능명].md` 생성
- `docs/_template.md` 포맷 사용
- 수락 조건, UI/UX 흐름, 테스트 케이스 포함

### 기존 문서 수정
- 해당 문서 읽고 수정사항 반영
- 변경 이력 업데이트

### 데이터 모델 설계
- `docs/04_data_models.md`에 테이블 추가
- Supabase PostgreSQL 스키마
- RLS 정책 정의

### API 설계
- `docs/05_api_spec.md`에 Edge Function 추가
- 요청/응답 예시 포함

## 출력

- 업데이트된 마크다운 문서
- 변경 요약
