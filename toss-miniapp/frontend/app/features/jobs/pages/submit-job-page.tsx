import { Hero } from "~/common/components/hero";
import type { Route } from "./+types/submit-job-page";
import { useOutletContext } from "react-router";
import InputPair from "~/common/components/input-pair";
import SelectPair from "~/common/components/select-pair";
import { JOB_TYPES, LOCATION_TYPES, SALARY_RANGE } from "../constants";
import { Button, buttonVariants } from "~/common/components/ui/button";
import { makeSSRClient } from "~/supa-client";
import { getLoggedInUserId } from "~/features/users/queries";
import { useEffect, useRef, useState } from "react";
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogFooter,
  DialogHeader,
} from "~/common/components/ui/dialog";
import { cn } from "~/lib/utils";
import {
  loadTossPayments,
  type TossPaymentsWidgets,
} from "@tosspayments/tosspayments-sdk";

export const meta: Route.MetaFunction = () => {
  return [
    { title: "Post a Job | wemake" },
    {
      name: "description",
      content: "Reach out to the best developers in the world",
    },
  ];
};

export const loader = async ({ request }: Route.LoaderArgs) => {
  const { client } = makeSSRClient(request);
  await getLoggedInUserId(client);
};

export default function SubmitJobPage() {
  const [isOpen, setIsOpen] = useState(false);
  const widgets = useRef<TossPaymentsWidgets | null>(null);
  const form = useRef<HTMLFormElement>(null);
  const [formData, setFormData] = useState<FormData | null>(null);
  useEffect(() => {
    if (isOpen) {
      const initToss = async () => {
        const toss = await loadTossPayments(
          "test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm"
        );
        widgets.current = await toss.widgets({
          customerKey: "1111111",
        });
        await widgets.current.setAmount({
          value: 100000,
          currency: "KRW",
        });
        await widgets.current.renderPaymentMethods({
          selector: "#toss-payment-methods",
        });
        await widgets.current.renderAgreement({
          selector: "#toss-payment-agreement",
        });
      };
      initToss();
    }
  }, [isOpen]);
  const onSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    if (!form.current) return;
    e.preventDefault();
    setIsOpen(true);
    const formData = new FormData(form.current!);
    setFormData(formData);
  };
  const { email, name } = useOutletContext<{ email: string; name: string }>();
  const requestPayment = async () => {
    if (!formData) return;
    // Convert FormData to URLSearchParams
    const params = new URLSearchParams();
    for (const [key, value] of formData.entries()) {
      params.append(key, value.toString());
    }

    await widgets.current?.requestPayment({
      orderId: crypto.randomUUID(),
      orderName: `WeMake Post Job`,
      customerEmail: email ?? "nico@nomadcoders.co",
      customerName: name ?? "Nico",
      customerMobilePhone: "01012345678",
      metadata: {
        ok: true,
      },
      successUrl: `${window.location.href}/success?${params.toString()}`,
      failUrl: `${window.location.href}/fail`,
    });
  };
  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <div>
        <Hero
          title="Post a Job"
          subtitle="Reach out to the best developers in the world"
        />
        <form
          className="max-w-screen-2xl flex flex-col items-center gap-10 mx-auto"
          method="post"
          ref={form}
          onSubmit={onSubmit}
        >
          <div className="grid grid-cols-1 md:grid-cols-3 w-full gap-10">
            <InputPair
              label="Position"
              description="(40 characters max)"
              name="position"
              maxLength={40}
              type="text"
              id="position"
              required
              defaultValue="Senior React Developer"
            />

            <InputPair
              id="overview"
              label="Overview"
              description="(400 characters max)"
              name="overview"
              maxLength={400}
              type="text"
              required
              defaultValue="We are looking for a Senior React Developer"
              textArea
            />

            <InputPair
              id="responsibilities"
              label="Responsibilities"
              description="(400 characters max, comma separated)"
              name="responsibilities"
              maxLength={400}
              type="text"
              required
              defaultValue="Implement new features, Maintain code quality, etc."
              textArea
            />

            <InputPair
              id="qualifications"
              label="Qualifications"
              description="(400 characters max, comma separated)"
              name="qualifications"
              maxLength={400}
              type="text"
              required
              defaultValue="3+ years of experience, Strong TypeScript skills, etc."
              textArea
            />

            <InputPair
              id="benefits"
              label="Benefits"
              description="(400 characters max, comma separated)"
              name="benefits"
              maxLength={400}
              type="text"
              required
              defaultValue="Flexible working hours, Health insurance, etc."
              textArea
            />

            <InputPair
              id="skills"
              label="Skills"
              description="(400 characters max, comma separated)"
              name="skills"
              maxLength={400}
              type="text"
              required
              defaultValue="React, TypeScript, etc."
              textArea
            />

            <InputPair
              id="companyName"
              label="Company Name"
              description="(40 characters max)"
              name="companyName"
              maxLength={40}
              type="text"
              required
              defaultValue="wemake"
            />

            <InputPair
              id="companyLogoUrl"
              label="Company Logo URL"
              description="(40 characters max)"
              name="companyLogoUrl"
              type="url"
              required
              defaultValue="https://wemake.services/logo.png"
            />

            <InputPair
              id="companyLocation"
              label="Company Location"
              description="(40 characters max)"
              name="companyLocation"
              maxLength={40}
              type="text"
              required
              defaultValue="Remote, New York, etc."
            />

            <InputPair
              id="applyUrl"
              label="Apply URL"
              description="(40 characters max)"
              name="applyUrl"
              maxLength={40}
              type="url"
              required
              defaultValue="https://wemake.services/apply"
            />

            <SelectPair
              label="Job Type"
              description="Select the type of job"
              name="jobType"
              required
              placeholder="Select the type of job"
              options={JOB_TYPES.map((type) => ({
                label: type.label,
                value: type.value,
              }))}
            />

            <SelectPair
              label="Job Location"
              description="Select the location of the job"
              name="jobLocation"
              required
              placeholder="Select the location of the job"
              options={LOCATION_TYPES.map((location) => ({
                label: location.label,
                value: location.value,
              }))}
            />

            <SelectPair
              label="Salary Range"
              description="Select the salary range of the job"
              name="salaryRange"
              required
              placeholder="Select the salary range of the job"
              options={SALARY_RANGE.map((salary) => ({
                label: salary,
                value: salary,
              }))}
            />
          </div>
          <Button className={cn("w-full cursor-pointer max-w-sm")}>
            Post job for $100
          </Button>
        </form>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Post a Job</DialogTitle>
          </DialogHeader>
          <div>
            Post a job for $100
            <div className="mt-10 rounded-lg overflow-hidden bg-white">
              <div id="toss-payment-methods" />
              <div id="toss-payment-agreement" />
            </div>
          </div>
          <DialogFooter>
            <Button onClick={requestPayment} size="lg" type="button">
              Post now for $100
            </Button>
          </DialogFooter>
        </DialogContent>
      </div>
    </Dialog>
  );
}
