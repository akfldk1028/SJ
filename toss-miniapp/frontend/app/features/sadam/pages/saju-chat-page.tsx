import { type MetaFunction, useLoaderData } from "react-router";
import { MessageCircleIcon } from "lucide-react";
import { Badge } from "~/common/components/ui/badge";
import { Button } from "~/common/components/ui/button";
import { loadSadamProfile, type SadamProfileLoaderData } from "../data/route-loaders";
import {
  ErrorState,
  PageShell,
  ProfileSummary,
  SajuNavButtons,
} from "./saju-page-utils";

export const meta: MetaFunction = () => [{ title: "SaDam 사주 상담" }];
export const loader = loadSadamProfile;

export default function SajuChatPage() {
  const data = useLoaderData() as SadamProfileLoaderData;
  if (data.error || !data.profile || !data.calculation) return <ErrorState data={data} />;

  const summary = data.summary?.content;
  const personality = summary?.personality && typeof summary.personality === "object"
    ? summary.personality as Record<string, unknown>
    : null;
  const core = typeof personality?.core === "string" ? personality.core : null;
  const questions = [
    "내 사주에서 지금 가장 강한 기운은 뭐야?",
    "올해 조심해야 할 관계 패턴을 알려줘.",
    "일과 돈 흐름에서 먼저 챙길 점은 뭐야?",
  ];

  return (
    <PageShell calculation={data.calculation} eyebrow="Saju Chat" title="AI 사주 상담 시작">
      <ProfileSummary data={data} />

      <section className="mt-5 rounded-lg border border-white/10 bg-white p-4 text-slate-950">
        <div className="flex items-center gap-2">
          <MessageCircleIcon className="size-5 text-sky-600" />
          <h2 className="text-lg font-bold">{data.calculation.identity.fullName} 상담 준비</h2>
        </div>
        <p className="mt-3 text-sm leading-6 text-slate-700">
          {core ?? "저장된 사주 분석을 바탕으로 상담을 시작할 수 있습니다. 실제 채팅 세션과 히스토리 저장은 다음 루프에서 연결합니다."}
        </p>
      </section>

      <section className="mt-5 rounded-lg border border-white/10 bg-white p-4 text-slate-950">
        <h3 className="text-sm font-bold">추천 질문</h3>
        <div className="mt-3 space-y-2">
          {questions.map((question) => (
            <button
              className="w-full rounded-md border border-slate-200 bg-slate-50 px-3 py-3 text-left text-sm leading-5 text-slate-800"
              key={question}
              type="button"
            >
              {question}
            </button>
          ))}
        </div>
      </section>

      <section className="mt-5 rounded-lg border border-amber-200 bg-amber-50 p-4 text-amber-950">
        <div className="flex flex-wrap gap-2">
          <Badge className="rounded-md bg-white text-amber-900">세션 저장 예정</Badge>
          <Badge className="rounded-md bg-white text-amber-900">AI API 연결 예정</Badge>
        </div>
        <p className="mt-3 text-sm leading-6">
          이번 화면은 Flutter `/saju/chat` 라우트의 진입점 역할입니다. 실제 대화 스트리밍, 메시지 DB 저장,
          채팅 히스토리는 별도 루프로 구현합니다.
        </p>
      </section>

      <Button className="mt-5 h-12 rounded-md bg-sky-500 text-white hover:bg-sky-400" disabled>
        실제 채팅은 다음 루프에서 연결
      </Button>
      <SajuNavButtons query={data.query} />
    </PageShell>
  );
}
