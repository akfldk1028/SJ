import type { SupabaseClient } from "@supabase/supabase-js";
import { premiumProducts, type PremiumProduct } from "../toss-adapters";
import {
  createServiceSupabase,
  createUserSupabase,
  getAccessTokenFromRequest,
  type SupabaseEnv,
} from "./supabase-server";
import { getProfileById } from "./queries";

type TossPaymentConfirmEnv = SupabaseEnv & {
  TOSS_PAYMENTS_SECRET_KEY?: string;
};

type ConfirmPaymentParams = {
  request: Request;
  env: TossPaymentConfirmEnv;
};

export type PaymentConfirmResult =
  | {
      status: "confirmed" | "already_confirmed";
      profileId: string;
      productId: string;
      orderId: string;
      paymentKey: string;
      amount: number;
      expiresAt: string;
    }
  | {
      status: "missing_session" | "invalid_request" | "config_error" | "failed";
      message: string;
      profileId: string;
      productId: string;
      orderId: string;
      paymentKey: string;
      amount: number | null;
    };

type TossPaymentConfirmResponse = {
  paymentKey: string;
  orderId: string;
  orderName: string;
  status: string;
  totalAmount: number;
  approvedAt?: string;
};

export async function confirmTossPayment({
  env,
  request,
}: ConfirmPaymentParams): Promise<PaymentConfirmResult> {
  const url = new URL(request.url);
  const profileId = url.searchParams.get("profileId") ?? "";
  const productId = url.searchParams.get("productId") ?? "";
  const paymentKey = url.searchParams.get("paymentKey") ?? "";
  const orderId = url.searchParams.get("orderId") ?? "";
  const amount = Number(url.searchParams.get("amount") ?? "");
  const product = premiumProducts.find((item) => item.id === productId);

  if (!profileId || !product || !paymentKey || !orderId || !Number.isFinite(amount)) {
    return invalidResult({
      amount: Number.isFinite(amount) ? amount : null,
      message: "결제 승인에 필요한 값이 부족합니다.",
      orderId,
      paymentKey,
      productId,
      profileId,
    });
  }

  if (amount !== product.amount) {
    return invalidResult({
      amount,
      message: "결제 금액이 선택한 상품 금액과 일치하지 않습니다.",
      orderId,
      paymentKey,
      productId,
      profileId,
    });
  }

  const accessToken = getAccessTokenFromRequest(request);
  if (!accessToken) {
    return {
      status: "missing_session",
      message: "로그인 세션을 찾을 수 없습니다. 다시 결제를 시도해 주세요.",
      profileId,
      productId,
      orderId,
      paymentKey,
      amount,
    };
  }

  const userClient = createUserSupabase(env, accessToken);
  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser(accessToken);
  if (userError || !user) {
    return {
      status: "missing_session",
      message: "로그인 세션을 확인할 수 없습니다. 다시 결제를 시도해 주세요.",
      profileId,
      productId,
      orderId,
      paymentKey,
      amount,
    };
  }

  const profile = await getProfileById(userClient, profileId);
  if (!profile || profile.user_id !== user.id) {
    return invalidResult({
      amount,
      message: "결제 대상 프로필을 확인할 수 없습니다.",
      orderId,
      paymentKey,
      productId,
      profileId,
    });
  }

  if (!env.TOSS_PAYMENTS_SECRET_KEY) {
    return {
      status: "config_error",
      message: "TOSS_PAYMENTS_SECRET_KEY 서버 환경변수가 필요합니다.",
      profileId,
      productId,
      orderId,
      paymentKey,
      amount,
    };
  }

  const serviceClient = createServiceSupabase(env);
  const alreadyConfirmed = await findExistingSubscription(
    serviceClient,
    user.id,
    paymentKey,
  );
  if (alreadyConfirmed) {
    return {
      status: "already_confirmed",
      profileId,
      productId,
      orderId,
      paymentKey,
      amount,
      expiresAt: alreadyConfirmed.expires_at,
    };
  }

  const payment = await requestTossPaymentConfirm({
    amount,
    orderId,
    paymentKey,
    secretKey: env.TOSS_PAYMENTS_SECRET_KEY,
  });

  if (payment.status !== "DONE" || payment.totalAmount !== product.amount) {
    return {
      status: "failed",
      message: "토스페이먼츠 승인 결과가 유효하지 않습니다.",
      profileId,
      productId,
      orderId,
      paymentKey,
      amount,
    };
  }

  const expiresAt = getPremiumExpiresAt(product, payment.approvedAt);
  const { error: subscriptionError } = await serviceClient
    .from("subscriptions")
    .upsert(
      {
        user_id: user.id,
        product_id: product.id,
        platform: "toss",
        status: "active",
        original_transaction_id: payment.paymentKey,
        starts_at: payment.approvedAt ?? new Date().toISOString(),
        expires_at: expiresAt,
        is_lifetime: false,
        cancelled_at: null,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id,product_id" },
    );

  if (subscriptionError) {
    return {
      status: "failed",
      message: `프리미엄 상태 저장에 실패했습니다: ${subscriptionError.message}`,
      profileId,
      productId,
      orderId,
      paymentKey,
      amount,
    };
  }

  return {
    status: "confirmed",
    profileId,
    productId,
    orderId,
    paymentKey,
    amount,
    expiresAt,
  };
}

function invalidResult({
  amount,
  message,
  orderId,
  paymentKey,
  productId,
  profileId,
}: {
  amount: number | null;
  message: string;
  orderId: string;
  paymentKey: string;
  productId: string;
  profileId: string;
}): PaymentConfirmResult {
  return {
    status: "invalid_request",
    message,
    profileId,
    productId,
    orderId,
    paymentKey,
    amount,
  };
}

async function findExistingSubscription(
  client: SupabaseClient,
  userId: string,
  paymentKey: string,
): Promise<{ expires_at: string } | null> {
  const { data, error } = await client
    .from("subscriptions")
    .select("expires_at")
    .eq("user_id", userId)
    .eq("original_transaction_id", paymentKey)
    .eq("status", "active")
    .maybeSingle<{ expires_at: string }>();

  if (error) {
    throw new Error(`기존 결제 확인에 실패했습니다: ${error.message}`);
  }

  return data;
}

async function requestTossPaymentConfirm({
  amount,
  orderId,
  paymentKey,
  secretKey,
}: {
  amount: number;
  orderId: string;
  paymentKey: string;
  secretKey: string;
}) {
  const response = await fetch("https://api.tosspayments.com/v1/payments/confirm", {
    method: "POST",
    headers: {
      Authorization: `Basic ${btoa(`${secretKey}:`)}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      paymentKey,
      orderId,
      amount,
    }),
  });
  const body = (await response.json()) as Partial<TossPaymentConfirmResponse> & {
    message?: unknown;
  };

  if (!response.ok) {
    const message =
      typeof body.message === "string"
        ? body.message
        : "토스페이먼츠 결제 승인에 실패했습니다.";
    throw new Error(message);
  }

  return body as TossPaymentConfirmResponse;
}

function getPremiumExpiresAt(product: PremiumProduct, approvedAt?: string) {
  const startedAt = approvedAt ? new Date(approvedAt) : new Date();
  const expiresAt = new Date(startedAt);

  if (product.id === "sadam_day_pass") {
    expiresAt.setHours(expiresAt.getHours() + 24);
  } else if (product.id === "sadam_week_pass") {
    expiresAt.setDate(expiresAt.getDate() + 7);
  } else {
    expiresAt.setDate(expiresAt.getDate() + 30);
  }

  return expiresAt.toISOString();
}
