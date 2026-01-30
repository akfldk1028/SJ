# AdMob 프로덕션 전환 작업 목록

## 현재 상태: Production 모드 전환 완료

- **광고 모드**: `AdMode.production`
- **수정 파일**: `lib/ad/ad_config.dart`

---

## 완료된 항목

| 항목 | ID | 상태 |
|------|-----|------|
| App ID (Android) | `ca-app-pub-7140787344231420~3931921704` | 완료 |
| Banner Android | `ca-app-pub-7140787344231420/8692228132` | 완료 |
| Interstitial Android | `ca-app-pub-7140787344231420/2126819784` | 완료 |
| Rewarded Android | `ca-app-pub-7140787344231420/8500656445` | 완료 |
| AD_ID 퍼미션 | AndroidManifest.xml | 완료 |
| AdMode 전환 | `AdMode.production` | 완료 |

---

## 체크리스트
- [x] App ID 설정 (AndroidManifest.xml)
- [x] AD_ID 퍼미션 추가
- [x] Banner Android ID 입력
- [x] Interstitial Android ID 입력
- [x] Rewarded Android ID 입력
- [x] `currentAdMode = AdMode.production` 전환
- [ ] 빌드 & 테스트
- [ ] Google Play Console → 앱 콘텐츠 → 광고 ID 선언 "예"

---

## 참고: iOS ID는 미입력 (Android만 출시 중)
- Banner iOS: `YOUR_BANNER_IOS_ID`
- Interstitial iOS: `YOUR_INTERSTITIAL_IOS_ID`
- Rewarded iOS: `YOUR_REWARDED_IOS_ID`
