import { Link, useOutletContext } from "react-router";
import type { Route } from "./+types/profile-page";
import { makeAdminClient } from "~/supa-client";
import { Button } from "~/common/components/ui/button";

export const loader = async ({ params }: Route.LoaderArgs) => {
  const adminClient = makeAdminClient();
  await adminClient.rpc("track_event", {
    event_type: "profile_view",
    event_data: {
      username: params.username,
    },
  });
  return null;
};

export default function ProfilePage() {
  const { headline, bio } = useOutletContext<{
    headline: string;
    bio: string;
  }>();
  return (
    <div className="max-w-screen-md flex flex-col space-y-10">
      <div className="space-y-2">
        <h4 className="text-lg font-bold">Headline</h4>
        {headline ? (
          <p className="text-muted-foreground">{headline}</p>
        ) : (
          <p className="text-muted-foreground">
            Go to{" "}
            <Button variant={"link"} asChild className="p-0 text-base">
              <Link to="/my/settings">settings</Link>
            </Button>{" "}
            to add a headline to your profile.
          </p>
        )}
      </div>
      <div className="space-y-2">
        <h4 className="text-lg font-bold">Bio</h4>
        {bio ? (
          <p className="text-muted-foreground">{bio}</p>
        ) : (
          <p className="text-muted-foreground">
            Go to{" "}
            <Button variant={"link"} asChild className="p-0 text-base">
              <Link to="/my/settings">settings</Link>
            </Button>{" "}
            to add a bio to your profile.
          </p>
        )}
      </div>
    </div>
  );
}
