# Lock System (충돌 방지)

## 목적
5명이 Claude CLI로 동시 작업 시 Git 충돌 방지

## 사용법

### Lock 파일 생성 (작업 시작 시)
```bash
# 예: core/ 폴더 수정 전
echo "owner: DK
task: 광고 모듈 설정 추가
started: $(date -Iseconds)" > .claude/locks/core.lock
```

### Lock 파일 삭제 (작업 완료 시)
```bash
rm .claude/locks/core.lock
git add . && git commit && git push
```

## Lock이 필요한 폴더

| 폴더 | Lock 파일 | 관리자 |
|------|----------|--------|
| `core/` | `core.lock` | DK 승인 |
| `shared/` | `shared.lock` | SH |
| `AI/common/` | `ai-common.lock` | JH_AI + Jina |
| `router/` | `router.lock` | DK |
| `pubspec.yaml` | `pubspec.lock` | DK 승인 |

## 규칙

1. **작업 전**: lock 파일 확인
2. **Lock 있으면**: 작업 중단, owner에게 연락
3. **Lock 없으면**: lock 파일 생성 후 작업
4. **작업 완료**: lock 파일 삭제 + 커밋 + 푸시
5. **2시간 초과**: lock 만료로 간주, 슬랙에서 확인 후 삭제 가능

## Claude CLI 자동 체크

CLAUDE.md에 규칙이 있으므로 Claude가 자동으로:
- 공유 폴더 수정 전 lock 확인
- Lock 있으면 사용자에게 알림
- 작업 완료 후 lock 삭제 알림
