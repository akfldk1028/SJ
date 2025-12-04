# 데이터 모델 정의

> 만톡: AI 사주 챗봇에서 사용하는 모든 데이터 구조를 정의합니다.

---

## 1. Entity vs Model vs DTO

| 구분 | 위치 | 용도 | 예시 |
|------|------|------|------|
| **Entity** | domain/entities | 비즈니스 로직에서 사용하는 순수 객체 | User |
| **Model** | data/models | Entity + JSON 변환 기능 | UserModel |
| **DTO** | data/models | API 요청/응답 전용 객체 | LoginRequestDto |

---

## 2. 사용자 관련

### 2.1 User Entity
```dart
// domain/entities/user.dart
class User {
  final String id;
  final String email;
  final String nickname;
  final String? profileImage;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.nickname,
    this.profileImage,
    required this.createdAt,
  });
}
```

### 2.2 User Model
```dart
// data/models/user_model.dart
class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    required super.nickname,
    super.profileImage,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      nickname: json['nickname'],
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
```

---

## 3. 인증 관련

### 3.1 Token Model
```dart
// data/models/token_model.dart
class TokenModel {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  TokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
```

### 3.2 Auth DTOs
```dart
// data/models/auth_dto.dart

// 로그인 요청
class LoginRequestDto {
  final String email;
  final String password;

  LoginRequestDto({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

// 로그인 응답
class LoginResponseDto {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  LoginResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      user: UserModel.fromJson(json['user']),
    );
  }
}

// 회원가입 요청
class RegisterRequestDto {
  final String email;
  final String password;
  final String nickname;

  RegisterRequestDto({
    required this.email,
    required this.password,
    required this.nickname,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'nickname': nickname,
  };
}
```

---

## 4. 공통 응답

### 4.1 API Response Wrapper
```dart
// data/models/api_response.dart
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final ApiError? error;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'])
          : null,
    );
  }
}

class ApiError {
  final String code;
  final String message;

  ApiError({required this.code, required this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'],
      message: json['message'],
    );
  }
}
```

### 4.2 Pagination
```dart
// data/models/pagination.dart
class PaginatedResponse<T> {
  final List<T> items;
  final int page;
  final int totalPages;
  final int totalItems;
  final bool hasNext;

  PaginatedResponse({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.hasNext,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      items: (json['items'] as List)
          .map((e) => fromJsonT(e))
          .toList(),
      page: json['page'],
      totalPages: json['totalPages'],
      totalItems: json['totalItems'],
      hasNext: json['hasNext'],
    );
  }
}
```

---

## 5. 사주 프로필 (핵심)

### 5.1 SajuProfile Entity
```dart
// features/profile/domain/entities/saju_profile.dart
class SajuProfile {
  final String id;
  final String displayName;           // "나", "연인", "친구" 등
  final DateTime birthDate;           // 생년월일
  final int? birthTimeMinutes;        // 출생시간 (분 단위, 0~1439)
  final bool birthTimeUnknown;        // 시간 모름 여부
  final bool isLunar;                 // 음력 여부
  final Gender gender;                // 성별
  final String? birthPlace;           // 출생지 (선택)
  final DateTime createdAt;
  final DateTime updatedAt;

  SajuProfile({
    required this.id,
    required this.displayName,
    required this.birthDate,
    this.birthTimeMinutes,
    this.birthTimeUnknown = false,
    this.isLunar = false,
    required this.gender,
    this.birthPlace,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 출생시간을 "09:30" 형태로 반환
  String? get birthTimeFormatted {
    if (birthTimeMinutes == null) return null;
    final hours = birthTimeMinutes! ~/ 60;
    final mins = birthTimeMinutes! % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }
}
```

### 5.2 SajuProfile Model
```dart
// features/profile/data/models/saju_profile_model.dart
class SajuProfileModel extends SajuProfile {
  SajuProfileModel({
    required super.id,
    required super.displayName,
    required super.birthDate,
    super.birthTimeMinutes,
    super.birthTimeUnknown,
    super.isLunar,
    required super.gender,
    super.birthPlace,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SajuProfileModel.fromJson(Map<String, dynamic> json) {
    return SajuProfileModel(
      id: json['id'],
      displayName: json['displayName'],
      birthDate: DateTime.parse(json['birthDate']),
      birthTimeMinutes: json['birthTimeMinutes'],
      birthTimeUnknown: json['birthTimeUnknown'] ?? false,
      isLunar: json['isLunar'] ?? false,
      gender: Gender.values.byName(json['gender']),
      birthPlace: json['birthPlace'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'birthDate': birthDate.toIso8601String().split('T')[0],
    'birthTimeMinutes': birthTimeMinutes,
    'birthTimeUnknown': birthTimeUnknown,
    'isLunar': isLunar,
    'gender': gender.name,
    'birthPlace': birthPlace,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
```

