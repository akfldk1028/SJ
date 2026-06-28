export type TossActionResult = {
  ok: boolean;
  message: string;
};

export type PremiumProductId =
  | "sadam_day_pass"
  | "sadam_week_pass"
  | "sadam_monthly";

export type PremiumProduct = {
  id: PremiumProductId;
  name: string;
  periodLabel: string;
  amount: number;
  badge: string;
  description: string;
  features: string[];
};

export const premiumProducts: PremiumProduct[] = [
  {
    id: "sadam_day_pass",
    name: "하루 이용권",
    periodLabel: "24시간",
    amount: 1900,
    badge: "가볍게",
    description: "오늘의 상세 분석과 AI 질문을 바로 열어봅니다.",
    features: ["상세 리포트", "AI 채팅", "광고 제거"],
  },
  {
    id: "sadam_week_pass",
    name: "7일 이용권",
    periodLabel: "7일",
    amount: 5900,
    badge: "추천",
    description: "일주일 동안 사주 흐름과 관계 조언을 이어서 확인합니다.",
    features: ["상세 리포트", "AI 채팅", "추가 질문"],
  },
  {
    id: "sadam_monthly",
    name: "30일 이용권",
    periodLabel: "30일",
    amount: 9900,
    badge: "프리미엄",
    description: "한 달 동안 프리미엄 분석을 계속 사용할 수 있습니다.",
    features: ["상세 리포트", "AI 채팅", "전체 운세"],
  },
];

export function formatKrw(amount: number) {
  return new Intl.NumberFormat("ko-KR", {
    style: "currency",
    currency: "KRW",
    maximumFractionDigits: 0,
  }).format(amount);
}

export async function requestRewardedAd(): Promise<TossActionResult> {
  await new Promise((resolve) => setTimeout(resolve, 450));
  return {
    ok: true,
    message: "리워드 광고 시청을 완료한 상태로 처리했습니다.",
  };
}

export async function requestPremiumPurchase({
  product,
  profileId,
  customerName,
}: {
  product: PremiumProduct;
  profileId: string;
  customerName: string;
}): Promise<TossActionResult> {
  if (typeof window === "undefined") {
    return {
      ok: false,
      message: "결제창은 브라우저에서만 열 수 있습니다.",
    };
  }

  const clientKey = getTossPaymentsClientKey();
  if (!clientKey) {
    return {
      ok: false,
      message: "VITE_TOSS_PAYMENTS_CLIENT_KEY 환경변수가 필요합니다.",
    };
  }

  try {
    const { ANONYMOUS, loadTossPayments } = await import(
      "@tosspayments/tosspayments-sdk"
    );
    const tossPayments = await loadTossPayments(clientKey);
    const payment = tossPayments.payment({ customerKey: ANONYMOUS });
    const orderId = buildOrderId(product.id, profileId);
    const successUrl = buildPaymentUrl("/premium/success", {
      profileId,
      productId: product.id,
    });
    const failUrl = buildPaymentUrl("/premium/fail", {
      profileId,
      productId: product.id,
    });

    await payment.requestPayment({
      method: "CARD",
      amount: {
        currency: "KRW",
        value: product.amount,
      },
      orderId,
      orderName: `사담 ${product.name}`,
      successUrl,
      failUrl,
      customerName,
      card: {
        flowMode: "DEFAULT",
        useEscrow: false,
        useCardPoint: false,
        useAppCardOnly: false,
      },
    });

    return {
      ok: true,
      message: "토스페이먼츠 결제창을 열었습니다.",
    };
  } catch (error) {
    return {
      ok: false,
      message:
        error instanceof Error
          ? error.message
          : "결제창을 여는 중 오류가 발생했습니다.",
    };
  }
}

function getTossPaymentsClientKey() {
  const env = (
    import.meta as ImportMeta & {
      env?: Record<string, string | undefined>;
    }
  ).env;
  const key = env?.VITE_TOSS_PAYMENTS_CLIENT_KEY;
  return key && key.trim().length > 0 ? key.trim() : null;
}

function buildPaymentUrl(pathname: string, params: Record<string, string>) {
  const url = new URL(pathname, window.location.origin);
  Object.entries(params).forEach(([key, value]) => {
    if (value) {
      url.searchParams.set(key, value);
    }
  });
  return url.toString();
}

function buildOrderId(productId: PremiumProductId, profileId: string) {
  const random =
    typeof crypto !== "undefined" && "randomUUID" in crypto
      ? crypto.randomUUID()
      : `${Date.now()}-${Math.random().toString(36).slice(2)}`;
  const prefix = profileId.replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 12);

  return `sadam-${productId}-${prefix}-${random}`
    .replace(/[^a-zA-Z0-9_-]/g, "")
    .slice(0, 64);
}
