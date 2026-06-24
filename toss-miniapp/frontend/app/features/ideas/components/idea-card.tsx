import { Link } from "react-router";
import {
  Card,
  CardContent,
  CardFooter,
  CardHeader,
  CardTitle,
} from "~/common/components/ui/card";
import { Button } from "~/common/components/ui/button";
import { DotIcon, EyeIcon, HeartIcon, LockIcon } from "lucide-react";
import { cn } from "~/lib/utils";
import { DateTime } from "luxon";
import { LikeButton } from "./like-button";

interface IdeaCardProps {
  id: number;
  title: string;
  owner?: boolean;
  viewsCount?: number;
  postedAt?: string;
  likesCount?: number;
  claimed?: boolean;
  isLiked?: boolean;
}

export function IdeaCard({
  id,
  title,
  owner,
  viewsCount,
  postedAt,
  likesCount,
  claimed,
  isLiked,
}: IdeaCardProps) {
  return (
    <Card className="bg-transparent hover:bg-card/50 transition-colors flex flex-col justify-between">
      <CardHeader>
        {claimed && !owner ? (
          <CardTitle className="text-xl">
            <span
              className={cn(
                claimed
                  ? "bg-muted-foreground break-all selection:bg-muted-foreground text-muted-foreground"
                  : ""
              )}
            >
              {title.length > 100 ? title.slice(0, 100) + "..." : title}
            </span>
          </CardTitle>
        ) : (
          <Link to={claimed || owner ? "" : `/ideas/${id}`}>
            <CardTitle className="text-xl">
              <span>
                {owner
                  ? title
                  : title.length > 100
                    ? title.slice(0, 100) + "..."
                    : title}
              </span>
            </CardTitle>
          </Link>
        )}
        {owner ? null : (
          <CardContent className="flex items-center text-sm pr-0 p-0">
            <div className="flex items-center gap-1">
              <EyeIcon className="w-4 h-4" />
              <span>{viewsCount}</span>
            </div>
            <DotIcon className="w-4 h-4" />
            {postedAt ? (
              <span>
                {DateTime.fromISO(postedAt, {
                  zone: "utc",
                }).toRelative()}
              </span>
            ) : null}
          </CardContent>
        )}
      </CardHeader>
      <CardFooter className="flex justify-end gap-2">
        {!claimed && !owner ? (
          <>
            {likesCount !== undefined ? (
              <LikeButton
                ideaId={id}
                likesCount={likesCount}
                isLiked={isLiked ?? false}
              />
            ) : null}
            <Button asChild>
              <Link to={`/ideas/${id}`}>Claim idea now &rarr;</Link>
            </Button>
          </>
        ) : (
          <Button variant="outline" disabled className="cursor-not-allowed">
            <LockIcon className="size-4" />
            Claimed
          </Button>
        )}
      </CardFooter>
    </Card>
  );
}
