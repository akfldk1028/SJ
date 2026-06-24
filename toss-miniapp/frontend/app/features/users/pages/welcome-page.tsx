import { Resend } from "resend";
import { render } from "@react-email/components";
import { WelcomeUser } from "react-email-starter/emails/welcome-user";
import type { Route } from "./+types/welcome-page";
import { redirect } from "react-router-dom";

export const loader = async ({ params }: Route.LoaderArgs) => {
  const client = new Resend(process.env.RESEND_API_KEY);
  return redirect("/");
};
