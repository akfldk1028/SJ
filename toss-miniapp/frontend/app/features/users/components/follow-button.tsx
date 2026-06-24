import type { Variable } from "lucide-react";
import { Link, useFetcher, useOutletContext } from "react-router";
import { Button, type ButtonProps } from "~/common/components/ui/button";

interface FollowButtonProps {
  username: string;
  isFollowing: boolean;
  variant?: ButtonProps["variant"];
}

export function FollowButton({
  username,
  isFollowing,
  variant = "outline",
}: FollowButtonProps) {
  const fetcher = useFetcher();
  const { isLoggedIn } = useOutletContext<{
    isLoggedIn: boolean;
  }>();
  const optimisitcIsFollowing =
    fetcher.state === "idle" ? isFollowing : !isFollowing;
  if (!isLoggedIn) {
    return (
      <Button variant="outline" className="w-full" asChild>
        <Link to="/auth/login">Log in to follow</Link>
      </Button>
    );
  }
  return (
    <fetcher.Form method="post" action={`/users/${username}/follow`}>
      <Button variant={variant} className="w-full">
        {optimisitcIsFollowing ? "Unfollow" : "Follow"}
      </Button>
    </fetcher.Form>
  );
}
