# /arch - ARCHITECTURE AGENT

$ARGUMENTS 기능의 폴더 구조를 생성합니다.

## 참조 문서

- `docs/03_architecture.md` - 폴더 구조 패턴
- `docs/09_state_management.md` - Riverpod 3.0 패턴

## 생성 구조

```
lib/features/$ARGUMENTS/
├── domain/
│   ├── entities/
│   │   └── [entity].dart
│   └── repositories/
│       └── [feature]_repository.dart
├── data/
│   ├── models/
│   │   └── [entity]_model.dart
│   ├── datasources/
│   │   └── [feature]_remote_datasource.dart
│   └── repositories/
│       └── [feature]_repository_impl.dart
└── presentation/
    ├── providers/
    │   └── [feature]_provider.dart
    ├── screens/
    │   └── [feature]_screen.dart
    └── widgets/
```

## 실행 내용

1. 폴더 구조 생성
2. 빈 템플릿 파일 생성 (기본 구조만)
3. 의존성 관계 주석 추가

## 출력

- 생성된 폴더/파일 목록
- 다음 단계 안내 (MODULE AGENT 호출)
