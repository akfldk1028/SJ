# iOS 빌드 크리덴셜 (비공개)

> 이 파일은 .gitignore에 등록되어 있습니다. Git에 올라가지 않습니다.
> Mac 빌드 담당자에게 **직접 전달**하세요 (슬랙 DM, USB 등)

---

## Apple Developer 계정

| 항목 | 값 |
|------|-----|
| **Apple ID** | `clickaround8@gmail.com` |
| **비밀번호** | `Q1W2E3r$t%` |
| **Team ID** | `UCXS46KDFJ` |
| **팀 이름** | ClickAround (개인) |
| **프로그램** | Apple Developer Program (갱신일: 2027-01-31) |

---

## 사용 방법

### 1. Xcode에 계정 등록

1. Xcode 실행
2. **Xcode → Settings** (`Cmd + ,`)
3. **Accounts** 탭 → `+` → **Apple ID**
4. 위 Apple ID / 비밀번호 입력
5. 2FA 인증 코드는 계정 소유자(DK)에게 요청

### 2. ExportOptions 설정 (이미 세팅됨)

Team ID `UCXS46KDFJ`는 ExportOptions에 이미 입력되어 있으므로 **별도 작업 불필요**.

### 3. Xcode에서 Team 선택

1. `open ios/Runner.xcworkspace`
2. Runner → Signing & Capabilities → Team 드롭다운에서 선택

### 4. 빌드

```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions-AppStore.plist
```

---

## 주의사항

- **2FA (이중 인증)**: 로그인 시 계정 소유자 기기에 인증 코드가 뜹니다. DK에게 코드 요청하세요.
- 이 파일을 **절대 Git에 커밋하지 마세요**.
- 비밀번호 변경 시 이 파일도 업데이트하세요.

---

*최종 업데이트: 2026-02-01*
