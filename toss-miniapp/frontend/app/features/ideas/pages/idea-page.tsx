import { DotIcon } from "lucide-react";
import { EyeIcon } from "lucide-react";
import { Hero } from "~/common/components/hero";
import { Button } from "~/common/components/ui/button";
import type { Route } from "./+types/idea-page";
import { getGptIdea } from "../queries";
import { DateTime } from "luxon";
import { makeSSRClient } from "~/supa-client";
import { redirect, useOutletContext } from "react-router";
import { LikeButton } from "../components/like-button";
import { Dialog } from "@radix-ui/react-dialog";
import { DialogHeader, DialogTitle } from "~/common/components/ui/dialog";
import {
  DialogContent,
  DialogFooter,
  DialogTrigger,
} from "~/common/components/ui/dialog";
import {
  loadTossPayments,
  type TossPaymentsWidgets,
} from "@tosspayments/tosspayments-sdk";
import { useEffect, useRef, useState } from "react";
import { getLoggedInUserId } from "~/features/users/queries";

export const meta = ({
  data: {
    idea: { gpt_idea_id, idea },
  },
}: Route.MetaArgs) => {
  return [
    { title: `Idea #${gpt_idea_id}: ${idea} | wemake` },
    { name: "description", content: "Find ideas for your next project" },
  ];
};

export const loader = async ({ request, params }: Route.LoaderArgs) => {
  const { client } = makeSSRClient(request);
  await getLoggedInUserId(client);
  const [idea, _] = await Promise.all([
    getGptIdea(client, { ideaId: params.ideaId }),
    client.rpc("track_idea_view", { p_idea_id: Number(params.ideaId) }),
  ]);
  if (idea.is_claimed) {
    throw redirect(`/ideas`);
  }
  return { idea };
};

export default function IdeaPage({ loaderData }: Route.ComponentProps) {
  const widgets = useRef<TossPaymentsWidgets | null>(null);
  const { email, name } = useOutletContext<{
    email?: string;
    name?: string;
  }>();
  const [isOpen, setIsOpen] = useState(false);
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

  const claimIdea = async () => {
    await widgets.current?.requestPayment({
      orderId: crypto.randomUUID(),
      orderName: `WeMake Claim Idea #${loaderData.idea.gpt_idea_id}`,
      customerEmail: email ?? "nico@nomadcoders.co",
      customerName: name ?? "Nico",
      customerMobilePhone: "01012345678",
      metadata: {
        ideaId: loaderData.idea.gpt_idea_id,
      },
      successUrl: `${window.location.href}/claim/success`,
      failUrl: `${window.location.href}/claim/fail`,
    });
  };
  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <div>
        <Hero title={`Idea #${loaderData.idea.gpt_idea_id}`} />
        <div className="max-w-screen-sm mx-auto flex flex-col items-center gap-10">
          <p className="italic text-center">"{loaderData.idea.idea}"</p>
          <div className="flex items-center text-sm">
            <div className="flex items-center gap-1">
              <EyeIcon className="w-4 h-4" />
              <span>{loaderData.idea.views}</span>
            </div>
            <DotIcon className="w-4 h-4" />
            <span>
              {DateTime.fromISO(loaderData.idea.created_at, {
                zone: "utc",
              }).toRelative()}
            </span>
            <DotIcon className="w-4 h-4" />
            <LikeButton
              ideaId={loaderData.idea.gpt_idea_id}
              likesCount={loaderData.idea.likes}
              isLiked={loaderData.idea.is_liked}
            />
          </div>
          {loaderData.idea.is_claimed ? null : (
            <DialogTrigger asChild>
              <Button size="lg">Claim idea</Button>
            </DialogTrigger>
          )}
        </div>
      </div>
      <DialogContent className="p-2.5 md:p-6">
        <DialogHeader className="hidden">
          <DialogTitle>Claim idea</DialogTitle>
        </DialogHeader>
        <div>
          <span className="hidden">
            Claim this idea and make it private for $100
          </span>
          <div className="md:mt-10 rounded-lg overflow-hidden bg-white">
            <div id="toss-payment-methods" />
            <div id="toss-payment-agreement" />
          </div>
        </div>
        <DialogFooter>
          <Button size="lg" onClick={claimIdea}>
            Claim now for $100
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
