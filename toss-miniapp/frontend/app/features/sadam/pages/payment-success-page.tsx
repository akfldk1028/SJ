import { Link, type MetaFunction, useSearchParams } from "react-router";
import { CheckCircle2Icon } from "lucide-react";
import { Button } from "~/common/components/ui/button";

export const meta: MetaFunction = () => {
  return [{ title: "SaDam 결제 승인" }];
};

export default function PaymentSuccessPage() {
  const [searchParams] = useSearchParams();
  const profileId = searchParams.get("profileId") ?? "";
  const productId = searchParams.get("productId") ?? "";
  const paymentKey = searchParams.get("paymentKey") ?? "";
  const orderId = searchParams.get("orderId") ?? "";
  const amount = searchParams.get("amount") ?? "";
  const resultQuery = profileId
    ? `?profileId=${encodeURIComponent(profileId)}`
    : "";

  return (
    <main className="min-h-screen bg-slate-950 px-5 py-6 text-white">
      <div className="mx-auto flex min-h-[calc(100vh-3rem)] w-full max-w-md flex-col justify-center">
        <section className="rounded-lg border border-emerald-300/20 bg-white/[0.06] p-5">
          <div className="flex size-12 items-center justify-center rounded-lg bg-emerald-400/15 text-emerald-200">
            <CheckCircle2Icon className="size-6" />
          </div>
          <h1 className="mt-5 text-2xl font-bold">결제 승인 정보를 받았습니다</h1>
          <p className="mt-2 text-sm leading-6 text-slate-300">
            토스페이먼츠 결제창에서 성공 리다이렉트가 돌아왔습니다. 최종
            프리미엄 적용은 서버 승인 API에서 paymentKey, orderId, amount 값을
            검증한 뒤 Supabase 구독 상태에 반영해야 합니다.
          </p>

          <dl className="mt-5 space-y-3 rounded-lg bg-black/20 p-4 text-sm">
            <PaymentRow label="상품" value={productId} />
            <PaymentRow label="금액" value={amount ? `${amount}원` : ""} />
            <PaymentRow label="주문번호" value={orderId} />
            <PaymentRow label="결제키" value={paymentKey} />
          </dl>

          <Button
            asChild
            className="mt-6 h-12 w-full rounded-md bg-blue-500 text-white hover:bg-blue-400"
          >
            <Link to={`/result${resultQuery}`}>결과로 돌아가기</Link>
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