---

## 6. 사주 차트 (만세력)

### 6.1 Pillar (기둥) Entity
```dart
// features/saju_chart/domain/entities/pillar.dart
/// 사주의 기둥 하나 (연주/월주/일주/시주)
class Pillar {
  final String heavenlyStem;    // 천간 (갑, 을, 병, 정, ...)
  final String earthlyBranch;   // 지지 (자, 축, 인, 묘, ...)

  Pillar({
    required this.heavenlyStem,
    required this.earthlyBranch,
  });

  /// 한자 표기 ("甲子" 등)
  String get hanja => _stemHanja[heavenlyStem]! + _branchHanja[earthlyBranch]!;

  static const _stemHanja = {
    '갑': '甲', '을': '乙', '병': '丙', '정': '丁', '무': '戊',
    '기': '己', '경': '庚', '신': '辛', '임': '壬', '계': '癸',
  };
  static const _branchHanja = {
    '자': '子', '축': '丑', '인': '寅', '묘': '卯', '진': '辰', '사': '巳',
    '오': '午', '미': '未', '신': '申', '유': '酉', '술': '戌', '해': '亥',
  };
}
```

### 6.2 SajuChart Entity
```dart
// features/saju_chart/domain/entities/saju_chart.dart
class SajuChart {
  final String id;
  final String profileId;
  final Pillar yearPillar;      // 연주
  final Pillar monthPillar;     // 월주
  final Pillar dayPillar;       // 일주 (일간이 "나")
  final Pillar? hourPillar;     // 시주 (시간 모르면 null)
  final List<Daewoon> daewoon;  // 대운 목록
  final DateTime calculatedAt;

  SajuChart({
    required this.id,
    required this.profileId,
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    this.hourPillar,
    required this.daewoon,
    required this.calculatedAt,
  });

  /// 일간 (나를 나타내는 천간)
  String get dayMaster => dayPillar.heavenlyStem;
}

/// 대운 정보
class Daewoon {
  final int index;
  final int startAge;
  final int endAge;
  final int startYear;
  final int endYear;
  final Pillar pillar;

  Daewoon({
    required this.index,
    required this.startAge,
    required this.endAge,
    required this.startYear,
    required this.endYear,
    required this.pillar,
  });
}
```

---

## 7. 사주 요약

### 7.1 SajuSummary Entity
```dart
// features/saju_chart/domain/entities/saju_summary.dart
class SajuSummary {
  final String id;
  final String profileId;
  final String overview;           // 전체 요약
  final List<String> strengths;    // 강점
  final List<String> weaknesses;   // 약점/주의점
  final String? career;            // 직업운
  final String? love;              // 연애운
  final String? money;             // 재물운
  final String? yearlyFocus;       // 올해 포커스
  final DateTime createdAt;

  SajuSummary({
    required this.id,
    required this.profileId,
    required this.overview,
    required this.strengths,
    required this.weaknesses,
    this.career,
    this.love,
    this.money,
    this.yearlyFocus,
    required this.createdAt,
  });
}
```

---

## 8. 채팅

### 8.1 ChatSession Entity
```dart
// features/saju_chat/domain/entities/chat_session.dart
class ChatSession {
  final String id;
  final String profileId;
  final String? title;             // 대화 제목 (자동 생성 or null)
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final int messageCount;

  ChatSession({
    required this.id,
    required this.profileId,
    this.title,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messageCount,
  });
}
```

### 8.2 ChatMessage Entity
```dart
// features/saju_chat/domain/entities/chat_message.dart
class ChatMessage {
  final String id;
  final String chatId;
  final MessageRole role;          // user / assistant
  final String content;
  final DateTime createdAt;
  final List<String>? suggestedQuestions;  // AI 추천 질문 (assistant만)

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.suggestedQuestions,
  });
}
```

