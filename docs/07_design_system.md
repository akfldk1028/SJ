# 디자인 시스템

> 만톡: AI 사주 챗봇의 시각적 일관성을 위한 디자인 가이드라인입니다.

---

## 1. 컬러 시스템

### 1.1 Primary Colors (인디고/보라 계열 - 신비로운 사주 느낌)
| 이름 | Hex | 용도 |
|------|-----|------|
| Primary | #6366F1 | 주요 버튼, 강조 (Indigo 500) |
| Primary Light | #A5B4FC | 배경, hover (Indigo 300) |
| Primary Dark | #4338CA | 눌림 상태 (Indigo 700) |

### 1.2 Secondary Colors (골드/앰버 계열 - 운세/행운 느낌)
| 이름 | Hex | 용도 |
|------|-----|------|
| Secondary | #F59E0B | 보조 버튼, 별점 (Amber 500) |
| Accent | #8B5CF6 | 강조 포인트 (Violet 500) |

### 1.3 Neutral Colors
| 이름 | Hex | 용도 |
|------|-----|------|
| Background | #FFFFFF | 배경 |
| Surface | #F5F5F5 | 카드 배경 |
| Text Primary | #212121 | 본문 텍스트 |
| Text Secondary | #757575 | 보조 텍스트 |
| Divider | #E0E0E0 | 구분선 |

### 1.4 Semantic Colors
| 이름 | Hex | 용도 |
|------|-----|------|
| Success | #4CAF50 | 성공 |
| Warning | #FF9800 | 경고 |
| Error | #F44336 | 에러 |
| Info | #2196F3 | 정보 |

### 1.5 코드 구현
```dart
// core/constants/app_colors.dart
class AppColors {
  // Primary (인디고)
  static const primary = Color(0xFF6366F1);
  static const primaryLight = Color(0xFFA5B4FC);
  static const primaryDark = Color(0xFF4338CA);

  // Secondary (앰버/골드)
  static const secondary = Color(0xFFF59E0B);
  static const accent = Color(0xFF8B5CF6);

  // Neutral
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F5F5);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const divider = Color(0xFFE0E0E0);

  // Semantic
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);

  // Chat Bubble Colors
  static const userBubble = Color(0xFF6366F1);      // Primary
  static const aiBubble = Color(0xFFF3F4F6);        // Gray 100
  static const userBubbleText = Color(0xFFFFFFFF);  // White
  static const aiBubbleText = Color(0xFF212121);    // Text Primary
}
```

---

## 2. 타이포그래피

### 2.1 폰트 패밀리
- 기본: [x] **Pretendard** (한글 + 영문 통합, 가독성 우수)
- 대안: Noto Sans KR (Google Fonts 무료)

### 2.2 텍스트 스타일
| 이름 | 크기 | 굵기 | 용도 |
|------|------|------|------|
| Heading1 | 28sp | Bold (700) | 페이지 제목 |
| Heading2 | 24sp | Bold (700) | 섹션 제목 |
| Heading3 | 20sp | SemiBold (600) | 서브 제목 |
| Body1 | 16sp | Regular (400) | 본문 |
| Body2 | 14sp | Regular (400) | 보조 본문 |
| Caption | 12sp | Regular (400) | 설명, 라벨 |
| Button | 14sp | SemiBold (600) | 버튼 텍스트 |

### 2.3 코드 구현
```dart
// core/constants/app_text_styles.dart
class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
```

---

## 3. 간격 시스템

### 3.1 Spacing Scale
| 이름 | 크기 | 용도 |
|------|------|------|
| xs | 4px | 아이콘-텍스트 간격 |
| sm | 8px | 요소 내부 간격 |
| md | 16px | 요소 간 간격 |
| lg | 24px | 섹션 간격 |
| xl | 32px | 큰 섹션 간격 |
| xxl | 48px | 페이지 패딩 |

