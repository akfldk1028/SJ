# DK - 총괄 + 광고 모듈

## 역할
- **프로젝트 총괄**: 전체 아키텍처, 일정, 코드 리뷰 관리
- **광고 모듈**: AdMob, 인앱 결제 연동
- **인터페이스 관리**: 팀 간 API 계약 정의/승인

---

## 담당 폴더

### 전용 영역 (자유 수정)
```
frontend/lib/
├── features/ads/           # 광고 모듈
├── router/                 # 라우팅 설정
└── core/interfaces/        # 팀 간 인터페이스 정의

.claude/
├── team/                   # 팀 역할 관리
└── JH_Agent/               # Agent 정의
```

### 승인 필요 영역
```
frontend/lib/core/          # 공통 코드 (팀원 PR 리뷰)
frontend/pubspec.yaml       # 의존성 추가
```

---

## 수정 금지

```
frontend/lib/AI/jh/         # JH_AI 전용
frontend/lib/AI/jina/       # Jina 전용
sql/                        # JH_BE 전용
```

---

## 사용 Agent

| Agent | 용도 |
|-------|------|
| 00_orchestrator | 작업 분석, 파이프라인 구성 |
| 00_widget_tree_guard | 위젯 트리 최적화 검증 |
| 07_task_tracker | TASKS.md 관리 |

---

## 커밋 컨벤션

```
[DK] feat: 광고 모듈 초기 구조
[DK] fix: 라우팅 버그 수정
[DK] chore: 인터페이스 계약 업데이트
```

---

## 주요 책임

1. **매일**: develop 브랜치 통합 빌드 확인
2. **PR 리뷰**: core/, shared/ 변경 승인
3. **인터페이스**: 팀 간 API 변경 시 조율
4. **릴리즈**: 버전 태깅, 배포 관리

---

## 충돌 방지 (Lock 시스템)

### 작업 시작 전
```bash
git pull origin develop
ls .claude/locks/   # lock 파일 확인
```

### 공유 폴더 수정 시
```bash
# 1. Lock 생성
echo "owner: DK
task: 작업 내용
started: $(date -Iseconds)" > .claude/locks/core.lock

# 2. 작업 진행...

# 3. 완료 후 lock 삭제 + 커밋
rm .claude/locks/core.lock
git add . && git commit && git push
```

### 내가 관리하는 Lock
- `core.lock` - core/ 폴더
- `router.lock` - router/ 폴더
- `pubspec.lock` - pubspec.yaml
