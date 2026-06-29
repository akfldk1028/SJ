import {
  Link,
  type MetaFunction,
  useLoaderData,
  useSearchParams,
} from "react-router";
import {
  AlertCircleIcon,
  CheckCircle2Icon,
  LoaderCircleIcon,
} from "lucide-react";
import { Button } from "~/common/components/ui/button";
import {
  confirmTossPayment,
  type PaymentConfirmResult,
} from "../data/payment-server";

export const meta: MetaFunction = () => {
  return [{ title: "SaDam 결제 승인" }];
};

export async function loader({
  context,
  request,
}: {
  request: Request;
  context: { cloudflare: { env: CloudflareEnvironment } };
}) {
  try {
    return await confirmTossPayment({
      request,
      env: context.cloudflare.env,
    });
  } catch (error) {
    const url = new URL(request.url);
    return {
      status: "failed",
      message:
        error instanceof Error
          ? error.message
          : "결제 승인 처리 중 오류가 발생했습니다.",
      profileId: url.searchParams.get("profileId") ?? "",
      productId: url.searchParams.get("productId") ?? "",
      orderId: url.searchParams.get("orderId") ?? "",
      paymentKey: url.searchParams.get("paymentKey") ?? "",
      amount: Number(url.searchParams.get("amount") ?? "") || null,
    } satisfies PaymentConfirmResult;
  }
}

export default function PaymentSuccessPage() {
  const result = useLoaderData() as PaymentConfirmResult;
  const [searchParams] = useSearchParams();
  const profileId = result.profileId || searchParams.get("profileId") || "";
  const resultQuery = profileId
    ? `?profileId=${encodeURIComponent(profileId)}`
    : "";
  const isSuccess =
    result.status === "confirmed" || result.status === "already_confirmed";
  const title =
    result.status === "confirmed"
      ? "프리미엄이 적용되었습니다"
      : result.status === "already_confirmed"
        ? "이미 적용된 결제입니다"
        : "결제 승인이 완료되지 못했습니다";
  const description = isSuccess
    ? "토스페이먼츠 결제 승인을 확인했고 Supabase 구독 상태에 프리미엄 이용권을 반영했습니다."
    : getFailureMessage(result);

  return (
    <main className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-800 to-slate-950 px-4 py-5 text-white sm:px-5 lg:py-7">
      <div className="mx-auto flex min-h-[calc(100vh-2.5rem)] w-full max-w-md flex-col justify-center lg:max-w-2xl">
        <section
          className={`rounded-lg border bg-white/[0.08] p-5 shadow-2xl shadow-black/25 backdrop-blur ${
            isSuccess ? "border-emerald-300/20" : "border-rose-300/20"
          }`}
        >
          <div
            className={`flex size-12 items-center justify-center rounded-lg ${
              isSuccess
                ? "bg-emerald-400/15 text-emerald-200"
                : "bg-rose-400/15 text-rose-200"
            }`}
          >
            {isSuccess ? (
              <CheckCircle2Icon className="size-6" />
            ) : result.status === "config_error" ? (
              <LoaderCircleIcon className="size-6" />
            ) : (
              <AlertCircleIcon className="size-6" />
            )}
          </div>
          <h1 className="mt-5 text-2xl font-bold">{title}</h1>
          <p className="mt-2 text-sm leading-6 text-slate-300">
            {description}
          </p>

          <dl className="mt-5 space-y-3 rounded-lg bg-black/25 p-4 text-sm ring-1 ring-white/10">
            <PaymentRow label="상품" value={result.productId} />
            <PaymentRow
              label="금액"
              value={result.amount ? `${result.amount}원` : ""}
            />
            <PaymentRow label="주문번호" value={result.orderId} />
            <PaymentRow label="결제키" value={result.paymentKey} />
            <PaymentRow
              label="만료일"
              value={"expiresAt" in result ? formatDateTime(result.expiresAt) : ""}
            />
          </dl>

          <Button
            asChild
            className="mt-6 h-12 w-full rounded-md bg-blue-500 text-white hover:bg-blue-400"
          >
            <Link to={`/result${resultQuery}`}>
              {isSuccess ? "결과로 돌아가기" : "결과 화면으로 이동"}
            </Link>
          </Button>

          {!isSuccess ? (
            <Button
              asChild
              className="mt-3 h-12 w-full rounded-md"
              variant="secondary"
            >
              <Link to={`/premium${resultQuery}`}>다시 결제하기</Link>
            </Button>
          ) : null}
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

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat("ko-KR", {
    dateStyle: "medium",
    timeStyle: "short",
    timeZone: "Asia/Seoul",
  }).format(new Date(value));
}

function getFailureMessage(result: PaymentConfirmResult) {
  return "message" in result
    ? result.message
    : "결제 승인 처리 중 오류가 발생했습니다.";
}
