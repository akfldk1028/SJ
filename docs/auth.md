# 인증(Auth) 기능 명세서

> 만톡: AI 사주 챗봇 – **계정/로그인 기능**  
> v0.1(MVP)은 **비회원 사용 가능**, v0.2 이후에 ON 할 기능으로 설계.

---

## 1. 기본 정보

| 항목 | 내용 |
|------|------|
| 기능명 | 사용자 인증 (이메일/소셜 로그인) |
| 우선순위 | P1 (중요, MVP 이후 단계에서 적용) |
| 담당 | - |
| 상태 | 기획중 |

- 현재 버전 전략
  - v0.1.0: 로그인 없이도 사주 챗봇 + 히스토리 로컬 저장만으로 사용 가능
  - v0.2.0: 계정 기능을 켜서 **여러 기기 동기화 / 백업 / 멀티 프로필 관리** 제공

---

## 2. 사용자 스토리

1. **신규 사용자**로서, 기기를 바꾸거나 앱을 지워도  
   **내 사주 프로필과 상담 기록이 유지되도록 계정 가입**을 하고 싶다.
2. **기존 사용자**로서, 다른 기기(새 핸드폰, 태블릿)에서도  
   **같은 사주 상담 이력을 이어서 보기 위해 로그인**을 하고 싶다.
3. **사용자**로서, 비밀번호를 잊었을 때  
   **간단히 비밀번호 재설정 링크를 받아서 로그인**을 다시 하고 싶다.
4. **사용자**로서, 이메일/비밀번호가 귀찮을 때  
   **Google / Apple / Kakao 같은 소셜 계정으로 간편 로그인**을 하고 싶다.

---

## 3. 화면 구성

### 3.1 화면 목록

| 화면명 | 라우트 | 설명 |
|--------|--------|------|
| 로그인 | /login | 이메일/비밀번호 + 소셜 로그인 |
| 회원가입 | /register | 새 계정 생성 |
| 비밀번호 찾기 | /forgot-password | 비밀번호 재설정 요청 |

> 네비게이션 설계(06_navigation.md)에는 **v0.2에서 추가 예정**으로 표시.

---

### 3.2 화면별 상세

#### 로그인 화면 (/login)

**레이아웃:**
┌─────────────────────────────┐
│ │
│ [앱 로고/타이틀] │
│ "만톡: AI 사주" │
│ │
├─────────────────────────────┤
│ ┌───────────────────┐ │
│ │ 이메일 입력 │ │
│ └───────────────────┘ │
│ ┌───────────────────┐ │
│ │ 비밀번호 입력 │ │
│ └───────────────────┘ │
│ │
│ [ 로그인 버튼 ] │
│ │
│ 비밀번호 찾기 | 회원가입 │
├─────────────────────────────┤
│ ───── 또는 ───── │
│ [ Google ] [ Apple ] │
│ [ Kakao ] │
└─────────────────────────────┘

markdown
코드 복사

**UI 요소:**

| 요소 | 타입 | 동작 |
|------|------|------|
| 이메일 입력 | TextField | 이메일 형식 검증 (`@` 포함, 공백 불가 등) |
| 비밀번호 입력 | TextField (obscure) | 6자 이상 검증 |
| 로그인 버튼 | Primary Button | 유효성 통과 시 `/auth/login` 호출 → 성공 시 사주 챗봇 화면으로 이동(`/saju/chat`) |
| 비밀번호 찾기 | TextButton | `/forgot-password`로 이동 |
| 회원가입 | TextButton | `/register`로 이동 |
| 소셜 로그인 버튼들 | Icon/Button | 각 소셜 SDK → 백엔드 `/auth/social` → 성공 시 토큰 저장 후 `/saju/chat` |

---

#### 회원가입 화면 (/register)

**레이아웃:**
┌─────────────────────────────┐
│ ← 회원가입 │
├─────────────────────────────┤
│ ┌───────────────────┐ │
│ │ 이메일 입력 │ │
│ └───────────────────┘ │
│ ┌───────────────────┐ │
│ │ 비밀번호 입력 │ │
│ └───────────────────┘ │
│ ┌───────────────────┐ │
│ │ 비밀번호 확인 │ │
│ └───────────────────┘ │
│ ┌───────────────────┐ │
│ │ 닉네임 입력 │ │
│ └───────────────────┘ │
│ │
│ [ ] 이용약관 동의 (필수) │
│ [ ] 개인정보처리방침 (필수) │
│ │
│ [ 가입하기 버튼 ] │
└─────────────────────────────┘

yaml
코드 복사

**UI 요소:**

| 요소 | 타입 | 동작 |
|------|------|------|
| 이메일 입력 | TextField | 형식 검증 + 중복 여부 체크 |
| 비밀번호/확인 | TextField | 6자 이상, 두 값 일치 여부 검증 |
| 닉네임 | TextField | 2~20자, 욕설/금지어 필터 (간단 검증) |
| 약관 체크박스 | Checkbox | 필수 모두 체크해야 가입 가능 |
| 가입하기 버튼 | Primary Button | `/auth/register` 호출 → 성공 시 `/login` 이동 + “가입 완료” 토스트/스낵바 |

