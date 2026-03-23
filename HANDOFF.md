# HANDOFF — SaDam→MOL 사주 8글자 딥 매핑 v3

> 작성: 2026-03-23 | DK-DD 브랜치

---

## Goal

SaDam 사주 앱의 사주 데이터를 MOL 에이전트 커뮤니티로 자동 이관하여, **사주 8글자 + 딥 데이터(격국/십신/합충/신살/지장간/대운)**를 전부 반영한 AI 에이전트 페르소나를 생성하는 시스템.

**v2.2 완료** → **v3 구현 필요** (8글자 딥 매핑)

---

## Current Progress (v2.2 완료)

### 인프라 (전부 작동 확인)
- SaDam trigger `trg_saju_to_mol` → MOL Edge Function `saju-to-agent` v2.2 (version 6)
- SaDam trigger `trg_ai_summary_to_mol` → MOL Edge Function `saju-enrich-agent` v3
- 시크릿: MOL secrets CLI 설정 완료 + SaDam `app_secrets` 테이블 (SECURITY DEFINER)
- 시크릿 값: `ascsoefc86NlWG5kimbr70wFipKwv3e8XeyHX7UAHsY`
- 트리거 함수: `app_secrets` 테이블에서 시크릿 읽도록 수정 완료

### DB 스키마
- MOL `agent_saju_origin`: 8글자 + 격국/용신/십신/합충/신살/십이운성 + **대운/지장간/길성/십이신살/세운** (5개 컬럼 추가)
- MOL `agents`: personality(jsonb), speaking_style(jsonb), persona(text), archetype(varchar)
- MOL `agent_ai_knowledge`: ai_summaries 이관 (COALESCE 인덱스 대응 완료)
- MOL `agent_chat_archive`: chat 이관

### v2.2 매핑 (현재)
```
personality = oheng_ratio(8글자 균등) + day_master_bonus(일간) + season_bonus(월지 계절)
archetype = DAY_MASTER_ARCHETYPE[일간]
```
**문제**: 8글자 오행 비율만 봄. 격국/십신/합충/신살/지장간/일간강약 미사용.

### E2E 검증 완료 (5명)
| 이름 | 일간 | Archetype | O/C/E/A/N |
|------|------|-----------|-----------|
| 배종환 | 癸 이슬 | lurker | 0.36/0.63/0.31/0.94/0.46 |
| dd | 戊 산 | character | 0.63/0.15/0.63/0.94/0.36 |
| 조현희 | 己 정원 | connector | 0.63/0.63/0.05/0.83/0.63 |
| 김지훈 | 乙 덩굴 | connector | 0.88/0.42/0.42/0.57/0.42 |
| 정인영 | 己 정원 | connector | 0.47/0.42/0.42/1.00/0.00 |

---

## What Worked
1. **`extractHanja()`** — DB의 "계(癸)" 형식에서 한자 추출. 정규식 `\((.)\)`
2. **agents INSERT 시 id/api_key_hash 직접 생성** — `crypto.randomUUID()` + `sha256Hex()`
3. **Supabase MCP로 배포** — `mcp__supabase__deploy_edge_function` 직접 사용
4. **Supabase CLI로 시크릿 설정** — `npx supabase secrets set --project-ref`
5. **app_secrets 테이블** — `ALTER DATABASE` 권한 없어서 테이블로 대체, SECURITY DEFINER
6. **saju-enrich-agent insert fallback** — COALESCE 함수 인덱스라 upsert 안 됨 → insert + 23505 무시

## What Didn't Work
1. **v2 handleNewSaju가 origin 읽기만 함** — 트리거 첫 호출 시 origin 없음. INSERT 먼저 해야 함
2. **`ALTER DATABASE SET app.mol_webhook_secret`** — Supabase 관리형이라 superuser 권한 없음
3. **`onConflict: 'source_hash,knowledge_type,coalesce_target_date'`** — COALESCE 함수 인덱스는 Supabase upsert 불가
4. **curl에서 한글/한자** — Windows cp949 인코딩 문제. Python urllib 사용해야 함
5. **백그라운드 에이전트 Bash 권한** — 서브에이전트에 Bash 없음. 직접 실행해야 함

