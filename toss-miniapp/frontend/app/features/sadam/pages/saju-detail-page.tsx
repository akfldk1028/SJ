import { type MetaFunction, useLoaderData } from "react-router";
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

  return (
    <PageShell calculation={calculation} eyebrow="Saju Detail" title="사주 상세 분석">
      <div className="mt-5 space-y-3">
        <InfoCard title="만세력">
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

        <ElementDistribution distribution={analysis?.oheng_distribution ?? calculation.analysis.ohengDistribution} />

        <InfoCard title="신강약과 용신">
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

        <InfoCard title="대운과 세운">
          <MetricRow label="대운 방향" value={daeun.is_forward ? "순행" : "역행"} />
          <MetricRow label="대운 시작" value={`${getText(daeun.start_age)}세`} />
          <MetricRow label="현재 세운" value={`${getText(currentSeun.year)}년 ${getText(currentSeun.gan)}${getText(currentSeun.ji)}`} />
          <div className="mt-3 grid grid-cols-2 gap-2">
            {getArray(daeun.daeun_list).slice(0, 6).map((item) => (
              <div className="rounded-md bg-slate-50 p-3 text-sm" key={`${item.order}-${item.gan}-${item.ji}`}>
                <p className="font-bold">{getText(item.gan)}{getText(item.ji)}</p>
                <p className="text-slate-500">{getText(item.start_age)}-{getText(item.end_age)}세</p>
              </div>
            ))}
          </div>
        </InfoCard>

        <InfoCard title="합충">
          <MetricRow label="육합" value={`${getArray(hapchung.jijiYukhaps).length}개`} />
          <MetricRow label="충" value={`${getArray(hapchung.jijiChungs).length}개`} />
          <SimpleBadgeList
            values={[
              ...getArray(hapchung.jijiYukhaps).map((item) => `육합 ${getText(item.pair)}`),
              ...getArray(hapchung.jijiChungs).map((item) => `충 ${getText(item.pair)}`),
            ]}
          />
        </InfoCard>

        <InfoCard title="십성">
          <MetricRow label="격국" value={getText(gyeokguk.name)} />
          <MetricRow label="월지 정기" value={getText(gyeokguk.month_main_gan)} />
          <MetricRow label="기준 십성" value={getText(gyeokguk.sipsin)} />
          <div className="mt-3 space-y-2">
            {["year", "month", "day", "hour"].map((key) => {
              const row = getRecord(sipsin[key]);
              if (!row) return null;
              const gan = getRecord(row.gan);
              const jiMain = getRecord(row.ji_main);
              return (
                <div className="rounded-md bg-slate-50 p-3 text-sm" key={key}>
                  <p className="font-bold">{getText(row.pillar)}</p>
                  <p className="text-slate-600">천간: {getText(gan?.value)} · {getText(gan?.sipsin)}</p>
                  <p className="text-slate-600">지장간 정기: {getText(jiMain?.value)} · {getText(jiMain?.sipsin)}</p>
                </div>
              );
            })}
          </div>
        </InfoCard>

        <InfoCard title="12운성">
          <div className="grid grid-cols-2 gap-2">
            {twelveUnsung.map((item) => (
              <div className="rounded-md bg-slate-50 p-3 text-sm" key={`${item.pillar}-${item.name}`}>
                <p className="font-bold">{getText(item.pillar_name)} · {getText(item.name)}</p>
                <p className="text-slate-500">강도 {getText(item.strength)} · {getText(item.fortune_type)}</p>
              </div>
            ))}
          </div>
        </InfoCard>

        <InfoCard title="신살과 길성">
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
            {["year", "month", "day", "hour"].map((key) => {
              const row = getRecord(jijanggan[key]);
              const stems = getArray(row?.stems);
              if (!row) return null;
              return (
                <div className="rounded-md bg-slate-50 p-3 text-sm" key={key}>
                  <p className="font-bold">{getText(row.pillar)} · {getText(row.jiji)}</p>
                  <SimpleBadgeList values={stems.map((stem) => `${getText(stem.type)} ${getText(stem.gan)} ${getText(stem.sipsin)}`)} />
                </div>
              );
            })}
          </div>
        </InfoCard>

        <InfoCard title="공망">
          <p className="text-sm leading-6 text-slate-600">
            Flutter에는 별도 공망 탭이 있습니다. Toss 분석 저장 payload에는 아직 공망 전용 필드가 없으므로 다음 계산 루프에서
            `gongmang` 필드를 추가해 이 섹션에 연결합니다.
          </p>
        </InfoCard>
      </div>
      <SajuNavButtons query={data.query} />
    </PageShell>
  );
}
