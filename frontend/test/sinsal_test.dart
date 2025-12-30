// 신살 계산 검증 테스트
// 박재현: 1997.11.29 08:03, 부산광역시, 남자
// 실행: dart test/sinsal_test.dart

import '../lib/features/saju_chart/data/constants/cheongan_jiji.dart';
import '../lib/features/saju_chart/data/constants/twelve_sinsal.dart';
import '../lib/features/saju_chart/domain/services/gilseong_service.dart';

void main() {
  print('=' * 60);
  print('🔍 박재현 사주 신살 검증 테스트');
  print('=' * 60);
  print('');

  // === 사주 계산 ===
  // 1997년 11월 29일 08시 03분, 부산

  // 년주 계산 (입춘 전이면 전년도, 11월이므로 그대로)
  final year = 1997;
  final yearGanIndex = (year - 4) % 10; // 3 = 정
  final yearJiIndex = (year - 4) % 12;  // 1 = 축
  final yearGan = cheongan[yearGanIndex];
  final yearJi = jiji[yearJiIndex];
  print('📅 년주: $yearGan$yearJi (${yearGan}${yearJi})');

  // 월주 계산 (11월은 해월(亥月), 10월 입동 ~ 11월 대설 사이)
  // 11/29는 대설(12/7) 전이므로 해월(亥月)
  // 정년(丁年) → 신해월 시작 (정임년은 경자시 시작이므로 월간은 ((년간 % 5) * 2 + 2) % 10)
  // 정(丁) = index 3, (3 % 5) * 2 + 2 = 8 = 임
  // 해월(亥月) = 10월(인월부터 0시작하면 9)
  // 월간 = (8 + 9) % 10 = 7 = 신
  final monthGan = '신'; // 辛
  final monthJi = '해';  // 亥
  print('📅 월주: $monthGan$monthJi (${monthGan}${monthJi})');

  // 일주 계산
  // 기준: 1900.1.1 = 계사일 (baseDayIndex = 10)
  final baseDate = DateTime(1900, 1, 1);
  final birthDate = DateTime(1997, 11, 29);
  final daysDiff = birthDate.difference(baseDate).inDays;
  print('📊 1900.1.1부터 일수: $daysDiff일');

  const baseDayIndex = 10;
  int dayIndex = (baseDayIndex + daysDiff) % 60;
  if (dayIndex < 0) dayIndex += 60;
  final dayGanIndex = dayIndex % 10;
  final dayJiIndex = dayIndex % 12;
  final dayGan = cheongan[dayGanIndex];
  final dayJi = jiji[dayJiIndex];
  print('📅 일주: $dayGan$dayJi (60갑자 index: $dayIndex, 간: $dayGanIndex, 지: $dayJiIndex)');

  // 시주 계산 (08:03 → 진시)
  // 진시: 07:00-09:00 (index 3)
  final hour = 8;
  final hourJiIndex = ((hour + 1) ~/ 2) % 12; // 4 = 진
  // 을일(乙) → index 1, (1 % 5) * 2 = 2 = 병
  // 시간 = (2 + 4) % 10 = 6 = 경
  final hourGanStart = (dayGanIndex % 5) * 2;
  final hourGanIndex = (hourGanStart + hourJiIndex) % 10;
  final hourGan = cheongan[hourGanIndex];
  final hourJi = jiji[hourJiIndex];
  print('📅 시주: $hourGan$hourJi (${hourGan}${hourJi})');

  print('');
  print('=' * 60);
  print('📋 사주팔자 요약');
  print('=' * 60);
  print('  시주  일주  월주  년주');
  print('  $hourGan    $dayGan    $monthGan    $yearGan   (천간)');
  print('  $hourJi    $dayJi    $monthJi    $yearJi   (지지)');
  print('');

  // === 신살 분석 ===
  print('=' * 60);
  print('🔮 Phase 23 신살 검증');
  print('=' * 60);
  print('');

  // GilseongService로 전체 분석
  final result = GilseongService.analyze(
    yearGan: yearGan,
    yearJi: yearJi,
    monthGan: monthGan,
    monthJi: monthJi,
    dayGan: dayGan,
    dayJi: dayJi,
    hourGan: hourGan,
    hourJi: hourJi,
  );

  print('✅ 발견된 신살 (전체):');
  for (final sinsal in result.allUniqueSinsals) {
    print('  - ${sinsal.korean} (${sinsal.hanja}): ${sinsal.meaning}');
  }
  print('');

  print('📊 기둥별 신살:');
  print('  년주($yearGan$yearJi): ${result.yearResult.sinsals.map((s) => s.korean).join(", ")}');
  print('  월주($monthGan$monthJi): ${result.monthResult.sinsals.map((s) => s.korean).join(", ")}');
  print('  일주($dayGan$dayJi): ${result.dayResult.sinsals.map((s) => s.korean).join(", ")}');
  print('  시주($hourGan$hourJi): ${result.hourResult?.sinsals.map((s) => s.korean).join(", ") ?? "-"}');
  print('');

  // === Phase 23 추가 신살 개별 검증 ===
  print('=' * 60);
  print('🔬 Phase 23 추가 신살 개별 검증');
  print('=' * 60);
  print('');

  // 1. 금여 (일간 → 지지)
  print('1️⃣ 금여 (金輿)');
  final geumYeoJi = getGeumYeoJi(dayGan);
  print('   일간 $dayGan의 금여 지지: $geumYeoJi');
  print('   사주 지지들: $yearJi, $monthJi, $dayJi, $hourJi');
  print('   결과: ${[yearJi, monthJi, dayJi, hourJi].any((ji) => isGeumYeo(dayGan, ji)) ? "✅ 있음" : "❌ 없음"}');
  print('');

  // 2. 삼기귀인 (천간 조합)
  print('2️⃣ 삼기귀인 (三奇貴人)');
  final samgi = checkSamgiGwiin(
    yearGan: yearGan,
    monthGan: monthGan,
    dayGan: dayGan,
    hourGan: hourGan,
  );
  print('   천간: $yearGan-$monthGan-$dayGan-$hourGan');
  print('   결과: ${samgi.hasSamgi ? "✅ ${samgi.type?.korean} (${samgi.location})" : "❌ 없음"}');
  print('');

  // 3. 복성귀인 일주
  print('3️⃣ 복성귀인 (福星貴人) - 일주');
  print('   일주: $dayGan$dayJi');
  print('   복성귀인 일주 목록: ${bokseongGwiinIlju.join(", ")}');
  print('   결과: ${isBokseongGwiinIlju(dayGan, dayJi) ? "✅ 해당" : "❌ 해당 안됨"}');
  print('');

  // 4. 복성귀인 천간 (연간 → 식신)
  print('4️⃣ 복성귀인 (福星貴人) - 천간');
  final bokseongShikshin = bokseongGwiinGanTable[yearGan];
  print('   연간 $yearGan의 식신: $bokseongShikshin');
  print('   사주 천간들: $monthGan, $dayGan, $hourGan');
  final hasBokseong = isBokseongGwiinGan(yearGan, monthGan) ||
      isBokseongGwiinGan(yearGan, dayGan) ||
      isBokseongGwiinGan(yearGan, hourGan);
  print('   결과: ${hasBokseong ? "✅ 있음" : "❌ 없음"}');
  print('');

  // 5. 낙정관살 (일간 → 지지)
  print('5️⃣ 낙정관살 (落井關殺)');
  final nakjeongJi = getNakjeongGwansalJi(dayGan);
  print('   일간 $dayGan의 낙정관살 지지: $nakjeongJi');
  print('   결과: ${[yearJi, monthJi, dayJi, hourJi].any((ji) => isNakjeongGwansal(dayGan, ji)) ? "✅ 있음" : "❌ 없음"}');
  print('   낙정관살 일주 여부: ${isNakjeongGwansalIlju(dayGan, dayJi) ? "✅ 강력" : "❌ 일반"}');
  print('');

  // 6. 문곡귀인 (일간 → 지지)
  print('6️⃣ 문곡귀인 (文曲貴人)');
  final mungokJi = getMungokGwiinJi(dayGan);
  print('   일간 $dayGan의 문곡 지지: $mungokJi');
  print('   결과: ${[yearJi, monthJi, dayJi, hourJi].any((ji) => isMungokGwiin(dayGan, ji)) ? "✅ 있음" : "❌ 없음"}');
  print('');

  // 7. 태극귀인 (일간 → 지지)
  print('7️⃣ 태극귀인 (太極貴人)');
  final taegukJis = getTaegukGwiinJis(dayGan);
  print('   일간 $dayGan의 태극 지지: ${taegukJis.join(", ")}');
  for (final ji in [yearJi, monthJi, dayJi, hourJi]) {
    if (isTaegukGwiin(dayGan, ji)) {
      print('   → $ji에서 태극귀인 발견! ✅');
    }
  }
  print('');

  // 8. 천의귀인 (월지 → 지지)
  print('8️⃣ 천의귀인 (天醫貴人)');
  final cheonuiJi = getCheonuiGwiinJi(monthJi);
  print('   월지 $monthJi의 천의 지지: $cheonuiJi');
  print('   결과: ${[yearJi, dayJi, hourJi].any((ji) => isCheonuiGwiin(monthJi, ji)) ? "✅ 있음" : "❌ 없음"}');
  print('');

  // 9. 천주귀인 (일간 → 지지)
  print('9️⃣ 천주귀인 (天廚貴人)');
  final cheonjuJi = getCheonjuGwiinJi(dayGan);
  print('   일간 $dayGan의 천주 지지: $cheonjuJi');
  print('   결과: ${[yearJi, monthJi, dayJi, hourJi].any((ji) => isCheonjuGwiin(dayGan, ji)) ? "✅ 있음" : "❌ 없음"}');
  print('');

  // 10. 암록귀인 (일간 → 지지)
  print('🔟 암록귀인 (暗祿貴人)');
  final amnokJi = getAmnokGwiinJi(dayGan);
  print('   일간 $dayGan의 암록 지지: $amnokJi');
  print('   결과: ${[yearJi, monthJi, dayJi, hourJi].any((ji) => isAmnokGwiin(dayGan, ji)) ? "✅ 있음" : "❌ 없음"}');
  print('');

  // 11. 홍란살 (년지 → 지지)
  print('1️⃣1️⃣ 홍란살 (紅鸞煞)');
  final hongranJi = getHongranSalJi(yearJi);
  print('   년지 $yearJi의 홍란 지지: $hongranJi');
  print('   결과: ${[monthJi, dayJi, hourJi].any((ji) => isHongranSal(yearJi, ji)) ? "✅ 있음" : "❌ 없음"}');
  print('');

  // 12. 천희살 (년지 → 지지)
  print('1️⃣2️⃣ 천희살 (天喜煞)');
  final cheonheeJi = getCheonheeSalJi(yearJi);
  print('   년지 $yearJi의 천희 지지: $cheonheeJi');
  print('   결과: ${[monthJi, dayJi, hourJi].any((ji) => isCheonheeSal(yearJi, ji)) ? "✅ 있음" : "❌ 없음"}');
  print('');

  // === 기존 신살도 확인 ===
  print('=' * 60);
  print('📌 기존 주요 신살 확인');
  print('=' * 60);
  print('');

  // 천을귀인
  print('• 천을귀인: ${getCheonEulGwinJi(dayGan).join(", ")}');
  for (final ji in [yearJi, monthJi, dayJi, hourJi]) {
    if (isCheonEulGwin(dayGan, ji)) {
      print('  → $ji에서 천을귀인 발견! ✅');
    }
  }

  // 양인살
  print('• 양인살: ${getYangInJi(dayGan)}');
  for (final ji in [yearJi, monthJi, dayJi, hourJi]) {
    if (isYangIn(dayGan, ji)) {
      print('  → $ji에서 양인살 발견! ⚠️');
    }
  }

  // 괴강살
  print('• 괴강살 일주 여부: ${isGoeGang(dayGan, dayJi) ? "✅ 해당" : "❌ 해당 안됨"}');

  // 귀문관살
  final allJis = [yearJi, monthJi, dayJi, hourJi];
  print('• 귀문관살 (인신사해 2개 이상): ${isGwiMunGwanSal(allJis) ? "⚠️ 해당" : "❌ 해당 안됨"}');
  final gwimunCount = allJis.where((ji) => gwiMunGwanSalJis.contains(ji)).length;
  print('  → 인신사해 개수: $gwimunCount개 (${allJis.where((ji) => gwiMunGwanSalJis.contains(ji)).join(", ")})');

  print('');

  // === Phase 24 추가 신살 검증 ===
  print('=' * 60);
  print('🆕 Phase 24 추가 신살 검증');
  print('=' * 60);
  print('');

  // 건록
  print('1️⃣ 건록 (健祿)');
  final geonrokJi = getGeonrokJi(dayGan);
  print('   일간 $dayGan의 건록 지지: $geonrokJi');
  for (final ji in [yearJi, monthJi, dayJi, hourJi]) {
    if (isGeonrok(dayGan, ji)) {
      print('   → $ji에서 건록 발견! ✅');
    }
  }
  print('');

  // 비인살
  print('2️⃣ 비인살 (飛刃殺)');
  final biinsalJi = getBiinsalJi(dayGan);
  print('   일간 $dayGan의 비인살 지지: $biinsalJi (양인 충)');
  for (final ji in [yearJi, monthJi, dayJi, hourJi]) {
    if (isBiinsal(dayGan, ji)) {
      print('   → $ji에서 비인살 발견! ⚠️');
    }
  }
  print('');

  // 효신살
  print('3️⃣ 효신살 (梟神殺)');
  print('   일주: $dayGan$dayJi');
  print('   효신살 일주 목록: ${hyosinsalIlju.join(", ")}');
  print('   결과: ${isHyosinsal(dayGan, dayJi) ? "✅ 해당" : "❌ 해당 안됨"}');
  print('');

  // 고신살 (남자)
  print('4️⃣ 고신살 (孤神殺) - 남자');
  final gosinsalJi = getGosinsalJi(yearJi);
  print('   년지 $yearJi의 고신살 지지: $gosinsalJi');
  final hasGosin = isGosinsal(yearJi, monthJi) ||
      isGosinsal(yearJi, dayJi) ||
      isGosinsal(yearJi, hourJi);
  print('   결과: ${hasGosin ? "⚠️ 있음" : "❌ 없음"}');
  print('');

  // 과숙살 (여자)
  print('5️⃣ 과숙살 (寡宿殺) - 여자');
  final gwasuksalJi = getGwasuksalJi(yearJi);
  print('   년지 $yearJi의 과숙살 지지: $gwasuksalJi');
  final hasGwasuk = isGwasuksal(yearJi, monthJi) ||
      isGwasuksal(yearJi, dayJi) ||
      isGwasuksal(yearJi, hourJi);
  print('   결과: ${hasGwasuk ? "⚠️ 있음" : "❌ 없음"}');
  print('');

  // 원진살
  print('6️⃣ 원진살 (怨嗔殺)');
  final wonJinCount = countWonJinsal(allJis);
  print('   사주 지지: ${allJis.join(", ")}');
  print('   원진 관계: 자-미, 축-오, 인-유, 묘-신, 진-해, 사-술');
  print('   결과: ${wonJinCount > 0 ? "⚠️ $wonJinCount개 발견" : "❌ 없음"}');
  print('');

  // 천라지망
  print('7️⃣ 천라지망 (天羅地網)');
  final hasCheollaJimangResult = hasCheollaJimang(allJis);
  print('   사주에 진(辰)과 술(戌) 동시 존재 여부');
  print('   결과: ${hasCheollaJimangResult ? "⚠️ 있음 (진술 충)" : "❌ 없음"}');
  print('');

  // 전체 결과 요약
  print('=' * 60);
  print('📊 GilseongService 전체 분석 결과');
  print('=' * 60);
  print('');
  print('📈 통계:');
  print('  - 길성 개수: ${result.totalGoodCount}');
  print('  - 흉성 개수: ${result.totalBadCount}');
  print('  - 전체 신살: ${result.totalSinsalCount}개');
  print('');
  print('🔖 Phase 24 추가 필드:');
  print('  - 효신살: ${result.hasHyosinsal ? "✅" : "❌"}');
  print('  - 고신살: ${result.hasGosinsal ? "⚠️" : "❌"}');
  print('  - 과숙살: ${result.hasGwasuksal ? "⚠️" : "❌"}');
  print('  - 천라지망: ${result.hasCheollaJimang ? "⚠️" : "❌"}');
  print('  - 원진살 개수: ${result.wonJinsalCount}');
  print('');
  print('=' * 60);
  print('✅ 테스트 완료');
  print('=' * 60);
}
