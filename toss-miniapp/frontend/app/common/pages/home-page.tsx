import type { MetaFunction } from "react-router";
import {
  AlertTriangleIcon,
  CheckCircle2Icon,
  ClipboardCheckIcon,
  FileSearchIcon,
  LayoutTemplateIcon,
  MegaphoneIcon,
  ShieldCheckIcon,
  SparklesIcon,
} from "lucide-react";
import { Badge } from "../components/ui/badge";
import { Button } from "../components/ui/button";

export const meta: MetaFunction = () => {
  return [
    { title: "SaDam Launch Desk" },
    {
      name: "description",
      content: "AI workspace for app policy, copy, design, and submission checks.",
    },
  ];
};

const platforms = ["App Store", "Google Play", "Apps in Toss"];

const agentChecks = [
  {
    icon: ShieldCheckIcon,
    label: "Policy",
    title: "법규/정책 검토",
    status: "위험 표현 3개 탐지",
    detail: "fortune, horoscope, divination 표현은 iOS 심사에서 제거 권장",
  },
  {
    icon: FileSearchIcon,
    label: "Market",
    title: "시장/경쟁 분석",
    status: "AI companion 포지션 권장",
    detail: "사주 엔진은 내부 로직으로 두고, 제품 설명은 성격 코칭 중심",
  },
  {
    icon: MegaphoneIcon,
    label: "Copy",
    title: "브랜드/카피 설계",
    status: "심사용 문구 준비",
    detail: "미래 예측이 아닌 자기 이해와 대화형 저널링으로 설명",
  },
  {
    icon: LayoutTemplateIcon,
    label: "Design",
    title: "디자인/스크린샷",
    status: "첫 3장 재배치 필요",
    detail: "캐릭터 선택, AI 대화, 성격 카드 순서가 가장 안전",
  },
  {
    icon: ClipboardCheckIcon,
    label: "Submit",
    title: "제출 체크리스트",
    status: "개인정보/광고/IAP 확인",
    detail: "App Privacy, 광고 ID, 인앱 상품, 심사 메모 누락 여부 점검",
  },
];

const deliverables = [
  "스토어 설명 초안",
  "심사 메모",
  "스크린샷 문구",
  "개인정보 라벨",
  "거절 대응 답변",
];

export default function HomePage() {
  return (
    <main className="min-h-screen bg-slate-50 text-slate-950">
      <div className="mx-auto flex min-h-screen w-full max-w-md flex-col">
        <header className="border-b border-slate-200 bg-white px-5 py-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold uppercase text-slate-500">
                SaDam Launch Desk
              </p>
              <h1 className="text-xl font-bold tracking-normal">
                앱 출시 준비 점검
              </h1>
            </div>
            <Badge className="rounded-md bg-blue-600 text-white">Beta</Badge>
          </div>
        </header>

        <section className="space-y-4 px-5 py-5">
          <div className="rounded-lg border border-slate-200 bg-white p-4">
            <div className="mb-4 flex items-start gap-3">
              <div className="rounded-md bg-blue-50 p-2 text-blue-700">
                <SparklesIcon className="size-5" />
              </div>
              <div>
                <h2 className="text-base font-semibold">검토할 앱</h2>
                <p className="mt-1 text-sm leading-5 text-slate-600">
                  스토어 심사 전에 정책, 문구, 디자인, 제출 항목을 한 번에
                  확인합니다.
                </p>
              </div>
            </div>

            <label className="text-sm font-medium text-slate-700">
              앱 포지션
            </label>
            <div className="mt-2 rounded-md border border-slate-200 bg-slate-50 px-3 py-2 text-sm">
              AI personality companion
            </div>

            <label className="mt-4 block text-sm font-medium text-slate-700">
              제출 플랫폼
            </label>
            <div className="mt-2 grid grid-cols-3 gap-2">
              {platforms.map((platform, index) => (
                <button
                  className={[
                    "h-10 rounded-md border text-xs font-medium",
                    index === 0
                      ? "border-blue-600 bg-blue-600 text-white"
                      : "border-slate-200 bg-white text-slate-700",
                  ].join(" ")}
                  key={platform}
                  type="button"
                >
                  {platform}
                </button>
              ))}
            </div>
          </div>

          <div className="rounded-lg border border-amber-200 bg-amber-50 p-4">
            <div className="flex gap-3">
              <AlertTriangleIcon className="mt-0.5 size-5 shrink-0 text-amber-700" />
              <div>
                <h2 className="text-sm font-semibold text-amber-950">
                  현재 리스크
                </h2>
                <p className="mt-1 text-sm leading-5 text-amber-900">
                  점술 앱으로 보이면 iOS 심사에서 거절 가능성이 높습니다.
                  사용자에게는 성격 코칭, 자기 이해, AI 대화 흐름을 먼저
                  보여줘야 합니다.
                </p>
              </div>
            </div>
          </div>

          <section className="space-y-3">
            <div className="flex items-center justify-between">
              <h2 className="text-base font-semibold">AI 팀 진행 상황</h2>
              <span className="text-sm font-semibold text-blue-700">92%</span>
            </div>
            {agentChecks.map((check) => {
              const Icon = check.icon;
              return (
                <article
                  className="rounded-lg border border-slate-200 bg-white p-4"
                  key={check.label}
                >
                  <div className="flex gap-3">
                    <div className="rounded-md bg-slate-100 p-2 text-slate-700">
                      <Icon className="size-5" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center justify-between gap-3">
                        <h3 className="text-sm font-semibold">
                          {check.title}
                        </h3>
                        <Badge
                          variant="outline"
                          className="rounded-md border-slate-300 text-[11px]"
                        >
                          {check.label}
                        </Badge>
                      </div>
                      <p className="mt-1 text-sm font-medium text-slate-800">
                        {check.status}
                      </p>
                      <p className="mt-1 text-sm leading-5 text-slate-600">
                        {check.detail}
                      </p>
                    </div>
                  </div>
                </article>
              );
            })}
          </section>

          <section className="rounded-lg border border-slate-200 bg-white p-4">
            <h2 className="text-base font-semibold">생성될 제출 패키지</h2>
            <div className="mt-3 space-y-2">
              {deliverables.map((item) => (
                <div className="flex items-center gap-2 text-sm" key={item}>
                  <CheckCircle2Icon className="size-4 text-emerald-600" />
                  <span>{item}</span>
                </div>
              ))}
            </div>
          </section>
        </section>

        <footer className="sticky bottom-0 mt-auto border-t border-slate-200 bg-white p-4">
          <Button className="h-12 w-full rounded-md bg-blue-600 text-white hover:bg-blue-700">
            제출 패키지 만들기
          </Button>
        </footer>
      </div>
    </main>
  );
}