---

#### 비밀번호 찾기 화면 (/forgot-password)

**레이아웃 (간단 버전):**
┌─────────────────────────────┐
│ ← 비밀번호 재설정 │
├─────────────────────────────┤
│ 설명 텍스트 │
│ "가입하신 이메일을 입력하시면"│
│ "재설정 링크를 보내드릴게요" │
│ ┌───────────────────┐ │
│ │ 이메일 입력 │ │
│ └───────────────────┘ │
│ │
│ [ 재설정 링크 보내기 ] │
└─────────────────────────────┘

markdown
코드 복사

**UI 요소:**

| 요소 | 타입 | 동작 |
|------|------|------|
| 이메일 입력 | TextField | 형식 검증 |
| 재설정 버튼 | Primary Button | `/auth/forgot-password` 호출 → 성공 시 “메일 발송 안내” 메시지 |

---

## 4. 수락 조건 (Acceptance Criteria)

### 4.1 로그인

- [ ] 이메일 형식이 올바르지 않으면 **실시간/제출 시 에러 메시지** 표시
- [ ] 비밀번호가 6자 미만이면 에러 표시
- [ ] 입력이 유효하지 않으면 로그인 버튼 비활성화
- [ ] 로그인 성공 시:
  - [ ] `accessToken` / `refreshToken`을 `flutter_secure_storage`에 저장
  - [ ] 현재 유저 정보(`User`) 메모리에 적재
  - [ ] `/saju/chat` 화면으로 이동
- [ ] 로그인 실패 시:
  - [ ] 에러 코드에 따라 적절한 메시지 (“이메일 또는 비밀번호가 틀렸습니다” 등)
  - [ ] Snackbar/Toast로 표시
- [ ] 로딩 중에는 버튼에 로딩 인디케이터 표시 & 중복 클릭 방지

### 4.2 회원가입

- [ ] 이메일 형식 + 비밀번호 길이 + 비밀번호 확인 + 닉네임 길이 검증
- [ ] 필수 약관 미동의 시 가입 버튼 비활성화
- [ ] 서버에서 이메일 중복일 경우, “이미 가입된 이메일입니다” 메시지
- [ ] 가입 성공 시:
  - [ ] “가입이 완료되었습니다” 안내
  - [ ] 로그인 화면으로 자동 이동
- [ ] 서버 에러 시, 일반적인 에러 메시지 (“잠시 후 다시 시도해주세요”)

### 4.3 비밀번호 찾기

- [ ] 존재하지 않는 이메일이면 “가입되지 않은 이메일입니다” 안내
- [ ] 존재하는 이메일이면 “비밀번호 재설정 링크를 이메일로 보내드렸어요” 안내
- [ ] 성공/실패 여부와 무관하게 보안상 **구체적인 계정 유무는 노출하지 않는 방향도 옵션** (서버 정책에 따름)

### 4.4 소셜 로그인

- [ ] Google / Apple / Kakao 각 SDK 연동 성공 시 백엔드 `/auth/social`에 토큰 전달
- [ ] 최초 소셜 로그인인 경우, 서버에서 자동 회원가입 처리 or 최소 닉네임만 추가로 입력받는 화면 플로우
- [ ] 이후에는 일반 로그인과 동일하게 토큰 저장 후 `/saju/chat` 이동

---

## 5. UI/UX 흐름

### 5.1 로그인 흐름

