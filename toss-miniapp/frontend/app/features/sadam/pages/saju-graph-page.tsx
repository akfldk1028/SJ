import { type MetaFunction, useLoaderData } from "react-router";
import { loadSadamProfile, type SadamProfileLoaderData } from "../data/route-loaders";
import { cheonganOheng, jijiOheng, ohengKorean, type OhengKey } from "../chart/constants";
import type { SajuResolveResult } from "../saju-calculation";
import {
  ErrorState,
  ohengStyle,
  PageShell,
  SajuNavButtons,
} from "./saju-page-utils";

export const meta: MetaFunction = () => [{ title: "SaDam 사주 관계 그래프" }];
export const loader = loadSadamProfile;

type NodeSpec = {
  id: string;
  label: string;
  sublabel: string;
  x: number;
  y: number;
  element: OhengKey;
};

export default function SajuGraphPage() {
  const data = useLoaderData() as SadamProfileLoaderData;
  if (data.error || !data.profile || !data.calculation) return <ErrorState data={data} />;

  const nodes = buildGraphNodes(data.calculation);
  const root = nodes.find((node) => node.id === "root")!;

  return (
    <PageShell calculation={data.calculation} eyebrow="Saju Graph" title="사주 관계 그래프">
      <section className="mt-5 rounded-lg border border-white/10 bg-white p-4 text-slate-950">
        <div className="mb-4 text-center">
          <p className="text-lg font-bold">{data.profile.display_name}</p>
          <p className="text-sm text-slate-500">일간을 중심으로 네 기둥의 천간/지지를 펼쳐 봅니다.</p>
        </div>
        <div className="overflow-x-auto">
          <svg className="h-[520px] min-w-[520px]" viewBox="0 0 520 520" role="img" aria-label="사주 관계 그래프">
            {nodes.filter((node) => node.id !== "root").map((node) => (
              <line
                key={`${root.id}-${node.id}`}
                stroke="#cbd5e1"
                strokeWidth="2"
                x1={root.x}
                x2={node.x}
                y1={root.y + 28}
                y2={node.y - 28}
              />
            ))}
            {nodes.map((node) => (
              <GraphNode key={node.id} node={node} />
            ))}
          </svg>
        </div>
        <div className="mt-3 grid grid-cols-5 gap-2">
          {(["wood", "fire", "earth", "metal", "water"] as OhengKey[]).map((key) => (
            <div className="rounded-md bg-slate-100 p-2 text-center text-xs" key={key}>
              <span className={`mx-auto mb-1 block size-3 rounded-full ${ohengStyle[key].bg}`} />
              {ohengKorean[key]}
            </div>
          ))}
        </div>
      </section>
      <SajuNavButtons query={data.query} />
    </PageShell>
  );
}

function GraphNode({ node }: { node: NodeSpec }) {
  const style = ohengStyle[node.element];
  return (
    <g transform={`translate(${node.x - 46} ${node.y - 30})`}>
      <rect className={`${style.bg}`} height="60" rx="8" width="92" />
      <text fill="white" fontSize="14" fontWeight="700" textAnchor="middle" x="46" y="25">
        {node.label}
      </text>
      <text fill="white" fontSize="11" opacity="0.86" textAnchor="middle" x="46" y="43">
        {node.sublabel}
      </text>
    </g>
  );
}

function buildGraphNodes(calculation: SajuResolveResult): NodeSpec[] {
  const pillars = [
    ["연주", calculation.yearPillar],
    ["월주", calculation.monthPillar],
    ["일주", calculation.dayPillar],
    ["시주", calculation.hourPillar],
  ] as const;
  const nodes: NodeSpec[] = [
    {
      id: "root",
      label: "나",
      sublabel: `${calculation.dayPillar.gan} 일간`,
      x: 260,
      y: 60,
      element: cheonganOheng[calculation.dayPillar.gan] ?? "earth",
    },
  ];

  pillars.forEach(([label, pillar], index) => {
    if (!pillar) return;
    const x = 80 + index * 120;
    nodes.push({
      id: `${label}-pillar`,
      label,
      sublabel: `${pillar.gan}${pillar.ji}`,
      x,
      y: 190,
      element: cheonganOheng[pillar.gan] ?? "earth",
    });
    nodes.push({
      id: `${label}-gan`,
      label: pillar.gan,
      sublabel: "천간",
      x,
      y: 330,
      element: cheonganOheng[pillar.gan] ?? "earth",
    });
    nodes.push({
      id: `${label}-ji`,
      label: pillar.ji,
      sublabel: "지지",
      x,
      y: 440,
      element: jijiOheng[pillar.ji] ?? "earth",
    });
  });

  return nodes;
}
