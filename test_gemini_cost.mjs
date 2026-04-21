/**
 * Gemini 비용 검증 테스트
 * - implicit caching 동작 확인 (cachedContentTokenCount > 0?)
 * - thinking 토큰 별도 확인 (thoughtsTokenCount)
 * - DB 비용 vs 실제 과금 비교
 *
 * 사용법: node test_gemini_cost.mjs
 */

const SUPABASE_URL = 'https://kfciluyxkomskyxjaeat.supabase.co';

// Edge Function 호출 (실제 사주 채팅 시뮬레이션)
async function callGemini(messages, sessionId, stream = false) {
  const url = `${SUPABASE_URL}/functions/v1/ai-gemini`;

  const body = {
    action: 'chat',
    messages,
    stream,
    session_id: sessionId,
    // user_id 없이 호출 → quota 체크/비용 기록 스킵 (테스트용)
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (stream) {
    // SSE 파싱
    const text = await res.text();
    const lines = text.split('\n').filter(l => l.startsWith('data: '));
    let lastUsage = null;
    let fullText = '';
    for (const line of lines) {
      try {
        const data = JSON.parse(line.slice(6));
        if (data.text) fullText += data.text;
        if (data.usage) lastUsage = data.usage;
      } catch {}
    }
    return { text: fullText, usage: lastUsage };
  } else {
    return await res.json();
  }
}

// 테스트용 시스템 프롬프트 (실제 앱과 비슷한 길이)
const SYSTEM_PROMPT = `당신은 사주 전문가입니다. 사용자의 사주팔자를 기반으로 운세를 분석합니다.
오행 상생상극, 천간합, 지지합충 등을 정확하게 판단하세요.
데이터에 없는 합이나 충을 지어내지 마세요.
유저가 실패를 말하면 현실에 맞춰 재해석하세요.
맹목적 낙관이나 비관은 금지합니다.

사주 데이터:
- 년주: 甲子 (갑자)
- 월주: 丙寅 (병인)
- 일주: 戊午 (무오)
- 시주: 庚申 (경신)
- 일간: 戊 (무토)
- 격국: 식신격
- 용신: 水 (수)

이 사주의 특징을 기반으로 답변하세요.`;

async function runTest() {
  console.log('=== Gemini 비용 검증 테스트 ===\n');

  const sessionId = `test-cost-${Date.now()}`;

  // --- 테스트 1: 첫 호출 (캐시 없음) ---
  console.log('📌 테스트 1: 첫 호출 (캐시 미스 예상)');
  const msg1 = [
    { role: 'system', content: SYSTEM_PROMPT },
    { role: 'user', content: '내 사주에서 올해 재물운은 어때?' },
  ];

  const r1 = await callGemini(msg1, sessionId, false);

  if (r1.usage) {
    const u = r1.usage;
    console.log(`  prompt_tokens: ${u.prompt_tokens}`);
    console.log(`  completion_tokens: ${u.completion_tokens}`);
    console.log(`  thoughts_tokens: ${u.thoughts_tokens || 'N/A'}`);
    console.log(`  cached_tokens: ${u.cached_tokens || 0}`);
    console.log(`  total: ${u.total_tokens}`);

    const cached = u.cached_tokens || 0;
    const nonCached = u.prompt_tokens - cached;
    const thoughts = u.thoughts_tokens || 0;

    // DB 비용 (현재 코드 방식 — thinking 미포함)
    const dbCost = (nonCached * 0.10 / 1e6) + (cached * 0.01 / 1e6) + (u.completion_tokens * 0.40 / 1e6);
    // 실제 과금 (thinking 포함)
    const realCost = (nonCached * 0.10 / 1e6) + (cached * 0.01 / 1e6) + ((u.completion_tokens + thoughts) * 0.40 / 1e6);

    console.log(`  💰 DB 기록 비용: $${dbCost.toFixed(6)}`);
    console.log(`  💰 실제 과금 추정: $${realCost.toFixed(6)}`);
    console.log(`  ⚠️ 차이: $${(realCost - dbCost).toFixed(6)} (thinking ${thoughts} tokens)`);
    console.log(`  📊 캐시 히트: ${cached > 0 ? `${Math.round(cached/u.prompt_tokens*100)}%` : '없음 (첫 호출)'}`);
  } else {
    console.log('  ❌ usage 정보 없음:', JSON.stringify(r1).substring(0, 200));
  }

  console.log('');

  // --- 테스트 2: 같은 세션 두 번째 호출 (캐시 히트 기대) ---
  console.log('📌 테스트 2: 같은 세션 두 번째 호출 (캐시 히트 기대)');
  const msg2 = [
    { role: 'system', content: SYSTEM_PROMPT },
    { role: 'user', content: '내 사주에서 올해 재물운은 어때?' },
    { role: 'assistant', content: r1.content || '재물운에 대해 분석하겠습니다.' },
    { role: 'user', content: '그럼 연애운은?' },
  ];

  const r2 = await callGemini(msg2, sessionId, false);

  if (r2.usage) {
    const u = r2.usage;
    console.log(`  prompt_tokens: ${u.prompt_tokens}`);
    console.log(`  completion_tokens: ${u.completion_tokens}`);
    console.log(`  thoughts_tokens: ${u.thoughts_tokens || 'N/A'}`);
    console.log(`  cached_tokens: ${u.cached_tokens || 0}`);

    const cached = u.cached_tokens || 0;
    const nonCached = u.prompt_tokens - cached;
    const thoughts = u.thoughts_tokens || 0;

    const dbCost = (nonCached * 0.10 / 1e6) + (cached * 0.01 / 1e6) + (u.completion_tokens * 0.40 / 1e6);
    const realCost = (nonCached * 0.10 / 1e6) + (cached * 0.01 / 1e6) + ((u.completion_tokens + thoughts) * 0.40 / 1e6);

    console.log(`  💰 DB 기록 비용: $${dbCost.toFixed(6)}`);
    console.log(`  💰 실제 과금 추정: $${realCost.toFixed(6)}`);
    console.log(`  ⚠️ 차이: $${(realCost - dbCost).toFixed(6)}`);
    console.log(`  📊 캐시 히트: ${cached > 0 ? `${Math.round(cached/u.prompt_tokens*100)}% ✅` : '없음 ❌ 캐싱 안 되고 있음!'}`);
  }

  console.log('');

  // --- 테스트 3: 다른 세션 (캐시 미스 기대) ---
  console.log('📌 테스트 3: 다른 세션 ID (캐시 미스 기대)');
  const msg3 = [
    { role: 'system', content: SYSTEM_PROMPT },
    { role: 'user', content: '내 건강운 알려줘' },
  ];

  const r3 = await callGemini(msg3, `different-session-${Date.now()}`, false);

  if (r3.usage) {
    const u = r3.usage;
    const cached = u.cached_tokens || 0;
    console.log(`  prompt_tokens: ${u.prompt_tokens}`);
    console.log(`  cached_tokens: ${cached}`);
    console.log(`  📊 캐시 히트: ${cached > 0 ? `${Math.round(cached/u.prompt_tokens*100)}% (다른 세션인데 캐시됨 → implicit caching 전역 동작)` : '없음 (정상 — 다른 세션)'}`);
  }

  console.log('\n=== 요약 ===');
  console.log('1. cached_tokens > 0 이면 implicit caching 동작 중');
  console.log('2. thoughts_tokens > 0 이면 thinking 활성화 확인');
  console.log('3. DB 비용 < 실제 과금이면 thinking 비용 누락 → Edge Function 수정 필요');
}

runTest().catch(console.error);
