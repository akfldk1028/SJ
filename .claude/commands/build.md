# /build - Orchestrator Agent (자동 파이프라인)

$ARGUMENTS 기능을 자동으로 전체 파이프라인으로 구현합니다.

## 🚨 중요: 자동 실행 지시

이 커맨드는 **Orchestrator**로서 아래 Worker Agent들을 **순차적으로 자동 호출**해야 합니다.
각 단계가 완료되면 다음 단계를 **자동으로** 진행하세요. 사용자에게 매번 확인받지 마세요.

---

## 실행 파이프라인

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
  TODO      ARCH     MODULE     TEST     DELETE
```

### Phase 1: TODO AGENT 실행
**Task tool로 subagent 호출:**
```
subagent_type: "general-purpose"
prompt: "docs/02_features/$ARGUMENTS.md를 분석하여 작업을 분해하고 TodoWrite로 체크리스트 생성"
```

실행 내용:
1. `docs/02_features/$ARGUMENTS.md` 로드
2. 수락 조건(Acceptance Criteria) 분석
3. TodoWrite로 세부 작업 체크리스트 생성

---

### Phase 2: ARCHITECTURE AGENT 실행
**Task tool로 subagent 호출:**
```
subagent_type: "general-purpose"
prompt: "lib/features/$ARGUMENTS/ 폴더 구조 생성. docs/03_architecture.md 패턴 준수"
```

실행 내용:
1. Feature 폴더 구조 생성 (domain/data/presentation)
2. 빈 템플릿 파일 생성
3. .gitkeep 추가

생성 구조:
```
lib/features/$ARGUMENTS/
├── domain/
│   ├── entities/
│   └── repositories/
├── data/
│   ├── models/
│   ├── datasources/
│   └── repositories/
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

---

### Phase 3: MODULE AGENT 실행
**Task tool로 subagent 호출:**
```
subagent_type: "general-purpose"
prompt: "$ARGUMENTS 기능 코드 구현. 참조: docs/02_features/$ARGUMENTS.md, docs/04_data_models.md, docs/05_api_spec.md, docs/09_state_management.md"
```

실행 내용 (순서대로):
1. **Domain Layer**
   - Entity 클래스 생성
   - Repository interface 정의

2. **Data Layer**
   - Model 클래스 (fromJson, toJson)
   - RemoteDataSource (Supabase)
   - LocalDataSource (Hive 캐시)
   - RepositoryImpl

3. **Presentation Layer**
   - Provider (@riverpod)
   - Screen 위젯
   - 재사용 위젯

코드 규칙:
- `docs/09_state_management.md` Riverpod 3.0 패턴
- `docs/10_widget_tree_optimization.md` const 위젯
- 에러 처리 포함

---

### Phase 4: TEST AGENT 실행
**Task tool로 subagent 호출:**
```
subagent_type: "general-purpose"
prompt: "$ARGUMENTS 기능 테스트 작성 및 실행. docs/02_features/$ARGUMENTS.md 테스트 케이스 섹션 참조"
```

실행 내용:
1. Provider 테스트 작성
2. Widget 테스트 작성
3. `flutter test` 실행
4. 실패 시 코드 수정 후 재실행

테스트 구조:
```
test/features/$ARGUMENTS/
├── domain/repositories/
├── data/repositories/
└── presentation/
    ├── providers/
    └── screens/
```

---

### Phase 5: DELETE AGENT 실행
**Task tool로 subagent 호출:**
```
subagent_type: "general-purpose"
prompt: "lib/features/$ARGUMENTS/ 코드 정리. unused import, dead code 제거"
```

실행 내용:
1. unused import 제거
2. unused 변수/함수 제거
3. 주석 처리된 코드 삭제
4. 코드 포맷팅

---

## 참조 문서

| 문서 | 용도 |
|------|------|
| `docs/02_features/$ARGUMENTS.md` | 기능 명세, 수락 조건 |
| `docs/03_architecture.md` | 폴더 구조 패턴 |
| `docs/04_data_models.md` | 데이터 모델 정의 |
| `docs/05_api_spec.md` | Supabase API |
| `docs/09_state_management.md` | Riverpod 3.0 패턴 |
| `docs/10_widget_tree_optimization.md` | 위젯 최적화 |

---

## 완료 조건

- [ ] 모든 수락 조건 충족
- [ ] 테스트 통과
- [ ] 빌드 성공 (`flutter analyze`)
- [ ] 불필요한 코드 정리 완료

---

## 최종 출력

각 Phase 완료 후 아래 형식으로 보고:

```
## Build Report: $ARGUMENTS

### Phase 1: TODO ✅
- 작업 N개로 분해

### Phase 2: ARCH ✅
- lib/features/$ARGUMENTS/ 구조 생성
- 파일 M개 생성

### Phase 3: MODULE ✅
- Domain: N개 파일
- Data: M개 파일
- Presentation: K개 파일

### Phase 4: TEST ✅
- 테스트 N개 작성
- 결과: X/Y 통과

### Phase 5: DELETE ✅
- unused import N개 제거
- dead code M개 제거

### 총 소요: 전체 파이프라인 완료
```
