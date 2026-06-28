import { type MetaFunction, useLoaderData } from "react-router";
import { cheongan, jiji } from "../chart/constants";
import { loadSadamProfile, type SadamProfileLoaderData } from "../data/route-loaders";
import {
  ElementDistribution,
  ErrorState,
  getArray,
  getRecord,
  getText,
  InfoCard,
  MetricRow,
  PageShell,
  PillarCard,
  SajuNavButtons,
  SimpleBadgeList,
} from "./saju-page-utils";

export const meta: MetaFunction = () => [{ title: "SaDam 사주 상세 분석" }];
export const loader = loadSadamProfile;

const pillarKeys = ["year", "month", "day", "hour"] as const;
const detailTabs = [
  { id: "manseryeok", label: "만세력" },
  { id: "oheng", label: "오행" },
  { id: "singang", label: "신강약" },
  { id: "daeun", label: "대운" },
  { id: "hapchung", label: "합충" },
  { id: "sipsung", label: "십성" },
  { id: "unsung", label: "12운성" },
  { id: "sinsal", label: "신살" },
  { id: "gongmang", label: "공망" },
];

function normalizeCycle(index: number, length: number) {
  return ((index % length) + length) % length;
}

function getYearGanji(year: number) {
  const index = normalizeCycle(year - 4, 60);
  return {
    gan: cheongan[index % 10],
    ji: jiji[index % 12],
  };
}

function getMonthGanji(year: number, month: number) {
  const yearGanIndex = normalizeCycle(year - 4, 10);
  const monthGanStartIndex = (yearGanIndex % 5) * 2;
  return {
    gan: cheongan[normalizeCycle(monthGanStartIndex + month - 1, 10)],
    ji: jiji[normalizeCycle(month + 1, 12)],
  };
}

function buildRecentSeunList(currentYear: number) {
  return Array.from({ length: 10 }, (_, index) => {
    const year = currentYear - index;
    return { year, ...getYearGanji(year) };
  });
}

function buildRecentWolunList(currentYear: number, currentMonth: number) {
  return Array.from({ length: 12 }, (_, index) => {
    const date = new Date(currentYear, currentMonth - 1 - index, 1);
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    return { year, month, ...getMonthGanji(year, month) };
  });
}

function incrementCount(counts: Record<string, number>, value: unknown) {
  if (typeof value !== "string" || value.length === 0 || value === "일간") return;
  counts[value] = (counts[value] ?? 0) + 1;
}

function buildSipsinCounts(
  sipsin: Record<string, unknown>,
  jijanggan: Record<string, unknown>,
) {
  const counts: Record<string, number> = {};

  for (const key of pillarKeys) {
    const row = getRecord(sipsin[key]);
    const gan = getRecord(row?.gan);
    const jiMain = getRecord(row?.ji_main);
    incrementCount(counts, gan?.sipsin);
    incrementCount(counts, jiMain?.sipsin);

    const jijangganRow = getRecord(jijanggan[key]);
    for (const stem of getArray(jijangganRow?.stems)) {
      incrementCount(counts, stem.sipsin);
    }
  }

  return Object.entries(counts)
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name));
}

function FortuneCard({
  title,
  subtitle,
  gan,
  ji,
  active = false,
}: {
  title: string;
  subtitle: string;
  gan: unknown;
  ji: unknown;
  active?: boolean;
}) {
  return (
    <div className={`min-w-24 rounded-md border p-3 text-center text-sm ${active ? "border-sky-300 bg-sky-50" : "border-slate-200 bg-slate-50"}`}>
      <p className="text-xs font-semibold text-slate-500">{title}</p>
      <p className="mt-1 text-[11px] text-slate-500">{subtitle}</p>
      <p className="mt-3 text-lg font-bold text-slate-950">{getText(gan)}{getText(ji)}</p>
    </div>
  );
}