### 3.2 코드 구현
```dart
// core/constants/app_sizes.dart
class AppSizes {
  // Spacing
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  // Border Radius
  static const radiusSm = 4.0;
  static const radiusMd = 8.0;
  static const radiusLg = 16.0;
  static const radiusFull = 9999.0;

  // Icon Sizes
  static const iconSm = 16.0;
  static const iconMd = 24.0;
  static const iconLg = 32.0;

  // Button Heights
  static const buttonHeightSm = 36.0;
  static const buttonHeightMd = 48.0;
  static const buttonHeightLg = 56.0;
}
```

---

## 4. 컴포넌트

### 4.1 버튼

#### Primary Button
```
┌─────────────────────────────┐
│        버튼 텍스트           │  ← 높이: 48px
└─────────────────────────────┘    배경: Primary
                                   모서리: 8px
```

#### Secondary Button (Outlined)
```
┌─────────────────────────────┐
│        버튼 텍스트           │  ← 테두리: Primary 1px
└─────────────────────────────┘    배경: 투명
```

#### Text Button
```
  버튼 텍스트                     ← 밑줄 없음
                                   색상: Primary
```

### 4.2 입력 필드
```
라벨
┌─────────────────────────────┐
│ 힌트 텍스트                  │  ← 높이: 48px
└─────────────────────────────┘    테두리: Divider
에러 메시지 (빨간색)              ← 12sp
```

### 4.3 카드
```
┌─────────────────────────────┐
│                             │
│         컨텐츠              │  ← 배경: Surface
│                             │     모서리: 12px
│                             │     그림자: elevation 2
└─────────────────────────────┘
```

### 4.4 코드 구현
```dart
// shared/widgets/custom_button.dart
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;

  const CustomButton({
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.buttonHeightMd,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(text, style: AppTextStyles.button),
      ),
    );
  }
}
```

---

## 5. 아이콘

### 5.1 아이콘 라이브러리
- [x] **Material Icons** (기본, Flutter 내장)
- [x] **Cupertino Icons** (iOS 스타일, 플랫폼별 대응)
- [ ] 커스텀 SVG (사주 관련 특수 아이콘 - 필요시)

### 5.2 아이콘 크기
| 크기 | 픽셀 | 용도 |
|------|------|------|
| Small | 16px | 인라인, 작은 버튼 |
| Medium | 24px | 기본, BottomNav |
| Large | 32px | 강조, 빈 상태 |

---

## 6. 애니메이션

### 6.1 Duration
| 이름 | 시간 | 용도 |
|------|------|------|
| Fast | 150ms | 호버, 탭 피드백 |
| Normal | 300ms | 페이지 전환, 모달 |
| Slow | 500ms | 복잡한 애니메이션 |

### 6.2 Easing Curve
- 기본: `Curves.easeInOut`
- 진입: `Curves.easeOut`
- 퇴장: `Curves.easeIn`

---

## 7. 다크 모드

### 7.1 다크 모드 컬러
| Light | Dark | 용도 |
|-------|------|------|
| #FFFFFF | #121212 | 배경 |
| #F5F5F5 | #1E1E1E | Surface |
| #212121 | #FFFFFF | Text Primary |
| #757575 | #B0B0B0 | Text Secondary |

### 7.2 코드 구현
```dart
// core/theme/app_theme.dart
class AppTheme {
  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    // ... 기타 설정
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: const Color(0xFF121212),
    // ... 기타 설정
  );
}
```

---

## 8. 반응형 디자인

### 8.1 Breakpoints
| 이름 | 너비 | 기기 |
|------|------|------|
| Mobile | < 600px | 스마트폰 |
| Tablet | 600-1024px | 태블릿 |
| Desktop | > 1024px | 데스크톱 |

### 8.2 그리드 시스템
- Mobile: 단일 컬럼
- Tablet: 2 컬럼
- Desktop: 3-4 컬럼

---

## 체크리스트

- [x] 컬러 팔레트 정의 (인디고 + 앰버)
- [x] 폰트 패밀리 선택 (Pretendard)
- [x] 타이포그래피 스케일 정의
- [x] 간격 시스템 정의
- [x] 버튼 스타일 정의
- [x] 입력 필드 스타일 정의
- [x] 아이콘 라이브러리 선택 (Material + Cupertino)
- [x] 다크 모드 지원 여부 (지원 예정)
