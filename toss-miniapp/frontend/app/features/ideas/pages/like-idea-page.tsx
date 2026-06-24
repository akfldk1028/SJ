import { makeSSRClient } from "~/supa-client";
import type { Route } from "./+types/like-idea-page";
import { getLoggedInUserId } from "~/features/users/queries";
import { toggleIdeaLike } from "../mutations";

export async function action({ request, params }: Route.ActionArgs) {
  const { client } = makeSSRClient(request);
  const loggedInUserId = await getLoggedInUserId(client);
  await toggleIdeaLike(client, {
    userId: loggedInUserId,
    ideaId: params.ideaId,
  });
  return {
    ok: true,
  };
}
