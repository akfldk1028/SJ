import { makeSSRClient } from "~/supa-client";
import type { Route } from "./+types/follow-page";
import { getLoggedInUserId, getUserById, getUserProfile } from "../queries";
import { toggleFollow } from "../mutations";
import { data } from "react-router";

export async function action({
  request,
  params: { username },
}: Route.ActionArgs) {
  const { client } = makeSSRClient(request);
  const loggedInUserId = await getLoggedInUserId(client);
  const followerProfile = await getUserById(client, { id: loggedInUserId });
  if (username === followerProfile.username) {
    return data(null, { status: 400 });
  }
  const targetProfile = await getUserProfile(client, { username });
  await toggleFollow(client, {
    userId: loggedInUserId,
    targetId: targetProfile.profile_id,
  });
  return {
    ok: true,
  };
}
