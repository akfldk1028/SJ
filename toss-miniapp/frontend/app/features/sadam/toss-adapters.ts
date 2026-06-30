export type TossActionResult = {
  ok: boolean;
  message: string;
  orderId?: string;
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

type AppsInTossSdk = typeof import("@apps-in-toss/web-framework");

export const premiumProducts: PremiumProduct[] = [
  {
    id: "sadam_day_pass",
    name: "하루 이용권",
    periodLabel: "24시간",
    amount: 1900,
    badge: "가볍게",
    description: "오늘의 상세 분석과 AI 질문을 바로 이어볼 수 있습니다.",
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
  const sdk = await loadAppsInTossSdk();
  if (sdk && isFunctionSupported(sdk.loadFullScreenAd) && isFunctionSupported(sdk.showFullScreenAd)) {
    return requestAppsInTossRewardedAd(sdk);
  }

  return {
    ok: false,
    message: "리워드 광고는 앱인토스 샌드박스 또는 토스앱 환경에서 테스트해야 합니다.",
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
  const sdk = await loadAppsInTossSdk();
  if (sdk) {
    const result = await requestAppsInTossPurchase(sdk, product);
    if (result.ok || !shouldFallbackToTossPayments(result.message)) {
      return result;
    }
  }

  return requestTossPaymentsPurchase({ product, profileId, customerName });
}

export async function getAppsInTossProductIds() {
  const sdk = await loadAppsInTossSdk();
  if (!sdk) return [];

  try {
    const result = await sdk.IAP.getProductItemList();
    return result.products.map((product) => product.sku);
  } catch {
    return [];
  }
}

async function requestAppsInTossPurchase(
  sdk: AppsInTossSdk,
  product: PremiumProduct,
): Promise<TossActionResult> {
  if (!isAppsInTossRuntime()) {
    return {
      ok: false,
      message: "앱인토스 IAP는 토스앱 또는 앱인토스 샌드박스에서만 실행됩니다.",
    };
  }

  try {
    const pending = await sdk.IAP.getPendingOrders().catch(() => null);
    const pendingOrder = pending?.orders.find((order) => order.sku === product.id);
    if (pendingOrder) {
      await sdk.IAP.completeProductGrant({ params: { orderId: pendingOrder.orderId } });
      return {
        ok: true,
        orderId: pendingOrder.orderId,
        message: "대기 중이던 앱인토스 결제를 복원하고 상품 지급을 완료했습니다.",
      };
    }

    return await new Promise<TossActionResult>((resolve) => {
      let cleanup: (() => void) | null = null;
      cleanup = sdk.IAP.createOneTimePurchaseOrder({
        options: {
          sku: product.id,
          processProductGrant: async ({ orderId }) => {
            await sdk.IAP.completeProductGrant({ params: { orderId } });
            return true;
          },
        },
        onEvent: (event) => {
          cleanup?.();
          resolve({
            ok: true,
            orderId: event.data.orderId,
            message: "앱인토스 인앱 결제가 완료되었습니다.",
          });
        },
        onError: (error) => {
          cleanup?.();
          resolve({
            ok: false,
            message: getErrorMessage(error, "앱인토스 결제 중 오류가 발생했습니다."),
          });
        },
      });
    });
  } catch (error) {
    return {
      ok: false,
      message: getErrorMessage(error, "앱인토스 결제를 시작하지 못했습니다."),
    };
  }
}

async function requestAppsInTossRewardedAd(sdk: AppsInTossSdk): Promise<TossActionResult> {
  const adGroupId = getRewardedAdGroupId();
  if (!adGroupId) {
    return {
      ok: false,
      message: "VITE_APPS_IN_TOSS_REWARDED_AD_GROUP_ID가 필요합니다.",
    };
  }

  try {
    await waitForFullScreenAdLoaded(sdk, adGroupId);
    const reward = await waitForFullScreenAdReward(sdk, adGroupId);

    return reward
      ? {
          ok: true,
          message: "리워드 광고 시청이 완료되었습니다.",
        }
      : {
          ok: false,
          message: "광고가 종료되었지만 보상 이벤트를 받지 못했습니다.",
        };
  } catch (error) {
    return {
      ok: false,
      message: getErrorMessage(error, "리워드 광고를 실행하지 못했습니다."),
    };
  }
}

function waitForFullScreenAdLoaded(sdk: AppsInTossSdk, adGroupId: string) {
  return new Promise<void>((resolve, reject) => {
    let cleanup: (() => void) | null = null;
    cleanup = sdk.loadFullScreenAd({
      options: { adGroupId },
      onEvent: (event) => {
        if (event.type === "loaded") {
          cleanup?.();
          resolve();
        }
      },
      onError: (error) => {
        cleanup?.();
        reject(error);
      },
    });
  });
}

function waitForFullScreenAdReward(sdk: AppsInTossSdk, adGroupId: string) {
  return new Promise<boolean>((resolve, reject) => {
    let cleanup: (() => void) | null = null;
    let rewarded = false;
    cleanup = sdk.showFullScreenAd({
      options: { adGroupId },
      onEvent: (event) => {
        if (event.type === "userEarnedReward") {
          rewarded = true;
        }
        if (event.type === "dismissed" || event.type === "failedToShow") {
          cleanup?.();
          resolve(rewarded);
        }
      },
      onError: (error) => {
        cleanup?.();
        reject(error);
      },
    });
  });
}

async function requestTossPaymentsPurchase({
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
      message: "토스앱 밖에서는 VITE_TOSS_PAYMENTS_CLIENT_KEY가 필요합니다.",
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

    const request = payment.requestPayment({
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

    await waitForImmediatePaymentError(request);

    return {
      ok: true,
      orderId,
      message: "토스페이먼츠 결제창을 열었습니다.",
    };
  } catch (error) {
    return {
      ok: false,
      message: getErrorMessage(error, "결제창을 여는 중 오류가 발생했습니다."),
    };
  }
}

async function waitForImmediatePaymentError(request: Promise<unknown>) {
  const opened = Symbol("opened");
  const result = await Promise.race([
    request.then(
      () => null,
      (error) => error instanceof Error ? error : new Error(String(error)),
    ),
    new Promise((resolve) => setTimeout(() => resolve(opened), 1500)),
  ]);

  if (result instanceof Error) {
    throw result;
  }

  if (result === opened) {
    request.catch((error) => {
      console.error("Toss Payments request failed after opening.", error);
    });
  }
}

async function loadAppsInTossSdk() {
  if (typeof window === "undefined") return null;

  try {
    return await import("@apps-in-toss/web-framework");
  } catch {
    return null;
  }
}

function isFunctionSupported(fn: unknown) {
  try {
    const supported = (fn as { isSupported?: () => boolean }).isSupported;
    return typeof fn === "function" && (typeof supported !== "function" || supported());
  } catch {
    return false;
  }
}

function isAppsInTossRuntime() {
  return typeof window !== "undefined" && "ReactNativeWebView" in window;
}

function shouldFallbackToTossPayments(message: string) {
  return message.includes("토스앱") || message.includes("샌드박스");
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

function getRewardedAdGroupId() {
  const env = (
    import.meta as ImportMeta & {
      env?: Record<string, string | undefined>;
    }
  ).env;
  const key = env?.VITE_APPS_IN_TOSS_REWARDED_AD_GROUP_ID ?? "ait-ad-test-rewarded-id";
  return key.trim().length > 0 ? key.trim() : null;
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

function getErrorMessage(error: unknown, fallback: string) {
  if (error instanceof Error && error.message) return error.message;
  if (error && typeof error === "object" && "message" in error) {
    const message = (error as { message?: unknown }).message;
    if (typeof message === "string" && message.length > 0) return message;
  }
  return fallback;
}
