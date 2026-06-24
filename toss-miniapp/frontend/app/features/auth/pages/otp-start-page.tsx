import { Button } from "~/common/components/ui/button";
import type { Route } from "./+types/otp-start-page";
import { Form, redirect, useNavigation } from "react-router";
import InputPair from "~/common/components/input-pair";
import { z } from "zod";
import { makeSSRClient } from "~/supa-client";
import { LoaderCircle } from "lucide-react";

export const meta: Route.MetaFunction = () => {
  return [{ title: "Start OTP | wemake" }];
};

const formSchema = z.object({
  phone: z.string(),
});

export const action = async ({ request }: Route.ActionArgs) => {
  return {
    error: "OTP is disabled for this demo.",
  };
};

export default function OtpStartPage({ actionData }: Route.ComponentProps) {
  const navigation = useNavigation();
  const isSubmitting =
    navigation.state === "submitting" || navigation.state === "loading";
  return (
    <div className="flex flex-col relative items-center justify-center h-full">
      <div className="flex items-center flex-col justify-center w-full max-w-md gap-10">
        <div className="text-center">
          <h1 className="text-2xl font-semibold">Log in with OTP</h1>
          <p className="text-sm text-muted-foreground">
            We will send you a 6-digit code to log in to your account.
          </p>
        </div>
        <Form className="w-full space-y-4" method="post">
          <InputPair
            label="Phone"
            description="Enter your phone number"
            name="phone"
            id="phone"
            required
            type="tel"
            placeholder="i.e 1234567890"
          />
          {actionData && "error" in actionData && (
            <p className="text-red-500 text-sm">{actionData.error}</p>
          )}
          <Button className="w-full" type="submit" disabled={isSubmitting}>
            {isSubmitting ? (
              <LoaderCircle className="animate-spin" />
            ) : (
              "Send OTP"
            )}
          </Button>
        </Form>
      </div>
    </div>
  );
}
