import { StarIcon } from "lucide-react";
import { ChevronUpIcon } from "lucide-react";
import {
  Link,
  NavLink,
  Outlet,
  useFetcher,
  useOutletContext,
} from "react-router";
import { Button, buttonVariants } from "~/common/components/ui/button";
import { cn } from "~/lib/utils";
import type { Route } from "./+types/product-overview-layout";
import { getProductById } from "../queries";
import { makeSSRClient } from "~/supa-client";

export function meta({ data }: Route.MetaArgs) {
  return [
    { title: `${data.product.name} Overview | wemake` },
    { name: "description", content: "View product details and information" },
  ];
}

export const loader = async ({
  request,
  params,
}: Route.LoaderArgs & { params: { productId: string } }) => {
  const { client, headers } = makeSSRClient(request);
  const product = await getProductById(client, {
    productId: params.productId,
  });
  return { product };
};

export default function ProductOverviewLayout({
  loaderData,
}: Route.ComponentProps) {
  const fetcher = useFetcher();
  const { isLoggedIn } = useOutletContext<{ isLoggedIn: boolean }>();
  return (
    <div className="space-y-10">
      <div className="flex flex-col md:flex-row gap-10 md:gap-0 justify-between">
        <div className="flex flex-col items-center md:items-start md:flex-row gap-10">
          <div className="size-40 rounded-xl overflow-hidden shadow-xl bg-primary/50">
            <img
              src={loaderData.product.icon}
              alt={loaderData.product.name}
              className="size-full object-cover"
            />
          </div>
          <div>
            <h1 className="text-5xl text-center md:text-left font-bold">
              {loaderData.product.name}
            </h1>
            <p className=" text-2xl font-light text-center md:text-left">
              {loaderData.product.tagline}
            </p>
            <div className="mt-5 flex md:justify-start text-lg md:text-base justify-center items-center gap-2">
              <div className="flex text-yellow-400">
                {Array.from({ length: 5 }).map((_, i) => (
                  <StarIcon
                    key={i}
                    className="size-4"
                    fill={
                      i < Math.floor(loaderData.product.average_rating)
                        ? "currentColor"
                        : "none"
                    }
                  />
                ))}
              </div>
              <span className="text-muted-foreground ">
                {loaderData.product.reviews} reviews
              </span>
            </div>
          </div>
        </div>
        <div className="flex flex-col md:flex-row md:gap-5 gap-2.5">
          <Button
            variant={"secondary"}
            size="lg"
            asChild
            className="md:text-lg w-full md:w-auto h-10 md:h-14 px-10"
          >
            <Link to={`/products/${loaderData.product.product_id}/visit`}>
              Visit Website
            </Link>
          </Button>
          <fetcher.Form
            method="post"
            action={`/products/${loaderData.product.product_id}/upvote`}
          >
            <Button
              size="lg"
              className={cn({
                "md:text-lg w-full md:w-auto h-10 md:h-14 px-10 flex items-center gap-2":
                  true,
                "border-white bg-white text-primary hover:bg-white/90":
                  loaderData.product.is_upvoted,
              })}
            >
              <ChevronUpIcon className="size-4" />
              Upvote ({loaderData.product.upvotes})
            </Button>
          </fetcher.Form>
        </div>
      </div>
      <div className="flex gap-2.5">
        <NavLink
          end
          className={({ isActive }) =>
            cn(
              buttonVariants({ variant: "outline" }),
              isActive && "bg-accent text-foreground "
            )
          }
          to={`/products/${loaderData.product.product_id}/overview`}
        >
          Overview
        </NavLink>
        <NavLink
          className={({ isActive }) =>
            cn(
              buttonVariants({ variant: "outline" }),
              isActive && "bg-accent text-foreground "
            )
          }
          to={`/products/${loaderData.product.product_id}/reviews`}
        >
          Reviews
        </NavLink>
      </div>
      <div>
        <Outlet
          context={{
            product_id: loaderData.product.product_id,
            description: loaderData.product.description,
            how_it_works: loaderData.product.how_it_works,
            review_count: loaderData.product.reviews,
            isLoggedIn: isLoggedIn,
          }}
        />
      </div>
    </div>
  );
}
