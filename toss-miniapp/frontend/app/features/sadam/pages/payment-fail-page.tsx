import { Link, type MetaFunction, useSearchParams } from "react-router";
import { XCircleIcon } from "lucide-react";
import { Button } from "~/common/components/ui/button";

export const meta: MetaFunction = () => {
  return [{ title: "SaDam 결제 실패" }];
};

export default function PaymentFailPage() {
  const [searchParams] = useSearchParams();
  const profileId = searchParams.get("profileId") ?? "";
  const code = searchParams.get("code") ?? "";
  const message = searchParams.get("message") ?? "";
  const orderId = searchParams.get("orderId") ?? "";
  const premiumQuery = profileId
    ? `?profileId=${encodeURIComponent(profileId)}`
    : "";

  return (
    <main className="min-h-screen bg-slate-950 px-5 py-6 text-white">
      <div className="mx-auto flex min-h-[calc(100vh-3rem)] w-full max-w-md flex-col justify-center">
        <section className="rounded-lg border border-rose-300/20 bg-white/[0.06] p-5">
          <div className="flex size-12 items-center justify-center rounded-lg bg-rose-400/15 text-rose-200">
            <XCircleIcon className="size-6" />
          </div>
          <h1 className="mt-5 text-2xl font-bold">결제가 완료되지 않았습니다</h1>
          <p className="mt-2 text-sm leading-6 text-slate-300">
            결제창에서 실패 또는 취소 응답이 돌아왔습니다. 다시 시도하거나 다른
            결제 수단을 선택해 주세요.
          </p>

          <dl className="mt-5 space-y-3 rounded-lg bg-black/20 p-4 text-sm">
            <PaymentRow label="오류코드" value={code} />
            <PaymentRow label="메시지" value={message} />
            <PaymentRow label="주문번호" value={orderId} />
          </dl>

          <Button
            asChild
            className="mt-6 h-12 w-full rounded-md bg-blue-500 text-white hover:bg-blue-400"
          >
            <Link to={`/premium${premiumQuery}`}>다시 결제하기</Link>
          </Button>
        </section>
      </div>
    </main>
  );
}

function PaymentRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="grid grid-cols-[5rem_1fr] gap-3">
      <dt className="text-slate-400">{label}</dt>
      <dd className="break-all text-white">{value || "-"}</dd>
    </div>
  );
}
