import { HeartIcon } from "lucide-react";
import { useState } from "react";
import { Link, useFetcher, useOutletContext } from "react-router";
import { Button } from "~/common/components/ui/button";

export function LikeButton({
  ideaId,
  likesCount,
  isLiked,
}: {
  ideaId: number;
  likesCount: number;
  isLiked: boolean;
}) {
  const { isLoggedIn } = useOutletContext<{
    isLoggedIn: boolean;
  }>();
  const fetcher = useFetcher();
  const [optimisticIsLiked, setOptimisticIsLiked] = useState(isLiked);
  const [optimisticLikesCount, setOptimisticLikesCount] = useState(likesCount);
  const onSubmit = () => {
    setOptimisticIsLiked((prev) => !prev);
    setOptimisticLikesCount(
      optimisticIsLiked ? optimisticLikesCount - 1 : optimisticLikesCount + 1
    );
  };
  if (!isLoggedIn) {
    return (
      <Button variant="outline" asChild>
        <Link to="/auth/login">
          <HeartIcon className="w-4 h-4" />
          <span>{optimisticLikesCount}</span>
        </Link>
      </Button>
    );
  }

  return (
    <fetcher.Form
      method="post"
      action={`/ideas/${ideaId}/like`}
      onSubmit={onSubmit}
    >
      <Button
        variant="outline"
        className={optimisticIsLiked ? "border-primary text-primary" : ""}
      >
        <HeartIcon
          fill={optimisticIsLiked ? "currentColor" : "none"}
          className="w-4 h-4"
        />
        <span>{optimisticLikesCount}</span>
      </Button>
    </fetcher.Form>
  );
}

export const shouldRevalidate = () => false;
