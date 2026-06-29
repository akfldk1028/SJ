import type { SupabaseClient } from "@supabase/supabase-js";
import {
  subscriptionColumns,
  subscriptionSelectColumns,
  subscriptionsTable,
} from "./schema";

export type SubscriptionRow = {
  id: string;
  user_id: string;
  product_id: string;
  platform: string;
  status: string;
  original_transaction_id: string | null;
  starts_at: string;
  expires_at: string | null;
  is_lifetime: boolean;
  cancelled_at: string | null;
  created_at: string;
  updated_at: string;
};

export function isSubscriptionActive(subscription: SubscriptionRow | null) {
  if (!subscription || subscription.status !== "active") return false;
  if (subscription.is_lifetime) return true;
  if (!subscription.expires_at) return true;
  return new Date(subscription.expires_at) > new Date();
}

export async function getActiveSubscription(
  client: SupabaseClient,
  userId: string,
): Promise<SubscriptionRow | null> {
  const { data, error } = await client
    .from(subscriptionsTable)
    .select(subscriptionSelectColumns)
    .eq(subscriptionColumns.userId, userId)
    .eq(subscriptionColumns.status, "active")
    .in(subscriptionColumns.productId, [
      "sadam_day_pass",
      "sadam_week_pass",
      "sadam_monthly",
    ])
    .order(subscriptionColumns.expiresAt, {
      ascending: false,
      nullsFirst: false,
    })
    .limit(1)
    .maybeSingle<SubscriptionRow>();

  if (error) {
    throw new Error(`프리미엄 상태를 불러오지 못했습니다: ${error.message}`);
  }

  return isSubscriptionActive(data) ? data : null;
}
