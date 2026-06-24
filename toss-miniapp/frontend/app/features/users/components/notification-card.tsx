import {
  Card,
  CardFooter,
  CardHeader,
  CardTitle,
} from "~/common/components/ui/card";
import {
  Avatar,
  AvatarFallback,
  AvatarImage,
} from "~/common/components/ui/avatar";
import { Button } from "~/common/components/ui/button";
import { EyeIcon } from "lucide-react";
import { cn } from "~/lib/utils";
import { Link, useFetcher } from "react-router";

interface NotificationCardProps {
  avatarUrl: string;
  avatarFallback: string;
  userName: string;
  type: "follow" | "review" | "reply";
  timestamp: string;
  seen: boolean;
  productName?: string;
  payloadId?: number;
  postTitle?: string;
  id: number;
}

export function NotificationCard({
  type,
  avatarUrl,
  avatarFallback,
  userName,
  timestamp,
  seen,
  productName,
  postTitle,
  payloadId,
  id,
}: NotificationCardProps) {
  const getMessage = (type: "follow" | "review" | "reply") => {
    switch (type) {
      case "follow":
        return " followed you.";
      case "review":
        return " reviewed your product: ";
      case "reply":
        return " replied to your post: ";
    }
  };
  const fetcher = useFetcher();
  const optimiscitSeen = fetcher.state === "idle" ? seen : true;
  return (
    <Card
      className={cn(
        "md:min-w-[500px] max-w-[500px] w-full",
        optimiscitSeen ? "" : "border border-yellow-400"
      )}
    >
      <CardHeader className="flex flex-row gap-5 space-y-0 ">
        <Avatar className="">
          <AvatarImage src={avatarUrl} />
          <AvatarFallback>{avatarFallback}</AvatarFallback>
        </Avatar>
        <div className="overflow-hidden whitespace-nowrap overflow-ellipsis">
          <CardTitle className="text-lg space-y-0 font-bold flex flex-col flex-wrap items-start w-full">
            <div>
              <span>{userName}</span>
              <span>{getMessage(type)}</span>
            </div>
            {productName && (
              <Button
                variant={"link"}
                asChild
                className="text-lg p-0 text-white "
              >
                <Link to={`/products/${payloadId}`}>{productName}</Link>
              </Button>
            )}
            {postTitle && (
              <Button
                variant={"link"}
                asChild
                className="text-lg p-0 text-white "
              >
                <Link to={`/community/${payloadId}`}>{postTitle}</Link>
              </Button>
            )}
          </CardTitle>
          <small className="text-muted-foreground text-sm">{timestamp}</small>
        </div>
      </CardHeader>
      {optimiscitSeen ? null : (
        <CardFooter className="flex justify-end pt-0">
          <fetcher.Form method="post" action={`/my/notifications/${id}/see`}>
            <Button variant="outline" size="icon">
              <EyeIcon className="w-4 h-4" />
            </Button>
          </fetcher.Form>
        </CardFooter>
      )}
    </Card>
  );
}