### 8.3 Chat DTOs
```dart
// features/saju_chat/data/models/chat_dto.dart

/// 메시지 전송 요청
class SendMessageRequestDto {
  final String? chatId;            // null이면 새 세션
  final String profileId;
  final String message;
  final String locale;

  SendMessageRequestDto({
    this.chatId,
    required this.profileId,
    required this.message,
    this.locale = 'ko-KR',
  });

  Map<String, dynamic> toJson() => {
    'chatId': chatId,
    'profileId': profileId,
    'message': message,
    'locale': locale,
  };
}

/// 메시지 전송 응답
class SendMessageResponseDto {
  final String chatId;
  final String messageId;
  final String content;
  final List<String>? suggestedQuestions;
  final DateTime createdAt;

  SendMessageResponseDto({
    required this.chatId,
    required this.messageId,
    required this.content,
    this.suggestedQuestions,
    required this.createdAt,
  });

  factory SendMessageResponseDto.fromJson(Map<String, dynamic> json) {
    return SendMessageResponseDto(
      chatId: json['chatId'],
      messageId: json['messageId'],
      content: json['content'],
      suggestedQuestions: json['suggestedQuestions'] != null
          ? List<String>.from(json['suggestedQuestions'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

---

## 9. Enum 정의

### 9.1 성별
```dart
enum Gender {
  male,    // 남성
  female,  // 여성
}
```

### 9.2 메시지 역할
```dart
enum MessageRole {
  user,       // 사용자 메시지
  assistant,  // AI 응답
}
```

### 9.3 오행 (참고용)
```dart
enum FiveElements {
  wood,   // 목
  fire,   // 화
  earth,  // 토
  metal,  // 금
  water,  // 수
}
```

---

## 10. 데이터 관계도

```
User (1) ─────< (N) SajuProfile
                      │
                      ├── (1) SajuChart
                      │         └── (4) Pillar (연/월/일/시)
                      │         └── (N) Daewoon
                      │
                      ├── (1) SajuSummary
                      │
                      └──< (N) ChatSession
                                  └──< (N) ChatMessage
```

---

## 11. Supabase 테이블 스키마 (PostgreSQL)

### 11.1 users 테이블
```sql
-- Supabase Auth의 auth.users와 연결되는 public.users
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  nickname TEXT,
  profile_image TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 정책
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);
```

### 11.2 saju_profiles 테이블
```sql
CREATE TABLE public.saju_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  birth_date DATE NOT NULL,
  birth_time_minutes INTEGER,  -- 0~1439 (분 단위)
  birth_time_unknown BOOLEAN DEFAULT FALSE,
  is_lunar BOOLEAN DEFAULT FALSE,
  is_leap_month BOOLEAN DEFAULT FALSE,  -- 음력 윤달 여부
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female')),
  birth_city TEXT NOT NULL,  -- 출생 도시 (진태양시 계산용)
  use_ya_jasi BOOLEAN DEFAULT TRUE,  -- 야자시/조자시 설정
  time_correction INTEGER DEFAULT 0,  -- 진태양시 보정값 (분 단위)
  is_active BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_saju_profiles_user_id ON public.saju_profiles(user_id);

-- RLS 정책
ALTER TABLE public.saju_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own profiles"
  ON public.saju_profiles FOR ALL
  USING (auth.uid() = user_id);
```

### 11.3 saju_charts 테이블
```sql
CREATE TABLE public.saju_charts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.saju_profiles(id) ON DELETE CASCADE UNIQUE,

  -- 연주 (Year Pillar)
  year_stem TEXT NOT NULL,
  year_branch TEXT NOT NULL,

  -- 월주 (Month Pillar)
  month_stem TEXT NOT NULL,
  month_branch TEXT NOT NULL,

  -- 일주 (Day Pillar)
  day_stem TEXT NOT NULL,
  day_branch TEXT NOT NULL,

  -- 시주 (Hour Pillar) - nullable
  hour_stem TEXT,
  hour_branch TEXT,

  -- 대운 (JSON 배열)
  daewoon JSONB,

  -- 원본 계산 데이터
  raw_data JSONB,

  calculated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_saju_charts_profile_id ON public.saju_charts(profile_id);

-- RLS 정책
ALTER TABLE public.saju_charts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own charts"
  ON public.saju_charts FOR SELECT
  USING (
    profile_id IN (
      SELECT id FROM public.saju_profiles WHERE user_id = auth.uid()
    )
  );
