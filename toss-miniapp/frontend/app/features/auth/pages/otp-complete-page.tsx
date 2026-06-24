import { LoaderCircle } from "lucide-react";
import type { Route } from "./+types/otp-complete-page";
import { Form, redirect, useNavigation, useSearchParams } from "react-router";
import { z } from "zod";
import InputPair from "~/common/components/input-pair";
import { Button } from "~/common/components/ui/button";
import { makeSSRClient } from "~/supa-client";

export const meta: Route.MetaFunction = () => {
  return [{ title: "Verify OTP | wemake" }];
};

const formSchema = z.object({
  phone: z.string(),
  otp: z.string().min(6).max(6),
});

export const action = async ({ request }: Route.ActionArgs) => {
  const formData = await request.formData();
  const { data, success, error } = formSchema.safeParse(
    Object.fromEntries(formData)
  );
  if (!success) {
    return { fieldErrors: error.flatten().fieldErrors };
  }
  const { phone, otp } = data;
  const { client, headers } = makeSSRClient(request);

  const { error: verifyError } = await client.auth.verifyOtp({
    phone,
    token: otp,
    type: "sms",
  });
  if (verifyError) {
    return { verifyError: verifyError.message };
  }
  return redirect("/", { headers });
};

export default function OtpPage({ actionData }: Route.ComponentProps) {
  const [searchParams] = useSearchParams();
  const phone = searchParams.get("phone");
  const navigation = useNavigation();
  const isSubmitting =
    navigation.state === "submitting" || navigation.state === "loading";
  return (
    <div className="flex flex-col relative items-center justify-center h-full">
      <div className="flex items-center flex-col justify-center w-full max-w-md gap-10">
        <div className="text-center">
          <h1 className="text-2xl font-semibold">Confirm OTP</h1>
          <p className="text-sm text-muted-foreground">
            Enter the OTP code sent to your email address.
          </p>
        </div>
        <Form className="w-full space-y-4" method="post">
          <InputPair
            label="Phone"
            description="Enter your phone number"
            name="phone"
            defaultValue={phone || ""}
            id="phone"
            required
            type="tel"
            placeholder="i.e 1234567890"
          />
          {actionData && "fieldErrors" in actionData && (
            <p className="text-sm text-red-500">
              {actionData.fieldErrors?.phone?.join(", ")}
            </p>
          )}
          <InputPair
            label="OTP"
            description="Enter the OTP code sent to your email address"
            name="otp"
            id="otp"
            required
            type="number"
            placeholder="i.e 1234"
          />
          {actionData && "fieldErrors" in actionData && (
            <p className="text-sm text-red-500">
              {actionData.fieldErrors?.otp?.join(", ")}
            </p>
          )}
          {actionData && "verifyError" in actionData && (
            <p className="text-sm text-red-500">{actionData.verifyError}</p>
          )}
          <Button className="w-full" type="submit" disabled={isSubmitting}>
            {isSubmitting ? (
              <LoaderCircle className="animate-spin" />
            ) : (
              "Verify OTP"
            )}
          </Button>
        </Form>
      </div>
    </div>
  );
}
