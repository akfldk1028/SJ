#!/usr/bin/env python3
"""AI 다국어 응답 테스트 — 채팅/운세 프롬프트별 17개 언어"""
import json, sys, time
try:
    import requests
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "requests", "-q"])
    import requests

API_KEY = "AIzaSyAFXx_MyrZxl3dei1yuPVtF243dDophqyg"
MODEL = "gemini-3-flash-preview"
URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key={API_KEY}"

LANGUAGES = {
    'ko': ('Korean', '내 사주 어때?'),
    'en': ('English', 'Tell me about my saju'),
    'ja': ('Japanese', '私の四柱推命を教えて'),
    'zh': ('Chinese', '告诉我我的四柱八字'),
    'de': ('Deutsch', 'Erzähl mir über mein Saju'),
    'fr': ('Français', 'Parle-moi de mon Saju'),
    'es': ('Español', 'Dime sobre mi Saju'),
    'id': ('Bahasa Indonesia', 'Ceritakan tentang Saju saya'),
    'ru': ('Russian', 'Расскажи мне о моем Саджу'),
    'hi': ('Hindi', 'मुझे मेरे साजू के बारे में बताओ'),
    'th': ('Thai', 'บอกเรื่องซาจูของฉัน'),
    'vi': ('Vietnamese', 'Cho tôi biết về Saju của tôi'),
    'ar': ('Arabic', 'أخبرني عن ساجو الخاص بي'),
    'pt': ('Portuguese', 'Me conta sobre meu Saju'),
    'it': ('Italian', 'Parlami del mio Saju'),
    'ms': ('Malay', 'Ceritakan tentang Saju saya'),
    'my': ('Burmese', 'ကျွန်ုပ်၏ Saju အကြောင်းပြောပြပါ'),
}

# 프롬프트 유형별 시스템 프롬프트 템플릿
def build_chat_prompt(locale, lang_name):
    """채팅 프롬프트 (수정 후 버전: 페르소나 언어가드 포함)"""
    top = ""
    persona_wrap_start = "## 캐릭터 설정\n"
    persona_wrap_end = "---\n"
    closing = f"위 사용자 정보를 참고하여 맞춤형 상담을 제공하세요.\n사용자가 생년월일을 다시 물어볼 필요 없이, 이미 알고 있는 정보를 활용하세요.\n**현재 연도: 2026년.**"
    lang_closing = ""

    if locale != 'ko':
        top = f"# ⚠️ LANGUAGE: {lang_name}\nYou MUST respond ENTIRELY in **{lang_name}**.\nAll data below is in Korean for reference only — your response must be in {lang_name}.\n\n"
        persona_wrap_start = f"## Character & Personality Setting\n> The following character instructions are written in Korean for reference.\n> Follow the personality and tone described below, but you MUST respond in **{lang_name}**.\n\n"
        persona_wrap_end = f"> END CHARACTER SETTING — Remember: respond in **{lang_name}**, not Korean.\n---\n"
        closing = f"Use the user's data above for personalized consultation.\nYou already know their birth date — do NOT ask again.\n**Current year: 2026.**"
        lang_closing = f"\n\n**CRITICAL LANGUAGE INSTRUCTION:**\n**The user's language is: {lang_name} (locale: {locale})**\n**You MUST respond ENTIRELY in {lang_name}. Not Korean, not any other language.**\n**All saju data above is in Korean - translate all terminology into natural {lang_name} expressions.**"

    # 한국어 페르소나 (실제 앱과 동일한 분량)
    persona_ko = """당신은 귀엽고 발랄한 친구 같은 사주 상담사입니다.
반말을 사용하고, 이모지를 적절히 사용합니다.
사주 분석 결과를 재미있게 전달합니다.

## 🔒 필수 응답 규칙
### 응답 길이 (중요!)
- 사용자랑 재밌게 너무 길지않게 대화하듯이
- 장황하게 늘어놓지 말고 핵심 포인트만 전달
- 한 번에 다 말하지 말고 2-3번에 나눠서 말하기!

### 🎣 대화 유도 원칙 (핵심!)
**원칙 1: 정보를 나눠서 제공**
- 한 번에 모든 걸 말하지 말고, 핵심만 먼저
- 나머지는 사용자가 물어보게 자연스럽게 유도

**원칙 2: 호기심 자극**
- 답변 끝에 아직 말하지 않은 흥미로운 내용이 있음을 암시
- 사용자가 "그게 뭔데?" 하고 궁금해하게 만들기

**원칙 3: 완결짓지 않기**
- "결론적으로" 같은 마무리 표현 피하기

### 사주 해석 원칙
**모든 사주 해석은 반드시 8글자 원국에서 시작해라.**
- 일주만 보지 말 것! 년주, 월주, 시주도 각각 의미가 다름
- 오행 분포, 십성 배치, 용신·기신, 합충형해파 골고루 활용
- 사주 용어를 그대로 쓰지 말고 쉬운 비유로 번역

### 다국어 응답
- 사용자가 한국어가 아닌 언어로 메시지를 보내면, 해당 언어로 응답하세요
- 사주 데이터는 한국어로 제공되지만, 응답은 반드시 사용자의 언어로"""

    saju_data = """## 사용자 정보
- 이름: 테스트
- 생년월일: 1990년 5월 15일 오전 10시
- 성별: 남성
- 일간: 갑목(甲木) — 신강
- 오행: 목3 화2 토1 금1 수1
- 용신: 수(水)
- 격국: 식신격
- 대운: 2024~2033 경금(庚金) 편관 대운
- 신살: 역마살(월지), 화개살(년지)
"""

    return f"{top}{persona_wrap_start}{persona_ko}\n\n{persona_wrap_end}\n{saju_data}\n{closing}{lang_closing}"