export default function SajuDetailPage() {
  const data = useLoaderData() as SadamProfileLoaderData;
  if (data.error || !data.profile || !data.calculation) return <ErrorState data={data} />;

  const calculation = data.calculation;
  const analysis = data.analysis;
  const dayStrength = getRecord(analysis?.day_strength) ?? calculation.analysis.dayStrength;
  const yongsin = getRecord(analysis?.yongsin) ?? calculation.analysis.yongsin;
  const gyeokguk = getRecord(analysis?.gyeokguk) ?? calculation.analysis.gyeokguk;
  const hapchung = getRecord(analysis?.hapchung) ?? calculation.analysis.hapchung;
  const gilseong = getRecord(analysis?.gilseong) ?? calculation.analysis.gilseong;
  const daeun = getRecord(analysis?.daeun) ?? calculation.analysis.daeun;
  const currentSeun = getRecord(analysis?.current_seun) ?? calculation.analysis.currentSeun;
  const sipsin = getRecord(analysis?.sipsin_info) ?? calculation.analysis.sipsinInfo;
  const jijanggan = getRecord(analysis?.jijanggan_info) ?? calculation.analysis.jijangganInfo;
  const sinsalList = getArray(analysis?.sinsal_list ?? calculation.analysis.sinsalList);
  const twelveUnsung = getArray(analysis?.twelve_unsung ?? calculation.analysis.twelveUnsung);
  const twelveSinsal = getArray(analysis?.twelve_sinsal ?? calculation.analysis.twelveSinsal);
  const gongmang = getRecord(calculation.analysis.gongmang) ?? {};
  const gongmangResults = getArray(gongmang.results);
  const now = new Date();
  const currentYear = now.getFullYear();
  const currentMonth = now.getMonth() + 1;
  const seunList = buildRecentSeunList(currentYear);
  const wolunList = buildRecentWolunList(currentYear, currentMonth);
  const sipsinCounts = buildSipsinCounts(sipsin, jijanggan);

  return (
    <PageShell calculation={calculation} eyebrow="Saju Detail" title="사주 상세 분석">
      <nav className="sticky top-0 z-10 -mx-1 mt-5 overflow-x-auto rounded-lg border border-white/10 bg-slate-950/85 p-1 backdrop-blur">
        <div className="flex min-w-max gap-1">
          {detailTabs.map((tab) => (
            <a
              className="rounded-md px-3 py-2 text-sm font-semibold text-white/70 hover:bg-white/10 hover:text-white"
              href={`#${tab.id}`}
              key={tab.id}
            >
              {tab.label}
            </a>
          ))}
        </div>
      </nav>
      <div className="mt-5 space-y-3">
        <InfoCard id="manseryeok" title="만세력">
          <div className="grid grid-cols-4 gap-2">
            {calculation.hourPillar ? (
              <PillarCard label="시주" gan={calculation.hourPillar.gan} ji={calculation.hourPillar.ji} />
            ) : (
              <div className="rounded-lg border border-dashed border-slate-300 bg-slate-50 p-3 text-center text-sm text-slate-500">
                시주 없음
              </div>
            )}
            <PillarCard isDayMaster label="일주" gan={calculation.dayPillar.gan} ji={calculation.dayPillar.ji} />
            <PillarCard label="월주" gan={calculation.monthPillar.gan} ji={calculation.monthPillar.ji} />
            <PillarCard label="연주" gan={calculation.yearPillar.gan} ji={calculation.yearPillar.ji} />
          </div>
        </InfoCard>

        <div id="oheng" className="scroll-mt-28">
          <ElementDistribution distribution={analysis?.oheng_distribution ?? calculation.analysis.ohengDistribution} />
        </div>

        <InfoCard id="singang" title="신강약과 용신">
          <MetricRow label="점수" value={`${getText(dayStrength.score, "50")}점`} />
          <MetricRow label="단계" value={getText(dayStrength.level)} />
          <MetricRow label="득령" value={getText(dayStrength.deukryeong)} />
          <MetricRow label="득지" value={getText(dayStrength.deukji)} />
          <MetricRow label="득시" value={getText(dayStrength.deuksi)} />
          <MetricRow label="득세" value={getText(dayStrength.deukse)} />
          <div className="mt-4 rounded-md bg-slate-50 p-3">
            <MetricRow label="용신" value={getText(yongsin.yongsin)} />
            <MetricRow label="희신" value={getText(yongsin.heesin ?? yongsin.huisin)} />
            <MetricRow label="기신" value={getText(yongsin.gisin)} />
            <MetricRow label="구신" value={getText(yongsin.gusin)} />
          </div>
        </InfoCard>

        <InfoCard id="daeun" title="대운과 세운">
          <MetricRow label="대운 방향" value={daeun.is_forward ? "순행" : "역행"} />
          <MetricRow label="대운 시작" value={`${getText(daeun.start_age)}세`} />
          <MetricRow label="현재 세운" value={`${getText(currentSeun.year)}년 ${getText(currentSeun.gan)}${getText(currentSeun.ji)}`} />
          <div className="mt-4 space-y-4">
            <div>
              <p className="text-xs font-bold text-slate-500">대운</p>
              <div className="mt-2 flex gap-2 overflow-x-auto pb-1">
                {getArray(daeun.daeun_list).map((item) => (
                  <FortuneCard
                    gan={item.gan}
                    ji={item.ji}
                    key={`${item.order}-${item.gan}-${item.ji}`}
                    subtitle={`${getText(item.start_age)}-${getText(item.end_age)}세`}
                    title={`${getText(item.order)}대운`}
                  />
                ))}
              </div>
            </div>
            <div>
              <p className="text-xs font-bold text-slate-500">최근 10년 세운</p>
              <div className="mt-2 flex gap-2 overflow-x-auto pb-1">
                {seunList.map((item) => (
                  <FortuneCard
                    active={item.year === currentYear}
                    gan={item.gan}
                    ji={item.ji}
                    key={item.year}
                    subtitle="세운"
                    title={`${item.year}년`}
                  />
                ))}
              </div>
            </div>
            <div>
              <p className="text-xs font-bold text-slate-500">최근 12개월 월운</p>
              <div className="mt-2 flex gap-2 overflow-x-auto pb-1">
                {wolunList.map((item) => (
                  <FortuneCard
                    active={item.year === currentYear && item.month === currentMonth}
                    gan={item.gan}
                    ji={item.ji}
                    key={`${item.year}-${item.month}`}
                    subtitle={`${item.year}`}
                    title={`${item.month}월`}
                  />
                ))}
              </div>
            </div>
          </div>
        </InfoCard>

        <InfoCard id="hapchung" title="합충">
          <MetricRow label="육합" value={`${getArray(hapchung.jijiYukhaps).length}개`} />
          <MetricRow label="충" value={`${getArray(hapchung.jijiChungs).length}개`} />
          <SimpleBadgeList
            values={[
              ...getArray(hapchung.jijiYukhaps).map((item) => `육합 ${getText(item.pair)}`),
              ...getArray(hapchung.jijiChungs).map((item) => `충 ${getText(item.pair)}`),
            ]}
          />
        </InfoCard>

        <InfoCard id="sipsung" title="십성">
          <MetricRow label="격국" value={getText(gyeokguk.name)} />
          <MetricRow label="월지 정기" value={getText(gyeokguk.month_main_gan)} />
          <MetricRow label="기준 십성" value={getText(gyeokguk.sipsin)} />
          <div className="mt-3 rounded-md bg-slate-50 p-3">
            <p className="text-xs font-bold text-slate-500">십성 분포</p>
            <div className="mt-2 grid grid-cols-2 gap-2">
              {sipsinCounts.map((item) => (
                <div className="flex items-center justify-between rounded-md bg-white px-3 py-2 text-sm" key={item.name}>
                  <span className="font-semibold text-slate-700">{item.name}</span>
                  <span className="text-slate-500">{item.count}개</span>
                </div>
              ))}
            </div>
          </div>
          <div className="mt-3 space-y-2">
            {pillarKeys.map((key) => {
              const row = getRecord(sipsin[key]);
              if (!row) return null;
              const gan = getRecord(row.gan);
              const jiMain = getRecord(row.ji_main);
              return (
                <div className="rounded-md bg-slate-50 p-3 text-sm" key={key}>
                  <p className="font-bold">{getText(row.pillar)}</p>
                  <p className="text-slate-600">천간: {getText(gan?.value)} · {getText(gan?.sipsin)}</p>
                  <p className="text-slate-600">지지 정기: {getText(jiMain?.value)} · {getText(jiMain?.sipsin)}</p>
                </div>
              );
            })}
          </div>
        </InfoCard>

        <InfoCard id="unsung" title="12운성">
          <div className="grid grid-cols-2 gap-2">
            {twelveUnsung.map((item) => (
              <div className="rounded-md bg-slate-50 p-3 text-sm" key={`${item.pillar}-${item.name}`}>
                <p className="font-bold">{getText(item.pillar_name)} · {getText(item.name)}</p>
                <p className="text-slate-500">강도 {getText(item.strength)} · {getText(item.fortune_type)}</p>
              </div>
            ))}
          </div>
        </InfoCard>

        <InfoCard id="sinsal" title="신살과 길성">
          <MetricRow label="길성" value={`${getText(gilseong.total_good_count, "0")}개`} />
          <MetricRow label="흉성" value={`${getText(gilseong.total_bad_count, "0")}개`} />
          <MetricRow label="원진" value={`${getText(gilseong.wonjinsal_count, "0")}개`} />
          <SimpleBadgeList values={sinsalList.map((item) => `${getText(item.name)} ${getText(item.pillar_name)}`)} />
        </InfoCard>

        <InfoCard title="12신살">
          <div className="grid gap-2">
            {twelveSinsal.map((item) => {
              const yearBased = getRecord(item.year_based);
              const dayBased = getRecord(item.day_based);
              return (
                <div className="rounded-md bg-slate-50 p-3 text-sm" key={`${item.pillar}-${item.jiji}`}>
                  <p className="font-bold">{getText(item.pillar_name)} · {getText(item.jiji)}</p>
                  <p className="text-slate-600">연지 기준: {getText(yearBased?.name)}</p>
                  <p className="text-slate-600">일지 기준: {getText(dayBased?.name)}</p>
                </div>
              );
            })}
          </div>
        </InfoCard>

        <InfoCard title="지장간">
          <div className="space-y-2">
            {pillarKeys.map((key) => {
              const row = getRecord(jijanggan[key]);
              if (!row) return null;
              const stems = getArray(row.stems);
              return (
                <div className="rounded-md bg-slate-50 p-3 text-sm" key={key}>
                  <p className="font-bold">{getText(row.pillar)} · {getText(row.jiji)}</p>
                  <SimpleBadgeList values={stems.map((stem) => `${getText(stem.type)} ${getText(stem.gan)} ${getText(stem.sipsin)}`)} />
                </div>
              );
            })}
          </div>
        </InfoCard>

        <InfoCard id="gongmang" title="공망">
          <MetricRow label="일주" value={getText(gongmang.day_gapja)} />
          <MetricRow label="공망 지지" value={getArray(gongmang.gongmang_jijis).map((item) => getText(item)).join(", ")} />
          <MetricRow label="공망 궁성" value={`${getText(gongmang.gongmang_count, "0")}개`} />
          <p className="mt-3 text-sm leading-6 text-slate-600">{getText(gongmang.summary)}</p>
          <div className="mt-3 grid gap-2">
            {gongmangResults.map((item) => (
              <div
                className={`rounded-md p-3 text-sm ${item.is_gongmang ? "bg-rose-50 text-rose-700" : "bg-slate-50 text-slate-600"}`}
                key={`${item.pillar}-${item.jiji}`}
              >
                <p className="font-bold">{getText(item.pillar_name)} · {getText(item.jiji)}</p>
                <p>{item.is_gongmang ? "공망" : "정상"} · {getText(item.interpretation)}</p>
              </div>
            ))}
          </div>
        </InfoCard>
      </div>
      <SajuNavButtons query={data.query} />
    </PageShell>
  );
}
