# /delete - DELETE AGENT

프로젝트의 불필요한 파일과 코드를 정리합니다.

## 삭제 대상

### 1. Unused Imports
```dart
// 삭제 대상
import 'package:unused/unused.dart';  // 사용되지 않음
```

### 2. Dead Code
```dart
// 삭제 대상
void _unusedFunction() {}  // 어디서도 호출 안됨
final _unusedVar = 'test'; // 어디서도 사용 안됨
```

### 3. Commented Code
```dart
// 삭제 대상
// final oldImplementation = 'deprecated';
// void oldFunction() { ... }
```

### 4. Empty Files
- 내용이 없는 .dart 파일
- 빈 폴더 (필요시)

### 5. Duplicate Code
- 중복된 유틸리티 함수
- 복사된 위젯

## 보호 파일 (삭제 안함)

- `pubspec.yaml`
- `main.dart`
- `.gitignore`
- `analysis_options.yaml`
- `README.md`
- `*.g.dart` (generated)
- `*.freezed.dart` (generated)

## 실행 흐름

1. 프로젝트 스캔
2. 삭제 대상 목록 생성
3. **사용자 확인 요청**
4. 승인 시 삭제 실행
5. 삭제 결과 보고

## 출력 예시

```
삭제 대상 발견:
1. [IMPORT] lib/features/profile/screen.dart:3 - unused import
2. [FILE] lib/utils/old_helper.dart - 사용되지 않는 파일
3. [CODE] lib/features/chat/widget.dart:45-52 - commented code

삭제하시겠습니까? (y/n)
```

## 안전장치

- 항상 삭제 전 목록 확인
- git 추적 파일만 대상
- 실행 취소 불가 경고