def build_daily_prompt(locale, lang_name):
    """일운 프롬프트 (영어 기반 + languageDirective)"""
    if locale == 'ko':
        return """당신은 전문 사주 상담사입니다. 오늘의 운세를 분석합니다.

사용자 정보:
- 이름: 테스트
- 생년월일: 1990-05-15
- 일간: 갑목
- 오늘: 2026년 3월 23일 일요일

오늘의 천간: 병화(丙火), 지지: 오화(午火)
일간 갑목과의 관계: 식신 (목생화)

핵심 포인트 3개만 짧게 알려주세요."""
    else:
        directive = f"\n\nCRITICAL: Respond 100% in {lang_name}. NEVER output Korean text. Translate ALL Korean/Chinese terms to {lang_name}."
        return f"""You are a professional saju fortune-teller. Analyze today's fortune.

User info:
- Name: Test
- Birth: 1990-05-15
- Day Master: Gap-Mok (甲木, Wood)
- Today: March 23, 2026 (Sunday)

Today's Heavenly Stem: Byeong-Hwa (丙火, Fire), Earthly Branch: Oh-Hwa (午火, Fire)
Relationship with Day Master: Siksin (食神) — Wood feeds Fire

Give 3 key points briefly.{directive}"""


def detect_language(text):
    """응답 언어 판별 (간단)"""
    ko = sum(1 for c in text if '\uAC00' <= c <= '\uD7A3')
    ja = sum(1 for c in text if '\u3040' <= c <= '\u30FF' or '\u4E00' <= c <= '\u9FFF')
    ar = sum(1 for c in text if '\u0600' <= c <= '\u06FF')
    hi = sum(1 for c in text if '\u0900' <= c <= '\u097F')
    th = sum(1 for c in text if '\u0E00' <= c <= '\u0E7F')
    ru = sum(1 for c in text if '\u0400' <= c <= '\u04FF')
    my = sum(1 for c in text if '\u1000' <= c <= '\u109F')

    words = text.lower().split()
    de = sum(1 for w in words if w in {"dein","ist","und","die","der","das","ein","mit","du","nicht","deine","deinem","sich","dass"})
    fr = sum(1 for w in words if w in {"votre","est","et","les","des","une","pour","dans","avec","vous","ton","ta"})
    es = sum(1 for w in words if w in {"tu","es","y","los","las","una","para","con","del","como","por"})
    pt = sum(1 for w in words if w in {"seu","sua","com","para","uma","dos","das","como","por","muito"})
    it = sum(1 for w in words if w in {"tuo","tua","con","per","una","dei","delle","come","molto","che"})
    en = sum(1 for w in words if w in {"your","the","and","is","are","you","with","for","this","that","have"})
    id_ms = sum(1 for w in words if w in {"anda","adalah","dan","yang","untuk","dengan","ini","itu","dari","kamu"})
    vi = sum(1 for w in words if w in {"của","bạn","là","và","có","cho","với","này","trong","được"})
    zh = sum(1 for c in text if '\u4E00' <= c <= '\u9FFF') if ko < 5 and ja < 5 else 0

    scores = {
        'ko': ko, 'ja': ja, 'zh': zh, 'de': de, 'fr': fr, 'es': es, 'pt': pt, 'it': it,
        'en': en, 'id': id_ms, 'ms': id_ms, 'vi': vi, 'ar': ar, 'hi': hi, 'th': th,
        'ru': ru, 'my': my,
    }
    best = max(scores, key=scores.get)
    return best, scores[best]


