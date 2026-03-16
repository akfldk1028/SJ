# iOS App Store 심사 상태 기록

> **담당**: DK
> **최종 업데이트**: 2026-02-24
> **상태**: Expedited Review 요청 완료, 응답 대기 중

---

## 앱 정보

| 항목 | 값 |
|------|-----|
| 앱 이름 | 사담 |
| Bundle ID | com.clickaround.sadam |
| Apple ID | 6758574982 |
| 버전 | 0.1.0 (빌드 9, 0.0.9) |
| 카테고리 | 라이프스타일 |
| 제출일 | 2026-02-05 오후 10:07 |
| 제출자 | KIMDONGHYEON |

---

## 타임라인

| 날짜 | 상태 | 비고 |
|------|------|------|
| 2026-02-05 | 제출 완료 | iOS 0.1.0 첫 제출 (신규 앱) |
| 2026-02-05 ~ 02-24 | 심사 대기 중 | 19일째 대기, 상태 변화 없음 |
| 2026-02-24 | **Expedited Review 요청** | Apple 응답: "We'll expedite review for 사담." |

---

## Expedited Review 요청 내용

- **경로**: https://developer.apple.com/contact/app-store/?topic=expedite
- **폼 제출 정보**:
  - I would like to: request an expedited app review
  - Name: DONGHYEON KIM
  - Email: clickaround8@gmail.com
  - Organization: DONG HYEON KIM
  - App Name: 사담
  - Platform: iOS
- **Apple 응답 메시지**:
  > "We'll expedite review for 사담."
  > If your submission is rejected during this review, you don't need to request another expedited review when you resubmit. Your resubmission will be automatically returned to the expedited queue.
- **예상 소요 시간**: 레딧 커뮤니티 기준 10분~48시간

---

## 심사 대기 중 수정 가능 여부

| 항목 | 수정 가능? | 비고 |
|------|-----------|------|
| 설명 (Description) | **불가** | 잠금됨 (generic tag, 텍스트박스 아님) |
| 부제 (Subtitle) | **불가** | 잠금됨 |
| 스크린샷 | **불가** | 잠금됨 |
| 프로모션 텍스트 | **가능** | 텍스트박스 |
| 키워드 | **가능** | 텍스트박스 |
| 심사 메모 (Review Notes) | **가능** | 텍스트박스 |

> **결론**: 설명을 수정하고 싶어도 심사 대기 중에는 불가능. 승인 후 다음 업데이트에서 개선.
> 현재 심사 메모에 차별화 근거가 잘 작성되어 있으므로 **지금은 아무것도 건드리지 않는다.**

---

## 카테고리 분석

- **현재**: 라이프스타일 (Lifestyle) → **최적**
- Entertainment로 변경하면 게임/운세 포화 카테고리와 더 가까워짐
- 4.3 리젝은 카테고리가 아니라 **앱 자체의 차별화 부족**이 트리거
- 카테고리 변경 불필요

---

## 현재 메타데이터 (수정 불필요)

### App Store Connect 버전 페이지
- **프로모션 텍스트**: AI가 풀어주는 나만의 사주 이야기. 생년월일만 입력하면 오늘의 운세부터 평생운세까지, 대화하듯 편하게 물어보세요.
- **부제**: AI 사주채팅
- **키워드**: 사주,운세,AI,챗봇,만세력,사담,오늘운세,신년운세,궁합,토정비결
- **스크린샷**: iPhone 6.5인치 10장 등록됨
- **로그인 필요**: 해제됨 (로그인 없는 앱)
- **출시 방식**: 자동으로 버전 출시

### 심사 메모 (이미 작성됨)
```
본 앱은 AI 사주 상담 챗봇입니다. 로그인 없이 이용 가능합니다.

[앱 기능 설명]
- 사용자가 생년월일을 입력하면 AI(GPT/Gemini)가 사주를 분석하고 채팅 형식으로 상담합니다.
- 모든 대화는 사용자와 AI 간 1:1로만 이루어집니다.
- 사용자가 직접 입력한 가족/친구의 생년월일로 궁합을 AI가 분석합니다.

[사용자 간 상호작용 없음 - Guideline 1.2 관련]
- 사용자 간 채팅, 메시징, 매칭 기능이 없습니다.
- 랜덤 채팅, 익명 채팅 기능이 없습니다.
- 소셜 네트워크, 커뮤니티, 공유 기능이 없습니다.
- 사용자 프로필은 비공개이며, 다른 사용자가 검색하거나 열람할 수 없습니다.
- User-Generated Content가 다른 사용자에게 노출되지 않습니다.

[데이터 격리]
- 모든 사용자 데이터는 Supabase Row-Level Security(RLS)로 보호되어 본인만 접근 가능합니다.
- DB에 사용자 간 상호작용 테이블이 존재하지 않습니다.
```

---

## 4.3 리젝 리스크 분석

### 위험 요소
- Apple Guideline 4.3에 "fortune telling"이 명시적 포화 카테고리로 지목됨
- 레딧에서 "신규 fortune telling 앱은 전부 4.3 Spam으로 리젝"이라는 의견 다수

### 방어 근거 (우리 앱이 다른 점)
1. **만세력 기반 계산 엔진**: 단순 AI 텍스트 생성이 아닌 전통 사주 로직 탑재
2. **대화형 AI 상담**: 리포트 뱉고 끝이 아닌, 채팅 형식 실시간 대화
3. **GPT + Gemini 이중 파이프라인**: GPT-5.2 분석 → Gemini 3.0 대화
4. **간단한 UX**: 생년월일만 입력하면 바로 이용 (로그인 불필요)
5. **한국어 전용**: 영어권 포화와 다른 마켓

### 리젝 시 대응 플랜
1. Apple이 4.3으로 리젝하면 → Appeal 제출 (차별화 근거 첨부)
2. 재제출 시 자동으로 expedited 큐에 복귀 (Apple 확인)
3. 필요시 메타데이터에서 "fortune telling" 직접 연상 표현 수정

---

## 리뷰어 테스트 관련

- 리뷰어는 실제 기기에서 앱을 다운받아 테스트함
- 로그인 없는 앱이므로 열기 → 생년월일 입력 → AI 대화 확인으로 리뷰 진행
- 리뷰어 입장에서 가장 테스트하기 쉬운 구조

---

## 다음 AI가 해야 할 것

1. **App Store Connect 상태 확인**: "심사 대기 중" → "심사 중" → "승인" 변화 모니터링
2. **리젝 시**: 리젝 사유 확인 → Resolution Center 메시지 확인 → 위 방어 근거로 Appeal 또는 수정 후 재제출
3. **승인 시**: 자동 출시 설정이므로 바로 App Store에 게시됨 → **다음 업데이트에서 설명(Description) 개선** (현재 잠금 상태라 수정 못 함)
4. **Expedited 재요청 금지**: Apple이 과도한 요청 시 향후 승인 안 해줄 수 있음
5. **현재 아무것도 건드리지 말 것**: 심사 메모에 차별화 근거 충분히 작성됨, 키워드/카테고리 변경 불필요
