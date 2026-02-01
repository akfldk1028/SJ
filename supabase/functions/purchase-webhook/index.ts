import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * RevenueCat Webhook Edge Function
 *
 * RevenueCat에서 구매/구독 이벤트 수신 → subscriptions 테이블 upsert
 *
 * 이벤트 유형:
 * - INITIAL_PURCHASE → INSERT (status: active)
 * - RENEWAL → UPDATE expires_at
 * - CANCELLATION → UPDATE status: cancelled
 * - EXPIRATION → UPDATE status: expired
 * - NON_RENEWING_PURCHASE → INSERT (is_lifetime: true)
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

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

    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);
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
        const isLifetime = event.type === "NON_RENEWING_PURCHASE" ||
          productId === "sadam_ad_removal";
        const expiresAt = event.expiration_at_ms
          ? new Date(event.expiration_at_ms).toISOString()
          : null;

        await supabase.from("subscriptions").upsert(
          {
            user_id: userId,
            product_id: productId,
            platform,
            status: "active",
            original_transaction_id: event.original_transaction_id,
            starts_at: event.purchased_at_ms
              ? new Date(event.purchased_at_ms).toISOString()
              : new Date().toISOString(),
            expires_at: isLifetime ? null : expiresAt,
            is_lifetime: isLifetime,
            updated_at: new Date().toISOString(),
          },
          { onConflict: "user_id,product_id" }
        );

        console.log(
          `[purchase-webhook] Subscription created: ${productId} (lifetime: ${isLifetime})`
        );
        break;
      }

      case "RENEWAL": {
        const expiresAt = event.expiration_at_ms
          ? new Date(event.expiration_at_ms).toISOString()
          : null;

        await supabase
          .from("subscriptions")
          .update({
            status: "active",
            expires_at: expiresAt,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", userId)
          .eq("product_id", productId);

        console.log(`[purchase-webhook] Subscription renewed: ${productId}`);
        break;
      }

      case "CANCELLATION": {
        const cancelledAt = event.cancellation_at_ms
          ? new Date(event.cancellation_at_ms).toISOString()
          : new Date().toISOString();

        await supabase
          .from("subscriptions")
          .update({
            status: "cancelled",
            cancelled_at: cancelledAt,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", userId)
          .eq("product_id", productId);

        console.log(
          `[purchase-webhook] Subscription cancelled: ${productId}`
        );
        break;
      }

      case "EXPIRATION": {
        await supabase
          .from("subscriptions")
          .update({
            status: "expired",
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", userId)
          .eq("product_id", productId);

        console.log(`[purchase-webhook] Subscription expired: ${productId}`);
        break;
      }

      default:
        console.log(`[purchase-webhook] Unhandled event type: ${event.type}`);
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("[purchase-webhook] Error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
