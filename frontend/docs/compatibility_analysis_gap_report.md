# Compatibility Analysis Data Flow Gap Report

**Generated**: 2026-03-08  
**Status**: Exploration Complete - Ready for Implementation Planning

---

## Executive Summary

The compatibility analysis system has **4 CRITICAL GAPS** where data is calculated but not passed to the system prompt builder for Gemini integration. These gaps prevent the AI from accessing detailed analysis reasoning that users expect in follow-up conversations.

| Gap ID | Severity | Issue | Impact |
|--------|----------|-------|--------|
| **GAP-1** | CRITICAL | Category scores breakdown missing | Gemini can't explain which compatibility category (oheng/hapchung/yongsin/sinsal/energy) is strongest/weakest |
| **GAP-2** | CRITICAL | detailed_analysis structure never populated | Missing oheng interpretation, hapchung interpretation, yongsin synergy reasoning |
| **GAP-3** | CRITICAL | _person1_chars / _person2_chars not injected | Gemini doesn't have individual saju character data for personalized explanations |
| **GAP-4** | MODERATE | Advice field always null | No recommendations calculated or stored |

---

## Data Flow Diagram

```
CompatibilityCalculator (Dart)
    ↓
    ├─ Calculates: overall_score, hapchung_details, strengths, challenges
    ├─ MISSING: category_scores breakdown
    ├─ MISSING: detailed_analysis with interpretations
    └─ MISSING: person1/person2 char data
    ↓
CompatibilityAnalysisService._saveAnalysisResult()
    ↓
    ├─ Saves to DB: overall_score, category_scores (empty?), summary, strengths, challenges
    ├─ Saves: saju_analysis JSON (profiles), hapchung details
    └─ Saves advice=null
    ↓
SystemPromptBuilder._addCompatibilityAnalysisResult()
    ↓
    ├─ Expects: category_scores with keys [oheng_harmony, hapchung_interaction, yongsin_compatibility, sinsal_synergy, energy_balance]
    ├─ Expects: detailed_analysis Map with oheng/hapchung/yongsin interpretations
    ├─ Expects: _person1_chars and _person2_chars with saju breakdown
    └─ Gets: only overall_score, summary, strengths, challenges
    ↓
Gemini (Constrained without detail context)
```

---

## CRITICAL GAP #1: Category Scores Breakdown Missing

### What's Calculated
In **compatibility_calculator.dart**:
- `_analyzeOheng()` → returns score + reason
- `_analyzeYongsinCompat()` → returns int score (-10 to 20)
- `_analyzeIlju()` → returns hapchung/chung/hap details
- `_analyzeHapchung()` → builds complete hapchung analysis

### What's Returned
In **CompatibilityResult.toJson()**:
```dart
'category_scores': {
  // Currently EMPTY or only has 'overall' key
  'overall': 65  // Only this is returned
}
```

### What's Expected
In **SystemPromptBuilder._addCategoryScore()**:
```dart
// Expects Map with these keys:
'oheng_harmony': int,           // 0-100: 오행 조화도
'hapchung_interaction': int,    // 0-100: 합충 상호작용
'yongsin_compatibility': int,   // 0-100: 용신 매치도
'sinsal_synergy': int,          // 0-100: 신살 시너지
'energy_balance': int           // 0-100: 에너지 균형
```

### Impact on User Experience
**Without this data, Gemini cannot:**
- Explain "Your oheng compatibility is 78/100 because..."
- Recommend "Focus on enhancing your yongsin synergy..."
- Identify specific strength areas for follow-up questions

### Fix Required
Modify **CompatibilityCalculator.toJson()** to return:
```dart
'category_scores': {
  'overall': overall,
  'oheng_harmony': ohengScore,
  'hapchung_interaction': hapchungScore,
  'yongsin_compatibility': yongsinScore,
  'sinsal_synergy': sinsalScore,
  'energy_balance': energyScore
}
```

---

