import {
  Form,
  Link,
  NavLink,
  Outlet,
  useNavigation,
  useOutletContext,
} from "react-router";
import {
  Avatar,
  AvatarFallback,
  AvatarImage,
} from "~/common/components/ui/avatar";
import { Badge } from "~/common/components/ui/badge";
import { Button, buttonVariants } from "~/common/components/ui/button";
import {
  Dialog,
  DialogDescription,
  DialogHeader,
  DialogContent,
  DialogTrigger,
  DialogTitle,
} from "~/common/components/ui/dialog";
import { Textarea } from "~/common/components/ui/textarea";
import { cn } from "~/lib/utils";
import type { Route } from "./+types/profile-layout";
import { getUserProfile } from "../queries";
import { makeSSRClient } from "~/supa-client";
import { FollowButton } from "../components/follow-button";

export const meta: Route.MetaFunction = ({ data }) => {
  return [{ title: `${data.user.name} | wemake` }];
};

export const loader = async ({
  request,
  params,
}: Route.LoaderArgs & { params: { username: string } }) => {
  const { client } = makeSSRClient(request);
  const user = await getUserProfile(client, {
    username: params.username,
  });
  return { user };
};

export default function ProfileLayout({
  loaderData,
  params,
}: Route.ComponentProps & { params: { username: string } }) {
  const { isLoggedIn, username } = useOutletContext<{
    isLoggedIn: boolean;
    username?: string;
  }>();
  const navigation = useNavigation();
  return (
    <div className="space-y-10">
      <div className="flex flex-col md:flex-row items-center gap-4">
        <Avatar className="size-40">
          {loaderData.user.avatar ? (
            <AvatarImage src={loaderData.user.avatar} />
          ) : (
            <AvatarFallback className="text-2xl">
              {loaderData.user.name[0]}
            </AvatarFallback>
          )}
        </Avatar>
        <div className="space-y-5">
          <div className="flex flex-wrap gap-2">
            <h1 className="text-2xl w-full md:w-fit font-semibold">
              {loaderData.user.name}
            </h1>
            {isLoggedIn && username === params.username ? (
              <Button variant="outline" asChild>
                <Link to="/my/settings">Edit profile</Link>
              </Button>
            ) : null}
            {isLoggedIn && username !== params.username ? (
              <>
                <FollowButton
                  username={params.username}
                  isFollowing={loaderData.user.is_following}
                  variant="secondary"
                />
                <Dialog>
                  <DialogTrigger asChild>
                    <Button variant="secondary">Message</Button>
                  </DialogTrigger>
                  <DialogContent>
                    <DialogHeader>
                      <DialogTitle>Message</DialogTitle>
                    </DialogHeader>
                    <DialogDescription className="space-y-4" asChild>
                      <Form
                        method="post"
                        action={`/users/${loaderData.user.username}/messages`}
                      >
                        <span className="text-sm text-muted-foreground">
                          Send a message to John Doe
                        </span>
                        <div className="space-y-4">
                          <Textarea
                            placeholder="Message"
                            className="resize-none"
                            name="content"
                            rows={4}
                          />
                          <Button
                            type="submit"
                            disabled={navigation.state === "submitting"}
                          >
                            {navigation.state === "submitting"
                              ? "Sending..."
                              : "Send"}
                          </Button>
                        </div>
                      </Form>
                    </DialogDescription>
                  </DialogContent>
                </Dialog>
              </>
            ) : null}
          </div>
          <div className="flex flex-wrap gap-2 items-center">
            <span className="text-sm text-muted-foreground">
              @{loaderData.user.username}
            </span>
            <Badge variant={"secondary"} className="capitalize">
              {loaderData.user.role}
            </Badge>
            <Badge variant={"secondary"}>
              {loaderData.user.followers} followers
            </Badge>
            <Badge variant={"secondary"}>
              {loaderData.user.following} following
            </Badge>
          </div>
        </div>
      </div>
      <div className="flex justify-center md:justify-start w-full gap-5">
        {[
          { label: "About", to: `/users/${loaderData.user.username}` },
          {
            label: "Products",
            to: `/users/${loaderData.user.username}/products`,
          },
          { label: "Posts", to: `/users/${loaderData.user.username}/posts` },
        ].map((item) => (
          <NavLink
            end
            key={item.label}
            className={({ isActive }) =>
              cn(
                buttonVariants({ variant: "outline" }),
                isActive && "bg-accent text-foreground "
              )
            }
            to={item.to}
          >
            {item.label}
          </NavLink>
        ))}
      </div>
      <div className="max-w-screen-md">
        <Outlet
          context={{
            headline: loaderData.user.headline,
            bio: loaderData.user.bio,
          }}
        />
      </div>
    </div>
  );
}
