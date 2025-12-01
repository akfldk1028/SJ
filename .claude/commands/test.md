# /test - TEST AGENT

$ARGUMENTS 기능의 테스트를 작성하고 실행합니다.

## 참조 문서

- `docs/02_features/$ARGUMENTS.md` - 테스트 케이스 섹션

## 테스트 구조

```
test/features/$ARGUMENTS/
├── domain/
│   └── repositories/
│       └── [feature]_repository_test.dart
├── data/
│   └── repositories/
│       └── [feature]_repository_impl_test.dart
└── presentation/
    ├── providers/
    │   └── [feature]_provider_test.dart
    └── screens/
        └── [feature]_screen_test.dart
```

## 테스트 유형

### Unit Test
```dart
void main() {
  group('FeatureRepository', () {
    test('should return entity when id is valid', () async {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

### Widget Test
```dart
void main() {
  testWidgets('should render correctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...],
        child: MaterialApp(home: FeatureScreen()),
      ),
    );

    expect(find.byType(FeatureScreen), findsOneWidget);
  });
}
```

## 실행 명령

```bash
# 특정 기능 테스트
flutter test test/features/$ARGUMENTS/

# 전체 테스트
flutter test

# 커버리지
flutter test --coverage
```

## 출력

- 테스트 파일 생성
- 테스트 실행 결과
- 실패 시 수정 제안
