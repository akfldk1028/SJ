● 🔥 진짜 원인 찾았습니다!                                                                                                                          
                                                                                          
  결정적 단서                                                                                                                                       
                                                                                                                                                    
  커밋 4c52d09 security: .env APK 노출 차단에서:
  - flutter_dotenv 제거 → String.fromEnvironment + --dart-define-from-file=.env 으로 전환                                                           
  - 즉 빌드 시 .env를 환경변수로 명시적 주입 필요                                                                                                 

  내가 했던 빌드 명령

  flutter build appbundle --release   # ❌ --dart-define-from-file=.env 누락!

  → 빌드된 apk에 SUPABASE_URL, SUPABASE_ANON_KEY 등이 모두 empty string으로 들어감 → Supabase 연결 자체 실패 → 모든 Edge Function 호출 실패
  (채팅/월별/평생/일별)

  즉시 재빌드합니다

