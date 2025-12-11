# Supabase Anonymous Sign-In 설정 가이드

> 만톡(Mantok) - 로그인 없이 앱 사용 후 나중에 계정 연동

---

## 1. 왜 Anonymous Sign-In인가?

### 1.1 UX 패턴
```
[첫 앱 실행]                    [나중에 로그인]
     │                              │
     ▼                              ▼
signInAnonymously()    →    linkIdentity() / updateUser()
     │                              │
     ▼                              ▼
익명 사용자 생성              기존 데이터 유지 + 영구 계정 전환
(is_anonymous=true)           (is_anonymous=false)
```

### 1.2 장점
- **동일한 user_id 유지**: 익명 → 영구 전환 시 데이터 마이그레이션 불필요
- **RLS 자동 적용**: 익명 사용자도 `authenticated` 역할 사용
- **기기 ID 관리 불필요**: Supabase Auth가 세션 관리

---

## 2. Dashboard 설정 (필수) - 상세 스크린샷 가이드

> ⚠️ **중요**: 이 설정을 하지 않으면 Flutter 코드에서 오류가 발생합니다!

---

### 2.1 Anonymous Sign-In 활성화

**직접 링크**:
```
https://supabase.com/dashboard/project/kfciluyxkomskyxjaeat/auth/providers
```

**상세 단계 (스크린샷 기준)**:

```
┌─────────────────────────────────────────────────────────────┐
│  Supabase Dashboard                                         │
│                                                             │
│  ┌─────────────┐  ┌───────────────────────────────────────┐ │
│  │ [홈 아이콘]  │  │  Authentication                       │ │
│  │             │  │                                       │ │
│  │ Database    │  │  Overview │ Users │ Policies │ Provid..│
│  │             │  │                              ^^^^^^^^^ │
│  │ Auth ◀──────│  │           여기 클릭!                   │ │
│  │ (사람모양)   │  │                                       │ │
│  │             │  │  ┌─────────────────────────────────┐  │ │
│  │ Storage     │  │  │  Email                    [ON]  │  │ │
│  │             │  │  │  Phone                    [OFF] │  │ │
│  │ Edge Func   │  │  │  ...                            │  │ │
│  │             │  │  │  ↓ 아래로 스크롤                 │  │ │
│  │ Settings    │  │  │  ...                            │  │ │
│  │ (톱니바퀴)   │  │  │  Anonymous Sign-Ins ◀─ 찾기!    │  │ │
│  └─────────────┘  │  │  [토글을 ON으로!] ◀──────────────│  │ │
│                   │  └─────────────────────────────────┘  │ │
│                   └───────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**찾는 방법**:
1. 왼쪽 사이드바에서 **사람 모양 아이콘** (Authentication) 클릭
2. 상단 탭에서 **"Providers"** 탭 클릭
3. Provider 목록을 **맨 아래까지 스크롤**
4. **"Anonymous Sign-Ins"** 섹션 찾기
5. 토글을 **ON (초록색)** 으로 변경
6. **Save** 버튼 클릭

**확인**: 토글이 초록색이면 성공! ✅

---

### 2.2 Manual Linking 활성화 (익명→영구 전환용)

> ⚠️ **주의**: 이 설정 위치가 Supabase 버전에 따라 다를 수 있습니다!

**방법 1: Authentication 섹션에서 찾기 (권장)**

**직접 링크**:
```
https://supabase.com/dashboard/project/kfciluyxkomskyxjaeat/auth/providers
```

**상세 단계**:

```
┌─────────────────────────────────────────────────────────────┐
│  Supabase Dashboard                                         │
│                                                             │
│  ┌─────────────┐  ┌───────────────────────────────────────┐ │
│  │ [홈 아이콘]  │  │  Authentication                       │ │
│  │             │  │                                       │ │
│  │ Database    │  │  Overview │ Users │ Policies │ Provid..│
│  │             │  │                              ^^^^^^^^^ │
│  │ Auth ◀──────│  │                                       │ │
│  │ (사람모양)   │  │  ┌─────────────────────────────────┐  │ │
│  │             │  │  │  Configuration / Settings       │  │ │
│  │ Storage     │  │  │  ↓ 아래로 스크롤                 │  │ │
│  │             │  │  │                                 │  │ │
│  │ Edge Func   │  │  │  "Allow manual linking"        │  │ │
│  │             │  │  │  [토글을 ON으로!] ◀─────────────│  │ │
│  │ Settings    │  │  └─────────────────────────────────┘  │ │
│  └─────────────┘  │                                       │ │
│                   └───────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

**찾는 방법** (2025년 12월 기준):
1. 왼쪽 사이드바에서 **사람 모양 아이콘** (Authentication) 클릭
2. **Providers** 탭 또는 **Configuration** 섹션 확인
3. 페이지를 스크롤하며 **"Allow manual linking"** 찾기
4. 토글을 **ON** 으로 변경
5. **Save** 버튼 클릭

---

**방법 2: 못 찾겠다면 검색 사용**

Dashboard 상단의 **검색창 (Cmd+K / Ctrl+K)** 에서:
```
manual linking
```
입력하면 해당 설정으로 바로 이동 가능

---

**방법 3: URL Configuration 확인**

일부 버전에서는 아래 위치에 있을 수 있음:
```
https://supabase.com/dashboard/project/kfciluyxkomskyxjaeat/auth/url-configuration
```

---

**설정이 안 보인다면?**

Supabase CLI 로컬 개발 환경에서는 `config.toml`에 추가:
```toml
[auth]
enable_manual_linking = true
```

