import { Link, useFetcher, useNavigate, useOutletContext } from "react-router";
import {
  Card,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "~/common/components/ui/card";
import { Button } from "~/common/components/ui/button";
import { ChevronUpIcon, EyeIcon, MessageCircleIcon } from "lucide-react";
import { cn } from "~/lib/utils";
import { NeonGradientCard } from "~/common/components/ui/neon-gradient-card";
import { Badge } from "~/common/components/ui/badge";

interface ProductCardProps {
  id: number | string;
  name: string;
  description: string;
  reviewsCount: string | number;
  viewsCount: string | number;
  votesCount: string | number;
  isUpvoted: boolean;
  promotedFrom: string | null;
}

export function ProductCard({
  id,
  name,
  description,
  reviewsCount,
  viewsCount,
  votesCount,
  isUpvoted,
  promotedFrom,
}: ProductCardProps) {
  const fetcher = useFetcher();
  const { isLoggedIn } = useOutletContext<{
    isLoggedIn: boolean;
  }>();
  const navigate = useNavigate();
  const optimisitcVotesCount =
    fetcher.state === "idle"
      ? votesCount
      : isUpvoted
        ? Number(votesCount) - 1
        : Number(votesCount) + 1;
  const optimisitcIsUpvoted = fetcher.state === "idle" ? isUpvoted : !isUpvoted;
  const absorbClick = (e: React.MouseEvent<HTMLButtonElement>) => {
    e.preventDefault();
    if (!isLoggedIn) {
      alert("Please log in first!");
      navigate("/auth/login");
      return;
    }
    fetcher.submit(null, {
      method: "POST",
      action: `/products/${id}/upvote`,
    });
  };
  const content = (
    <Link to={`/products/${id}`} className="block relative z-10">
      <Card
        className={cn(
          "w-full flex items-center justify-between",
          promotedFrom ? "" : "bg-transparent hover:bg-card/50"
        )}
      >
        <CardHeader className="w-full">
          <CardTitle className="text-2xl flex-wrap font-semibold leading-none flex justify-between w-full items-center gap-2 tracking-tight">
            {name}{" "}
            {promotedFrom ? <Badge variant={"outline"}>Promoted</Badge> : null}
          </CardTitle>
          <CardDescription className="text-muted-foreground">
            {description}
          </CardDescription>
          <div className="flex items-center gap-4 mt-2">
            <div className="flex items-center gap-px text-xs text-muted-foreground">
              <MessageCircleIcon className="w-4 h-4" />
              <span>{reviewsCount}</span>
            </div>
            <div className="flex items-center gap-px text-xs text-muted-foreground">
              <EyeIcon className="w-4 h-4" />
              <span>{viewsCount}</span>
            </div>
          </div>
        </CardHeader>
        <CardFooter className="py-0">
          <Button
            variant="outline"
            className={cn(
              optimisitcIsUpvoted && "border-primary text-primary",
              "flex flex-col h-14"
            )}
            onClick={absorbClick}
          >
            <ChevronUpIcon className="size-4 shrink-0" />
            <span>{optimisitcVotesCount}</span>
          </Button>
        </CardFooter>
      </Card>
    </Link>
  );
  return promotedFrom ? (
    <NeonGradientCard
      borderRadius={12}
      className="dark"
      borderSize={1}
      neonColors={{
        firstColor: "#fc4a1a",
        secondColor: "#f7b733",
      }}
    >
      {content}
    </NeonGradientCard>
  ) : (
    content
  );
}