```

### 11.4 saju_summaries 테이블
```sql
CREATE TABLE public.saju_summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.saju_profiles(id) ON DELETE CASCADE UNIQUE,
  overview TEXT NOT NULL,
  strengths TEXT[] NOT NULL,
  weaknesses TEXT[] NOT NULL,
  career TEXT,
  love TEXT,
  money TEXT,
  yearly_focus TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_saju_summaries_profile_id ON public.saju_summaries(profile_id);

-- RLS 정책
ALTER TABLE public.saju_summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own summaries"
  ON public.saju_summaries FOR SELECT
  USING (
    profile_id IN (
      SELECT id FROM public.saju_profiles WHERE user_id = auth.uid()
    )
  );
```

### 11.5 chat_sessions 테이블
```sql
CREATE TABLE public.chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID REFERENCES public.saju_profiles(id) ON DELETE CASCADE,
  title TEXT,
  message_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_message_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_chat_sessions_profile_id ON public.chat_sessions(profile_id);
CREATE INDEX idx_chat_sessions_last_message_at ON public.chat_sessions(last_message_at DESC);

-- RLS 정책
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own chat sessions"
  ON public.chat_sessions FOR ALL
  USING (
    profile_id IN (
      SELECT id FROM public.saju_profiles WHERE user_id = auth.uid()
    )
  );
```

### 11.6 chat_messages 테이블
```sql
CREATE TABLE public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  suggested_questions TEXT[],  -- AI 추천 질문 (assistant만)
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_chat_messages_chat_id ON public.chat_messages(chat_id);
CREATE INDEX idx_chat_messages_created_at ON public.chat_messages(created_at);

-- RLS 정책
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own messages"
  ON public.chat_messages FOR ALL
  USING (
    chat_id IN (
      SELECT cs.id FROM public.chat_sessions cs
      JOIN public.saju_profiles sp ON cs.profile_id = sp.id
      WHERE sp.user_id = auth.uid()
    )
  );
```

### 11.7 트리거: updated_at 자동 갱신
```sql
-- updated_at 자동 갱신 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- 각 테이블에 트리거 적용
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_saju_profiles_updated_at
  BEFORE UPDATE ON public.saju_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_saju_summaries_updated_at
  BEFORE UPDATE ON public.saju_summaries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### 11.8 트리거: 메시지 카운트 자동 업데이트
```sql
-- 메시지 추가 시 세션의 message_count, last_message_at 업데이트
CREATE OR REPLACE FUNCTION update_chat_session_on_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.chat_sessions
  SET
    message_count = message_count + 1,
    last_message_at = NEW.created_at
  WHERE id = NEW.chat_id;
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER on_chat_message_insert
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION update_chat_session_on_message();
```

### 11.9 새 유저 생성 시 자동 프로필 생성 (선택)
```sql
-- auth.users에 새 유저 추가 시 public.users에도 추가
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ language 'plpgsql' SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

---

## 12. Supabase 쿼리 예시

### 12.1 프로필 + 차트 + 요약 한번에 조회
```dart
final response = await supabase
    .from('saju_profiles')
    .select('''
      *,
      saju_charts (*),
      saju_summaries (*)
    ''')
    .eq('id', profileId)
    .single();
```

### 12.2 채팅 세션 목록 (최신순)
```dart
final response = await supabase
    .from('chat_sessions')
    .select()
    .eq('profile_id', profileId)
    .order('last_message_at', ascending: false)
    .limit(20);
```

### 12.3 채팅 히스토리 제목 검색
```dart
final response = await supabase
    .from('chat_sessions')
    .select()
    .eq('profile_id', profileId)
    .ilike('title', '%이직%')
    .order('last_message_at', ascending: false);
```

---

## 체크리스트

- [x] User Entity/Model 정의 (P1 - 로그인 시)
- [x] Token Model 정의 (P1)
- [x] API Response 래퍼 정의
- [x] Pagination 모델 정의
- [x] SajuProfile Entity/Model 정의 (P0)
- [x] SajuChart Entity/Model 정의 (P0)
- [x] SajuSummary Entity 정의 (P0)
- [x] ChatSession Entity 정의 (P0)
- [x] ChatMessage Entity/Model 정의 (P0)
- [x] Enum 정의 (Gender, MessageRole)
- [x] Supabase 테이블 스키마 정의
- [x] RLS 정책 정의
- [x] 트리거 함수 정의