**이 설정이 필요한 이유**:
- `linkIdentity()` 메서드가 동작하려면 이 설정이 필수
- 익명 사용자가 나중에 Google/Apple/Kakao 로그인으로 전환할 때 사용
- 설정 안 하면 에러: `"Manual linking is disabled"`

---

### 2.3 (권장) CAPTCHA 설정 - 악용 방지

> Anonymous Sign-In은 Rate Limit이 **30 requests/hour/IP**로 제한되어 있습니다.
> CAPTCHA 설정으로 봇 공격을 방지하세요.

**직접 링크**:
```
https://supabase.com/dashboard/project/kfciluyxkomskyxjaeat/settings/auth
```

**설정 위치**: Settings > Authentication > CAPTCHA protection

**지원 CAPTCHA**:
- Cloudflare Turnstile (권장 - 무료)
- hCaptcha

---

### 2.4 Rate Limits 확인

**직접 링크**:
```
https://supabase.com/dashboard/project/kfciluyxkomskyxjaeat/auth/rate-limits
```

**Anonymous Sign-In 기본 제한**:
| 항목 | 제한 |
|------|------|
| IP 기준 | 30 requests/hour |
| 버스트 | 최대 30 requests |

> 💡 테스트 중에 Rate Limit에 걸리면 1시간 기다리거나 다른 IP 사용

---

## 3. 설정 확인 체크리스트

Dashboard에서 확인:

- [ ] **Authentication > Providers**
  - [ ] Anonymous Sign-Ins: Enabled

- [ ] **Project Settings > Authentication**
  - [ ] Enable Manual Linking: Enabled (익명→영구 전환용)

---

## 4. Flutter 코드 구현

### 4.1 앱 시작 시 인증 초기화

```dart
// lib/core/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  /// 앱 시작 시 호출 - 세션 없으면 익명 로그인
  Future<User?> initializeAuth() async {
    final session = _supabase.auth.currentSession;

    if (session == null) {
      // 세션 없음 → 익명 로그인
      final response = await _supabase.auth.signInAnonymously();
      return response.user;
    }

    return _supabase.auth.currentUser;
  }

  /// 현재 사용자가 익명인지 확인
  bool get isAnonymous {
    final user = _supabase.auth.currentUser;
    return user?.isAnonymous ?? true;
  }

  /// 현재 사용자 ID
  String? get currentUserId => _supabase.auth.currentUser?.id;
}
```

### 4.2 익명 → 이메일 계정 전환

```dart
/// 이메일로 영구 계정 전환
Future<void> convertToEmailUser(String email, String password) async {
  // 1. 이메일 연결 (인증 메일 발송)
  await _supabase.auth.updateUser(
    UserAttributes(email: email),
  );

  // 2. 이메일 인증 완료 후 비밀번호 설정
  // (사용자가 이메일 링크 클릭 후 호출)
  await _supabase.auth.updateUser(
    UserAttributes(password: password),
  );
}
```

### 4.3 익명 → OAuth 계정 전환

```dart
/// Google 계정으로 영구 계정 전환
Future<void> convertToGoogleUser() async {
  await _supabase.auth.linkIdentity(OAuthProvider.google);
}

/// Apple 계정으로 영구 계정 전환
Future<void> convertToAppleUser() async {
  await _supabase.auth.linkIdentity(OAuthProvider.apple);
}

/// Kakao 계정으로 영구 계정 전환 (커스텀 OAuth)
Future<void> convertToKakaoUser() async {
  await _supabase.auth.linkIdentity(OAuthProvider.kakao);
}
```

### 4.4 main.dart 통합

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화
  await Supabase.initialize(
    url: 'https://kfciluyxkomskyxjaeat.supabase.co',
    anonKey: 'your-anon-key',
  );

  // 인증 초기화 (익명 로그인)
  final authService = AuthService(Supabase.instance.client);
  await authService.initializeAuth();

  runApp(const MyApp());
}
```

---

## 5. RLS 정책 참고

현재 적용된 RLS 정책은 익명 사용자와 영구 사용자를 **동일하게** 취급합니다.
(`authenticated` 역할 기반)

만약 특정 기능을 영구 사용자에게만 허용하려면:

```sql
-- 예: 영구 사용자만 프로필 공개 설정 가능
CREATE POLICY "only_permanent_users_can_make_public" ON public.saju_profiles
  FOR UPDATE TO authenticated
  WITH CHECK (
    (SELECT (auth.jwt()->>'is_anonymous')::boolean) IS FALSE
  );
```

---

## 6. 익명 사용자 정리 (관리자용)

30일 이상 비활성 익명 사용자 삭제:

```sql
DELETE FROM auth.users
WHERE is_anonymous = true
  AND created_at < NOW() - INTERVAL '30 days';
```

---

## 7. 문제 해결

### 7.1 signInAnonymously() 오류

**오류**: `Anonymous sign-ins are disabled`

**해결**: Dashboard에서 Anonymous Sign-In 활성화 확인

### 7.2 linkIdentity() 오류

**오류**: `Manual linking is disabled`

**해결**: Project Settings > Authentication > Enable Manual Linking 활성화

### 7.3 Rate Limit 오류

**오류**: `Rate limit exceeded`

**해결**:
- 기본 30 requests/hour
- Dashboard에서 Rate Limit 조정 또는 CAPTCHA 설정

---

## 8. 참고 문서

- [Supabase Anonymous Sign-Ins](https://supabase.com/docs/guides/auth/auth-anonymous)
- [Identity Linking](https://supabase.com/docs/guides/auth/auth-identity-linking)
- [RLS with Anonymous Users](https://supabase.com/docs/guides/database/database-advisors?lint=0012_auth_allow_anonymous_sign_ins)