## CRITICAL GAP #2: detailed_analysis Structure Never Populated

### What's Calculated
In **compatibility_calculator.dart**:
- `_analyzeOheng()` calculates: compatible, type (sangsaeng/sanggeuk/same), reason
- `_analyzeYongsinCompat()` calculates: score, yongsin effects
- `_analyzeHapchung()` calculates: detailed lists of hap/chung/hyung/hae/pa/wonjin

### What's Returned
In **CompatibilityResult.toJson()**:
```dart
'hapchung_details': hapchungDetails.toJson(),  // Only this
'strengths': [...],
'challenges': [...]
// NO 'detailed_analysis' key at all
```

### What's Expected
In **SystemPromptBuilder._addCompatibilityAnalysisResult()**:
```dart
final detailedAnalysis = analysis['detailed_analysis'] as Map?;
if (detailedAnalysis != null) {
  // Expects structure:
  final oheng = detailedAnalysis['oheng'] as Map?;
  final hapchung = detailedAnalysis['hapchung'] as Map?;
  final yongsin = detailedAnalysis['yongsin'] as Map?;
}
```

With these expected keys inside:
```
detailed_analysis:
  oheng:
    my_day_master: 甲
    target_day_master: 丙
    relationship: "상생"
    interpretation: "Wood generates Fire, creating harmony..."
  
  hapchung:
    haps: ["자오합 (Rat-Horse Match)", ...]
    chungs: ["자축충 (Rat-Cow Clash)", ...]
    others: [...]
    interpretation: "You have 3 positive haps and 2 negative chungs..."
  
  yongsin:
    my_yongsin_effect: "Your yongsin is Fire..."
    target_yongsin_effect: "Partner's yongsin is Wood..."
    synergy: "Fire and Wood create complementary energy..."
```

### What's Actually Stored
Currently saved to DB (from compatibility_analysis_service.dart):
```dart
'saju_analysis': {
  'person1': sajuAnalysis1.toJson(),
  'person2': sajuAnalysis2.toJson()
}
// No interpretations, no relationship analysis
```

### Impact on User Experience
**Without this data, Gemini cannot:**
- Explain "You have strong 合 (Hap) matching in years and days..."
- Show "This Fire-Wood pairing suggests natural complementary energy..."
- Deep-dive conversations like "Tell me more about why our 용신 compatibility is strong"

### Fix Required
Populate new `detailed_analysis` field in **CompatibilityResult**:
```dart
'detailed_analysis': {
  'oheng': {
    'my_day_master': dayMasterChar1,
    'target_day_master': dayMasterChar2,
    'relationship': ohengType,
    'interpretation': ohengInterpretation
  },
  'hapchung': {
    'haps': listOfPositiveMatches,
    'chungs': listOfNegativeClashes,
    'others': listOfNeutralInteractions,
    'interpretation': hapchungInterpretation
  },
  'yongsin': {
    'my_yongsin_effect': person1YongsinInterpretation,
    'target_yongsin_effect': person2YongsinInterpretation,
    'synergy': yongsinSynergyInterpretation
  }
}
```

---

## CRITICAL GAP #3: Person Character Data Not Injected

### What's Calculated
In **compatibility_calculator.dart**:
- Parses both saju profiles into `_ParsedSaju` with: year_gan/ji, month_gan/ji, day_gan/ji, hour_gan/ji, all character elements

### What's Available in DB
From **compatibility_analysis_service._saveAnalysisResult()**:
```dart
// Saves individual saju characters:
'target_year_gan', 'target_year_ji', 'target_month_gan', 'target_month_ji',
'target_day_gan', 'target_day_ji', 'target_hour_gan', 'target_hour_ji',
// But owner's characters are only in 'saju_analysis' JSON
```

