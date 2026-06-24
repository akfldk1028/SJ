import { makeSSRClient } from "~/supa-client";

import { getLoggedInUserId } from "~/features/users/queries";
import { redirect } from "react-router-dom";
import type { Route } from "./+types/submit-job-success";
import { createJob } from "../mutations";
import { z } from "zod";
import { JOB_TYPES, LOCATION_TYPES, SALARY_RANGE } from "../constants";

const TOSS_SECRET_KEY = "test_gsk_docs_OaPz8L5KdmQXkzRz3y47BMw6";

export const paramsSchema = z.object({
  paymentType: z.string(),
  orderId: z.string().uuid(),
  paymentKey: z.string(),
  amount: z.coerce.number(),
  position: z.string().max(40),
  overview: z.string().max(400),
  responsibilities: z.string().max(400),
  qualifications: z.string().max(400),
  benefits: z.string().max(400),
  skills: z.string().max(400),
  companyName: z.string().max(40),
  companyLogoUrl: z.string().max(40),
  companyLocation: z.string().max(40),
  applyUrl: z.string().max(40),
  jobType: z.enum(JOB_TYPES.map((type) => type.value) as [string, ...string[]]),
  jobLocation: z.enum(
    LOCATION_TYPES.map((location) => location.value) as [string, ...string[]]
  ),
  salaryRange: z.enum(SALARY_RANGE),
});

export const loader = async ({ request, params }: Route.LoaderArgs) => {
  const { client } = makeSSRClient(request);
  await getLoggedInUserId(client);
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
  const data: any = await response.json();
  if (!data.mId) {
    return redirect("/jobs/submit");
  }
  const { job_id } = await createJob(client, { ...aData });
  return redirect(`/jobs/${job_id}`);
};
