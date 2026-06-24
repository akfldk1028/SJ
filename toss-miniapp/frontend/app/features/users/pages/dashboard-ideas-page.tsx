import { IdeaCard } from "~/features/ideas/components/idea-card";
import type { Route } from "./+types/dashboard-ideas-page";
import { makeSSRClient } from "~/supa-client";
import { getLoggedInUserId } from "../queries";
import { getClaimedIdeas } from "~/features/ideas/queries";
import { LightbulbOffIcon } from "lucide-react";
import { Button } from "~/common/components/ui/button";
import { Link } from "react-router";

export const meta: Route.MetaFunction = () => {
  return [{ title: "My Ideas | wemake" }];
};

export const loader = async ({ request }: Route.LoaderArgs) => {
  const { client } = makeSSRClient(request);
  const userId = await getLoggedInUserId(client);
  const ideas = await getClaimedIdeas(client, { userId });
  return { ideas };
};

export default function DashboardIdeasPage({
  loaderData,
}: Route.ComponentProps) {
  return (
    <div className="space-y-5 w-full h-full">
      {loaderData.ideas.length > 0 && (
        <h1 className="text-2xl font-semibold mb-6">Claimed Ideas</h1>
      )}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {loaderData.ideas.map((idea) => (
          <IdeaCard
            key={idea.gpt_idea_id}
            id={idea.gpt_idea_id}
            title={idea.idea}
            owner
            claimed
          />
        ))}
        {loaderData.ideas.length === 0 && (
          <div className="col-span-full flex flex-col text-muted-foreground items-center justify-center gap-5">
            <LightbulbOffIcon className="size-10" />
            <p className=" text-center font-semibold ">
              You have not claimed any ideas yet. Your claimed ideas will appear
              here.
            </p>
            <Button asChild variant={"secondary"}>
              <Link to="/ideas">Explore ideas &rarr;</Link>
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}
