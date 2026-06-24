import { makeAdminClient, makeSSRClient } from "~/supa-client";

import { getLoggedInUserId } from "~/features/users/queries";

import { getGptIdea } from "../queries";

import { redirect, data } from "react-router-dom";
import type { Route } from "./+types/claim-idea-success";
import { claimIdea } from "../mutations";
import { z } from "zod";

const TOSS_SECRET_KEY = "test_gsk_docs_OaPz8L5KdmQXkzRz3y47BMw6";

const paramsSchema = z.object({
  paymentType: z.string(),
  orderId: z.string().uuid(),
  paymentKey: z.string(),
  amount: z.coerce.number(),
});

export const loader = async ({ request, params }: Route.LoaderArgs) => {
  const url = new URL(request.url);
  const { success, data: aData } = paramsSchema.safeParse(
    Object.fromEntries(url.searchParams)
  );
  if (!success) {
    return new Response(null, { status: 400 });
  }
  const encryptedSecretKey = `Basic ${Buffer.from(
    TOSS_SECRET_KEY + ":"
  ).toString("base64")}`;
  const response = await fetch(
    "https://api.tosspayments.com/v1/payments/confirm",
    {
      method: "POST",
      headers: {
        Authorization: encryptedSecretKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        orderId: aData.orderId,
        paymentKey: aData.paymentKey,
        amount: aData.amount,
      }),
    }
  );
  const { client } = makeSSRClient(request);
  const userId = await getLoggedInUserId(client);
  const adminClient = makeAdminClient();
  const idea = await getGptIdea(adminClient, { ideaId: params.ideaId });
  if (!idea.is_claimed) {
    await claimIdea(adminClient, { ideaId: params.ideaId, userId });
  }
  return redirect(`/my/dashboard/ideas`);
};