```text
앱 실행
    ↓
로컬 토큰 확인 (secure_storage)
    ├─ [유효 토큰 있음] → 자동 로그인 처리 → /saju/chat
    └─ [토큰 없음 or 만료] → /login 화면
                              ↓
                        이메일/비밀번호 입력
                              ↓
                        [로그인] 버튼 클릭
                              ↓
                        /auth/login API 호출 (로딩)
                              ├─ [성공]
                              │     ↓
                              │  토큰 저장 → 유저 정보 저장 → /saju/chat
                              └─ [실패]
                                    ↓
                                에러 메시지 표시
5.2 회원가입 흐름
text
코드 복사
/login 화면
    ↓
"회원가입" 버튼 클릭
    ↓
/register 화면
    ↓
이메일/비밀번호/닉네임/약관 입력
    ↓
[가입하기] 버튼
    ↓
/auth/register API 호출
    ├─ [성공]
    │     ↓
    │  "가입 완료" 메시지 → /login 이동
    └─ [실패]
          ↓
      에러 메시지 표시
5.3 소셜 로그인 흐름 (예: Kakao)
text
코드 복사
/login 화면
    ↓
[Kakao 로그인] 버튼 클릭
    ↓
Kakao SDK 인증 → accessToken 획득
    ↓
백엔드 /auth/social 호출 (provider=kakao, token=...)
    ├─ [성공] (신규 or 기존 유저)
    │     ↓
    │  토큰 저장 → /saju/chat 이동
    └─ [실패]
          ↓
      에러 메시지 표시
6. 예외 처리
상황	에러 코드	처리 방법	UI 표시
이메일 형식 오류	-	제출 차단	“올바른 이메일을 입력해주세요”
비밀번호 짧음	-	제출 차단	“비밀번호는 6자 이상이어야 합니다”
이메일/비밀번호 틀림	AUTH_INVALID_CREDENTIALS	재입력 요청	“이메일 또는 비밀번호가 틀렸습니다”
이미 가입된 이메일	AUTH_EMAIL_EXISTS	로그인 유도	“이미 가입된 이메일입니다. 로그인으로 이동할까요?”
소셜 로그인 취소	AUTH_SOCIAL_CANCELED	아무것도 안 함	Snackbar로 “로그인이 취소되었습니다”
네트워크 오류	NETWORK_ERROR	재시도 버튼 제공	“네트워크 연결을 확인해주세요”
서버 오류	SERVER_ERROR	잠시 후 재시도	“잠시 후 다시 시도해주세요”

7. 데이터 요구사항
7.1 로그인 요청/응답
dart
코드 복사
// POST /auth/login

// Request
{
  "email": "user@example.com",
  "password": "password123"
}

// Response (성공)
{
  "success": true,
  "data": {
    "accessToken": "eyJhbG...",       // JWT
    "refreshToken": "eyJhbG...",
    "expiresIn": 3600,               // 초 단위
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "nickname": "닉네임",
      "profileImage": "https://.../avatar.png"
    }
  }
}
7.2 회원가입 요청/응답
dart
코드 복사
// POST /auth/register

// Request
{
  "email": "user@example.com",
  "password": "password123",
  "nickname": "닉네임",
  "agreements": {
    "termsOfService": true,
    "privacyPolicy": true,
    "marketing": false
  }
}

// Response (성공)
{
  "success": true,
  "data": {
    "message": "회원가입이 완료되었습니다",
    "userId": "uuid"
  }
}
7.3 관련 API
메서드	엔드포인트	설명
POST	/auth/login	로그인
POST	/auth/register	회원가입
POST	/auth/refresh	토큰 갱신
POST	/auth/logout	로그아웃 (선택)
POST	/auth/forgot-password	비밀번호 재설정 메일 발송
POST	/auth/social	소셜 로그인 통합 엔드포인트
GET	/auth/check-email?email=	이메일 중복 확인

8. 상태 관리
8.1 AuthState
dart
코드 복사
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}
8.2 Riverpod Provider 예시
dart
코드 복사
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return AuthNotifier(authRepository);
});
8.3 상태 변화 다이어그램
less
코드 복사
Initial (isAuthenticated: false)
    ↓ [login 호출]
Loading (isLoading: true)
    ├─ [성공] → Authenticated (isAuthenticated: true, user: User)
    └─ [실패] → Error (errorMessage: "...") → 다시 Initial
9. 의존성
9.1 다른 기능과의 관계
선행: 없음 (앱 시작 시 선택적으로 진입 가능)

후행:

프로필 동기화 (로그인 유저의 SajuProfile을 서버와 동기화)

상담 히스토리 서버 저장 & 복원

구독/결제 기능 (추후)

현재 설계 기준:

사주 계산/챗봇 자체는 비로그인도 사용 가능 (로컬 저장)

로그인 시 “클라우드 백업/동기화” 기능이 추가되는 구조

9.2 외부 패키지 (예상)
flutter_secure_storage: 토큰 안전 저장

dio: Auth API 호출

(선택) google_sign_in: Google 로그인

(선택) sign_in_with_apple: Apple 로그인

(선택) kakao_flutter_sdk_user: Kakao 로그인

10. 테스트 케이스
TC ID	시나리오	입력	예상 결과
AUTH-001	정상 로그인	유효한 이메일/비밀번호	/saju/chat 이동, 토큰 저장
AUTH-002	잘못된 비밀번호	올바른 이메일, 틀린 비밀번호	“이메일 또는 비밀번호가 틀렸습니다”
AUTH-003	이메일 형식 오류	invalid-email	이메일 필드 아래 형식 에러
AUTH-004	정상 회원가입	유효한 정보	“가입 완료” 후 /login 이동
AUTH-005	중복 이메일 가입	이미 가입된 이메일	“이미 가입된 이메일입니다” 메시지
AUTH-006	비밀번호 불일치	서로 다른 비밀번호/확인	“비밀번호가 일치하지 않습니다”
AUTH-007	네트워크 끊김	오프라인 상태	“네트워크 연결을 확인해주세요”
AUTH-008	소셜 로그인 취소	Kakao 창에서 취소	“로그인이 취소되었습니다” 안내