---

## Next Steps: v3 딥 매핑 구현

### 플랜 파일: `D:\DevCache\claude-data\plans\calm-riding-jellyfish.md`

### 7 Layer 매핑 설계

**Layer 1: 기둥별 가중 오행** (v2는 균등)
```
년간/년지: 0.10, 월간/월지: 0.30, 일간/일지: 0.40, 시간/시지: 0.20
```

**Layer 2: 지장간(Hidden Stems)** → 내면 Big Five
```
지지 속 숨겨진 천간의 오행 → "hidden_personality" (외면과 별도)
子:癸 | 丑:己癸辛 | 寅:甲丙戊 | 卯:乙 | 辰:戊乙癸 | 巳:丙庚戊
午:丁己 | 未:己丁乙 | 申:庚壬戊 | 酉:辛 | 戌:戊辛丁 | 亥:壬甲
```

**Layer 3: 십신(Ten Gods)** → 대인관계 패턴
```
비겁 → A 감소, 식상 → O 증가, 재성 → C 증가, 관성 → C+N 증가, 인성 → A 증가
```

**Layer 4: 격국** → archetype 정교화
```
식신격→creator, 편재격→provocateur, 비견격→expert, 정관격→character
편관격→critic, 정인격→connector, 편인격→lurker
```

**Layer 5: 일간 강약** → 자신감/독립성
```
신강(>50): E+0.10 A-0.05 | 신약(<40): N+0.10 A+0.05
```

**Layer 6: 합충** → 내적 갈등/조화
```
충 개수 → N+(충*0.03) | 합 개수 → A+(합*0.03) | 형 → N+0.05
```

**Layer 7: 신살** → 특수 trait
```
도화살→E+0.10 | 역마살→O+0.10 | 화개살→O+0.10 | 양인살→C+0.10 | 천을귀인→A+0.05
```

### 최종 공식
```
personality = weighted_oheng * 0.35 + day_master * 0.20 + sipsin * 0.15
            + strength * 0.10 + hapchung * 0.10 + sinsal * 0.10
archetype = gyeokguk_archetype || day_master_archetype
hidden_personality = jijanggan_oheng (내면 별도)
```

### 구현 순서
1. `mol-saju-to-agent/index.ts`에 7 layer 매핑 구현
2. 5명 테스트 케이스로 v2 vs v3 비교
3. MOL 재배포 + recalculate 실행
4. 메모리 업데이트

---

## 핵심 파일 위치

| 파일 | 용도 |
|------|------|
| `supabase/functions/mol-saju-to-agent/index.ts` | v2.2 Edge Function 코드 (v3로 교체) |
| `docs/manseryeok_logic.md` | 만세력 계산 기술 문서 |
| `frontend/lib/features/saju_chart/data/constants/` | 천간/지지/오행/지장간 데이터 |
| `frontend/lib/features/saju_chart/domain/services/` | 사주 계산 서비스들 |

## 프로젝트 연결
- SaDam Supabase: `kfciluyxkomskyxjaeat` (싱가포르)
- MOL Supabase: `ccqwgtemeqprpzvjghbo` (도쿄)

## 메모리
- `memory/mol/saju_agent_bridge_status.md` — 전체 시스템 상태
- `memory/mol/saju_bigfive_mapping_v2_verified.md` — v2 매핑 공식 + 5명 검증
- `memory/mol/arxiv_research_results.md` — 학술 논문 조사 결과
- `memory/mol/saju_bigfive_mapping_research.md` — 일간/오행 매핑 리서치

## 학술 참고
- **Big5-Scaler** (arxiv 2508.06149) — 숫자 기반 프롬프트가 가장 효과적
- **Persona Alchemy** (2505.18351) — SCT 4요소 프레임워크
- **BaZi→Big Five 직접 논문은 없음** — 학계 최초 시도
