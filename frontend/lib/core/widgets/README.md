# core/widgets/

앱 전역에서 사용하는 공통 위젯.

## 파일 목록

| 파일 | 역할 |
|------|------|
| `main_shell.dart` | ShellRoute 레이아웃 (Scaffold + BottomNav) |
| `main_bottom_nav.dart` | 하단 네비게이션 바 (5탭: 운세, 인맥, AI상담, 캘린더, 설정) |

## main_bottom_nav.dart

- `ConsumerWidget` (Riverpod WidgetRef 사용)
- 탭 전환 시 `context.go(route)` 호출
- **v30**: "운세"(index 0) 또는 "AI 상담"(index 2) 탭 클릭 시 `_triggerSajuBaseIfNeeded()` 호출
  - GPT-5.2 saju_base가 없으면 백그라운드로 생성 시작 (fire-and-forget)
  - `SajuAnalysisService._analyzingProfiles` Set으로 중복 방지
  - 이미 캐시 있으면 즉시 반환 (비용 0)

## main_shell.dart

- `StatelessWidget`
- `MainBottomNav`를 포함하는 Scaffold
- `app_router.dart`의 `ShellRoute.builder`에서 사용

## 참고

- `main_scaffold.dart` (`features/home/`)는 미사용 레거시 파일. 실제 앱은 `MainShell` + `MainBottomNav` 사용.
