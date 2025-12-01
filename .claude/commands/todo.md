# /todo - TODO AGENT

$ARGUMENTS 기능의 작업을 분해하고 체크리스트를 생성합니다.

## 실행 순서

1. `docs/02_features/$ARGUMENTS.md` 로드
2. 수락 조건(Acceptance Criteria) 분석
3. 세부 작업으로 분해
4. TodoWrite 도구로 체크리스트 생성

## 작업 분해 기준

```
1. Domain Layer
   - [ ] Entity 클래스 생성
   - [ ] Repository interface 정의

2. Data Layer
   - [ ] Model 클래스 생성 (fromJson, toJson)
   - [ ] DataSource 구현 (Supabase 연동)
   - [ ] Repository 구현체

3. Presentation Layer
   - [ ] Provider 생성 (@riverpod)
   - [ ] Screen 위젯
   - [ ] 재사용 위젯

4. 테스트
   - [ ] Provider 테스트
   - [ ] Widget 테스트

5. 정리
   - [ ] unused import 제거
   - [ ] 코드 클린업
```

## 출력

- TodoWrite를 통한 체크리스트
- 각 작업의 예상 파일 목록