### What's Expected
In **SystemPromptBuilder._addCompatibilityAnalysisResult()**:
```dart
final person1Chars = analysis['_person1_chars'] as Map?;
final person2Chars = analysis['_person2_chars'] as Map?;

// Expects structure:
{
  'year_gan': '甲',
  'year_ji': '子',
  'month_gan': '正',
  'month_ji': '寅',
  'day_gan': '甲',
  'day_ji': '子',
  'hour_gan': '甲',
  'hour_ji': '子',
  'ten_gods': {month_gan relative to day_gan: [관/편관/etc]},
  'day_master_element': '木',
  'oheng_distribution': {목: 3, 화: 1, 토: 0, 금: 2, 수: 2}
}
```

### Impact on User Experience
**Without this data, Gemini cannot:**
- Say "Your day master is 甲木 (Wood). Partner's is 丙火 (Fire)..."
- Explain "You have abundant Wood element (3 characters) creating active leadership energy..."
- Provide targeted advice: "Your Metal weakness can be balanced by partner's abundant Metal..."
- Reference during conversations: "Given your 子(Rat) month, this explains your intuitive nature..."

### Fix Required
In **compatibility_analysis_service.analyzeCompatibility()**:
```dart
// After calculation, inject character data:
result.data?['_person1_chars'] = {
  'year_gan': person1Saju.yearGan,
  'year_ji': person1Saju.yearJi,
  'month_gan': person1Saju.monthGan,
  'month_ji': person1Saju.monthJi,
  'day_gan': person1Saju.dayGan,
  'day_ji': person1Saju.dayJi,
  'hour_gan': person1Saju.hourGan,
  'hour_ji': person1Saju.hourJi,
  'day_master_element': _getElement(person1Saju.dayGan),
  'oheng_distribution': person1Saju.ohengDistribution
};

result.data?['_person2_chars'] = { ... similar for person2 }
```

---

## MODERATE GAP #4: Advice Field Always Null

### Current State
In **compatibility_analysis_service._saveAnalysisResult()**:
```dart
'advice': null,  // Always null
```

### What's Expected
In **SystemPromptBuilder._addCompatibilityAnalysisResult()**:
```dart
final advice = analysis['advice'];
if (advice != null) {
  // Uses it for recommendations section
}
```

### Impact on User Experience
- No personalized relationship recommendations stored
- Advice must come entirely from Gemini, without grounding in calculated data
- Harder to maintain consistency across conversations

### Fix Consideration
Could calculate advice based on:
- Weakest category scores → suggest focus areas
- Specific hapchung clashes → compatibility maintenance tips
- Yongsin mismatches → energy balancing activities

However, this is MODERATE priority compared to gaps 1-3, as Gemini can generate reasonable advice without pre-calculated suggestions.

---

## Detailed Field Mapping

### CompatibilityCalculator.toJson() → DB Storage → SystemPromptBuilder Expectation

| Field | toJson() Returns | Stored to DB | Prompt Builder Expects | Gap |
|-------|-----------------|-------------|----------------------|-----|
| `overall_score` | 0-100 int | ✓ | ✓ | None |
| `category_scores` | `{overall: X}` | Partial | `{oheng: X, hapchung: X, yongsin: X, sinsal: X, energy: X}` | **GAP-1** |
| `hapchung_details` | HapchungAnalysis.toJson() | ✓ as `pair_hapchung` | ✓ (`pair_hapchung` or in `detailed_analysis`) | None |
| `strengths` | List<String> | ✓ | ✓ | None |
| `challenges` | List<String> | ✓ | ✓ | None |
| `summary` | String | ✓ | ✓ | None |
| `detailed_analysis` | NOT CREATED | N/A | Expected (oheng/hapchung/yongsin interpretations) | **GAP-2** |
| `_person1_chars` | NOT CREATED | Partially (individual chars) | Expected (consolidated Map) | **GAP-3** |
| `_person2_chars` | NOT CREATED | Partially (individual chars) | Expected (consolidated Map) | **GAP-3** |
| `advice` | NOT CREATED | null | Optional (nice-to-have) | **GAP-4** |

---

## Affected Code Locations

### Files That Need Modification

