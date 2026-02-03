import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * RevenueCat Webhook Edge Function (v2)
 *
 * RevenueCat에서 구매/구독 이벤트 수신 → subscriptions 테이블 upsert
 * 모든 에러/실패를 chat_error_logs에 기록
 *
 * 이벤트 유형:
 * - INITIAL_PURCHASE → INSERT (status: active)
 * - RENEWAL → UPDATE expires_at
 * - CANCELLATION → UPDATE status: cancelled
 * - UNCANCELLATION → UPDATE status: active (취소 철회)
 * - EXPIRATION → UPDATE status: expired
 * - BILLING_ISSUE → UPDATE status: billing_issue
 * - NON_RENEWING_PURCHASE → INSERT (is_lifetime: false, expires_at 설정)
 * - TEST → 로그만 기록
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const REVENUECAT_WEBHOOK_SECRET = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");

interface RevenueCatEvent {
  type: string;
  app_user_id: string;
  product_id: string;
  store: string;
  environment: string;
  original_transaction_id?: string;
  expiration_at_ms?: number;
  cancellation_at_ms?: number;
  purchased_at_ms?: number;
}

interface RevenueCatWebhook {
  api_version: string;
  event: RevenueCatEvent;
}

/** chat_error_logs에 에러/이벤트 기록 */
async function logError(
  supabase: ReturnType<typeof createClient>,
  userId: string | null,
  operation: string,
  errorMsg: string,
  extraData?: Record<string, unknown>
) {
  try {
    const payload = {
      user_id: userId,
      error_type: "webhook",
      error_message: errorMsg.substring(0, 2000),
      operation: `purchase-webhook:${operation}`,
      source_file: "purchase-webhook/index.ts",
      extra_data: extraData ?? {},
    };
    const { error } = await supabase.from("chat_error_logs").insert(payload);
    // FK 위반 시 user_id를 null로 재시도 (테스트 이벤트 등 미등록 유저)
    if (error && userId) {
      await supabase.from("chat_error_logs").insert({ ...payload, user_id: null });
    }
  } catch (_) { /* 로그 실패는 무시 */ }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let supabase: ReturnType<typeof createClient> | null = null;

  try {
    // Webhook 인증 (선택적)
    if (REVENUECAT_WEBHOOK_SECRET) {
      const authHeader = req.headers.get("authorization");
      if (authHeader !== `Bearer ${REVENUECAT_WEBHOOK_SECRET}`) {
        console.error("[purchase-webhook] Invalid webhook secret");
        return new Response(JSON.stringify({ error: "Unauthorized" }), {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);
    const body: RevenueCatWebhook = await req.json();
    const event = body.event;

    console.log(
      `[purchase-webhook] Event: ${event.type}, user: ${event.app_user_id}, product: ${event.product_id}`
    );

    const userId = event.app_user_id;
    const productId = event.product_id;
    const platform = event.store === "APP_STORE" ? "ios" : "android";

    switch (event.type) {
      case "INITIAL_PURCHASE":
      case "NON_RENEWING_PURCHASE": {
        const expiresAt = event.expiration_at_ms
          ? new Date(event.expiration_at_ms).toISOString()
          : null;

        const { error: dbError } = await supabase.from("subscriptions").upsert(
          {
            user_id: userId,
            product_id: productId,
            platform,
            status: "active",
            original_transaction_id: event.original_transaction_id,
            starts_at: event.purchased_at_ms
              ? new Date(event.purchased_at_ms).toISOString()
              : new Date().toISOString(),
            expires_at: expiresAt,
            is_lifetime: false,
            updated_at: new Date().toISOString(),
          },
          { onConflict: "user_id,product_id" }
        );

        if (dbError) {
          console.error(`[purchase-webhook] DB error on ${event.type}:`, dbError);
          await logError(supabase, userId, event.type, dbError.message, {
            product_id: productId,
            platform,
            db_code: dbError.code,
          });
        } else {
          console.log(
            `[purchase-webhook] Subscription created: ${productId}`
          );
          await logError(supabase, userId, event.type, `SUCCESS: ${productId}`, {
            product_id: productId,
            platform,
            status: "active",
          });
        }
        break;
      }

      case "RENEWAL": {
        const expiresAt = event.expiration_at_ms
          ? new Date(event.expiration_at_ms).toISOString()
          : null;

        const { error: dbError } = await supabase
          .from("subscriptions")
          .update({
            status: "active",
            expires_at: expiresAt,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", userId)
          .eq("product_id", productId);

        if (dbError) {
          console.error("[purchase-webhook] DB error on RENEWAL:", dbError);
          await logError(supabase, userId, "RENEWAL", dbError.message, {
            product_id: productId,
            db_code: dbError.code,
          });
        } else {
          console.log(`[purchase-webhook] Subscription renewed: ${productId}`);
          await logError(supabase, userId, "RENEWAL", `SUCCESS: ${productId}`, {
            product_id: productId,
            status: "active",
          });
        }
        break;
      }

      case "CANCELLATION": {
        const cancelledAt = event.cancellation_at_ms
          ? new Date(event.cancellation_at_ms).toISOString()
          : new Date().toISOString();

        const { error: dbError } = await supabase
          .from("subscriptions")
          .update({
            status: "cancelled",
            cancelled_at: cancelledAt,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", userId)
          .eq("product_id", productId);

        if (dbError) {
          console.error("[purchase-webhook] DB error on CANCELLATION:", dbError);
          await logError(supabase, userId, "CANCELLATION", dbError.message, {
            product_id: productId,
            db_code: dbError.code,
          });
        } else {
          console.log(`[purchase-webhook] Subscription cancelled: ${productId}`);
          await logError(supabase, userId, "CANCELLATION", `SUCCESS: ${productId}`, {
            product_id: productId,
            status: "cancelled",
          });
        }
        break;
      }

      case "UNCANCELLATION": {
        const { error: dbError } = await supabase
          .from("subscriptions")
          .update({
            status: "active",
            cancelled_at: null,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", userId)
          .eq("product_id", productId);

        if (dbError) {
          console.error("[purchase-webhook] DB error on UNCANCELLATION:", dbError);
          await logError(supabase, userId, "UNCANCELLATION", dbError.message, {
            product_id: productId,
            db_code: dbError.code,
          });
        } else {
          console.log(`[purchase-webhook] Subscription uncancelled: ${productId}`);
          await logError(supabase, userId, "UNCANCELLATION", `SUCCESS: ${productId}`, {
            product_id: productId,
            status: "active",
          });
        }
        break;
      }

      case "BILLING_ISSUE": {
        const { error: dbError } = await supabase
          .from("subscriptions")
          .update({
            status: "billing_issue",
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", userId)
          .eq("product_id", productId);

        if (dbError) {
          console.error("[purchase-webhook] DB error on BILLING_ISSUE:", dbError);
          await logError(supabase, userId, "BILLING_ISSUE", dbError.message, {
            product_id: productId,
            db_code: dbError.code,
          });
        } else {
          console.log(`[purchase-webhook] Billing issue: ${productId}`);
          await logError(supabase, userId, "BILLING_ISSUE", `SUCCESS: ${productId}`, {
            product_id: productId,
            status: "billing_issue",
          });
        }
        break;
      }

      case "EXPIRATION": {
        const { error: dbError } = await supabase
          .from("subscriptions")
          .update({
            status: "expired",
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", userId)
          .eq("product_id", productId);

        if (dbError) {
          console.error("[purchase-webhook] DB error on EXPIRATION:", dbError);
          await logError(supabase, userId, "EXPIRATION", dbError.message, {
            product_id: productId,
            db_code: dbError.code,
          });
        } else {
          console.log(`[purchase-webhook] Subscription expired: ${productId}`);
          await logError(supabase, userId, "EXPIRATION", `SUCCESS: ${productId}`, {
            product_id: productId,
            status: "expired",
          });
        }
        break;
      }

      case "TEST": {
        console.log(`[purchase-webhook] Test event received for user: ${userId}`);
        await logError(supabase, userId, "TEST", `Test event: ${productId}`, {
          product_id: productId,
          environment: event.environment,
        });
        break;
      }

      default:
        console.log(`[purchase-webhook] Unhandled event type: ${event.type}`);
        await logError(supabase, userId, event.type, `Unhandled event type: ${event.type}`, {
          product_id: productId,
          environment: event.environment,
        });
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : "Unknown error";
    console.error("[purchase-webhook] Error:", error);

    // 가능하면 에러 로그 기록
    if (supabase) {
      await logError(supabase, null, "UNHANDLED_ERROR", errorMsg);
    }

    return new Response(
      JSON.stringify({ success: false, error: errorMsg }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
