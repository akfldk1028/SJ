# SH - UI/UX 개발

## 역할
- **UI 컴포넌트**: shadcn_ui 기반 위젯 개발
- **화면 구현**: 모든 Screen/Page 개발
- **애니메이션**: 인터랙션, 트랜지션 효과
- **공통 위젯**: shared/ 폴더 관리

---

## 담당 폴더

### 전용 영역 (자유 수정)
```
frontend/lib/
├── shared/                 # 공통 위젯
│   ├── widgets/            # 재사용 위젯
│   ├── extensions/         # Dart 확장
│   └── theme/              # 테마 설정
│
├── features/*/presentation/
│   ├── screens/            # 화면
│   └── widgets/            # 화면별 위젯
│
└── core/theme/             # 앱 테마
```

### 협업 영역
```
frontend/lib/features/saju_chat/presentation/  # AI 팀과 협업
frontend/lib/features/saju_chart/presentation/ # AI 팀과 협업
```

---

## 수정 금지

```
frontend/lib/AI/              # AI 팀 전용
sql/                          # JH_BE 전용
frontend/lib/features/*/data/ # 데이터 레이어
frontend/lib/router/          # DK 전용
```

---

## 사용 Agent

| Agent | 용도 |
|-------|------|
| 08_shadcn_ui_builder | shadcn_ui 컴포넌트 |
| 02_widget_composer | 위젯 분해 |
| 00_widget_tree_guard | 성능 검증 (필수) |

---

## 커밋 컨벤션

```
[SH] feat: 채팅 화면 UI 구현
[SH] fix: 버튼 스타일 수정
[SH] refactor: 공통 위젯 분리
[SH] style: 다크모드 테마 적용
```

---

## 주요 책임

1. **위젯 분리**: 100줄 이하, const 생성자 사용
2. **성능**: ListView.builder 필수, 불필요한 rebuild 방지
3. **접근성**: 시맨틱 위젯 사용
4. **반응형**: 다양한 화면 크기 대응

---

## Widget Tree Guard 체크리스트

모든 PR 전 확인:
- [ ] const 생성자 사용
- [ ] ListView.builder 사용 (10개 이상 리스트)
- [ ] 위젯 100줄 이하
- [ ] setState 범위 최소화
- [ ] 불필요한 Container 제거

---

## AI 팀과 협업

```dart
// AI 팀이 제공하는 Stream 사용
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // AI Provider에서 Stream 받아서 UI 렌더링
    final chatStream = ref.watch(chatStreamProvider);

    return StreamBuilder<String>(
      stream: chatStream,
      builder: (context, snapshot) {
        // UI 렌더링
      },
    );
  }
}
```

---

## shadcn_ui 컴포넌트

우선 사용:
- `ShadButton` (버튼)
- `ShadInput` (입력)
- `ShadCard` (카드)
- `ShadDialog` (다이얼로그)
- `ShadSheet` (바텀시트)
- `ShadToast` (토스트)

---

## 충돌 방지 (Lock 시스템)

### 작업 시작 전
```bash
git pull origin develop
ls .claude/locks/   # lock 파일 확인
```

### shared/ 폴더 수정 시
```bash
# 1. Lock 생성
echo "owner: SH
task: 작업 내용
started: $(date -Iseconds)" > .claude/locks/shared.lock

# 2. 작업 진행...

# 3. 완료 후
rm .claude/locks/shared.lock
git add . && git commit && git push
```

### features/*/presentation/ 은 내 전용 → Lock 불필요

### core/theme/ 수정 시
```bash
echo "owner: SH
task: 테마 수정
started: $(date -Iseconds)" > .claude/locks/core.lock
# ... 작업 후 삭제
```