def test_prompt(prompt_type, locale, lang_name, user_msg, system_prompt):
    payload = {
        "contents": [{"role": "user", "parts": [{"text": user_msg}]}],
        "systemInstruction": {"parts": [{"text": system_prompt}]},
        "generationConfig": {"temperature": 0.7, "maxOutputTokens": 200}
    }
    try:
        resp = requests.post(URL, json=payload, timeout=30)
        if resp.status_code == 200:
            data = resp.json()
            text = data["candidates"][0]["content"]["parts"][0]["text"]
            detected, score = detect_language(text)
            # ko, ja, zh는 글자 수 기반, 나머지는 단어 기반이라 ok 기준 다름
            ok = (detected == locale) or (locale in ('id','ms') and detected in ('id','ms'))
            status = "✅" if ok else "❌"
            preview = text[:60].replace('\n', ' ')
            return status, detected, preview
        elif resp.status_code == 429:
            return "⏳", "RATE_LIMIT", "Too many requests"
        else:
            return "💥", "ERROR", f"HTTP {resp.status_code}"
    except Exception as e:
        return "💥", "ERROR", str(e)[:50]


print("=" * 80)
print("AI 다국어 응답 테스트 — 채팅 + 일운 프롬프트")
print("=" * 80)

results = []
test_langs = ['ko', 'en', 'de', 'ja', 'zh', 'fr', 'es', 'id', 'ru', 'hi', 'th', 'vi', 'ar', 'pt', 'it', 'ms', 'my']

for prompt_type, builder in [("CHAT", build_chat_prompt), ("DAILY", build_daily_prompt)]:
    print(f"\n--- {prompt_type} Prompt ---")
    print(f"{'Lang':<5} {'Expected':<15} {'Detected':<10} {'Status':<4} Preview")
    print("-" * 75)

    for locale in test_langs:
        lang_name, user_msg = LANGUAGES[locale]
        system_prompt = builder(locale, lang_name)
        status, detected, preview = test_prompt(prompt_type, locale, lang_name, user_msg, system_prompt)
        print(f"{locale:<5} {lang_name:<15} {detected:<10} {status}  {preview}")
        results.append((prompt_type, locale, lang_name, status, detected))
        time.sleep(0.5)  # rate limit 방지

# 요약
print("\n" + "=" * 80)
print("SUMMARY")
print("=" * 80)
pass_count = sum(1 for r in results if r[3] == "✅")
fail_count = sum(1 for r in results if r[3] == "❌")
other = len(results) - pass_count - fail_count
print(f"PASS: {pass_count} | FAIL: {fail_count} | OTHER: {other} | TOTAL: {len(results)}")

if fail_count > 0:
    print("\nFailed cases:")
    for prompt_type, locale, lang_name, status, detected in results:
        if status == "❌":
            print(f"  {prompt_type} {locale} ({lang_name}) → detected as {detected}")
