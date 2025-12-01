# /review - 코드 리뷰 Agent

$ARGUMENTS 기능의 코드를 리뷰합니다.

## 실행 순서

1. **명세서 로드**: `docs/02_features/$ARGUMENTS.md`
2. **구현 코드 로드**: `lib/features/$ARGUMENTS/`
3. **테스트 코드 로드**: `test/features/$ARGUMENTS/`
4. **리뷰 수행**

## 검토 항목

### 기능 완성도
- [ ] 명세서의 모든 수락 조건 충족
- [ ] UI/UX 흐름 일치
- [ ] 예외 처리 구현

### 아키텍처 (03_architecture.md)
- [ ] 폴더 구조 준수
- [ ] 레이어 분리 (presentation/domain/data)
- [ ] 의존성 방향 준수

### 상태관리 (09_state_management.md)
- [ ] Riverpod 3.0 패턴 준수
- [ ] @riverpod annotation 사용
- [ ] AsyncNotifier 적절히 사용
- [ ] 불필요한 rebuild 없음

### 위젯 최적화 (10_widget_tree_optimization.md)
- [ ] const 위젯 사용
- [ ] 위젯 분리 적절함
- [ ] ListView.builder 사용 (리스트)
- [ ] 불필요한 setState 없음

### 코드 품질
- [ ] 네이밍 일관성
- [ ] 주석 적절함
- [ ] 중복 코드 없음
- [ ] 에러 처리 적절함

## 출력

- 리뷰 결과 요약
- 수정 필요 항목 목록
- 개선 제안