| File | Method | Change Required | Priority |
|------|--------|-----------------|----------|
| `compatibility_calculator.dart` | `toJson()` | Add category_scores breakdown + detailed_analysis | **P0** |
| `compatibility_calculator.dart` | `_calculateScores()` | Return individual category scores (not just overall) | **P0** |
| `compatibility_analysis_service.dart` | `analyzeCompatibility()` | Inject _person1_chars/_person2_chars before sending to DB | **P0** |
| `compatibility_analysis_service.dart` | `_saveAnalysisResult()` | Store category_scores breakdown and detailed_analysis | **P0** |
| `system_prompt_builder.dart` | `_addCompatibilityAnalysisResult()` | Already expects data (no change needed) | - |

### Files That Do NOT Need Modification

| File | Reason |
|------|--------|
| `compatibility_data_loader.dart` | Only loads raw profiles - correctly leaves transformation to other layers |
| `system_prompt_builder.dart` | Already has parsing logic; just needs complete data |

---

## Implementation Roadmap

### Phase 1: Scoring Method Separation (CompatibilityCalculator)
**Goal**: Calculate individual category scores instead of one overall score

1. Extract `_calculateOhengScore()` from `_analyzeOheng()` logic
2. Extract `_calculateHapchungScore()` from `_analyzeHapchung()` logic
3. Extract `_calculateYongsinScore()` from `_analyzeYongsinCompat()` logic
4. Extract `_calculateSinsalScore()` from sinsal analysis
5. Extract `_calculateEnergyScore()` from energy distribution
6. Modify `_calculateScores()` to return all five categories
7. Modify `toJson()` to return complete `category_scores` map

**Files**: `compatibility_calculator.dart`

### Phase 2: Detailed Analysis Injection (CompatibilityCalculator)
**Goal**: Generate interpretations for each analysis type

1. Create `_generateOhengInterpretation(String type, String reason)` method
2. Create `_generateHapchungInterpretation(HapchungAnalysis hapchung)` method
3. Create `_generateYongsinInterpretation(int score, String myEffect, String targetEffect)` method
4. Build `detailed_analysis` Map in `toJson()`

**Files**: `compatibility_calculator.dart`

### Phase 3: Character Data Consolidation (CompatibilityAnalysisService)
**Goal**: Ensure both person character data is available in a unified format

1. Extract `_consolidateCharacterData(SajuAnalysis saju)` helper method
2. Inject `_person1_chars` and `_person2_chars` into result before saving
3. Verify all fields match SystemPromptBuilder expectations

**Files**: `compatibility_analysis_service.dart`

### Phase 4: Database Schema Verification
**Goal**: Ensure all new fields can be stored

1. Verify `category_scores` column supports JSON storage
2. Verify new fields don't exceed row size limits
3. Update any indexes if needed for performance

**Files**: Supabase migration (if needed)

---

## Testing Checkpoints

After implementation, verify:

1. **Category Scores Test**: Call analyzeCompatibility(), confirm `result.data['category_scores']` has all 5 keys with values 0-100
2. **Detailed Analysis Test**: Confirm `result.data['detailed_analysis']['oheng']['interpretation']` is populated with meaningful text
3. **Character Data Test**: Confirm `result.data['_person1_chars']['day_master_element']` matches calculated value
4. **DB Storage Test**: Query compatibility_analyses table, confirm category_scores and new fields persist
5. **Gemini Integration Test**: Run full chat flow, verify Gemini uses new data in responses (check prompt history)
6. **Backward Compatibility Test**: Verify existing saved analyses still load (handle missing fields gracefully)

---

## Notes

- All gaps are in the **calculation → storage → prompt** layer, NOT in the user-facing API
- SystemPromptBuilder already has parsing code; it just needs complete data
- No schema changes required; JSON columns can store new structure
- Changes are backward compatible if handled with null checks
- Priority: Gaps 1-3 are blocking detailed AI conversations; Gap 4 is nice-to-have

