# /implement - 기능 구현 Agent

$ARGUMENTS 기능을 구현합니다.

## 실행 순서

1. **문서 로드**: `docs/02_features/$ARGUMENTS.md` 읽기
2. **아키텍처 확인**: `docs/03_architecture.md` 폴더 구조 확인
3. **데이터 모델 확인**: `docs/04_data_models.md` 참조
4. **상태관리 패턴**: `docs/09_state_management.md` Riverpod 3.0 패턴 적용
5. **위젯 최적화**: `docs/10_widget_tree_optimization.md` 원칙 준수

## 코드 생성 순서

1. Domain Layer
   - `entities/` - 엔티티 클래스
   - `repositories/` - 레포지토리 인터페이스

2. Data Layer
   - `models/` - 데이터 모델 (fromJson, toJson)
   - `datasources/` - 데이터소스 (Supabase 연동)
   - `repositories/` - 레포지토리 구현체

3. Presentation Layer
   - `providers/` - Riverpod Provider (@riverpod)
   - `screens/` - 화면 위젯
   - `widgets/` - 재사용 위젯

## 체크리스트

- [ ] 명세서 수락 조건 모두 충족
- [ ] const 위젯 사용
- [ ] 에러 처리 포함
- [ ] 로딩 상태 처리
